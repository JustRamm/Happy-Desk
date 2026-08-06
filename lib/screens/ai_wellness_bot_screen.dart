import 'dart:async';
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
import '../services/sound_service.dart';
import '../services/offline_sync_service.dart';
import '../widgets/box_breathing_modal.dart';
import '../widgets/desk_stretches_modal.dart';

class AiWellnessBotScreen extends StatefulWidget {
  const AiWellnessBotScreen({super.key});

  @override
  State<AiWellnessBotScreen> createState() => AiWellnessBotScreenState();
}

class AiWellnessBotScreenState extends State<AiWellnessBotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
    _pulseController.dispose();
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

    // Keep messages empty for the clean Gemini-style landing screen
    setState(() {
      _messages.clear();
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

    // Step 1: LLM-based Intent & Psychological Classification using Gemini
    final MochiIntentAnalysis intentAnalysis = await _analyzeIntentWithGemini(text);

    final List<String> detectedDistortions = intentAnalysis.detectedDistortions;
    final String? determinedAction = intentAnalysis.actionTrigger;

    // Pre-fetch user's NGL Jar notes and Weekly Hero nominations
    List<Map<String, dynamic>> nglNotes = [];
    List<Map<String, dynamic>> myHeroNoms = [];
    try {
      nglNotes = await SupabaseService.instance.getNglJarMessages();
      final allHero = await SupabaseService.instance.getWeeklyHeroNominations();
      final myName = UserPreferencesStore.getUserName();
      myHeroNoms = allHero.where((n) => n['nominee_name'] == myName).toList();
    } catch (e) {
      debugPrint('Error pre-fetching feature data for Mochi: $e');
    }

    final String nglJarSummary = nglNotes.isNotEmpty
        ? nglNotes.map((n) => '- "${n['message']}"').join('\n')
        : 'None';
    final String weeklyHeroSummary = myHeroNoms.isNotEmpty
        ? myHeroNoms.map((n) => '- "${n['reason']}"').join('\n')
        : 'None';

    String? unnoticedResponseOverride;
    if (intentAnalysis.feelsUnnoticed && (nglNotes.isNotEmpty || myHeroNoms.isNotEmpty)) {
      if (nglNotes.isNotEmpty && myHeroNoms.isNotEmpty) {
        final nglContent = nglNotes.first['message'] ?? '';
        final heroContent = myHeroNoms.first['reason'] ?? '';
        unnoticedResponseOverride = 'I\'m sure you\'re wrong since one coworker said this "$nglContent" or you were one coworker hero of this week because u did "$heroContent"';
      } else if (nglNotes.isNotEmpty) {
        final nglContent = nglNotes.first['message'] ?? '';
        unnoticedResponseOverride = 'I\'m sure you\'re wrong since one coworker said this in your NGL Jar: "$nglContent"';
      } else {
        final heroContent = myHeroNoms.first['reason'] ?? '';
        unnoticedResponseOverride = 'I\'m sure you\'re wrong since you were one coworker hero of this week because u did "$heroContent"';
      }
    }

    // Step 2: Call Gemini for Mochi Personality Response Generation
    try {
      final String reply;
      if (unnoticedResponseOverride != null) {
        reply = unnoticedResponseOverride;
      } else {
        reply = await _fetchGeminiResponse(
          text,
          intentAnalysis: intentAnalysis,
          detectedDistortions: detectedDistortions,
          nglJarSummary: nglJarSummary,
          weeklyHeroSummary: weeklyHeroSummary,
        );
      }
      final parsed = _promptService.parseModelReply(reply);

      if (parsed.moodLog != null) {
        await UserPreferencesStore.appendMochiMoodLog(parsed.moodLog!);
        await UserPreferencesStore.incrementMochiCheckIns();
        try {
          await SupabaseService.instance.saveMochiMoodLog(
            score: parsed.moodLog!.score,
            label: parsed.moodLog!.label,
            tags: parsed.moodLog!.tags,
          );
        } catch (_) {
          await OfflineSyncService.instance.enqueueAction(
            actionType: 'log_mood',
            payload: {
              'score': parsed.moodLog!.score,
              'label': parsed.moodLog!.label,
              'tags': parsed.moodLog!.tags,
            },
          );
        }
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
          setState(() {
            _isTyping = true;
          });
          _scrollToBottom();
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          setState(() {
            _isTyping = false;
          });
        }
      }

      summarizeSessionIfNeeded();
    } catch (e) {
      if (!mounted) return;
      final fallbackText = unnoticedResponseOverride ?? _generateDomainFallbackResponse(text);
      final chunks = _splitBotResponse(fallbackText);
      final finalAction = determinedAction;

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
          setState(() {
            _isTyping = true;
          });
          _scrollToBottom();
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          setState(() {
            _isTyping = false;
          });
        }
      }
    }
  }

  String _generateDomainFallbackResponse(String userText) {
    final lower = userText.trim().toLowerCase();
    final name = UserPreferencesStore.getUserName();
    final firstName = name.isNotEmpty ? name.split(' ').first : '';

    // Clinical Crises, Severe Depression, Self-Harm, or Professional Psychological Referral
    if (lower.contains('psychologist') ||
        lower.contains('psychiatrist') ||
        lower.contains('therapist') ||
        lower.contains('suicide') ||
        lower.contains('self harm') ||
        lower.contains('clinical') ||
        lower.contains('trauma') ||
        lower.contains('medication') ||
        lower.contains('mental illness') ||
        lower.contains('end it all') ||
        lower.contains('kill myself')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "I want to be completely honest with you$namePart — what you're sharing is really heavy, and as your workplace stress companion, this is beyond what I can safely help you navigate here.\n\nYou deserve real, specialized care. I strongly encourage you to connect with a licensed psychologist or psychiatrist who can give you the deep professional support you need.\n\nIs there a doctor, crisis hotline, or trusted friend you can reach out to right now? You don't have to carry this alone.";
    }

    // Meta questions about Breathing / Action Buttons
    if (lower.contains('breathing') ||
        lower.contains('action') ||
        lower.contains('button') ||
        lower.contains('reset') ||
        lower.contains('why did you') ||
        lower.contains('why did u')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "I suggested the 60-second breathing reset action card earlier because I noticed keywords or cues related to stress or taking a mental break$namePart! Whenever you feel overwhelmed or just need a 1-minute reset, tapping that button guides you through a calming box-breathing exercise.";
    }

    // Active CBT Evidence & Reframe Trigger (When user taps "Examine Evidence & Reframe Thought")
    if (lower.contains('examine the evidence') ||
        lower.contains('reframe') ||
        lower.contains('cbt_reframe')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Let's examine the evidence together$namePart! First, what is the exact thought in your head right now (for example: 'I'm going to get fired' or 'I'm not good enough')? What makes you feel this thought is 100% true?";
    }

    // Founder / Leader Scenario: Firing Interns / Team Members
    if (lower.contains('fire my interns') ||
        lower.contains('fire interns') ||
        lower.contains('fire employee') ||
        lower.contains('fire my employee') ||
        lower.contains('firing interns') ||
        lower.contains('want to fire')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "I hear that frustration$namePart — managing interns or team members when things aren't working out can be really exhausting. Before taking any action, what specifically happened with the interns that led you to this point? Tell me what's been going on.";
    }

    // Founder Scenario 1: Co-Founder Friction & Strategic Disagreement
    if (lower.contains('co-founder') ||
        lower.contains('cofounder') ||
        lower.contains('partner friction') ||
        lower.contains('equity split') ||
        lower.contains('disagree on direction')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Co-founder friction is one of the hardest and most exhausting parts of building a company$namePart. When you're both poured into the mission, disagreement feels deeply personal.\n\nBefore jumping to conclusions, what specific decision or situation triggered this friction between you two? Tell me what happened.";
    }

    // Founder Scenario 2: Investor & Pitch Deck Panic / Runway Stress
    if (lower.contains('pitch deck') ||
        lower.contains('investor') ||
        lower.contains('fundraising') ||
        lower.contains('runway') ||
        lower.contains('pitching')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Pitching and investor stress can make your chest feel so tight$namePart. Take a slow, grounding breath with me right now.\n\nWhat is the main concern keeping you up right now — is it the narrative of the deck, or a specific metric investors pushed back on? Tell me what's on your mind.";
    }

    // Founder Scenario 3: Delegation & Micromanagement Trap
    if (lower.contains('micromanag') ||
        lower.contains('can\'t delegate') ||
        lower.contains('cannot delegate') ||
        lower.contains('check everything myself') ||
        lower.contains('hand off')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Founder perfectionism is real$namePart — when it's your company, handing over the steering wheel to anyone else feels risky.\n\nWhich specific task or domain feels hardest for you to delegate right now? Tell me a bit about what you're trying to hand off.";
    }

    // Team Lead Scenario 1: Peer-to-Manager Transition Awkwardness
    if (lower.contains('peer to manager') ||
        lower.contains('used to be my friend') ||
        lower.contains('now their boss') ||
        lower.contains('former peers') ||
        lower.contains('friend to manager')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Shifting from a peer/friend to a manager is one of the trickiest workplace transitions$namePart. It's completely normal for things to feel awkward at first.\n\nHow has your dynamic with them changed since stepping into the lead role? Tell me what's been happening.";
    }

    // Team Lead Scenario 2: Delivering Hard / Constructive Feedback (SBI Framework)
    if (lower.contains('give negative feedback') ||
        lower.contains('give tough feedback') ||
        lower.contains('sensitive employee') ||
        lower.contains('hard feedback') ||
        lower.contains('performance review feedback')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Delivering tough feedback gives almost every manager anxiety$namePart, but avoiding it only hurts the team in the long run.\n\nWhat specific behavior needs to change, and what reaction are you worried about? Tell me the situation and we can structure it together.";
    }

    // Team Lead Scenario 3: Inter-Department & Slack Conflict
    if (lower.contains('arguing in slack') ||
        lower.contains('slack drama') ||
        lower.contains('department conflict') ||
        lower.contains('blaming each other') ||
        lower.contains('team conflict')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Public team friction or Slack drama can derail team morale fast$namePart. De-escalating quickly and privately is key.\n\nDid this argument break out in a public channel or during a sync meeting? Tell me what happened.";
    }

    // Employee Scenario 1: Imposter Syndrome in Technical / New Roles
    if (lower.contains('imposter syndrome') ||
        lower.contains('imposter') ||
        lower.contains('everyone is smarter') ||
        lower.contains('not good enough') ||
        lower.contains('fake my way')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Take a deep breath$namePart. Imposter syndrome almost always hits high achievers who care deeply about doing great work.\n\nWhat recent project, code review, or conversation triggered this feeling of not being good enough? Tell me what happened.";
    }

    // Employee Scenario 2: Promotion & Salary Negotiation Anxiety
    if (lower.contains('ask for a raise') ||
        lower.contains('ask for raise') ||
        lower.contains('salary negotiation') ||
        lower.contains('promotion') ||
        lower.contains('underpaid')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Asking for what you're worth is empowering, but advocating for yourself can feel nerve-wracking$namePart!\n\nWhat key achievements or expanded responsibilities have you taken on over the past 6 months? Tell me what you've been working on.";
    }

    // Employee Scenario 3: Back-to-Back Meeting & Zoom Fatigue
    if (lower.contains('zoom fatigue') ||
        lower.contains('meeting fatigue') ||
        lower.contains('back to back meetings') ||
        lower.contains('back-to-back') ||
        lower.contains('brain fried')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Back-to-back meetings fry your cognitive energy fast$namePart! Let's pause and give your brain a 30-second break.\n\nDo you have any open time left today, or are you in syncs until the end of your shift? Tell me how your schedule looks.";
    }

    // Employee Scenario 4: Career Growth Plateau
    if (lower.contains('career plateau') ||
        lower.contains('not growing') ||
        lower.contains('stagnant') ||
        lower.contains('stuck in my role') ||
        lower.contains('stuck in same role')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Feeling stagnant in your role can make every workday feel like an uphill drag$namePart. You deserve to feel challenged and growing.\n\nIs the stagnation coming from repetitive tasks, or a lack of new stretch projects? Tell me what's going on.";
    }

    // Fear of Getting Fired / Job Security / Layoffs / Performance Panic (Employee)
    if (lower.contains('fired') ||
        lower.contains('lose my job') ||
        lower.contains('losing my job') ||
        lower.contains('layoff') ||
        lower.contains('laid off') ||
        lower.contains('terminated') ||
        lower.contains('pip') ||
        lower.contains('getting fired') ||
        lower.contains('gonna get fired') ||
        lower.contains('going to get fired')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Take a slow, deep breath$namePart. Fearing that you might lose your job is extremely frightening, and it's completely natural for your mind to panic when job security feels threatened.\n\nWhat specifically happened recently that made you feel this way? Tell me a bit more about what's going on.";
    }

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

    // Leave, Vacation, Day Off & Off-Duty
    if (lower.contains('leave') ||
        lower.contains('vacation') ||
        lower.contains('day off') ||
        lower.contains('days off') ||
        lower.contains('holiday') ||
        lower.contains('no work') ||
        lower.contains('not working') ||
        lower.contains('off tomorrow') ||
        lower.contains('off today') ||
        lower.contains('off-duty')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "That sounds wonderful$namePart! Taking time off is so important to recharge and reset. Make sure to fully disconnect, mute your work notifications, and enjoy your time off. You've earned it!";
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

    // Poor Mentorship, Senior Guidance, & Wasting Time
    if (lower.contains('mentor') ||
        lower.contains('mentoring') ||
        lower.contains('senior') ||
        lower.contains('wasting my time') ||
        lower.contains('wasting time') ||
        lower.contains('no guidance') ||
        lower.contains('unguided')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Feeling like you're wasting time due to poor mentorship is deeply frustrating$namePart, but it's a common trap in workplace roles. Seniors are often underwater with their own deliverables, and unless you push them, mentoring usually falls to the bottom of their priority list.\n\nHere is a 3-step action plan to fix this right now:\n\n• Shift from Passive Waiting to Active Extraction: Don't wait for formal 'mentorship sessions.' Send specific, isolated questions, pull-request links with clear context, or request a 15-minute weekly code/work review.\n• Audit Your Own Skill Growth: Is the issue a lack of feedback, or low-value tasks? Focus on gaining technical or domain skills by asking for high-value tasks or building internal side projects.\n• Define Your Stay/Exit Criteria: Try managing up proactively for 2 weeks. If nothing changes, treat the role as a resume line-item while channeling your energy into self-learning or prepping for your next move.\n\nWhich side of this is bothering you more — the lack of technical learning, or feeling unguided day-to-day?";
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

    // Informal boundary resolution, de-escalation, & private handling without drama
    if (lower.contains('lawyer') ||
        lower.contains('legal') ||
        lower.contains('public') ||
        lower.contains('drama') ||
        lower.contains('complicated') ||
        lower.contains('complected') ||
        lower.contains('issue public') ||
        lower.contains('don\'t want to escalate') ||
        lower.contains('wanna make sure this stops') ||
        lower.contains('make sure this stops')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "That makes complete sense$namePart. Wanting to resolve this quietly and safely without escalating to a public conflict or legal hassle is completely valid.\n\nHere are 3 low-profile, effective steps you can take right now to stop this privately:\n\n1. Clear, Direct Written Boundary: Send a concise message (e.g., 'Hey, I want to keep our interaction strictly professional going forward. Please respect this boundary.'). That sets an unmistakable record without drama.\n2. Keep a Quiet Log: Save screenshots and note down dates/times privately just in case.\n3. Subtle Physical Distance: Avoid 1-on-1 isolated situations with them whenever possible.\n\nYou are in full control. I'm right here if you'd like me to help you draft a calm, firm boundary text!";
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

    // High stress / anxiety / burnout
    if (lower.contains('anxious') ||
        lower.contains('overwhelmed') ||
        lower.contains('stress') ||
        lower.contains('burnout') ||
        lower.contains('panic')) {
      return "That sounds like a heavy weight to carry right now. I'm right here with you. Would a quick 60-second breathing exercise help clear space, or do you want to talk it through?";
    }

    // Micromanagement & Controlling Bosses (Pillar 2)
    if (lower.contains('micromana') ||
        lower.contains('control') ||
        lower.contains('over my shoulder') ||
        lower.contains('watching my every move') ||
        lower.contains('constantly checking')) {
      return "Dealing with micromanagement can feel suffocating and destroy trust. Here is a proven, proactive strategy to regain your autonomy:\n\n1. Over-communicate Proactively: Send a concise morning/daily summary email outlining your 3 top priorities before they ask.\n2. Scheduled Check-Ins: Propose a fixed 10-minute daily or weekly alignment instead of ad-hoc interruptions.\n3. Frame as Efficiency: Frame it as 'To protect focus time and deliver faster results, I'll update you at 4 PM daily.'";
    }

    // Imposter Syndrome & Self-Doubt (Pillar 3)
    if (lower.contains('imposter') ||
        lower.contains('not good enough') ||
        lower.contains('don\'t belong') ||
        lower.contains('fraud') ||
        lower.contains('fooling everyone')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Imposter syndrome is a classic sign that you care deeply about your work$namePart! High achievers almost always experience this when stepping into challenging roles.\n\nLet's reframe this together:\n• Feeling out of your depth means you are growing, not failing.\n• You were hired and trusted based on verified skills and real past performance, not luck.\n\nWould you like to review some of your real strengths or past wins together?";
    }

    // Asking for a Raise, Salary, or Promotion (Pillar 5)
    if (lower.contains('raise') ||
        lower.contains('salary') ||
        lower.contains('promotion') ||
        lower.contains('underpaid') ||
        lower.contains('compensation')) {
      return "Asking for what you're worth is an essential career skill! Here is a simple, structured 3-step approach:\n\n1. Gather Concrete Evidence: Note 3 major contributions or projects from the past 6-12 months and their measurable impact.\n2. Research Market Benchmark: Find the compensation range for your role and location.\n3. Schedule a Dedicated Discussion: 'I'd love to schedule 15 minutes to review my recent contributions and discuss my growth and compensation trajectory with the company.'";
    }

    // Saying No & Over-commitment Boundaries (Pillar 4)
    if (lower.contains('say no') ||
        lower.contains('too much work') ||
        lower.contains('overcommitted') ||
        lower.contains('overwhelmed by tasks') ||
        lower.contains('can\'t take more')) {
      return "Setting workload boundaries isn't being unhelpful — it protects the quality of your work! Here is a collaborative way to say 'No' without conflict:\n\n'I want to make sure I deliver high quality on [Current Project]. If I take on this new task, which existing priority should I pause or push back?'";
    }

    // Impulsive Anger / Resignation De-escalation (Pillar 6)
    if (lower.contains('quit') ||
        lower.contains('resigning') ||
        lower.contains('walk out') ||
        lower.contains('so angry') ||
        lower.contains('furious') ||
        lower.contains('screw this')) {
      return "I can hear how angry and pushed to the limit you feel right now. That frustration is real, but please don't make permanent career decisions in an acute emotional moment.\n\nLet's take a 24-hour pause before taking any action:\n1. Step away from your computer/desk right now.\n2. Vent everything to me — draft your thoughts safely here.\n3. Re-evaluate tomorrow with a calm, clear head when you're in full control.";
    }

    // Vague, trailing, incomplete inputs (e.g. "I'm cool, just", "just...", "nothing, just", "hard to explain")
    if (lower == 'just' ||
        lower == 'just...' ||
        lower.endsWith(' just') ||
        lower.endsWith(' just...') ||
        lower.endsWith(' but') ||
        lower.endsWith(' but...') ||
        lower.contains('hard to explain') ||
        lower.contains('hard to say') ||
        lower.contains('don\'t know') ||
        lower.contains('not sure') ||
        lower.contains('nothing really') ||
        lower.contains('nothing, just') ||
        lower.contains('fine, just') ||
        lower.contains('cool, just') ||
        lower.contains('ok, just') ||
        lower.contains('okay, just')) {
      return "I'm right here with you. You don't have to explain it right now, and we don't have to talk about anything specific. Just know that I'm standing by your side whenever you feel like sharing.";
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

  Future<MochiIntentAnalysis> _analyzeIntentWithGemini(String userPrompt) async {
    await _promptService.ensureLoaded();
    final config = _promptService.config;

    final recentHistory = _messages.length > 6
        ? _messages.sublist(_messages.length - 6).map((m) => '${m.isUser ? "User" : "Mochi"}: ${m.text}').toList()
        : _messages.map((m) => '${m.isUser ? "User" : "Mochi"}: ${m.text}').toList();

    final intentPrompt = _promptService.buildIntentAnalysisPrompt(userPrompt, recentHistory);

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent?key=$_geminiApiKey',
    );

    final payload = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": intentPrompt},
          ],
        }
      ],
      "generationConfig": {
        "temperature": 0.2,
        "maxOutputTokens": 400,
        "responseMimeType": "application/json",
      },
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? textResponse =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (textResponse != null && textResponse.trim().isNotEmpty) {
          final cleanJson = textResponse.trim();
          final parsedJson = jsonDecode(cleanJson) as Map<String, dynamic>;
          return MochiIntentAnalysis.fromJson(parsedJson);
        }
      }
    } catch (e) {
      debugPrint('Error performing Step 1 Gemini intent analysis: $e');
    }

    return MochiIntentAnalysis.fallback(userPrompt);
  }

  Future<String> _fetchGeminiResponse(
    String userPrompt, {
    MochiIntentAnalysis? intentAnalysis,
    List<String>? detectedDistortions,
    String? nglJarSummary,
    String? weeklyHeroSummary,
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
      intentAnalysis: intentAnalysis,
      detectedDistortions: detectedDistortions ?? intentAnalysis?.detectedDistortions,
      nglJarSummary: nglJarSummary,
      weeklyHeroSummary: weeklyHeroSummary,
    );

    // Build multi-turn chat history ensuring user/model alternation AND user start
    final List<Map<String, dynamic>> contents = [];
    final history = _messages.length > 8
        ? _messages.sublist(_messages.length - 8)
        : List<_ChatMessage>.from(_messages);

    for (var msg in history) {
      final role = msg.isUser ? 'user' : 'model';

      // Gemini API rule: contents must start with 'user'
      if (contents.isEmpty && role == 'model') {
        continue;
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

    // Always ensure userPrompt is appended as the final 'user' turn for Gemini API
    if (contents.isNotEmpty && contents.last["role"] == "user") {
      final existingText = (contents.last['parts'] as List)[0]['text'];
      (contents.last['parts'] as List)[0]['text'] = '$existingText\n$userPrompt';
    } else {
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

  void _showUpcomingFeatureSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Upcoming feature — Stay tuned!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF171B2B),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildGeminiStyleLandingView() {
    final name = UserPreferencesStore.getUserName();
    final firstName = name.isNotEmpty ? name.split(' ').first : '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top action buttons row (Plus & History icons) for landing screen
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _showUpcomingFeatureSnackBar,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF95416C),
                      size: 20,
                    ),
                  ),
                  tooltip: 'Chat History',
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _showUpcomingFeatureSnackBar,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Color(0xFF95416C),
                      size: 20,
                    ),
                  ),
                  tooltip: 'New Chat',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Animated Central Mochi Spark Icon
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF0EB),
                      Color(0xFFF3F2FF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFAB3500).withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF95416C).withValues(alpha: 0.12),
                      blurRadius: 36,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/brand/mochi_bot.svg',
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Gemini-Style Welcome Headline
            Text(
              firstName.isNotEmpty ? "What's next, $firstName?" : "What's next today?",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
                letterSpacing: -0.5,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "I'm Mochi, your workplace companion. Ask me anything about work stress, focus, or your day.",
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF594139),
                height: 1.45,
              ),
            ),

            const SizedBox(height: 32),

            // Suggestion Prompt Chips with Material Icons
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip("De-stress Reset", Icons.self_improvement_rounded, "Help me de-stress after a long meeting"),
                _buildSuggestionChip("Vent about Workload", Icons.chat_bubble_outline_rounded, "I'm feeling overwhelmed with my tasks today"),
                _buildSuggestionChip("Coffee Break", Icons.coffee_rounded, "I need a quick 2-minute mental reset"),
                _buildSuggestionChip("Focus & Goals", Icons.center_focus_strong_rounded, "Give me a quick action plan for my priorities"),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, IconData icon, String fullPrompt) {
    return InkWell(
      onTap: () {
        _textController.text = fullPrompt;
        _handleSendMessage();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E7FE), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF171B2B).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFAB3500)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF171B2B),
              ),
            ),
          ],
        ),
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
            // Top Header — Mochi avatar, name, and online tag (Shown only when in active conversation)
            if (_messages.isNotEmpty)
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
                    IconButton(
                      onPressed: _showUpcomingFeatureSnackBar,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: Color(0xFF95416C),
                          size: 20,
                        ),
                      ),
                      tooltip: 'Chat History',
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _showUpcomingFeatureSnackBar,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF95416C),
                          size: 20,
                        ),
                      ),
                      tooltip: 'New Chat',
                    ),
                  ],
                ),
              ),

            // Main Body: Gemini-style Landing View when empty, Chat ListView when messages exist
            Expanded(
              child: _messages.isEmpty
                  ? _buildGeminiStyleLandingView()
                  : ListView.builder(
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

                          final bubble = _buildMessageBubble(msg, showAvatar: showAvatar);
                          if (msg.isNew) {
                            return _AnimatedMessageBubble(
                              message: msg,
                              child: bubble,
                            );
                          }
                          return bubble;
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
                      onTap: () {
                        SystemChannels.textInput.invokeMethod('TextInput.show');
                      },
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

class _AnimatedMessageBubble extends StatefulWidget {
  final Widget child;
  final _ChatMessage message;
  const _AnimatedMessageBubble({
    required this.child,
    required this.message,
  });

  @override
  State<_AnimatedMessageBubble> createState() => __AnimatedMessageBubbleState();
}

class __AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward().then((_) {
      if (mounted) {
        widget.message.isNew = false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final String? actionType;
  bool isNew;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.actionType,
    this.isNew = true,
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
    isNew: false,
  );
}
