import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo_widget.dart';
import '../widgets/multi_coffee_reset_modal.dart';
import 'notifications_screen.dart';

class AiWellnessBotScreen extends StatefulWidget {
  const AiWellnessBotScreen({super.key});

  @override
  State<AiWellnessBotScreen> createState() => _AiWellnessBotScreenState();
}

class _AiWellnessBotScreenState extends State<AiWellnessBotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _isAssessmentCompleted = false;
  int _currentStep = 0;
  String _selectedTrigger = '';
  String _selectedSignal = '';
  String _selectedRestStyle = '';
  bool _isTyping = false;

  final List<String> _triggers = [
    'Deadlines & Heavy Workload',
    'Unclear Communication',
    'Back-to-Back Meetings',
    'Work-Life Boundaries',
  ];

  final List<String> _signals = [
    'Neck & Shoulder Tension',
    'Mental Fog & Anxiety',
    'Shallow Breathing',
    'Restlessness & Exhaustion',
  ];

  final List<String> _restStyles = [
    'Guided 60s Breathing',
    'Gentle Actionable Advice',
    'Empathetic Listening',
    'Silent Mindful Reset',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(
      _ChatMessage(
        text:
            "Hello, I'm **Mochi** — your personal workplace emotional & stress companion. Before we begin, let's complete a quick 3-step baseline to understand your stress signals and rest style.",
        isUser: false,
        time: 'Just now',
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _completeAssessmentStep() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_currentStep < 2) {
        _currentStep++;
      } else {
        _isAssessmentCompleted = true;
        _messages.add(
          _ChatMessage(
            text:
                "Thank you for sharing your baseline profile! I've noted that **$_selectedTrigger** triggers your stress, showing as **$_selectedSignal**, and you prefer **$_selectedRestStyle**.\n\nHow are you feeling right now? Tell me what's on your mind.",
            isUser: false,
            time: 'Just now',
          ),
        );
        _scrollToBottom();
      }
    });
  }

  void _handleSendMessage([String? prefilledText]) {
    final text = prefilledText ?? _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.selectionClick();
    _textController.clear();

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: true,
          time: 'Just now',
        ),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    // Check for strict domain guardrail (coding / trivia / off-topic)
    final lowerText = text.toLowerCase();
    final bool isOffTopic = lowerText.contains('code') ||
        lowerText.contains('python') ||
        lowerText.contains('flutter') ||
        lowerText.contains('java') ||
        lowerText.contains('bug') ||
        lowerText.contains('write a script') ||
        lowerText.contains('capital of') ||
        lowerText.contains('who is');

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      String reply;
      if (isOffTopic) {
        reply =
            "I am Mochi, your dedicated workplace emotional & stress companion. I don't answer coding or general trivia questions, but I'm here to support your peace of mind and well-being. How can I help you feel calmer right now?";
      } else {
        // Personalized stress response based on assessment profile
        reply =
            "I hear you. Dealing with $text can weigh heavily when your stress manifests as $_selectedSignal. Let's take a moment together: pause your task, drop your shoulders down, and take 2 slow, deep breaths.\n\nWould you like to try a quick 60s breathing reset or talk through what's bothering you?";
      }

      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text: reply,
            isUser: false,
            time: 'Just now',
          ),
        );
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar (Matching Home Header)
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
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // AI Status Bar Banner with Custom Mochi Avatar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE4E7FE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(4),
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
                        Text(
                          'Mochi — Mindful AI Companion',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF171B2B),
                          ),
                        ),
                        Text(
                          'Workplace Stress & Emotional Wellness Only',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11.5,
                            color: const Color(0xFF594139),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),

            // Main Body Chat + Onboarding Assessment Card
            Expanded(
              child: ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Initial Behavioral Assessment Card (Step 0 to 2)
                  if (!_isAssessmentCompleted) _buildAssessmentCard(),

                  const SizedBox(height: 12),

                  // Chat Message Bubbles
                  ..._messages.map((msg) => _buildMessageBubble(msg)),

                  // Typing Indicator
                  if (_isTyping) _buildTypingIndicator(),
                ],
              ),
            ),

            // Quick Prompt Suggestion Chips
            if (_isAssessmentCompleted)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    _buildSuggestionChip('Feeling overwhelmed by deadlines'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('Hard to disconnect after work'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('Need a 2-min anxiety reset'),
                  ],
                ),
              ),

            // Bottom Text Input Field Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEFEFF6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: _isAssessmentCompleted,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendMessage(),
                      style: GoogleFonts.beVietnamPro(fontSize: 14, color: const Color(0xFF171B2B)),
                      decoration: InputDecoration(
                        hintText: _isAssessmentCompleted
                            ? 'Share your stress or feelings...'
                            : 'Complete baseline above first...',
                        hintStyle: GoogleFonts.beVietnamPro(fontSize: 13.5, color: const Color(0xFF8D7168)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isAssessmentCompleted ? () => _handleSendMessage() : null,
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isAssessmentCompleted ? const Color(0xFF95416C) : const Color(0xFFCCCCCC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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

  Widget _buildAssessmentCard() {
    String title = '';
    List<String> options = [];
    String selectedValue = '';

    if (_currentStep == 0) {
      title = 'Step 1/3: What is your primary work stress trigger?';
      options = _triggers;
      selectedValue = _selectedTrigger;
    } else if (_currentStep == 1) {
      title = 'Step 2/3: How does stress show up physically for you?';
      options = _signals;
      selectedValue = _selectedSignal;
    } else {
      title = 'Step 3/3: What rest style helps you recover fastest?';
      options = _restStyles;
      selectedValue = _selectedRestStyle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD6C7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFAB3500).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Color(0xFFAB3500), size: 20),
              const SizedBox(width: 8),
              Text(
                'PERSONAL STRESS BASELINE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFAB3500),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.titleDark,
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: options.map((option) {
              final isSelected = selectedValue == option;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_currentStep == 0) _selectedTrigger = option;
                    if (_currentStep == 1) _selectedSignal = option;
                    if (_currentStep == 2) _selectedRestStyle = option;
                  });
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF0EB) : const Color(0xFFFAF9F8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFAB3500) : const Color(0xFFEFEFF6),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        option,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? const Color(0xFFAB3500) : const Color(0xFF171B2B),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFFAB3500), size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: selectedValue.isNotEmpty ? _completeAssessmentStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAB3500),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                _currentStep == 2 ? 'Complete & Start Chat' : 'Next Step →',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF95416C) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 20),
          ),
          border: message.isUser ? null : Border.all(color: const Color(0xFFEFEFF6)),
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
                height: 1.4,
                color: message.isUser ? Colors.white : const Color(0xFF171B2B),
              ),
            ),
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
          border: Border.all(color: const Color(0xFFEFEFF6)),
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
              'Joy is thinking...',
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

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}
