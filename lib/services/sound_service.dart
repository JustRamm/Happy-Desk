import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

enum HapticFeedbackType { light, medium, heavy, selection }

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _audioContextConfigured = false;

  static void _ensureAudioContextConfigured() {
    if (_audioContextConfigured) return;
    try {
      AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ));
      _audioContextConfigured = true;
    } catch (_) {}
  }

  static Future<void> _playSoundUrl(
    String url,
    SystemSoundType soundType,
    HapticFeedbackType hapticType,
  ) async {
    _ensureAudioContextConfigured();
    try {
      if (hapticType == HapticFeedbackType.heavy) {
        await HapticFeedback.heavyImpact();
      } else if (hapticType == HapticFeedbackType.medium) {
        await HapticFeedback.mediumImpact();
      } else if (hapticType == HapticFeedbackType.light) {
        await HapticFeedback.lightImpact();
      } else {
        await HapticFeedback.selectionClick();
      }

      await SystemSound.play(soundType);

      await _player.stop();
      await _player.setVolume(0.7);
      await _player.play(UrlSource(url)).timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () async {
          await SystemSound.play(soundType);
        },
      );
    } catch (e) {
      await SystemSound.play(soundType);
    }
  }

  /// Play Inhale breath sound
  static Future<void> playInhaleSound() async {
    await _playSoundUrl(
      'https://assets.mixkit.co/active_storage/sfx/2569/2569-preview.mp3',
      SystemSoundType.click,
      HapticFeedbackType.selection,
    );
  }

  /// Play Exhale breath sound
  static Future<void> playExhaleSound() async {
    await _playSoundUrl(
      'https://assets.mixkit.co/active_storage/sfx/2570/2570-preview.mp3',
      SystemSoundType.click,
      HapticFeedbackType.light,
    );
  }

  /// Play Hold breath tone
  static Future<void> playHoldSound() async {
    await HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  /// Play Desk Stretches step transition sound
  static Future<void> playStretchStepSound() async {
    await _playSoundUrl(
      'https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3',
      SystemSoundType.click,
      HapticFeedbackType.medium,
    );
  }

  /// Play Shred paper / Dissolve Vent Note sound
  static Future<void> playShredSound() async {
    await _playSoundUrl(
      'https://assets.mixkit.co/active_storage/sfx/2048/2048-preview.mp3',
      SystemSoundType.click,
      HapticFeedbackType.heavy,
    );
  }

  /// Play Open NGL Jar note sound
  static Future<void> playJarOpenSound() async {
    await _playSoundUrl(
      'https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3',
      SystemSoundType.click,
      HapticFeedbackType.medium,
    );
  }

  /// Play Clock-In sound
  static Future<void> playClockInSound() async {
    await _playSoundUrl(
      'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3',
      SystemSoundType.click,
      HapticFeedbackType.selection,
    );
  }

  /// Play Clock-Out sound
  static Future<void> playClockOutSound() async {
    await _playSoundUrl(
      'https://assets.mixkit.co/active_storage/sfx/2571/2571-preview.mp3',
      SystemSoundType.click,
      HapticFeedbackType.light,
    );
  }

  /// Play Message Sent sound
  static Future<void> playMessageSentSound() async {
    await _playSoundUrl(
      'https://assets.mixkit.co/active_storage/sfx/2354/2354-preview.mp3',
      SystemSoundType.click,
      HapticFeedbackType.light,
    );
  }

  /// Play Message Open / Chat click sound
  static Future<void> playMessageOpenSound() async {
    await _playSoundUrl(
      'https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3',
      SystemSoundType.click,
      HapticFeedbackType.selection,
    );
  }

  /// Play NGL Anonymous Message Sent sound
  static Future<void> playNglSendSound() async {
    await _playSoundUrl(
      'https://assets.mixkit.co/active_storage/sfx/2578/2578-preview.mp3',
      SystemSoundType.click,
      HapticFeedbackType.heavy,
    );
  }
}
