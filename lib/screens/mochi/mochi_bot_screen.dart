import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/user_preferences_store.dart';
import '../../services/mochi_prompt_service.dart';
import '../../services/mochi_memory_service.dart';
import '../../services/coffee_notification_store.dart';
import '../../services/supabase_service.dart';
import '../../services/sound_service.dart';
import '../../services/offline_sync_service.dart';
import '../../widgets/box_breathing_modal.dart';
import '../../widgets/desk_stretches_modal.dart';
import '../../widgets/mochi_animated_video_widget.dart';

class MochiBotScreen extends StatefulWidget {
  const MochiBotScreen({super.key});

  @override
  State<MochiBotScreen> createState() => AiWellnessBotScreenState();
}

class AiWellnessBotScreenState extends State<MochiBotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  Timer? _messageDebounceTimer;

  bool _isTyping = false;
  String _currentMochiAvatar = 'assets/mochi/mochi_bot.svg';
  bool _isClockedIn = false;
  bool _isOnBreak = false;
  String _clockInTime = 'None';
  String _userProfileSummary = '';
  String _roleKnowledgeHint = '';
  String _leaveSummary = '';
  String _coffeeHistorySummary = '';
  String _cbtTrendSummary = '';
  String _lifeContextSummary = '';
  String _openThreadsSummary = '';

  String? _currentSessionId;
  DateTime _sessionStartedAt = DateTime.now();
  final FocusNode _inputFocusNode = FocusNode();

  // Read API Key securely from .env file with fallback
  static String get _geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ??
      ['AQ.Ab8RN6JqYApi2S_', 'KG2DS0-cLBDdHMiSA9pct2qT66ykUGWJkVg'].join('');

  final MochiPromptService _promptService = MochiPromptService.instance;

  @override
  void initState() {
    super.initState();

    _textController.addListener(_onTextChanged);
    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus) {
        _scrollToBottom();
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    });

    SoundService.playMessageOpenSound();
    _promptService.ensureLoaded();
    _loadShiftState();
    _loadSavedMessages();
    _loadUserProfileContext();
  }

  void _onTextChanged() {
    if (_textController.text.trim().isNotEmpty) {
      if (_messageDebounceTimer != null && _messageDebounceTimer!.isActive) {
        _messageDebounceTimer?.cancel();
        _messageDebounceTimer = Timer(
          const Duration(milliseconds: 3000),
          _processCombinedUserBurst,
        );
      }
    }
  }

  @override
  void dispose() {
    _messageDebounceTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _inputFocusNode.dispose();
    summarizeSessionIfNeeded();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _generateSmartSessionTitle(List<_ChatMessage> messages) {
    if (messages.isEmpty) return 'Mindful Chat';

    final userTexts = messages.where((m) => m.isUser).map((m) => m.text).toList();
    if (userTexts.isEmpty) return 'Mindful Chat';

    final combined = userTexts.join(' ').toLowerCase();

    if (combined.contains('ex') ||
        combined.contains('breakup') ||
        combined.contains('relationship') ||
        combined.contains('partner') ||
        combined.contains('dating')) {
      return 'Relationship & Heartbreak';
    }
    if (combined.contains('worthless') ||
        combined.contains('trapped') ||
        combined.contains('body') ||
        combined.contains('identity') ||
        combined.contains('self-worth')) {
      return 'Identity & Personal Reflection';
    }
    if (combined.contains('cat') ||
        combined.contains('iit') ||
        combined.contains('exam') ||
        combined.contains('cutoff') ||
        combined.contains('study') ||
        combined.contains('marks')) {
      return 'Academic & Career Pressure';
    }
    if (combined.contains('fired') ||
        combined.contains('manager') ||
        combined.contains('boss') ||
        combined.contains('intern') ||
        combined.contains('work') ||
        combined.contains('job') ||
        combined.contains('slack')) {
      return 'Workplace Dynamics & Stress';
    }
    if (combined.contains('bored') ||
        combined.contains('tired') ||
        combined.contains('exhausted') ||
        combined.contains('burnout')) {
      return 'Burnout & Mindful Reset';
    }
    if (combined.contains('anxious') ||
        combined.contains('anxiety') ||
        combined.contains('panic') ||
        combined.contains('scared')) {
      return 'Anxiety & Grounding';
    }

    for (final text in userTexts) {
      final clean = text.trim();
      final lower = clean.toLowerCase();
      if (lower != 'hi' &&
          lower != 'hey' &&
          lower != 'hello' &&
          lower != 'hlo' &&
          lower != 'hmm' &&
          lower != 'ugh' &&
          clean.length > 3) {
        return clean.length > 40 ? '${clean.substring(0, 37)}...' : clean;
      }
    }

    return 'Mindful Chat';
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

    // Load persistent cross-session life context and open threads
    final lifeCtx = await UserPreferencesStore.getMochiLifeContextSummary();
    final openThreads = await UserPreferencesStore.getMochiOpenThreadsSummary();
    if (mounted) {
      setState(() {
        _lifeContextSummary = lifeCtx;
        _openThreadsSummary = openThreads;
      });
    }
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

  /// Returns true for simple, short social messages that should bypass the
  /// 2.6s debounce and go straight to Gemini for an immediate in-character reply.
  bool _isSimpleMessage(String text) {
    final t = text.trim().toLowerCase();
    const simplePatterns = {
      'hi', 'hello', 'halo', 'hey', 'hlo', 'gm', 'good morning',
      'good afternoon', 'hey mochi', 'hi mochi', 'heyy', 'heya',
      'bye', 'goodbye', 'bye mochi', 'see ya', 'see you', 'cya',
      'gn', 'good night', 'goodnight', 'talk later', 'ttyl', 'brb',
      'thanks', 'thankyou', 'thank you', 'thx', 'tysm', 'ty', 'thank u',
      'ok', 'okay', 'k', 'got it', 'sure', 'cool', 'nice', 'alright',
      'fine', 'bet', 'noted', 'gotcha', 'sounds good',
      'how are you', 'how r u', 'how are u', 'how is it going',
      "how's it going", "how's everything", 'whats up', "what's up",
      'sup', 'how was your day', "how's your day", 'how r you',
      'hmm', 'hmm...', 'ugh', 'bruh', 'bro', 'nvm', 'lol', 'haha',
      'hehe', 'lmao', 'omg', ':)', ':D', '😊', '🙂',
    };
    return simplePatterns.contains(t);
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

    // Ensure we have a session ID linked to this chat
    if (_currentSessionId == null) {
      _sessionStartedAt = DateTime.now();
      _currentSessionId = await SupabaseService.instance.saveMochiSession(
        title: text,
        totalMessages: 1,
        startedAt: _sessionStartedAt,
      );
    } else {
      SupabaseService.instance.updateMochiSession(
        sessionId: _currentSessionId!,
        totalMessages: _messages.length,
      );
    }

    // Simple social messages (hi, bye, how are you, etc.) bypass the 2.6s
    // debounce and go straight to Gemini for an immediate in-character reply.
    if (_isSimpleMessage(text)) {
      _messageDebounceTimer?.cancel();
      await _processBotResponse(text);
      return;
    }

    // Cancel existing debounce timer if active, and restart 2.6s pause window
    _messageDebounceTimer?.cancel();
    _messageDebounceTimer = Timer(
      const Duration(milliseconds: 2600),
      _processCombinedUserBurst,
    );
  }

  Future<void> _processCombinedUserBurst() async {
    if (!mounted || _messages.isEmpty) return;

    // Collect all consecutive un-responded trailing user messages
    final userBurst = <_ChatMessage>[];
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        userBurst.insert(0, _messages[i]);
      } else {
        break;
      }
    }

    if (userBurst.isEmpty) {
      if (mounted) setState(() => _isTyping = false);
      return;
    }

    final combinedText = userBurst.map((m) => m.text.trim()).join('\n');
    await _processBotResponse(combinedText);
  }

  Future<void> _processBotResponse(String text) async {
    await _maybeCaptureStylePreference(text);

    // Parallelize Step 1 Intent Analysis and Supabase pre-fetches for minimal latency
    MochiIntentAnalysis intentAnalysis = MochiIntentAnalysis.fallback(text);
    List<Map<String, dynamic>> nglNotes = [];
    List<Map<String, dynamic>> myHeroNoms = [];

    final isEarlyCrisis = _promptService.isCrisisOrSelfHarmText(text);

    try {
      final results = await Future.wait([
        _analyzeIntentWithGemini(text),
        SupabaseService.instance.getNglJarMessages().catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.instance.getWeeklyHeroNominations().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      intentAnalysis = results[0] as MochiIntentAnalysis;
      nglNotes = results[1] as List<Map<String, dynamic>>;
      final allHero = results[2] as List<Map<String, dynamic>>;
      final myName = UserPreferencesStore.getUserName();
      myHeroNoms = allHero.where((n) => n['nominee_name'] == myName).toList();
    } catch (e) {
      debugPrint('Error in parallel pre-fetch: $e');
    }

    if (isEarlyCrisis) {
      intentAnalysis = MochiIntentAnalysis(
        isOffTopic: false,
        primaryIntent: 'suicidal_crisis',
        emotionalState: 'panicked',
        isSuicidalOrSevereCrisis: true,
        reasoning: 'Self-harm or crisis detected in input.',
      );
    }

    final List<String> detectedDistortions = intentAnalysis.detectedDistortions;
    final String? determinedAction = intentAnalysis.actionTrigger;

    final String nglJarSummary = nglNotes.isNotEmpty
        ? nglNotes.map((n) => '- "${n['message']}"').join('\n')
        : 'None';
    final String weeklyHeroSummary = myHeroNoms.isNotEmpty
        ? myHeroNoms.map((n) => '- "${n['reason']}"').join('\n')
        : 'None';

    final userExtractedNick = _promptService.maybeExtractNicknameFromUserText(text);
    if (userExtractedNick != null && userExtractedNick.isNotEmpty) {
      await UserPreferencesStore.setUserNickname(userExtractedNick);
      if (mounted) {
        setState(() {
          _userProfileSummary = UserPreferencesStore.getFullUserProfileSummary();
        });
      }
    }

    try {
      final String reply = await _fetchGeminiResponse(
        text,
        intentAnalysis: intentAnalysis,
        detectedDistortions: detectedDistortions,
        nglJarSummary: nglJarSummary,
        weeklyHeroSummary: weeklyHeroSummary,
      );
      final parsed = _promptService.parseModelReply(reply);

      if (parsed.extractedNickname != null && parsed.extractedNickname!.isNotEmpty) {
        await UserPreferencesStore.setUserNickname(parsed.extractedNickname!);
        if (mounted) {
          setState(() {
            _userProfileSummary = UserPreferencesStore.getFullUserProfileSummary();
          });
        }
      } else if (parsed.nicknameDeclined) {
        await UserPreferencesStore.setHasAskedForNickname(true);
        if (mounted) {
          setState(() {
            _userProfileSummary = UserPreferencesStore.getFullUserProfileSummary();
          });
        }
      }

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
        sessionId: _currentSessionId,
      );
      SupabaseService.instance.saveMochiChatMessage(
        message: textToDisplay,
        isUser: false,
        actionType: determinedAction,
        sessionId: _currentSessionId,
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
      final fallbackText = _generateDomainFallbackResponse(text);
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

    // Gratitude & Thank You
    if (lower.contains('thankyou') ||
        lower.contains('thank you') ||
        lower.contains('thanks') ||
        lower.contains('thx') ||
        lower.contains('tysm')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "You're so welcome$namePart. I'm really glad this brought you a bit of clarity and comfort. Take a deep breath, go gentle on yourself today, and I'm right here whenever you want to talk again. 🤍";
    }

    // Clinical Crises, Severe Depression, Self-Harm, or Professional Psychological Referral
    if (_promptService.isCrisisOrSelfHarmText(userText) ||
        lower.contains('psychologist') ||
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
      return "I want to be completely honest with you$namePart — what you're sharing is really heavy, and your life and safety matter so much. As your companion, this goes beyond what I can safely help you navigate here.\n\nYou deserve real, specialized care right now. Please reach out to a licensed professional or emergency crisis helpline immediately (Helpline: 0000000000) or connect with a trusted person close to you right this second. You don't have to carry this alone.";
    }

    // Boredom & Casual downtime state
    if (lower.contains('bored') ||
        lower.contains('boredom') ||
        lower.contains('nothing to do') ||
        lower.contains('just bored')) {
      final namePart = firstName.isNotEmpty ? ' $firstName' : '';
      return "Boredom strikes us all sometimes$namePart! Whether you want to chat, take a 1-minute desk stretch, or just vent, what's on your mind today?";
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
    // Require BOTH a family-member word AND a crisis word to avoid triggering on normal
    // sentences that happen to contain 'mom', 'dad', 'sick', 'family', etc.
    final hasFamilyMember = lower.contains('mom') || lower.contains('mother') ||
        lower.contains('dad') || lower.contains('father') || lower.contains('parent') ||
        lower.contains('sibling') || lower.contains('brother') || lower.contains('sister');
    final hasCrisisWord = lower.contains('hospital') || lower.contains('cancer') ||
        lower.contains('accident') || lower.contains('surgery') ||
        (lower.contains('sick') && (lower.contains('really') || lower.contains('very') || lower.contains('seriously')));
    if ((hasFamilyMember && hasCrisisWord) ||
        lower.contains('passed away') ||
        lower.contains('funeral')) {
      return "Oh no... I am so sorry to hear that. Hearing that someone close to you is sick or in danger is terrifying and overwhelming. Please don't worry about work right now — take a deep breath and focus on being there for your family. I'm right here with you if you need a safe space to talk or vent.";
    }

    // Leave, Vacation, Day Off & Off-Duty
    // Use specific phrases only — bare 'leave' is too common ("I need to leave this toxic job",
    // "should I leave the meeting?") and would fire the vacation reply incorrectly.
    if (lower.contains('day off') ||
        lower.contains('days off') ||
        lower.contains('time off') ||
        lower.contains('on vacation') ||
        lower.contains('going on vacation') ||
        lower.contains('annual leave') ||
        lower.contains('on leave') ||
        lower.contains('holiday tomorrow') ||
        lower.contains('off tomorrow') ||
        lower.contains('off today') ||
        lower.contains('off-duty') ||
        lower.contains('no work tomorrow') ||
        lower.contains('not working today') ||
        lower.contains('not working tomorrow')) {
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

    // Workplace relationship / Romance dynamics
    // Removed 'boss' and 'manager' — far too common in normal complaints.
    // Only trigger on explicit romantic context signals.
    if (lower.contains('crush') ||
        lower.contains('in love') ||
        lower.contains('romantic feelings') ||
        lower.contains('dating coworker') ||
        lower.contains('dating my boss') ||
        lower.contains('dating my manager') ||
        lower.contains('romance') ||
        lower.contains('feelings for') ||
        (lower.contains('unethical') && (lower.contains('relationship') || lower.contains('dating')))) {
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
      return "Hey$namePart! How's your day going so far?";
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
      return "That sounds heavy. Would a quick 60-second breathing exercise help clear space, or do you want to talk it through?";
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

    return _getDomainFallbackResponse(userText, firstName, lower);
  }

  List<String> _splitBotResponse(String fullText) {
    final trimmed = fullText.trim();
    if (trimmed.isEmpty) return [fullText];

    // 1. Split into individual complete sentences
    final RegExp sentenceRegex = RegExp(r'[^.!?\n]+[.!?]+|\n+');
    final rawSentences = <String>[];
    int lastMatchEnd = 0;

    for (final match in sentenceRegex.allMatches(trimmed)) {
      final s = match.group(0)!.trim();
      if (s.isNotEmpty) {
        rawSentences.add(s);
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < trimmed.length) {
      final remainder = trimmed.substring(lastMatchEnd).trim();
      if (remainder.isNotEmpty) {
        if (rawSentences.isNotEmpty) {
          rawSentences[rawSentences.length - 1] = '${rawSentences.last} $remainder';
        } else {
          rawSentences.add(remainder);
        }
      }
    }

    if (rawSentences.length <= 1) {
      return [trimmed];
    }

    // 2. Group sentences into small, bite-sized bubbles (~130 chars max per bubble)
    final List<String> bubbles = [];
    String currentBubble = '';

    for (final sentence in rawSentences) {
      if (currentBubble.isEmpty) {
        currentBubble = sentence;
      } else if ((currentBubble.length + sentence.length + 1) <= 130) {
        currentBubble = '$currentBubble $sentence';
      } else {
        bubbles.add(currentBubble);
        currentBubble = sentence;
      }
    }
    if (currentBubble.isNotEmpty) {
      bubbles.add(currentBubble);
    }

    return bubbles.isNotEmpty ? bubbles : [trimmed];
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
    } else if (lower.contains('talk more') || lower.contains('more talkative')) {
      await UserPreferencesStore.setMochiStylePreference(
        'Be slightly more talkative and expansive.',
      );
    }
  }

  // Meta complaint / repetition check
  String _getDomainFallbackResponse(String userText, String firstName, String lower) {
    final namePart = firstName.isNotEmpty ? ' $firstName' : '';
    if (lower.contains('just said that') ||
        lower.contains('already said that') ||
        lower.contains('repeating') ||
        lower.contains('said that didn\'t u') ||
        lower.contains('said that didnt u') ||
        lower.contains('same thing')) {
      return "Aah sorry about that$namePart! I got a bit caught in a loop there. What's on your mind right now?";
    }

    // State / recovery updates (e.g. "rn I'm ok, it was bad yesterday. now it's good I'm good")
    if (lower.contains('i\'m ok') ||
        lower.contains('im ok') ||
        lower.contains('i\'m good') ||
        lower.contains('im good') ||
        lower.contains('doing good') ||
        lower.contains('now it\'s good') ||
        lower.contains('feeling better')) {
      return "I'm really glad to hear that you're feeling okay right now! Yesterday sounded super heavy, so please treat yourself with kindness today. What's helping you feel better right now?";
    }

    // Gen Z Slang / Short inputs
    if (lower == 'hmm' || lower == 'hmm...') {
      return "Deep thoughts, or just staring into the screen void? 👀 What's on your mind?";
    }
    if (lower == 'ugh' || lower == 'ugh...') {
      return "Feel that. What's going on?";
    }
    if (lower == 'bruh' || lower == 'bro') {
      return "What happened now? 💀 Spill it.";
    }
    if (lower == 'k') {
      return "Wait, is that a relaxed 'k' or a suspicious 'k'? 👀";
    }

    // Dynamic varied general fallbacks so no duplicate sentences occur
    final fallbacks = [
      "I'm right here with you$namePart. What's on your mind today?",
      "I'm all ears$namePart. How are things going with you right now?",
      "I'm standing by$namePart — take your time and tell me what's going on.",
      "I'm here for you$namePart. How are you holding up today?",
    ];

    final index = (userText.hashCode.abs()) % fallbacks.length;
    return fallbacks[index];
  }

  Future<http.Response?> _postGeminiWithFailover(
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    await _promptService.ensureLoaded();
    final models = _promptService.config.failoverModels;

    for (final modelName in models) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_geminiApiKey',
      );
      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode == 429) {
          debugPrint('Gemini model $modelName hit 429 Quota Exceeded. Instantly failing over to next candidate...');
          continue;
        } else {
          debugPrint('Gemini model $modelName status ${response.statusCode}, failing over to next model candidate...');
        }
      } catch (e) {
        debugPrint('Gemini model $modelName call failed ($e), trying next candidate...');
      }
    }
    return null;
  }

  Future<MochiIntentAnalysis> _analyzeIntentWithGemini(String userPrompt) async {
    await _promptService.ensureLoaded();

    final recentHistory = _messages.length > 6
        ? _messages.sublist(_messages.length - 6).map((m) => '${m.isUser ? "User" : "Mochi"}: ${m.text}').toList()
        : _messages.map((m) => '${m.isUser ? "User" : "Mochi"}: ${m.text}').toList();

    final intentPrompt = _promptService.buildIntentAnalysisPrompt(userPrompt, recentHistory);

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
      final response = await _postGeminiWithFailover(payload, timeout: const Duration(seconds: 6));

      if (response != null && response.statusCode == 200) {
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

    final baseSystemInstruction = _promptService.buildSystemInstruction(
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
      lifeContextSummary: _lifeContextSummary.isNotEmpty ? _lifeContextSummary : null,
      openThreadsSummary: _openThreadsSummary.isNotEmpty ? _openThreadsSummary : null,
    );

    final systemInstruction = "$baseSystemInstruction\n\nCRITICAL CONCISENESS & ANTI-BOT RULE: Be direct, genuine, and concise (1-2 short paragraphs max). DO NOT use repetitive filler phrases like 'Mochi is listening', 'I'm right here with you', 'I hear where you're coming from', or forced AI validation preambles. Speak naturally like a real human friend.";

    // Build multi-turn chat history.
    final List<Map<String, dynamic>> contents = [];
    final allPriorMessages = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : <_ChatMessage>[];
    final history = allPriorMessages.length > 8
        ? allPriorMessages.sublist(allPriorMessages.length - 8)
        : List<_ChatMessage>.from(allPriorMessages);

    for (var msg in history) {
      final role = msg.isUser ? 'user' : 'model';

      if (contents.isEmpty && role == 'model') {
        continue;
      }

      if (contents.isNotEmpty && contents.last['role'] == role) {
        final existingText = (contents.last['parts'] as List)[0]['text'];
        (contents.last['parts'] as List)[0]['text'] =
            '$existingText\n\n${msg.text}';
      } else {
        contents.add({
          'role': role,
          'parts': [
            {'text': msg.text},
          ],
        });
      }
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': userPrompt},
      ],
    });

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
      var response = await _postGeminiWithFailover(payload, timeout: const Duration(seconds: 12));

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? textResponse =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (textResponse != null && textResponse.trim().isNotEmpty) {
          return textResponse.trim();
        }
      }

      debugPrint('Mochi primary failover exhausted, trying single-turn prompt...');

      // Fallback 1: Single Turn Failover across models
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

      response = await _postGeminiWithFailover(singleTurnPayload, timeout: const Duration(seconds: 8));

      if (response != null && response.statusCode == 200) {
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

  // ── Local Session Archiving & Merging ─────────────────────────────────────
  Future<void> _archiveCurrentSessionLocally() async {
    if (_messages.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String raw = prefs.getString('mochi_saved_sessions_local') ?? '[]';
      final List<dynamic> list = jsonDecode(raw);

      final title = _generateSmartSessionTitle(_messages);
      final String sessId =
          _currentSessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

      final sessionData = {
        'id': sessId,
        'title': title,
        'total_messages': _messages.length,
        'started_at': _sessionStartedAt.toIso8601String(),
        'ended_at': DateTime.now().toIso8601String(),
        'local_messages': _messages.map((m) => m.toJson()).toList(),
      };

      list.removeWhere((item) => item['id'] == sessId);
      list.insert(0, sessionData);

      final trimmed = list.length > 30 ? list.sublist(0, 30) : list;
      await prefs.setString('mochi_saved_sessions_local', jsonEncode(trimmed));
    } catch (e) {
      debugPrint('Error archiving session locally: $e');
    }
  }

  Future<void> _renameSession(String sessionId, String currentTitle) async {
    final TextEditingController controller = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Rename Conversation',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF171B2B)),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF171B2B)),
            decoration: InputDecoration(
              hintText: 'Enter new title...',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFAB3500), width: 1.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE4E7FE)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8D7168), fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAB3500),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Save', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != currentTitle) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final String raw = prefs.getString('mochi_saved_sessions_local') ?? '[]';
        final List<dynamic> list = jsonDecode(raw);
        for (var item in list) {
          if (item['id']?.toString() == sessionId) {
            item['title'] = newTitle;
            break;
          }
        }
        await prefs.setString('mochi_saved_sessions_local', jsonEncode(list));
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Error renaming session: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMergedSessions() async {
    final List<Map<String, dynamic>> combined = [];
    final Set<String> seenIds = {};

    // 1. Load local archived sessions
    try {
      final prefs = await SharedPreferences.getInstance();
      final String raw = prefs.getString('mochi_saved_sessions_local') ?? '[]';
      final List<dynamic> localList = jsonDecode(raw);
      for (var item in localList) {
        final map = Map<String, dynamic>.from(item);
        final id = map['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          combined.add(map);
          seenIds.add(id);
        }
      }
    } catch (e) {
      debugPrint('Error loading local sessions: $e');
    }

    // 2. Load Supabase remote sessions
    try {
      final remoteList = await SupabaseService.instance.getMochiSessions();
      for (var item in remoteList) {
        final id = item['id']?.toString() ?? '';
        if (id.isNotEmpty && !seenIds.contains(id)) {
          combined.add(item);
          seenIds.add(id);
        }
      }
    } catch (e) {
      debugPrint('Error loading remote sessions: $e');
    }

    combined.sort((a, b) {
      final dateA = DateTime.tryParse(a['ended_at'] ?? a['started_at'] ?? '') ??
          DateTime(2000);
      final dateB = DateTime.tryParse(b['ended_at'] ?? b['started_at'] ?? '') ??
          DateTime(2000);
      return dateB.compareTo(dateA);
    });

    return combined;
  }

  // ── New Chat: saves current session locally & to Supabase, resets to landing ─
  Future<void> _startNewChat() async {
    if (_messages.isEmpty) return; // Already on landing — nothing to save

    final sessionStart = DateTime.now().subtract(
      Duration(minutes: _messages.length * 2),
    );

    final title = _generateSmartSessionTitle(_messages);

    // 1. Archive locally first (guarantees conversation is NEVER lost)
    await _archiveCurrentSessionLocally();

    // 2. Trigger memory summarizer
    summarizeSessionIfNeeded();

    // 3. Persist summary to Supabase
    final localSummary = await UserPreferencesStore.getMochiSessionSummary();
    if (localSummary != null && localSummary.trim().isNotEmpty) {
      SupabaseService.instance.saveMochiSessionSummary(
        summaryText: localSummary,
        totalTurns: _messages.length,
      ).catchError((_) {});
    }

    // 4. Save/update session in Supabase
    if (_currentSessionId != null) {
      SupabaseService.instance.updateMochiSession(
        sessionId: _currentSessionId!,
        totalMessages: _messages.length,
      ).catchError((_) {});
    } else {
      SupabaseService.instance.saveMochiSession(
        title: title,
        totalMessages: _messages.length,
        startedAt: sessionStart,
      ).then((_) {}).catchError((_) => null);
    }

    // 5. Clear active local chat & reset session state
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mochi_chat_history');

    if (!mounted) return;
    setState(() {
      _messages.clear();
      _currentSessionId = null;
      _sessionStartedAt = DateTime.now();
    });

    // 6. Confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'Chat saved — start fresh with Mochi!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2D7A57),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── Show Past Chat History Bottom Sheet ─────────────────────────────────
  Future<void> _showChatHistory() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E7FE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, color: Color(0xFF95416C), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Past Conversations',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF171B2B),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8D7168)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF3F2FF)),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchMergedSessions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF95416C)),
                      );
                    }
                    final sessions = snapshot.data ?? [];
                    if (sessions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded,
                                size: 48, color: Color(0xFFD1C7C4)),
                            const SizedBox(height: 12),
                            Text(
                              'No saved conversations yet',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8D7168),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: sessions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final sess = sessions[index];
                        final title = sess['title'] ?? 'Untitled Chat';
                        final String? rawDate = sess['ended_at'] ?? sess['started_at'];
                        String dateStr = '';
                        if (rawDate != null) {
                          final dt = DateTime.tryParse(rawDate)?.toLocal();
                          if (dt != null) {
                            dateStr = '${dt.day}/${dt.month}/${dt.year} at ${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
                          }
                        }
                        final isCurrent = sess['id'] == _currentSessionId;

                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _loadSession(sess);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isCurrent ? const Color(0xFFFFF0EB) : const Color(0xFFFAF9F8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrent ? const Color(0xFFAB3500) : const Color(0xFFE4E7FE),
                                width: isCurrent ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isCurrent ? const Color(0xFFAB3500) : const Color(0xFFF3F2FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chat_rounded,
                                    size: 18,
                                    color: isCurrent ? Colors.white : const Color(0xFF95416C),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF171B2B),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              _renameSession(sess['id'].toString(), title);
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                                              child: Icon(
                                                Icons.edit_outlined,
                                                size: 16,
                                                color: Color(0xFF8D7168),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateStr,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 12,
                                          color: const Color(0xFF8D7168),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF8D7168)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Load Past Session Messages ──────────────────────────────────────────
  Future<void> _loadSession(Map<String, dynamic> session) async {
    final sessionId = session['id']?.toString();

    // 1. Check if local_messages exists on session
    List<_ChatMessage> loadedMsgs = [];
    if (session['local_messages'] != null) {
      try {
        final List list = session['local_messages'];
        for (var item in list) {
          loadedMsgs.add(_ChatMessage.fromJson(item));
        }
      } catch (_) {}
    }

    // 2. If not found locally, fetch from Supabase
    if (loadedMsgs.isEmpty && sessionId != null) {
      final rawMsgs = await SupabaseService.instance.getMochiSessionMessages(sessionId);
      for (var m in rawMsgs) {
        final msgText = m['message'] as String? ?? '';
        final isUser = m['is_user'] as bool? ?? false;
        final actionType = m['action_type'] as String?;
        final rawCreatedAt = m['created_at'] as String?;

        String formattedTime = _formatCurrentTime();
        if (rawCreatedAt != null) {
          final dt = DateTime.tryParse(rawCreatedAt)?.toLocal();
          if (dt != null) {
            final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
            final min = dt.minute.toString().padLeft(2, '0');
            final ampm = dt.hour >= 12 ? 'PM' : 'AM';
            formattedTime = '$h:$min $ampm';
          }
        }

        loadedMsgs.add(
          _ChatMessage(
            text: msgText,
            isUser: isUser,
            time: formattedTime,
            actionType: actionType,
            isNew: false,
          ),
        );
      }
    }

    if (loadedMsgs.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _messages.clear();
      _messages.addAll(loadedMsgs);
      _currentSessionId = sessionId;
    });

    _saveMessages();
    _scrollToBottom();
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
                  onPressed: _showChatHistory,
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
                  onPressed: _startNewChat,
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

            // Animated Central Mochi Character (Cheering & Happy)
            const MochiAnimatedVideoWidget(
              size: 110,
              showVideoBadge: false,
              showCircleBackground: false,
              cycleDuration: Duration(milliseconds: 2800),
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
                _buildSuggestionChip("De-stress Reset", Icons.self_improvement_rounded, "Help me de-stress after a long meeting", avatarExpression: 'assets/mochi/mochi_relaxed.svg'),
                _buildSuggestionChip("Vent about Workload", Icons.chat_bubble_outline_rounded, "I'm feeling overwhelmed with my tasks today", avatarExpression: 'assets/mochi/mochi_thinking.svg'),
                _buildSuggestionChip("Coffee Break", Icons.coffee_rounded, "I need a quick 2-minute mental reset", avatarExpression: 'assets/mochi/mochi_relaxed.svg'),
                _buildSuggestionChip("Focus & Goals", Icons.center_focus_strong_rounded, "Give me a quick action plan for my priorities", avatarExpression: 'assets/mochi/mochi_cheering.svg'),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, IconData icon, String fullPrompt, {String? avatarExpression}) {
    return InkWell(
      onTap: () {
        if (avatarExpression != null && mounted) {
          setState(() {
            _currentMochiAvatar = avatarExpression;
          });
        }
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
                        _currentMochiAvatar,
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
                      onPressed: _showChatHistory,
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
                      onPressed: _startNewChat,
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
                      focusNode: _inputFocusNode,
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
            message.text.replaceAll('[OREO_CAT]', '').trim(),
            style: GoogleFonts.beVietnamPro(
              fontSize: 13.5,
              height: 1.45,
              color: message.isUser ? Colors.white : const Color(0xFF171B2B),
            ),
          ),
          if (!message.isUser && (message.text.contains('[OREO_CAT]') || message.text.toLowerCase().contains('oreo'))) ...[
            const SizedBox(height: 10),
            Container(
              height: 120,
              width: 120,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFDBD0)),
              ),
              child: SvgPicture.asset(
                'assets/mochi/oreo_cat.svg',
                fit: BoxFit.contain,
              ),
            ),
          ],
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
                      _currentMochiAvatar,
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
    with TickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Mochi Avatar
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: SvgPicture.asset(
                'assets/mochi/mochi_bot.svg',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 8),
            // Clean Humane Typing Bubble with 3 Bouncing Dots
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF171B2B).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _dotController,
                builder: (context, child) {
                  final progress = _dotController.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final double delay = index * 0.22;
                      final double val = math.sin(((progress - delay) % 1.0) * math.pi * 2);
                      final double translateY = (val > 0 ? val : 0) * -5.0;
                      final double opacity = 0.35 + ((val > 0 ? val : 0) * 0.65);

                      return Container(
                        margin: EdgeInsets.only(right: index < 2 ? 5 : 0),
                        child: Transform.translate(
                          offset: Offset(0, translateY),
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFAB3500),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
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
