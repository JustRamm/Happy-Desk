import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads Mochi's system prompt and config from assets, then composes
/// the full instruction sent to Gemini with live runtime context.
class MochiPromptService {
  MochiPromptService._();

  static final MochiPromptService instance = MochiPromptService._();

  static const _promptAsset = 'assets/prompts/mochi_system_prompt.md';
  static const _configAsset = 'assets/prompts/mochi_config.json';
  static const _roleOntologyAsset = 'assets/prompts/role_ontology.json';

  String? _basePrompt;
  MochiConfig? _config;
  Map<String, dynamic>? _roleOntologyJson;
  Future<void>? _loadFuture;

  Future<void> ensureLoaded() {
    _loadFuture ??= _loadAssets();
    return _loadFuture!;
  }

  Future<void> _loadAssets() async {
    final results = await Future.wait([
      rootBundle.loadString(_promptAsset),
      rootBundle.loadString(_configAsset),
      rootBundle.loadString(_roleOntologyAsset),
    ]);

    _basePrompt = results[0].trim();
    _config = MochiConfig.fromJson(
      jsonDecode(results[1]) as Map<String, dynamic>,
    );
    try {
      _roleOntologyJson = jsonDecode(results[2]) as Map<String, dynamic>;
    } catch (_) {}
  }

  MochiConfig get config {
    if (_config == null) {
      throw StateError('Call ensureLoaded() before accessing config.');
    }
    return _config!;
  }

  List<String> get offTopicKeywords => config.offTopicKeywords;

  String buildRoleKnowledgeHint(String userRole) {
    if (_roleOntologyJson == null) return '';
    final rolesList = _roleOntologyJson!['roles'] as List<dynamic>? ?? [];
    final lowerRole = userRole.toLowerCase();

    Map<String, dynamic>? matchedRole;
    for (final item in rolesList) {
      final map = item as Map<String, dynamic>;
      final keywords = List<String>.from(map['keywords'] as List? ?? []);
      if (keywords.any((k) => lowerRole.contains(k))) {
        matchedRole = map;
        break;
      }
    }

    matchedRole ??= rolesList.firstWhere(
      (item) => (item as Map<String, dynamic>)['id'] == 'general_office',
      orElse: () => rolesList.first,
    ) as Map<String, dynamic>;

    final title = matchedRole['title'] ?? userRole;
    final terms = (matchedRole['domain_terms'] as List? ?? []).join(', ');
    final stressors = (matchedRole['common_stressors'] as List? ?? []).join(', ');
    final guidance = matchedRole['guidance_note'] ?? '';

    return 'Role Ontology Profile [$title]: Key terms ($terms). Common stressors ($stressors). Guidance: $guidance.';
  }

  /// Automated detection of common cognitive distortion patterns in workplace distress.
  List<String> detectCognitiveDistortions(String userText) {
    final lower = userText.toLowerCase();
    final distortions = <String>[];

    if (lower.contains('fired') ||
        lower.contains('disaster') ||
        lower.contains('ruined') ||
        lower.contains('terrible') ||
        lower.contains('worst') ||
        lower.contains('hopeless') ||
        lower.contains('doomed')) {
      distortions.add('Catastrophizing');
    }

    if (lower.contains('always') ||
        lower.contains('never') ||
        lower.contains('everyone') ||
        lower.contains('nobody') ||
        lower.contains('perfect') ||
        lower.contains('total failure')) {
      distortions.add('All-or-Nothing / Overgeneralization');
    }

    if (lower.contains('thinks i') ||
        lower.contains('hate me') ||
        lower.contains('disappointed in me') ||
        lower.contains('must think')) {
      distortions.add('Mind Reading');
    }

    if (lower.contains('i should be') ||
        lower.contains('i should have') ||
        lower.contains('i should never') ||
        lower.contains('should always') ||
        lower.contains('must always') ||
        lower.contains('i must be') ||
        lower.contains('i must have') ||
        lower.contains('ought to be') ||
        lower.contains('should be perfect') ||
        lower.contains('should never feel')) {
      distortions.add('Should Statements');
    }

    if (lower.contains('feel useless') ||
        lower.contains('feel stupid') ||
        lower.contains('am a failure')) {
      distortions.add('Emotional Reasoning / Labeling');
    }

    return distortions;
  }

  /// High-confidence crisis & self-harm detection (including typos like 'chock', 'chocked', 'holing to die').
  bool isCrisisOrSelfHarmText(String userText) {
    final lower = userText.toLowerCase().trim();

    if (lower.contains('suicide') ||
        lower.contains('suicid') ||
        lower.contains('self harm') ||
        lower.contains('self-harm') ||
        lower.contains('kill myself') ||
        lower.contains('end it all') ||
        lower.contains('end my life') ||
        lower.contains('hurt myself') ||
        lower.contains('harming myself') ||
        lower.contains('want to die') ||
        lower.contains('wanna die') ||
        lower.contains('hoping to die') ||
        lower.contains('holing to die') ||
        lower.contains('chock') ||
        lower.contains('choked') ||
        lower.contains('chocking') ||
        lower.contains('choking') ||
        lower.contains('hanging myself') ||
        lower.contains('overdose') ||
        lower.contains('cut myself') ||
        lower.contains('dont want to live') ||
        lower.contains('don\'t want to live') ||
        lower.contains('no reason to live') ||
        lower.contains('better off dead')) {
      return true;
    }
    return false;
  }

  String buildSystemInstruction({
    required bool isClockedIn,
    required bool isOnBreak,
    required String clockInTime,
    String? sessionMemorySummary,
    String? userStylePreference,
    String? moodTrendSummary,
    String? userProfileSummary,
    String? roleKnowledgeHint,
    String? leaveSummary,
    String? coffeeHistorySummary,
    String? cbtTrendSummary,
    MochiIntentAnalysis? intentAnalysis,
    List<String>? detectedDistortions,
    String? nglJarSummary,
    String? weeklyHeroSummary,
    String? lifeContextSummary,
    String? openThreadsSummary,
  }) {
    if (_basePrompt == null) {
      throw StateError('Call ensureLoaded() before building the prompt.');
    }

    final basePrompt = _basePrompt!;
    final buffer = StringBuffer(basePrompt);

    buffer.writeln();
    buffer.writeln();
    buffer.writeln('## Live context (runtime)');
    buffer.writeln(
      'Shift: Clocked In = $isClockedIn | On Break = $isOnBreak | Shift Start = $clockInTime.',
    );

    if (userProfileSummary != null && userProfileSummary.trim().isNotEmpty) {
      buffer.writeln('User profile context: $userProfileSummary');
    }

    if (roleKnowledgeHint != null && roleKnowledgeHint.trim().isNotEmpty) {
      buffer.writeln('Role-specific context: $roleKnowledgeHint');
    }

    if (leaveSummary != null && leaveSummary.trim().isNotEmpty) {
      buffer.writeln('Leave requests & status context: $leaveSummary');
    }

    if (coffeeHistorySummary != null && coffeeHistorySummary.trim().isNotEmpty) {
      buffer.writeln('Coffee break history context: $coffeeHistorySummary');
    }

    if (cbtTrendSummary != null && cbtTrendSummary.trim().isNotEmpty) {
      buffer.writeln('Past CBT Thought Record history: $cbtTrendSummary');
    }

    if (detectedDistortions != null && detectedDistortions.isNotEmpty) {
      buffer.writeln(
        'Detected Cognitive Distortion pattern(s) in latest user message: ${detectedDistortions.join(", ")}. Gently help the user examine evidence or reframe.',
      );
    }

    if (userStylePreference != null && userStylePreference.trim().isNotEmpty) {
      buffer.writeln('User style preference: $userStylePreference');
    }

    if (moodTrendSummary != null && moodTrendSummary.trim().isNotEmpty) {
      buffer.writeln('Recent mood trends: $moodTrendSummary');
    }

    if (sessionMemorySummary != null &&
        sessionMemorySummary.trim().isNotEmpty) {
      buffer.writeln('Memory from past sessions: $sessionMemorySummary');
    }

    if (nglJarSummary != null && nglJarSummary.trim().isNotEmpty) {
      buffer.writeln('User NGL Jar Messages: $nglJarSummary');
    }

    if (weeklyHeroSummary != null && weeklyHeroSummary.trim().isNotEmpty) {
      buffer.writeln('User Weekly Hero Nominations Received: $weeklyHeroSummary');
    }

    if (lifeContextSummary != null && lifeContextSummary.trim().isNotEmpty) {
      buffer.writeln(
        'User Life Context (remembered from past sessions — reference naturally as a friend who remembers): $lifeContextSummary',
      );
    }

    if (openThreadsSummary != null && openThreadsSummary.trim().isNotEmpty) {
      buffer.writeln(
        'Open Conversational Threads (follow up naturally when it fits the conversation):\n$openThreadsSummary',
      );
    }

    if (intentAnalysis != null) {
      buffer.writeln();
      buffer.writeln('## Gemini Intent Analysis Context (Step 1 LLM Classification)');
      buffer.writeln('Primary Intent: ${intentAnalysis.primaryIntent}');
      buffer.writeln('User Emotional State: ${intentAnalysis.emotionalState}');
      buffer.writeln('Is Off-Topic: ${intentAnalysis.isOffTopic}');
      buffer.writeln('User In The Wrong / Behavioral Issue: ${intentAnalysis.isUserInTheWrong}');
      if (intentAnalysis.behavioralInsight != null && intentAnalysis.behavioralInsight!.isNotEmpty) {
        buffer.writeln('Behavioral Insight: ${intentAnalysis.behavioralInsight}');
      }
      buffer.writeln('Suicidal or Extreme Crisis: ${intentAnalysis.isSuicidalOrSevereCrisis}');
      buffer.writeln('Feels Unnoticed: ${intentAnalysis.feelsUnnoticed}');
      if (intentAnalysis.actionTrigger != null) {
        buffer.writeln('Suggested UI Action Trigger: ${intentAnalysis.actionTrigger}');
      }
      if (intentAnalysis.isGoodbye) {
        buffer.writeln('User is Signing Off / Goodbye: true');
      }
    }

    return buffer.toString();
  }

  /// Builds a specialized prompt for Step 1 LLM Intent Analysis.
  String buildIntentAnalysisPrompt(String userText, List<String> recentHistory) {
    final historyContext = recentHistory.isNotEmpty
        ? 'Recent conversation context:\n${recentHistory.join('\n')}\n\n'
        : '';
    return '''
You are an expert AI Intent & Psychological Classifier for Mochi, a workplace mental wellness & stress companion.
Analyze the user's latest sentence in full context (not just isolated keywords).

$historyContext
Latest User Message: "$userText"

Perform a complete intent analysis and output ONLY valid JSON matching this exact structure:
{
  "isOffTopic": false,
  "primaryIntent": "workplace_overload",
  "emotionalState": "burnt_out",
  "actionTrigger": null,
  "detectedDistortions": [],
  "feelsUnnoticed": false,
  "isPersonalCrisis": false,
  "isSuicidalOrSevereCrisis": false,
  "isUserInTheWrong": false,
  "behavioralInsight": null,
  "isGoodbye": false,
  "reasoning": "User is expressing workload stress."
}

Field instructions:
- "isOffTopic": true ONLY if asking for code generation, math homework, general trivia, programming debugging, or non-emotional technical tasks. Personal emotional topics like breakups, loneliness, grief, relationship heartbreak, family issues ARE NOT off-topic (set isOffTopic: false).
- "primaryIntent": e.g. "workplace_overload", "team_conflict", "harassment", "performance_anxiety", "feels_unnoticed", "user_behavioral_issue", "breakup_heartbreak", "loneliness", "personal_grief", "personal_crisis", "suicidal_crisis", "boundary_setting", "breathing_needed", "desk_stretches", "cbt_reframe", "time_off", "casual_chat", "farewell", "off_topic".
- "emotionalState": "calm", "anxious", "angry", "burnt_out", "sad", "panicked".
- "actionTrigger": "boundary", "breathing", "stretches", "cbt_reframe", or null.
- "detectedDistortions": list of strings if present (e.g. ["Catastrophizing", "All-or-Nothing", "Mind Reading", "Should Statements", "Labeling"]).
- "feelsUnnoticed": true if user feels ignored, unappreciated, or invisible by colleagues or boss.
- "isPersonalCrisis": true if sick family member, hospital emergency, death, severe illness, breakup, or personal grief.
- "isSuicidalOrSevereCrisis": true if self-harm, suicidal ideation, extreme helplessness.
- "isUserInTheWrong": true if the user's own perspective, actions, or expectations are flawed, overly harsh, micromanaging, or unfair to colleagues/interns (e.g. wanting to fire interns without guidance/feedback).
- "behavioralInsight": brief explanation of why the user might be in the wrong or what behavioral flaw is observed.
- "isGoodbye": true if sign-off phrase like bye, good night, gotta go, ttyl.
- "reasoning": 1 sentence summary of the classification.
''';
  }

  /// Extracts user nickname assignments or refusals if user typed e.g. "you can call me Abi if u like".
  String? maybeExtractNicknameFromUserText(String userText) {
    final patterns = [
      RegExp(r'(?:you|u)\s+can\s+call\s+me\s+([a-zA-Z0-9_\-]+)', caseSensitive: false),
      RegExp(r'call\s+me\s+([a-zA-Z0-9_\-]+)', caseSensitive: false),
      RegExp(r'my\s+nickname\s+is\s+([a-zA-Z0-9_\-]+)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final match = p.firstMatch(userText);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)!.trim();
        final lower = extracted.toLowerCase();
        if (extracted.isNotEmpty && lower != 'if' && lower != 'you' && lower != 'a' && lower != 'please') {
          return extracted;
        }
      }
    }
    return null;
  }

  /// Strips MOOD_LOG, SET_NICKNAME lines from model output and returns parsed data.
  MochiParsedReply parseModelReply(String rawReply) {
    final lines = rawReply.split('\n');
    final visibleLines = <String>[];
    MochiMoodLog? moodLog;
    String? extractedNickname;
    bool nicknameDeclined = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith(config.moodLogPrefix)) {
        final jsonPart = trimmed.substring(config.moodLogPrefix.length).trim();
        try {
          moodLog = MochiMoodLog.fromJson(
            jsonDecode(jsonPart) as Map<String, dynamic>,
          );
        } catch (_) {}
        continue;
      }

      if (trimmed.contains('SET_NICKNAME:')) {
        final parts = trimmed.split('SET_NICKNAME:');
        if (parts.length > 1) {
          final nick = parts[1].replaceAll(']', '').trim();
          if (nick.isNotEmpty) {
            extractedNickname = nick;
          }
        }
        final cleanLine = trimmed.replaceAll(RegExp(r'\[?SET_NICKNAME:[^\]\n]+\]?'), '').trim();
        if (cleanLine.isNotEmpty) visibleLines.add(cleanLine);
        continue;
      }

      if (trimmed.contains('SET_NICKNAME_DECLINED:')) {
        nicknameDeclined = true;
        final cleanLine = trimmed.replaceAll(RegExp(r'\[?SET_NICKNAME_DECLINED:[^\]\n]+\]?'), '').trim();
        if (cleanLine.isNotEmpty) visibleLines.add(cleanLine);
        continue;
      }

      visibleLines.add(line);
    }

    return MochiParsedReply(
      visibleText: visibleLines.join('\n').trim(),
      moodLog: moodLog,
      extractedNickname: extractedNickname,
      nicknameDeclined: nicknameDeclined,
    );
  }
}

class MochiParsedReply {
  final String visibleText;
  final MochiMoodLog? moodLog;
  final String? extractedNickname;
  final bool nicknameDeclined;

  const MochiParsedReply({
    required this.visibleText,
    this.moodLog,
    this.extractedNickname,
    this.nicknameDeclined = false,
  });
}

class MochiConfig {
  final String version;
  final String model;
  final double temperature;
  final int maxOutputTokens;
  final List<String> moodTags;
  final List<String> exercises;
  final List<String> offTopicKeywords;
  final String moodLogPrefix;

  List<String> get failoverModels => [
        if (model.isNotEmpty) model,
        'gemini-3.5-flash',
        'gemini-3.5-flash-lite',
        'gemini-3.1-flash-lite',
      ];

  const MochiConfig({
    required this.version,
    required this.model,
    required this.temperature,
    required this.maxOutputTokens,
    required this.moodTags,
    required this.exercises,
    required this.offTopicKeywords,
    required this.moodLogPrefix,
  });

  factory MochiConfig.fromJson(Map<String, dynamic> json) {
    final generation = json['generation'] as Map<String, dynamic>? ?? {};
    return MochiConfig(
      version: json['version'] as String? ?? '1.0',
      model: json['model'] as String? ?? 'gemini-flash-latest',
      temperature: (generation['temperature'] as num?)?.toDouble() ?? 0.7,
      maxOutputTokens: generation['maxOutputTokens'] as int? ?? 300,
      moodTags: List<String>.from(json['moodTags'] as List? ?? []),
      exercises: List<String>.from(json['exercises'] as List? ?? []),
      offTopicKeywords: List<String>.from(
        json['offTopicKeywords'] as List? ?? [],
      ),
      moodLogPrefix: json['moodLogPrefix'] as String? ?? 'MOOD_LOG:',
    );
  }
}

class MochiMoodLog {
  final int score;
  final String label;
  final List<String> tags;
  final DateTime loggedAt;

  MochiMoodLog({
    required this.score,
    required this.label,
    required this.tags,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'score': score,
    'label': label,
    'tags': tags,
    'loggedAt': loggedAt.toIso8601String(),
  };

  factory MochiMoodLog.fromJson(Map<String, dynamic> json) {
    return MochiMoodLog(
      score: (json['score'] as num?)?.toInt() ?? 5,
      label: json['label'] as String? ?? 'unknown',
      tags: List<String>.from(json['tags'] as List? ?? []),
      loggedAt: json['loggedAt'] != null
          ? DateTime.tryParse(json['loggedAt'] as String)
          : null,
    );
  }
}

class MochiIntentAnalysis {
  final bool isOffTopic;
  final String primaryIntent;
  final String emotionalState;
  final String? actionTrigger;
  final List<String> detectedDistortions;
  final bool feelsUnnoticed;
  final bool isPersonalCrisis;
  final bool isSuicidalOrSevereCrisis;
  final bool isUserInTheWrong;
  final String? behavioralInsight;
  final bool isGoodbye;
  final String reasoning;

  const MochiIntentAnalysis({
    required this.isOffTopic,
    required this.primaryIntent,
    this.emotionalState = 'calm',
    this.actionTrigger,
    this.detectedDistortions = const [],
    this.feelsUnnoticed = false,
    this.isPersonalCrisis = false,
    this.isSuicidalOrSevereCrisis = false,
    this.isUserInTheWrong = false,
    this.behavioralInsight,
    this.isGoodbye = false,
    this.reasoning = '',
  });

  factory MochiIntentAnalysis.fromJson(Map<String, dynamic> json) {
    return MochiIntentAnalysis(
      isOffTopic: json['isOffTopic'] as bool? ?? false,
      primaryIntent: json['primaryIntent'] as String? ?? 'general_support',
      emotionalState: json['emotionalState'] as String? ?? 'calm',
      actionTrigger: json['actionTrigger'] as String?,
      detectedDistortions: List<String>.from(json['detectedDistortions'] as List? ?? []),
      feelsUnnoticed: json['feelsUnnoticed'] as bool? ?? false,
      isPersonalCrisis: json['isPersonalCrisis'] as bool? ?? false,
      isSuicidalOrSevereCrisis: json['isSuicidalOrSevereCrisis'] as bool? ?? false,
      isUserInTheWrong: json['isUserInTheWrong'] as bool? ?? false,
      behavioralInsight: json['behavioralInsight'] as String?,
      isGoodbye: json['isGoodbye'] as bool? ?? false,
      reasoning: json['reasoning'] as String? ?? '',
    );
  }

  factory MochiIntentAnalysis.fallback(String userText) {
    return MochiIntentAnalysis(
      isOffTopic: false,
      primaryIntent: 'general_support',
      emotionalState: 'calm',
      reasoning: 'Fallback intent analysis',
    );
  }
}
