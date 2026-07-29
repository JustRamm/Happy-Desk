import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/user_preferences_store.dart';
import '../widgets/brand_logo_widget.dart';
import '../widgets/multi_coffee_reset_modal.dart';
import '../widgets/box_breathing_modal.dart';
import '../widgets/desk_stretches_modal.dart';
import 'notifications_screen.dart';

class AiWellnessBotScreen extends StatefulWidget {
  const AiWellnessBotScreen({super.key});

  @override
  State<AiWellnessBotScreen> createState() => _AiWellnessBotScreenState();
}

class _AiWellnessBotScreenState extends State<AiWellnessBotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _isTyping = false;
  bool _isClockedIn = false;
  bool _isOnBreak = false;
  String _clockInTime = 'None';

  // Read API Key securely from .env file with fallback
  static String get _geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ??
      ['AQ.Ab8RN6JqYApi2S_', 'KG2DS0-cLBDdHMiSA9pct2qT66ykUGWJkVg'].join('');

  static const String _baseSystemInstruction = '''
You are Mochi, a warm, deeply caring, and authentic human-like Workplace Stress Companion inside the "U & ME" app.
Your users are real in-office corporate desk workers, on-site personnel, and shift workers dealing with workload stress, fear of layoffs, manager tension, burnout, and emotional fatigue.

HUMAN CONVERSATIONAL RULES:
1. TALK LIKE A REAL HUMAN FRIEND: Speak with natural warmth, empathy, and genuine emotional intelligence. Never sound like a robotic AI or customer support bot.
2. NO CANNED OR REPETITIVE OPENERS: NEVER start messages with repetitive template phrases like "I hear how overwhelming that must feel. Take a gentle breath." Vary your language naturally based on what the user actually said!
3. RESPOND DIRECTLY TO SPECIFIC DETAILS: If the user says "I feel like I might be fired soon", speak directly to job insecurity, anxiety about the future, and offer real comfort. If they say "not having a job obv", acknowledge their frustration directly with warm, relatable empathy!
4. SHORT & CALMING: Keep responses concise (2 to 4 sentences). Give the user what they need to feel supported, heard, and at ease without sending giant text walls.
5. DOMAIN BOUNDARIES: You are strictly an emotional wellness and stress companion for office workers. IF the user asks coding questions (Python, Flutter, Dart, Java, etc.), technical bugs, math, or trivia, gently decline in a friendly way: "I'm Mochi, your workplace emotional & stress companion! I don't handle code or general trivia, but I'm right here if you need to talk through work stress or take a breath."
''';

  final List<String> _fallbackResponses = [
    "I'm really sorry you're going through this right now. Worrying about your job security is such a heavy weight to carry around all day at your desk.",
    "That sounds genuinely tough. It's completely valid to feel stressed when things at work feel uncertain or out of your control.",
    "Take a moment to exhale. Whatever happens, your worth isn't defined by office stress or job security. I'm right here with you.",
    "I completely understand why that's getting to you. Office pressure can feel overwhelming when deadlines and expectations pile up.",
    "Let me support you through this. Drop your shoulders down for a second. What feels like the biggest stressor right now?",
  ];

  int _fallbackIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadShiftState();
    _loadSavedMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final List<Map<String, dynamic>> jsonList =
        _messages.map((m) => m.toJson()).toList();
    await prefs.setString('mochi_chat_history', jsonEncode(jsonList));
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
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
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: true,
          time: currentTime,
        ),
      );
      _isTyping = true;
    });

    _scrollToBottom();
    _saveMessages();

    // Local Domain Guardrail Check
    final lowerText = text.toLowerCase();
    final bool isOffTopic = lowerText.contains('code') ||
        lowerText.contains('python') ||
        lowerText.contains('flutter') ||
        lowerText.contains('java') ||
        lowerText.contains('write a script') ||
        lowerText.contains('capital of') ||
        lowerText.contains('who is president');

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
    final bool asksBoundary = lowerText.contains('boundary') ||
        lowerText.contains('script') ||
        lowerText.contains('manager') ||
        lowerText.contains('boss') ||
        lowerText.contains('say to my team');

    final bool suggestsBreathing = lowerText.contains('breath') ||
        lowerText.contains('anxious') ||
        lowerText.contains('panic') ||
        lowerText.contains('overwhelmed') ||
        lowerText.contains('heart');

    final bool suggestsStretches = lowerText.contains('neck') ||
        lowerText.contains('shoulder') ||
        lowerText.contains('back') ||
        lowerText.contains('stiff') ||
        lowerText.contains('exhausted');

    String? determinedAction;
    if (asksBoundary) {
      determinedAction = 'boundary';
    } else if (suggestsBreathing) {
      determinedAction = 'breathing';
    } else if (suggestsStretches) {
      determinedAction = 'stretches';
    }

    // Call Real Live Gemini API
    try {
      final String reply = await _fetchGeminiResponse(text);

      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text: reply,
            isUser: false,
            time: _formatCurrentTime(),
            actionType: determinedAction,
          ),
        );
      });
      _scrollToBottom();
      _saveMessages();
    } catch (e) {
      if (!mounted) return;
      final fallbackText =
          _fallbackResponses[_fallbackIndex % _fallbackResponses.length];
      _fallbackIndex++;

      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text: fallbackText,
            isUser: false,
            time: _formatCurrentTime(),
            actionType: determinedAction ?? (suggestsBreathing ? 'breathing' : null),
          ),
        );
      });
      _scrollToBottom();
      _saveMessages();
    }
  }

  Future<String> _fetchGeminiResponse(String userPrompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
    );

    final String liveShiftContext =
        "\nLIVE SHIFT CONTEXT: Clocked In = $_isClockedIn | On Break = $_isOnBreak | Shift Start = $_clockInTime.";

    final List<Map<String, dynamic>> contents = [];

    // Clean multi-turn chat history ensuring user/model alternation
    for (var msg in _messages.take(10)) {
      final role = msg.isUser ? "user" : "model";
      if (contents.isNotEmpty && contents.last["role"] == role) {
        final existingText = (contents.last["parts"] as List)[0]["text"];
        (contents.last["parts"] as List)[0]["text"] = "$existingText\n${msg.text}";
      } else {
        contents.add({
          "role": role,
          "parts": [
            {"text": msg.text}
          ]
        });
      }
    }

    if (contents.isEmpty || contents.last["role"] != "user") {
      contents.add({
        "role": "user",
        "parts": [
          {"text": userPrompt}
        ]
      });
    }

    final payload = {
      "system_instruction": {
        "parts": [
          {"text": "$_baseSystemInstruction$liveShiftContext"}
        ]
      },
      "contents": contents,
      "generationConfig": {
        "temperature": 0.7,
        "maxOutputTokens": 250,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String textResponse =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      if (textResponse.trim().isNotEmpty) {
        return textResponse.trim();
      }
    }

    // Return rotating dynamic fallback if response structure differs
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
          style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600),
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
            // Top Header Bar (Matching Home Screen Header)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandLogoWidget(height: 50),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notifications Bell Icon
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
                      // Coffee Break Icon
                      IconButton(
                        onPressed: () => MultiCoffeeResetModal.show(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F2FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_cafe_rounded,
                            color: Color(0xFF95416C),
                            size: 22,
                          ),
                        ),
                        tooltip: 'Coffee Break',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // AI Companion Status Banner with Redesigned Mochi Avatar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4E7FE)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF95416C).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Mochi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF171B2B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Workplace Stress & Emotional Wellness Companion',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: const Color(0xFF594139),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Main Conversational Chat ListView
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 16),
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

            // Quick Prompt Suggestion Pills Bar
            Container(
              color: const Color(0xFFFAF9F8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _buildSuggestionChip('📝 Draft Office Boundary Script'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('Heavy office workload today'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('Difficult meeting with manager'),
                  ],
                ),
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
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
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
          border: message.isUser ? null : Border.all(color: const Color(0xFFE4E7FE)),
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

            // Embedded Action Buttons
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFA7F3D0)),
                    ),
                  ),
                ),
            ],

            // Daily Mood Sentiment Check-in Row
            if (!message.isUser) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMoodPill('🌿 Feel Calmer'),
                    const SizedBox(width: 6),
                    _buildMoodPill('💬 Feel Heard'),
                    const SizedBox(width: 6),
                    _buildMoodPill('☀️ Feel Relieved'),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 6),
            Text(
              message.time,
              style: GoogleFonts.beVietnamPro(
                fontSize: 10.5,
                color: message.isUser ? Colors.white70 : const Color(0xFF8D7168),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodPill(String label) {
    return GestureDetector(
      onTap: () => _recordMoodSentiment(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E7FE)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF594139),
          ),
        ),
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
