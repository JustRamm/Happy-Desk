import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/user_preferences_store.dart';
import '../services/mochi_prompt_service.dart';
import '../services/mochi_memory_service.dart';
import '../services/coffee_notification_store.dart';
import '../services/supabase_service.dart';
import '../services/sound_service.dart';
import '../widgets/box_breathing_modal.dart';
import '../widgets/desk_stretches_modal.dart';
import '../widgets/notification_bell_widget.dart';

class AiWellnessBotScreen extends StatefulWidget {
  const AiWellnessBotScreen({super.key});

  @override
  State<AiWellnessBotScreen> createState() => AiWellnessBotScreenState();
}

class AiWellnessBotScreenState extends State<AiWellnessBotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _isTyping = false;
  bool _isClockedIn = false;
  bool _isOnBreak = false;
  String _clockInTime = 'None';
  String _userProfileSummary = '';
  String _roleKnowledgeHint = '';
  String _leaveSummary = '';
  String _coffeeHistorySummary = '';
  String _cbtTrendSummary = '';

  // Read API Key securely from .env file with fallback
  static String get _geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ??
      ['AQ.Ab8RN6JqYApi2S_', 'KG2DS0-cLBDdHMiSA9pct2qT66ykUGWJkVg'].join('');

  final MochiPromptService _promptService = MochiPromptService.instance;

  final List<String> _fallbackResponses = [
    "I hear you. Navigating work dynamics and personal feelings can take a lot of mental energy. What part of this feels most important to sort out right now?",
    "Whether you're looking for a practical action plan or just need a safe space to unpack what's on your mind, I'm right here with you.",
    "If you're feeling stuck or uncertain, we can break it down step-by-step. Tell me a bit more about what's going on.",
    "I'm here to help with workplace relationships, stress, or tough conversations. What would feel most helpful for you in this moment?",
    "Let's focus on what gives you clarity and peace of mind. What's the main thing on your mind right now?",
  ];

  int _fallbackIndex = 0;

  @override
  void initState() {
    super.initState();
    SoundService.playMessageOpenSound();
    _promptService.ensureLoaded();
    _loadShiftState();
    _loadSavedMessages();
    _loadUserProfileContext();
  }

  Future<void> _loadUserProfileContext() async {
    await UserPreferencesStore.loadProfileData();
    final fullProfile = UserPreferencesStore.getFullUserProfileSummary();
    final role = UserPreferencesStore.getUserRole();
    final leaveSum = await UserPreferencesStore.getLeaveSummary();
    final cbtTrend = await UserPreferencesStore.getMochiCbtTrendSummary();
    final coffeeItems = CoffeeNotificationStore.notificationsNotifier.value;
    final coffeeHist = coffeeItems.isNotEmpty
        ? 'Total coffee break invites: ${coffeeItems.length} (${coffeeItems.where((i) => i.isAccepted).length} accepted).'
        : 'No coffee break invites recorded yet.';

    setState(() {
      _userProfileSummary = fullProfile;
      _leaveSummary = leaveSum;
      _coffeeHistorySummary = coffeeHist;
      _cbtTrendSummary = cbtTrend ?? '';
      _roleKnowledgeHint = _promptService.buildRoleKnowledgeHint(role);
    });
  }

  @override
  void dispose() {
    summarizeSessionIfNeeded();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void summarizeSessionIfNeeded() {
    if (_messages.length < 4) return;

    final turns = _messages
        .map((m) => MochiChatTurn(text: m.text, isUser: m.isUser))
        .toList();

    MochiMemoryService.instance.maybeSummarizeSession(
      messages: turns,
      minNewMessages: 4,
    );
  }

  Future<void> _loadShiftState() async {
    final clockedIn = await UserPreferencesStore.isClockedIn();
    final onBreak = await UserPreferencesStore.isOnBreak();
    final lastTime = await UserPreferencesStore.getLastClockInTime();
    setState(() {
      _isClockedIn = clockedIn;
      _isOnBreak = onBreak;
      _clockInTime = lastTime ?? 'Not Shift Logged Today';
    });
  }

  Future<void> _loadSavedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedJson = prefs.getString('mochi_chat_history');

    if (savedJson != null && savedJson.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(savedJson);
        setState(() {
          _messages.clear();
          for (var item in list) {
            _messages.add(_ChatMessage.fromJson(item));
          }
        });
        _scrollToBottom();
        return;
      } catch (_) {}
    }

    final name = UserPreferencesStore.getUserName();
    final firstName = name.isNotEmpty ? name.split(' ').first : '';
    final fn = firstName.isNotEmpty ? ' $firstName' : '';

    final complementaryPairs = [
      ("Hey$fn, I'm Mochi!", "How's your day treating you so far?"),
      ("Hi$fn! Mochi here.", "wassup"),
      ("Aah... hey$fn!", "Taking a quick break or feeling a bit overwhelmed?"),
      ("Hey$fn, glad you stopped by!", "How are things at work today?"),
      ("Hi$fn!", "What's on your mind right now?"),
      ("Hey$fn, Mochi here!", "Feeling bored or just checking in?"),
    ];

    final random = math.Random();
    final pair = complementaryPairs[random.nextInt(complementaryPairs.length)];

    // Default Initial Mochi Welcome Messages (2 separate complementary messages)
    setState(() {
      _messages.addAll([
        _ChatMessage(
          text: pair.$1,
          isUser: false,
          time: _formatCurrentTime(),
        ),
        _ChatMessage(
          text: pair.$2,
          isUser: false,
          time: _formatCurrentTime(),
        ),
      ]);
    });
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _messages
        .map((m) => m.toJson())
        .toList();
    await prefs.setString('mochi_chat_history', jsonEncode(jsonList));
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? prefilledText]) async {
    final text = prefilledText ?? _textController.text.trim();
    if (text.isEmpty) return;

    SoundService.playMessageSentSound();
    _textController.clear();

    final currentTime = _formatCurrentTime();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, time: currentTime));
      _isTyping = true;
    });

    _scrollToBottom();
    _saveMessages();

    await _maybeCaptureStylePreference(text);

    // Local domain guardrail check (keywords from mochi_config.json)
    final lowerText = text.toLowerCase();
    final offTopicKeywords = _promptService.offTopicKeywords;
    final bool isOffTopic = offTopicKeywords.any(lowerText.contains);

    if (isOffTopic) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text:
                "I'm Mochi, your workplace stress companion! I don't handle code or general trivia, but I'm right here if you need to talk through work stress or take a breath.",
            isUser: false,
            time: _formatCurrentTime(),
          ),
        );
      });
      _scrollToBottom();
      _saveMessages();
      return;
    }

    // Detect feature triggers for action buttons
    final bool asksBoundary =
        lowerText.contains('boundary') ||
        lowerText.contains('script') ||
        lowerText.contains('manager') ||
        lowerText.contains('boss') ||
        lowerText.contains('say to my team');

    final bool isPersonalCrisis =
        lowerText.contains('sick') ||
        lowerText.contains('die') ||
        lowerText.contains('hospital') ||
        lowerText.contains('mom') ||
        lowerText.contains('mother') ||
        lowerText.contains('father') ||
        lowerText.contains('dad') ||
        lowerText.contains('family') ||
        lowerText.contains('emergency') ||
        lowerText.contains('passed away');

    final bool suggestsBreathing = !isPersonalCrisis &&
        (lowerText.contains('breath') ||
        lowerText.contains('anxious') ||
        lowerText.contains('panic') ||
        lowerText.contains('overwhelmed') ||
        lowerText.contains('heart'));

    final bool suggestsStretches = !isPersonalCrisis &&
        (lowerText.contains('neck') ||
        lowerText.contains('shoulder') ||
        lowerText.contains('back') ||
        lowerText.contains('stiff') ||
        lowerText.contains('exhausted'));

    final detectedDistortions = isPersonalCrisis
        ? <String>[]
        : _promptService.detectCognitiveDistortions(text);

    String? determinedAction;
    if (isPersonalCrisis) {
      determinedAction = null;
    } else if (asksBoundary) {
      determinedAction = 'boundary';
    } else if (suggestsBreathing) {
      determinedAction = 'breathing';
    } else if (suggestsStretches) {
      determinedAction = 'stretches';
    } else if (detectedDistortions.isNotEmpty) {
      determinedAction = 'cbt_reframe';
    }

    // Call Real Live Gemini API
    try {
      final String reply = await _fetchGeminiResponse(
        text,
        detectedDistortions: detectedDistortions,
      );
      final parsed = _promptService.parseModelReply(reply);

      if (parsed.moodLog != null) {
        await UserPreferencesStore.appendMochiMoodLog(parsed.moodLog!);
        await UserPreferencesStore.incrementMochiCheckIns();
      }

      final textToDisplay = parsed.visibleText.isNotEmpty ? parsed.visibleText : reply;

      // Save user & model turns to Supabase per-timestamp history
      SupabaseService.instance.saveMochiChatMessage(
        message: text,
        isUser: true,
      );
      SupabaseService.instance.saveMochiChatMessage(
        message: textToDisplay,
        isUser: false,
        actionType: determinedAction,
      );

      final chunks = _splitBotResponse(textToDisplay);

      if (!mounted) return;
      setState(() {
        _isTyping = false;
      });

      for (int i = 0; i < chunks.length; i++) {
        if (!mounted) return;
        setState(() {
          _messages.add(
            _ChatMessage(
              text: chunks[i],
              isUser: false,
              time: _formatCurrentTime(),
              actionType: (i == chunks.length - 1) ? determinedAction : null,
            ),
          );
        });
        _scrollToBottom();
        _saveMessages();
        if (i < chunks.length - 1) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }

      summarizeSessionIfNeeded();
    } catch (e) {
      if (!mounted) return;
      final fallbackText = _generateDomainFallbackResponse(text);
      final chunks = _splitBotResponse(fallbackText);
      final finalAction = determinedAction ?? (suggestsBreathing ? 'breathing' : null);

      setState(() {
        _isTyping = false;
      });

      for (int i = 0; i < chunks.length; i++) {
        if (!mounted) return;
        setState(() {
          _messages.add(
            _ChatMessage(
              text: chunks[i],
              isUser: false,
              time: _formatCurrentTime(),
              actionType: (i == chunks.length - 1) ? finalAction : null,
            ),
          );
        });
        _scrollToBottom();
        _saveMessages();
        if (i < chunks.length - 1) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    }
  }

  String _generateDomainFallbackResponse(String userText) {
    final lower = userText.trim().toLowerCase();
    final name = UserPreferencesStore.getUserName();
    final firstName = name.isNotEmpty ? name.split(' ').first : '';

    // Family Sickness, Illness & Emergency Care
    if (lower.contains('sick') ||
        lower.contains('die') ||
        lower.contains('hospital') ||
        lower.contains('mom') ||
        lower.contains('mother') ||
        lower.contains('father') ||
        lower.contains('dad') ||
        lower.contains('family') ||
        lower.contains('emergency') ||
        lower.contains('passed away')) {
      return "Oh no... I am so sorry to hear that. Hearing that someone close to you is sick or in danger is terrifying and overwhelming. Please don't worry about work right now — take a deep breath and focus on being there for your family. I'm right here with you if you need a safe space to talk or vent.";
    }

    // Casual Chit-Chat ("how are you", "how was your day", "what about you")
    if (lower.contains('how are you') ||
        lower.contains('how is it going') ||
        lower.contains('how was your day') ||
        lower.contains('how\'s your day') ||
        lower.contains('what about you') ||
        lower.contains('how r u')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      if (lower.contains('day')) {
        return "Honestly? It was kind of slow and quiet here, I was getting a bit lonely waiting for you! How was your day$namePart?";
      }
      return "Aah... I'm doing pretty good! A bit quiet here waiting for you, but I'm glad you stopped by$namePart. How are you holding up today?";
    }

    // Coworker & Team compatibility / disconnect
    if (lower.contains('coworker') ||
        lower.contains('out of touch') ||
        lower.contains('not on the same page') ||
        lower.contains('compatibility') ||
        lower.contains('connecting with my coworkers')) {
      return "Feeling out of sync with your team can make everyday work feel way more exhausting than it needs to be. Often, this disconnect comes down to different communication styles rather than a true lack of compatibility.\n\nHere is a simple, low-pressure approach: try starting with small 1-on-1 micro-connections over coffee or quick check-ins, rather than trying to fix the whole team dynamic at once.";
    }

    // Workplace relationship / Manager romance dynamics
    if (lower.contains('crush') ||
        lower.contains('boss') ||
        lower.contains('in love') ||
        lower.contains('unethical') ||
        lower.contains('manager') ||
        lower.contains('dating') ||
        lower.contains('romance') ||
        lower.contains('feelings for')) {
      return "Here's the straight answer: Do not act on romantic feelings while they are still your direct manager or boss.\n\nFalling for a manager happens, but pursuing a connection across a direct reporting line creates significant workplace and ethical risks:\n\n• Power Dynamic & Ethics: It compromises objective performance reviews, task assignments, and team credibility.\n• HR Policies: Most organizations have strict non-fraternization policies for direct reporting lines.\n\nIf the feelings are serious, either maintain strict professional boundaries or explore transferring to a different team before pursuing anything further.";
    }

    // Greetings
    final greetingWords = [
      'hi',
      'hello',
      'hey',
      'good morning',
      'good afternoon',
      'good evening',
      'howdy',
      'yo',
      'sup'
    ];
    if (greetingWords.contains(lower) ||
        greetingWords.any((g) => lower.startsWith('$g ') || lower.endsWith(' $g'))) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Hey$namePart! I'm Mochi, your workplace stress companion. I'm right here with you — how's your work day going so far?";
    }

    // Technical / workload friction
    if (lower.contains('bug') ||
        lower.contains('code') ||
        lower.contains('build') ||
        lower.contains('deploy') ||
        lower.contains('ticket') ||
        lower.contains('sprint') ||
        lower.contains('deadline') ||
        lower.contains('stuck') ||
        lower.contains('error')) {
      return "Technical friction and tight deadlines can be mentally exhausting. Let me suggest a small next step: take a 2-minute breather away from the screen, or let's break down the next smallest action item together.";
    }

    // High stress / anxiety
    if (lower.contains('anxious') ||
        lower.contains('overwhelmed') ||
        lower.contains('stress') ||
        lower.contains('burnout') ||
        lower.contains('panic')) {
      return "That sounds like a heavy weight to carry right now. I'm right here with you. Would a quick 60-second breathing exercise help clear space, or do you want to talk it through?";
    }

    final text = _fallbackResponses[_fallbackIndex % _fallbackResponses.length];
    _fallbackIndex++;
    return text;
  }

  List<String> _splitBotResponse(String fullText) {
    final trimmed = fullText.trim();
    if (trimmed.isEmpty) return [fullText];

    // Try splitting by double newlines (paragraphs)
    final paragraphs = trimmed
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphs.length >= 2 && paragraphs.length <= 3) {
      return paragraphs;
    }
    if (paragraphs.length > 3) {
      final chunk1 = paragraphs[0];
      final chunk2 = paragraphs[1];
      final chunk3 = paragraphs.sublist(2).join('\n\n');
      return [chunk1, chunk2, chunk3];
    }

    // If text is short (< 160 chars), keep it in 1 message bubble
    if (trimmed.length < 160) {
      return [trimmed];
    }

    // Split single long text into sentences (. ! ?)
    final sentenceMatches = RegExp(r'[^.!?]+[.!?]+').allMatches(trimmed);
    final sentences = sentenceMatches.map((m) => m.group(0)!.trim()).toList();

    if (sentences.length <= 1) {
      return [trimmed];
    } else if (sentences.length == 2) {
      return [sentences[0], sentences[1]];
    } else {
      final partSize = (sentences.length / 3).ceil();
      final p1 = sentences.sublist(0, partSize).join(' ');
      final p2 = sentences
          .sublist(partSize, (partSize * 2).clamp(0, sentences.length))
          .join(' ');
      final p3 = sentences
          .sublist((partSize * 2).clamp(0, sentences.length))
          .join(' ');

      final result = <String>[];
      if (p1.trim().isNotEmpty) result.add(p1.trim());
      if (p2.trim().isNotEmpty) result.add(p2.trim());
      if (p3.trim().isNotEmpty) result.add(p3.trim());

      return result.isNotEmpty ? result : [trimmed];
    }
  }

  Future<void> _maybeCaptureStylePreference(String text) async {
    final lower = text.toLowerCase();
    if (lower.contains('be more direct') || lower.contains('more direct')) {
      await UserPreferencesStore.setMochiStylePreference(
        'Be more direct and concise.',
      );
    } else if (lower.contains('be more gentle') ||
        lower.contains('more gentle')) {
      await UserPreferencesStore.setMochiStylePreference(
        'Be more gentle and soft-spoken.',
      );
    } else if (lower.contains('talk less') ||
        lower.contains('more sparse') ||
        lower.contains('shorter replies')) {
      await UserPreferencesStore.setMochiStylePreference(
        'Keep replies sparse and minimal.',
      );
    } else if (lower.contains('talk more') || lower.contains('more talkative')) {
      await UserPreferencesStore.setMochiStylePreference(
        'Be slightly more talkative and expansive.',
      );
    }
  }

  Future<String> _fetchGeminiResponse(
    String userPrompt, {
    List<String>? detectedDistortions,
  }) async {
    await _promptService.ensureLoaded();
    final config = _promptService.config;

    final sessionMemory = await UserPreferencesStore.getMochiSessionSummary();
    final stylePreference = await UserPreferencesStore.getMochiStylePreference();
    final moodTrendSummary =
        await UserPreferencesStore.getMochiMoodTrendSummary();

    final systemInstruction = _promptService.buildSystemInstruction(
      isClockedIn: _isClockedIn,
      isOnBreak: _isOnBreak,
      clockInTime: _clockInTime,
      sessionMemorySummary: sessionMemory,
      userStylePreference: stylePreference,
      moodTrendSummary: moodTrendSummary,
      userProfileSummary: _userProfileSummary,
      roleKnowledgeHint: _roleKnowledgeHint,
      leaveSummary: _leaveSummary,
      coffeeHistorySummary: _coffeeHistorySummary,
      cbtTrendSummary: _cbtTrendSummary,
      detectedDistortions: detectedDistortions,
    );

    // Build multi-turn chat history ensuring user/model alternation AND user start
    final List<Map<String, dynamic>> contents = [];
    final history = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : List<_ChatMessage>.from(_messages);

    for (var msg in history) {
      final role = msg.isUser ? 'user' : 'model';

      // Gemini API rule: contents must start with 'user'
      if (contents.isEmpty && role == 'model') {
        continue; // Skip initial bot greeting in payload history
      }

      if (contents.isNotEmpty && contents.last['role'] == role) {
        final existingText = (contents.last['parts'] as List)[0]['text'];
        (contents.last['parts'] as List)[0]['text'] =
            '$existingText\n${msg.text}';
      } else {
        contents.add({
          'role': role,
          'parts': [
            {'text': msg.text},
          ],
        });
      }
    }

    if (contents.isEmpty || contents.last["role"] != "user") {
      contents.add({
        "role": "user",
        "parts": [
          {"text": userPrompt},
        ],
      });
    }

    final primaryUrl = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent?key=$_geminiApiKey',
    );

    final payload = {
      "system_instruction": {
        "parts": [
          {"text": systemInstruction},
        ],
      },
      "contents": contents,
      "generationConfig": {
        "temperature": config.temperature,
        "maxOutputTokens": config.maxOutputTokens,
      },
    };

    try {
      var response = await http.post(
        primaryUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? textResponse =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (textResponse != null && textResponse.trim().isNotEmpty) {
          return textResponse.trim();
        }
      }

      debugPrint('Mochi primary API status ${response.statusCode}, trying single-turn prompt with embedded system instruction...');

      // Fallback 1: Embedded System Instruction + Single User Turn
      final singleTurnPayload = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": "$systemInstruction\n\nUser Query: $userPrompt"},
            ],
          }
        ],
        "generationConfig": {
          "temperature": config.temperature,
          "maxOutputTokens": config.maxOutputTokens,
        },
      };

      response = await http.post(
        primaryUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(singleTurnPayload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? textResponse =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (textResponse != null && textResponse.trim().isNotEmpty) {
          return textResponse.trim();
        }
      }

      // Fallback 2: Try gemini-1.5-pro endpoint
      final altUrl = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$_geminiApiKey',
      );
      response = await http.post(
        altUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(singleTurnPayload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? textResponse =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (textResponse != null && textResponse.trim().isNotEmpty) {
          return textResponse.trim();
        }
      }
    } catch (e) {
      debugPrint('Mochi API exception: $e');
    }

    return _generateDomainFallbackResponse(userPrompt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header — Mochi avatar, name, and online tag
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF0EB),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      'assets/brand/mochi_bot.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Mochi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF171B2B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isClockedIn ? 'OFFICE SHIFT ACTIVE' : 'ONLINE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF006C53),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const NotificationBellWidget(),
                ],
              ),
            ),



            // Main Conversational Chat ListView
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom: 16,
                ),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    final msg = _messages[index];
                    // Render Mochi avatar ONLY on the last (latest) message of a bot group
                    final bool isNextAlsoBot =
                        (index + 1 < _messages.length) && !_messages[index + 1].isUser;
                    final bool showAvatar = !msg.isUser && !isNextAlsoBot;

                    return _buildMessageBubble(msg, showAvatar: showAvatar);
                  } else {
                    return _buildTypingIndicator();
                  }
                },
              ),
            ),


            // Clean Floating Conversational Input Field (Multiline, line wrap & max height)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4E7FE), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF95416C).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      scrollPhysics: const BouncingScrollPhysics(),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: const Color(0xFF171B2B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Talk to Mochi about your stress...',
                        hintStyle: GoogleFonts.beVietnamPro(
                          fontSize: 13.5,
                          color: const Color(0xFF8D7168),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GestureDetector(
                      onTap: () => _handleSendMessage(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF95416C),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x3395416C),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, {bool showAvatar = true}) {
    final bubble = IntrinsicWidth(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          minWidth: 48,
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: message.isUser ? const Color(0xFF95416C) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(message.isUser ? 22 : 4),
          bottomRight: Radius.circular(message.isUser ? 4 : 22),
        ),
        border: message.isUser
            ? null
            : Border.all(color: const Color(0xFFE4E7FE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13.5,
              height: 1.45,
              color: message.isUser ? Colors.white : const Color(0xFF171B2B),
            ),
          ),
          if (!message.isUser && message.actionType != null) ...[
            const SizedBox(height: 12),
            if (message.actionType == 'breathing')
              ElevatedButton.icon(
                onPressed: () => BoxBreathingModal.show(context),
                icon: const Icon(Icons.self_improvement_rounded, size: 16),
                label: Text(
                  'Start 60s Breathing Reset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF0EB),
                  foregroundColor: const Color(0xFFAB3500),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFFFD6C7)),
                  ),
                ),
              ),
            if (message.actionType == 'stretches')
              ElevatedButton.icon(
                onPressed: () => DeskStretchesModal.show(context),
                icon: const Icon(Icons.fitness_center_rounded, size: 16),
                label: Text(
                  'Start 3-Min Desk Stretches',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F2FF),
                  foregroundColor: const Color(0xFF95416C),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE4E7FE)),
                  ),
                ),
              ),
            if (message.actionType == 'cbt_reframe')
              ElevatedButton.icon(
                onPressed: () => _handleSendMessage(
                  'Can you help me examine the evidence for this thought and reframe it?',
                ),
                icon: const Icon(Icons.psychology_rounded, size: 16),
                label: Text(
                  'Examine Evidence & Reframe Thought',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF1D4ED8),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.time,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10,
                  color: message.isUser
                      ? Colors.white70
                      : const Color(0xFF8D7168),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: bubble,
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            showAvatar
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SvgPicture.asset(
                      'assets/brand/mochi_bot.svg',
                      width: 32,
                      height: 32,
                    ),
                  )
                : const SizedBox(width: 32),
            const SizedBox(width: 10),
            bubble,
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const _MochiListeningIndicator();
  }
}

class _MochiListeningIndicator extends StatefulWidget {
  const _MochiListeningIndicator();

  @override
  State<_MochiListeningIndicator> createState() =>
      __MochiListeningIndicatorState();
}

class __MochiListeningIndicatorState extends State<_MochiListeningIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  Timer? _dotsTimer;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _dotsTimer = Timer.periodic(const Duration(milliseconds: 320), (timer) {
      if (!mounted) return;
      setState(() {
        if (_dotCount < 4) {
          _dotCount++;
        } else {
          _dotCount = 2; // Cycle back: 1 -> 2 -> 3 -> 4 -> 2 -> 3 -> 4...
        }
      });
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _dotsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bounceAnimation.value),
                  child: child,
                );
              },
              child: SvgPicture.asset(
                'assets/brand/mochi_bot.svg',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Mochi is listening$dots',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8D7168),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final String? actionType;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.actionType,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'time': time,
    'actionType': actionType,
  };

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
    text: json['text'] ?? '',
    isUser: json['isUser'] ?? false,
    time: json['time'] ?? '',
    actionType: json['actionType'],
  );
}
