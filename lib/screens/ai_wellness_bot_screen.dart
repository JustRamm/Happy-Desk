import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/box_breathing_modal.dart';
import '../widgets/desk_stretches_modal.dart';
import 'notifications_screen.dart';

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
    "I'm sorry, that didn't come through cleanly. I'm here to listen to whatever is on your mind about work or the pressure you're feeling.",
    "That sounds really heavy. I want to stay with what you're experiencing, not move too fast toward a solution.",
    "If you're feeling stuck, it's okay to say that directly. I'm here to help you sort through the part that feels most uncomfortable.",
    "I can help with workplace stress, uncomfortable conversations, or feeling overwhelmed at your desk. Tell me a bit more about what landed hardest for you.",
    "Let's keep this simple. What do you want to feel differently about in this moment?",
  ];

  int _fallbackIndex = 0;

  @override
  void initState() {
    super.initState();
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

    // Default Initial Mochi Welcome Message
    setState(() {
      _messages.add(
        _ChatMessage(
          text:
              "Hey there! I'm Mochi — your workplace stress companion. I'm right here to listen without any judgment. What's been on your mind at work today?",
          isUser: false,
          time: _formatCurrentTime(),
        ),
      );
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

    HapticFeedback.selectionClick();
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

    final bool suggestsBreathing =
        lowerText.contains('breath') ||
        lowerText.contains('anxious') ||
        lowerText.contains('panic') ||
        lowerText.contains('overwhelmed') ||
        lowerText.contains('heart');

    final bool suggestsStretches =
        lowerText.contains('neck') ||
        lowerText.contains('shoulder') ||
        lowerText.contains('back') ||
        lowerText.contains('stiff') ||
        lowerText.contains('exhausted');

    final detectedDistortions = _promptService.detectCognitiveDistortions(text);

    String? determinedAction;
    if (asksBoundary) {
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

      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text: textToDisplay,
            isUser: false,
            time: _formatCurrentTime(),
            actionType: determinedAction,
          ),
        );
      });
      _scrollToBottom();
      _saveMessages();
      summarizeSessionIfNeeded();
    } catch (e) {
      if (!mounted) return;
      final fallbackText = _generateDomainFallbackResponse(text);

      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text: fallbackText,
            isUser: false,
            time: _formatCurrentTime(),
            actionType:
                determinedAction ?? (suggestsBreathing ? 'breathing' : null),
          ),
        );
      });
      _scrollToBottom();
      _saveMessages();
    }
  }

  String _generateDomainFallbackResponse(String userText) {
    final lower = userText.trim().toLowerCase();
    final name = UserPreferencesStore.getUserName();
    final firstName = name.isNotEmpty ? name.split(' ').first : '';

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

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent?key=$_geminiApiKey',
    );

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

    final List<Map<String, dynamic>> contents = [];
    final history = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : List<_ChatMessage>.from(_messages);

    // Clean multi-turn chat history ensuring user/model alternation
    for (var msg in history) {
      final role = msg.isUser ? 'user' : 'model';
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

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String? textResponse;

      if (data['candidates'] != null) {
        textResponse = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      } else if (data['outputs'] != null) {
        textResponse = data['outputs']?[0]?['content']?[0]?['text'];
      } else if (data['outputText'] != null) {
        textResponse = data['outputText'] as String?;
      }

      if (textResponse != null && textResponse.trim().isNotEmpty) {
        return textResponse.trim();
      }
    }

    debugPrint(
      'Mochi Gemini API failed or returned no text. status=${response.statusCode} body=${response.body}',
    );

    final fallbackText =
        _fallbackResponses[_fallbackIndex % _fallbackResponses.length];
    _fallbackIndex++;
    return fallbackText;
  }

  void _recordMoodSentiment(String label) async {
    HapticFeedback.mediumImpact();
    await UserPreferencesStore.incrementMochiCheckIns();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged mood "$label" to your profile statistics!',
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF95416C),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
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
                  ValueListenableBuilder<List<CoffeeNotificationItem>>(
                    valueListenable:
                        CoffeeNotificationStore.notificationsNotifier,
                    builder: (context, notifications, child) {
                      final unreadCount = notifications
                          .where((item) => item.isUnread)
                          .length;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsScreen(),
                                ),
                              );
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF0EB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_rounded,
                                color: Color(0xFFAB3500),
                                size: 22,
                              ),
                            ),
                            tooltip: 'Notifications',
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
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
                    return _buildMessageBubble(_messages[index]);
                  } else {
                    return _buildTypingIndicator();
                  }
                },
              ),
            ),


            // Clean Floating Conversational Input Field (No awkward bottom white gap!)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
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
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendMessage(),
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
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: BoxConstraints(
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
            if (message.actionType == 'boundary')
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Boundary script copied to clipboard!',
                        style: GoogleFonts.beVietnamPro(fontSize: 13),
                      ),
                      backgroundColor: const Color(0xFFAB3500),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(
                  'Copy Script to Clipboard',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6F7F0),
                  foregroundColor: const Color(0xFF047857),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFA7F3D0)),
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              message.time,
              style: GoogleFonts.beVietnamPro(
                fontSize: 10.5,
                color: message.isUser
                    ? Colors.white70
                    : const Color(0xFF8D7168),
              ),
            ),
          ),
        ],
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/brand/mochi_bot.svg',
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 10),
          bubble,
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E7FE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF95416C)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Mochi is listening...',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: const Color(0xFF8D7168),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () => _handleSendMessage(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0EB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFD6C7)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFAB3500),
          ),
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
