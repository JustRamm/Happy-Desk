import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// Voice Emotion Result — returned after recording + analysis
// ---------------------------------------------------------------------------
class VoiceEmotionResult {
  final String transcript;
  final String emotionTag;
  final double avgAmplitudeDb;
  final double peakAmplitudeDb;
  final double silenceRatio;
  final bool likelyCalmBaseline;
  final String detectedLanguage; // 'english', 'manglish', 'malayalam'

  const VoiceEmotionResult({
    required this.transcript,
    required this.emotionTag,
    required this.avgAmplitudeDb,
    required this.peakAmplitudeDb,
    required this.silenceRatio,
    required this.likelyCalmBaseline,
    required this.detectedLanguage,
  });

  bool get isEmpty => transcript.trim().isEmpty;

  /// Human-readable context annotation injected into Gemini's system context.
  String toContextAnnotation() {
    final parts = <String>[];
    parts.add('Tone: $emotionTag');
    parts.add('Language: $detectedLanguage');
    if (avgAmplitudeDb > -15) {
      parts.add('Volume: loud');
    } else if (avgAmplitudeDb < -45) {
      parts.add('Volume: very soft / whisper');
    }
    if (silenceRatio > 0.4) parts.add('Long pauses detected');
    return '[VOICE_EMOTION: ${parts.join(' | ')}]';
  }
}

// ---------------------------------------------------------------------------
// VoiceEmotionService — singleton orchestrating mic, STT, and analysis
// ---------------------------------------------------------------------------
class VoiceEmotionService {
  VoiceEmotionService._();
  static final VoiceEmotionService instance = VoiceEmotionService._();

  final AudioRecorder _recorder = AudioRecorder();
  final SpeechToText _stt = SpeechToText();

  bool _sttInitialized = false;
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  // Amplitude sampling
  final List<double> _amplitudeSamples = [];
  Timer? _amplitudeTimer;
  Timer? _vadTimer;

  // Amplitude stream — UI subscribes for waveform ring
  final StreamController<double> _amplitudeStreamController =
      StreamController<double>.broadcast();
  Stream<double> get amplitudeStream => _amplitudeStreamController.stream;

  // VAD parameters
  static const double _silenceThresholdDb = -50.0;
  static const Duration _vadSilenceDuration = Duration(milliseconds: 1500);

  // Callback when VAD auto-stops
  VoidCallback? _onVadAutoStop;

  // Current locale for STT
  String _currentLocaleId = 'en_IN';

  // -------------------------------------------------------------------------
  // Permission
  // -------------------------------------------------------------------------
  static Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> hasMicPermission() async {
    return await Permission.microphone.isGranted;
  }

  // -------------------------------------------------------------------------
  // STT initialization
  // -------------------------------------------------------------------------
  Future<bool> initializeStt() async {
    if (_sttInitialized) return true;
    try {
      _sttInitialized = await _stt.initialize(
        onError: (e) => debugPrint('Mochi STT error: $e'),
        debugLogging: false,
      );
    } catch (e) {
      debugPrint('Mochi STT init failed: $e');
      _sttInitialized = false;
    }
    return _sttInitialized;
  }

  // -------------------------------------------------------------------------
  // Start recording
  // localeId: 'en_IN' for English / Manglish, 'ml_IN' for Malayalam script
  // -------------------------------------------------------------------------
  Future<bool> startRecording({
    bool whisperMode = false,
    String localeId = 'en_IN',
    VoidCallback? onVadAutoStop,
  }) async {
    if (_isRecording) return false;

    final hasPermission = await hasMicPermission();
    if (!hasPermission) {
      final granted = await requestMicPermission();
      if (!granted) return false;
    }

    _currentLocaleId = localeId;
    _onVadAutoStop = onVadAutoStop;
    _amplitudeSamples.clear();
    _isRecording = true;

    // Start STT listening (live, continuous)
    await initializeStt();
    if (_sttInitialized) {
      _stt.listen(
        onResult: (_) {}, // results collected in stopAndAnalyze
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: const Duration(minutes: 2),
          pauseFor: const Duration(seconds: 3),
          cancelOnError: false,
          partialResults: true,
        ),
      );
    }

    // Start recorder for amplitude polling
    try {
      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
        autoGain: whisperMode,
        echoCancel: true,
        noiseSuppress: true,
      );
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/mochi_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(config, path: tempPath);
    } catch (e) {
      debugPrint('Mochi recorder start error: $e');
    }

    // Poll amplitude every 80ms
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      if (!_isRecording) return;
      try {
        final amp = await _recorder.getAmplitude();
        final db = amp.current.clamp(-80.0, 0.0);
        final displayDb = whisperMode ? (db + 20.0).clamp(-60.0, 0.0) : db;
        _amplitudeSamples.add(db);
        _amplitudeStreamController.add(_dbToNormalized(displayDb));

        // VAD
        if (db > _silenceThresholdDb) {
          _vadTimer?.cancel();
          _vadTimer = null;
        } else {
          _vadTimer ??= Timer(_vadSilenceDuration, () {
            if (_isRecording) {
              debugPrint('Mochi VAD: auto-stop after 1.5s silence');
              _onVadAutoStop?.call();
            }
          });
        }
      } catch (_) {}
    });

    return true;
  }

  // -------------------------------------------------------------------------
  // Stop recording + analyse → return VoiceEmotionResult
  // -------------------------------------------------------------------------
  Future<VoiceEmotionResult> stopAndAnalyze() async {
    _isRecording = false;
    _amplitudeTimer?.cancel();
    _vadTimer?.cancel();
    _amplitudeStreamController.add(0.0);

    // Collect STT result
    String transcript = '';
    try {
      await _stt.stop();
      transcript = _stt.lastRecognizedWords;
    } catch (e) {
      debugPrint('Mochi STT stop error: $e');
    }

    // Stop recorder and delete temp file
    try {
      final audioPath = await _recorder.stop();
      if (audioPath != null) {
        final file = File(audioPath);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}

    // Biomarker analysis
    final biomarkers = _analyzeBiomarkers(_amplitudeSamples);

    // If STT gave empty result (e.g. locale unavailable), transcript stays ''
    final detectedLang = transcript.trim().isNotEmpty
        ? detectLanguage(transcript)
        : (_currentLocaleId == 'ml_IN' ? 'malayalam' : 'english');

    final emotionTag = _classifyEmotion(biomarkers);

    // Update personal vocal baseline (async, fire & forget)
    VocalBaselineStore.update(
      avgDb: biomarkers.avgDb,
      silenceRatio: biomarkers.silenceRatio,
    );

    return VoiceEmotionResult(
      transcript: transcript,
      emotionTag: emotionTag,
      avgAmplitudeDb: biomarkers.avgDb,
      peakAmplitudeDb: biomarkers.peakDb,
      silenceRatio: biomarkers.silenceRatio,
      likelyCalmBaseline: biomarkers.likelyCalmBaseline,
      detectedLanguage: detectedLang,
    );
  }

  // -------------------------------------------------------------------------
  // Cancel without result
  // -------------------------------------------------------------------------
  Future<void> cancelRecording() async {
    _isRecording = false;
    _amplitudeTimer?.cancel();
    _vadTimer?.cancel();
    _amplitudeStreamController.add(0.0);
    try { _stt.cancel(); } catch (_) {}
    try {
      final path = await _recorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Language detection (static — used in text send path too)
  // -------------------------------------------------------------------------
  static String detectLanguage(String text) {
    if (text.trim().isEmpty) return 'english';
    if (_isMalayalamScript(text)) return 'malayalam';
    if (detectManglish(text)) return 'manglish';
    return 'english';
  }

  static bool _isMalayalamScript(String text) {
    return text.runes.any((r) => r >= 0x0D00 && r <= 0x0D7F);
  }

  /// Manglish: Malayalam words written in English (Latin) script.
  static bool detectManglish(String text) {
    final lower = text.toLowerCase();
    const manglishWords = <String>[
      'engane', 'entha', 'enthaa', 'ethu', 'ivide', 'avide', 'ividey',
      'aane', 'aanu', 'anu', 'alle', 'allel', 'alla', 'ayyo',
      'machane', 'machi', 'mone', 'mol', 'eda', 'ede', 'chetta',
      'chechi', 'anna', 'amma', 'achan', 'ente',
      'njan', 'nee', 'ningal', 'avanu', 'aval', 'avar',
      'vere', 'veru', 'venam', 'venda', 'vann', 'vannu',
      'pani', 'paani', 'scene', 'kali', 'kaali', 'kaaryam', 'karyam',
      'adipoli', 'thamasha', 'thamasham',
      'poyi', 'poyo', 'povunnu', 'vaa', 'vaavaa', 'cheyyu',
      'evideyaan', 'enikku', 'ninakku', 'avanku', 'avalku',
      'samayam', 'samayathu', 'bodiyilekku',
      'visecham', 'vishesham', 'nannaayi', 'nannayi', 'nallathu',
      'sheriyalle', 'sheri', 'iipo', 'ippo', 'ippol',
      'athinu', 'ithinu', 'veluppu', 'valiya', 'pakaram',
      'full stress', 'full tension', 'full pani',
      'scene aane', 'pani paali', 'okay aane', 'okay aanu',
    ];
    return manglishWords.any((word) => lower.contains(word));
  }

  // -------------------------------------------------------------------------
  // Acoustic biomarker analysis
  // -------------------------------------------------------------------------
  _AudioBiomarkers _analyzeBiomarkers(List<double> samples) {
    if (samples.isEmpty) {
      return const _AudioBiomarkers(
        avgDb: -60.0, peakDb: -60.0,
        silenceRatio: 1.0, varianceDb: 0.0,
        likelyCalmBaseline: false,
      );
    }
    final avg = samples.reduce((a, b) => a + b) / samples.length;
    final peak = samples.reduce((a, b) => a > b ? a : b);
    final silentCount = samples.where((s) => s < _silenceThresholdDb).length;
    final silenceRatio = silentCount / samples.length;
    final variance = samples
        .map((s) => (s - avg) * (s - avg))
        .reduce((a, b) => a + b) / samples.length;
    return _AudioBiomarkers(
      avgDb: avg,
      peakDb: peak,
      silenceRatio: silenceRatio,
      varianceDb: variance,
      likelyCalmBaseline: avg > -45 && avg < -20 && variance < 60,
    );
  }

  // -------------------------------------------------------------------------
  // Emotion classifier
  // -------------------------------------------------------------------------
  String _classifyEmotion(_AudioBiomarkers b) {
    if (b.avgDb < -52) {
      return b.varianceDb > 80 ? 'Choked / Trembling' : 'Very Soft / Suppressed';
    }
    if (b.varianceDb > 130) return 'High Stress / Trembling';
    if (b.avgDb > -18 && b.varianceDb > 90) return 'Acute Stress / Elevated';
    if (b.silenceRatio > 0.58) return 'Hesitant / Holding Back';
    if (b.avgDb >= -42 && b.avgDb <= -18 && b.varianceDb < 60) return 'Calm';
    if (b.avgDb > -30 && b.varianceDb > 65) return 'Tense';
    return 'Neutral';
  }

  // -------------------------------------------------------------------------
  // dBFS → normalized 0.0–1.0 for waveform ring
  // -------------------------------------------------------------------------
  static double _dbToNormalized(double db) {
    return ((db + 80.0) / 80.0).clamp(0.0, 1.0);
  }

  void dispose() {
    _amplitudeTimer?.cancel();
    _vadTimer?.cancel();
    if (!_amplitudeStreamController.isClosed) {
      _amplitudeStreamController.close();
    }
    _recorder.dispose();
  }
}

// ---------------------------------------------------------------------------
// Internal DTO
// ---------------------------------------------------------------------------
class _AudioBiomarkers {
  final double avgDb;
  final double peakDb;
  final double silenceRatio;
  final double varianceDb;
  final bool likelyCalmBaseline;

  const _AudioBiomarkers({
    required this.avgDb,
    required this.peakDb,
    required this.silenceRatio,
    required this.varianceDb,
    required this.likelyCalmBaseline,
  });
}

// ---------------------------------------------------------------------------
// VocalBaselineStore — persists personal vocal baseline in SharedPreferences
// ---------------------------------------------------------------------------
class VocalBaselineStore {
  static const _keyAvgDb = 'vocal_baseline_avg_db';
  static const _keySilenceRatio = 'vocal_baseline_silence_ratio';
  static const _keySamples = 'vocal_baseline_samples_count';

  static Future<({double avgDb, double silenceRatio})> getBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      avgDb: prefs.getDouble(_keyAvgDb) ?? -35.0,
      silenceRatio: prefs.getDouble(_keySilenceRatio) ?? 0.25,
    );
  }

  /// Exponential moving average update (alpha = 0.15 — gradual learning).
  static Future<void> update({
    required double avgDb,
    required double silenceRatio,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    const alpha = 0.15;
    final currentAvg = prefs.getDouble(_keyAvgDb) ?? avgDb;
    final currentSilence = prefs.getDouble(_keySilenceRatio) ?? silenceRatio;
    final count = prefs.getInt(_keySamples) ?? 0;

    await prefs.setDouble(_keyAvgDb, currentAvg + alpha * (avgDb - currentAvg));
    await prefs.setDouble(_keySilenceRatio, currentSilence + alpha * (silenceRatio - currentSilence));
    await prefs.setInt(_keySamples, count + 1);
  }

  static Future<bool> hasEstablishedBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_keySamples) ?? 0) >= 5;
  }
}
