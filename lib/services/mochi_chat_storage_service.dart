import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MochiSessionModel {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;
  List<Map<String, dynamic>> messages; // [{text, isUser, time, actionType}]
  String? unresolvedIssue; // e.g. "suicide", "burnout", "manager_conflict"
  bool issueAddressed;

  MochiSessionModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.unresolvedIssue,
    this.issueAddressed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages,
        'unresolvedIssue': unresolvedIssue,
        'issueAddressed': issueAddressed,
      };

  factory MochiSessionModel.fromJson(Map<String, dynamic> json) {
    return MochiSessionModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Chat Session',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      unresolvedIssue: json['unresolvedIssue'] as String?,
      issueAddressed: json['issueAddressed'] as bool? ?? false,
    );
  }
}

class MochiChatStorageService {
  MochiChatStorageService._();
  static final MochiChatStorageService instance = MochiChatStorageService._();

  static const String _keyChatSessions = 'mochi_chat_sessions_list';
  static const String _keyActiveSessionId = 'mochi_active_session_id';

  /// Fetch all chat sessions ordered by updatedAt descending (latest first)
  Future<List<MochiSessionModel>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_keyChatSessions);

    if (rawJson == null || rawJson.isEmpty) {
      // Migrate old mochi_chat_history if available
      final oldHistory = prefs.getString('mochi_chat_history');
      if (oldHistory != null && oldHistory.isNotEmpty) {
        try {
          final oldMsgs = List<Map<String, dynamic>>.from(jsonDecode(oldHistory));
          final migratedSession = MochiSessionModel(
            id: 'session_${DateTime.now().millisecondsSinceEpoch}',
            name: _generateUniqueChatName('Mindful Check-in'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            messages: oldMsgs,
          );
          await saveSession(migratedSession);
          await setActiveSessionId(migratedSession.id);
          return [migratedSession];
        } catch (_) {}
      }
      // Create brand new default session
      final defaultSession = createNewSessionSync();
      await saveSession(defaultSession);
      await setActiveSessionId(defaultSession.id);
      return [defaultSession];
    }

    try {
      final List<dynamic> list = jsonDecode(rawJson);
      final sessions = list.map((item) => MochiSessionModel.fromJson(item)).toList();
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions;
    } catch (e) {
      debugPrint('Error loading chat sessions: $e');
      return [];
    }
  }

  Future<MochiSessionModel?> getActiveSession() async {
    final sessions = await getAllSessions();
    if (sessions.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_keyActiveSessionId);

    if (activeId != null) {
      final found = sessions.firstWhere((s) => s.id == activeId, orElse: () => sessions.first);
      return found;
    }
    return sessions.first;
  }

  Future<void> setActiveSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveSessionId, sessionId);
  }

  MochiSessionModel createNewSessionSync({String initialTopic = 'Wellness Chat'}) {
    final now = DateTime.now();
    final String uniqueName = _generateUniqueChatName(initialTopic);
    return MochiSessionModel(
      id: 'session_${now.millisecondsSinceEpoch}',
      name: uniqueName,
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
  }

  Future<MochiSessionModel> createNewSession({String initialTopic = 'Wellness Chat'}) async {
    final sessions = await getAllSessions();
    final newSession = createNewSessionSync(initialTopic: initialTopic);
    
    // Check if previous active session had unresolved critical/heavy issues
    final previousActive = await getActiveSession();
    if (previousActive != null && previousActive.messages.isNotEmpty) {
      final lastUnresolved = _detectUnresolvedIssueInMessages(previousActive.messages);
      if (lastUnresolved != null) {
        previousActive.unresolvedIssue = lastUnresolved;
        await saveSession(previousActive);
      }
    }

    sessions.add(newSession);
    await _saveAllSessions(sessions);
    await setActiveSessionId(newSession.id);
    return newSession;
  }

  Future<void> saveSession(MochiSessionModel session) async {
    final sessions = await getAllSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }
    await _saveAllSessions(sessions);
  }

  Future<void> renameSession(String sessionId, String newName) async {
    final sessions = await getAllSessions();
    final index = sessions.indexWhere((s) => s.id == sessionId);
    if (index >= 0) {
      sessions[index].name = newName.trim();
      sessions[index].updatedAt = DateTime.now();
      await _saveAllSessions(sessions);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final sessions = await getAllSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await _saveAllSessions(sessions);

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_keyActiveSessionId) == sessionId) {
      if (sessions.isNotEmpty) {
        await setActiveSessionId(sessions.first.id);
      } else {
        await prefs.remove(_keyActiveSessionId);
      }
    }
  }

  Future<void> _saveAllSessions(List<MochiSessionModel> sessions) async {
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_keyChatSessions, jsonEncode(jsonList));
  }

  String _generateUniqueChatName(String baseTopic) {
    final timeStr = DateTime.now().toString().substring(11, 16);
    final topics = [
      'Mindful Space',
      'Quiet Corner',
      'Daily Reflection',
      'Inner Reset',
      'Unpack & Breathe',
      'Thought Haven',
    ];
    final randomTopic = topics[DateTime.now().millisecondsSinceEpoch % topics.length];
    return '$randomTopic #$timeStr';
  }

  String? _detectUnresolvedIssueInMessages(List<Map<String, dynamic>> messages) {
    final userTexts = messages
        .where((m) => m['isUser'] == true)
        .map((m) => (m['text'] as String? ?? '').toLowerCase())
        .join(' ');

    if (userTexts.contains('die') ||
        userTexts.contains('suicide') ||
        userTexts.contains('end it') ||
        userTexts.contains('disappear') ||
        userTexts.contains('hurt myself') ||
        userTexts.contains('not wanting to exist')) {
      return 'suicide_selfharm';
    }

    if (userTexts.contains('overwhelmed') ||
        userTexts.contains('panic') ||
        userTexts.contains('can\'t breathe') ||
        userTexts.contains('burnout') ||
        userTexts.contains('breakdown')) {
      return 'severe_anxiety_burnout';
    }

    if (userTexts.contains('fired') ||
        userTexts.contains('hate my job') ||
        userTexts.contains('manager') ||
        userTexts.contains('conflict')) {
      return 'workplace_distress';
    }

    return null;
  }

  /// Builds a cross-session knowledge summary to inform Mochi about previous chats
  Future<String> buildCrossSessionKnowledgeSummary() async {
    final sessions = await getAllSessions();
    if (sessions.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('## Cross-Session Memory & Avoidance Awareness');

    for (var s in sessions) {
      if (s.messages.isEmpty) continue;

      final lastUserMsg = s.messages.lastWhere(
        (m) => m['isUser'] == true,
        orElse: () => s.messages.last,
      )['text'];

      buffer.writeln('- Session "${s.name}": ${s.messages.length} msgs. Last topic: "$lastUserMsg".');
      
      if (s.unresolvedIssue != null && !s.issueAddressed) {
        buffer.writeln('  [AVOIDANCE WARNING]: User previously shared heavy distress (${s.unresolvedIssue}) in session "${s.name}" before starting a new chat. If the user is currently avoiding or speaking casually, gently and subtly check in on them without forcing (e.g. "I know we switched chats, but I wanted to make sure you\'re feeling okay after what you mentioned earlier.").');
      }
    }

    return buffer.toString();
  }
}
