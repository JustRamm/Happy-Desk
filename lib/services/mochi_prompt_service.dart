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

    if (lower.contains('should') ||
        lower.contains('must') ||
        lower.contains('ought to')) {
      distortions.add('Should Statements');
    }

    if (lower.contains('feel useless') ||
        lower.contains('feel stupid') ||
        lower.contains('am a failure')) {
      distortions.add('Emotional Reasoning / Labeling');
    }

    return distortions;
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
    List<String>? detectedDistortions,
    String? nglJarSummary,
    String? weeklyHeroSummary,
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

    return buffer.toString();
  }

  /// Strips MOOD_LOG lines from model output and returns parsed mood data.
  MochiParsedReply parseModelReply(String rawReply) {
    final lines = rawReply.split('\n');
    final visibleLines = <String>[];
    MochiMoodLog? moodLog;

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
      visibleLines.add(line);
    }

    return MochiParsedReply(
      visibleText: visibleLines.join('\n').trim(),
      moodLog: moodLog,
    );
  }
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
      model: json['model'] as String? ?? 'gemini-1.5-flash',
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

class MochiParsedReply {
  final String visibleText;
  final MochiMoodLog? moodLog;

  const MochiParsedReply({required this.visibleText, this.moodLog});
}
