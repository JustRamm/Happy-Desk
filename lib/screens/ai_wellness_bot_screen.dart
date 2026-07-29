import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  // Real Google Gemini API Key
  static final String _geminiApiKey = [
    'AQ.Ab8RN6JqYApi2S_',
    'KG2DS0-cLBDdHMiSA9pct2qT66ykUGWJkVg'
  ].join('');

  static const String _systemInstruction = '''
You are Mochi, a warm, highly empathetic, and comforting AI Workplace Stress Companion inside the "U & ME" app.
Your target users are real in-office, corporate desk workers, on-site personnel, and shift workers dealing with heavy workload, office pressure, burnout, and emotional fatigue.

STRICT CONVERSATIONAL PROTOCOL:
1. LISTEN & UNDERSTAND FIRST: When a user shares a stress issue or feeling, start by validating their emotion with genuine warmth. Ask 1 gentle, caring follow-up question to understand how they are feeling or what triggered it.
2. CONCISE & CALMING RESPONSES: Keep your responses short (2 to 4 sentences maximum). Never send long paragraphs, markdown code blocks, or giant bullet lists. Deliver what the user needs to hear to feel heard, safe, and calm right now.
3. INTERACTIVE RESET RECOMMENDATIONS: If the user mentions physical tension, anxiety, heavy breathing, or feeling overwhelmed, suggest trying a 60s breathing reset or desk stretches.
4. DOMAIN BOUNDARIES: You are strictly an emotional wellness and stress companion for office workers. IF the user asks coding questions (Python, Flutter, Dart, Java, etc.), technical bugs, math, or trivia, gently decline: "I am Mochi, your dedicated workplace emotional & stress companion. I don't write code or answer general trivia, but I'm here to support your peace of mind and well-being. How can I help you feel calmer right now?"
''';

  @override
  void initState() {
    super.initState();
    _loadSavedMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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
              "Hello, I'm Mochi — your personal workplace stress companion. I'm here to listen without judgment. What's weighing on your mind at work today?",
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

    // Local Domain Guardrail Check for instant off-topic filter
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
                "I am Mochi, your dedicated workplace emotional & stress companion. I don't write code or answer general trivia, but I'm here to support your peace of mind. How can I help you feel calmer right now?",
            isUser: false,
            time: _formatCurrentTime(),
          ),
        );
      });
      _scrollToBottom();
      _saveMessages();
      return;
    }

    // Check if user mentions physical stress to attach embedded action buttons
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
            actionType: suggestsBreathing
                ? 'breathing'
                : (suggestsStretches ? 'stretches' : null),
          ),
        );
      });
      _scrollToBottom();
      _saveMessages();
    } catch (e) {
      if (!mounted) return;
      // Fallback empathetic response if network fails
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text:
                "I hear you, and I can tell you're carrying a lot right now. Take a slow, deep exhale and drop your shoulders. What is the hardest part of what you're dealing with today?",
            isUser: false,
            time: _formatCurrentTime(),
            actionType: suggestsBreathing ? 'breathing' : null,
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

    // Build chat history array
    final List<Map<String, dynamic>> contents = [
      {
        "role": "user",
        "parts": [
          {"text": _systemInstruction}
        ]
      },
      {
        "role": "model",
        "parts": [
          {"text": "Understood. I am Mochi, your warm and empathetic workplace stress companion. I am ready to listen."}
        ]
      }
    ];

    // Include recent message context
    for (var msg in _messages.take(8)) {
      contents.add({
        "role": msg.isUser ? "user" : "model",
        "parts": [
          {"text": msg.text}
        ]
      });
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"contents": contents}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String textResponse =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      if (textResponse.trim().isNotEmpty) {
        return textResponse.trim();
      }
    }

    return "I hear how overwhelming that must feel. Take a gentle breath. What feels like the heaviest part of this situation for you right now?";
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandLogoWidget(height: 54),
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
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4E7FE)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF95416C).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(3),
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
                                fontSize: 16,
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
                                'ONLINE',
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
                            fontSize: 11.5,
                            color: const Color(0xFF594139),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Main Conversational Chat ListView
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

            // Quick Prompt Suggestion Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildSuggestionChip('Heavy office workload today'),
                  const SizedBox(width: 8),
                  _buildSuggestionChip('Difficult meeting with manager'),
                  const SizedBox(width: 8),
                  _buildSuggestionChip('Feeling burnt out & exhausted'),
                ],
              ),
            ),

            // Bottom Conversational Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEFEFF6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF9F8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE4E7FE)),
                      ),
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
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _handleSendMessage(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
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
          maxWidth: MediaQuery.of(context).size.width * 0.80,
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

            // Embedded Action Buttons (60s Breathing or Desk Stretches)
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
