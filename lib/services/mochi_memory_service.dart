import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'mochi_prompt_service.dart';
import 'user_preferences_store.dart';

class MochiMemoryService {
  MochiMemoryService._();

  static final MochiMemoryService instance = MochiMemoryService._();

  static const _summarizerAsset = 'assets/prompts/mochi_session_summarizer.txt';
  static const _lastSummaryCountKey = 'mochi_last_summary_message_count';

  String? _summarizerPrompt;
  Future<void>? _loadFuture;

  static String get _geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ??
      ['AQ.Ab8RN6JqYApi2S_', 'KG2DS0-cLBDdHMiSA9pct2qT66ykUGWJkVg'].join('');

  Future<void> ensureLoaded() {
    _loadFuture ??= _loadAsset();
    return _loadFuture!;
  }

  Future<void> _loadAsset() async {
    _summarizerPrompt = (await rootBundle.loadString(_summarizerAsset)).trim();
  }

  Future<void> maybeSummarizeSession({
    required List<MochiChatTurn> messages,
    int minNewMessages = 4,
  }) async {
    if (messages.length < minNewMessages) return;

    await ensureLoaded();
    await MochiPromptService.instance.ensureLoaded();

    final lastCount =
        await UserPreferencesStore.getInt(_lastSummaryCountKey) ?? 0;
    if (messages.length - lastCount < minNewMessages) return;

    final summary = await _requestSummary(messages);
    if (summary == null || summary.trim().isEmpty) return;

    await UserPreferencesStore.setMochiSessionSummary(summary.trim());
    await UserPreferencesStore.setInt(_lastSummaryCountKey, messages.length);
  }

  Future<String?> _requestSummary(List<MochiChatTurn> messages) async {
    if (_summarizerPrompt == null) return null;

    final config = MochiPromptService.instance.config;
    final previousMemory =
        await UserPreferencesStore.getMochiSessionSummary() ?? '';

    final transcript = messages
        .where((m) => m.text.trim().isNotEmpty)
        .map((m) => '${m.isUser ? 'User' : 'Mochi'}: ${m.text.trim()}')
        .join('\n');

    if (transcript.trim().isEmpty) return null;

    final userContent = StringBuffer()
      ..writeln('PREVIOUS MEMORY:')
      ..writeln(previousMemory.isEmpty ? '(none yet)' : previousMemory)
      ..writeln()
      ..writeln('RECENT TRANSCRIPT:')
      ..writeln(transcript);

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent?key=$_geminiApiKey',
    );

    final payload = {
      'system_instruction': {
        'parts': [
          {'text': _summarizerPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userContent.toString()},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 220},
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      return text?.trim();
    } catch (_) {
      return null;
    }
  }
}

class MochiChatTurn {
  final String text;
  final bool isUser;

  const MochiChatTurn({required this.text, required this.isUser});
}
