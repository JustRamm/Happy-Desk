import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mochi_prompt_service.dart';
import 'supabase_service.dart';

class UserPreferencesStore {
  static const String _keyIsClockedIn = 'is_clocked_in';
  static const String _keyIsOnBreak = 'is_on_break';
  static const String _keyLastClockInTime = 'last_clock_in_time';
  static const String _keyLastClockInLocation = 'last_clock_in_location';
  static const String _keyUserName = 'user_name';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserTeam = 'user_team';
  static const String _keyUserBio = 'user_bio';
  static const String _keyUserCompany = 'user_company';
  static const String _keyUserStrengths = 'user_strengths';
  static const String _keyUserFocusArea = 'user_focus_area';
  static const String _keyUserCurrentChallenges = 'user_current_challenges';
  static const String _keyUserCommunicationPreference = 'user_communication_preference';
  static const String _keyMasterNotifications = 'master_notifications';
  static const String _keyNglJarAlerts = 'ngl_jar_alerts';
  static const String _keyCoffeeInvites = 'coffee_invites';
  static const String _keyHeroNominations = 'hero_nominations';
  static const String _keyMochiContextSummary = 'mochi_context_summary';
  static const String _keyMochiFeedbackHistory = 'mochi_feedback_history';

  static const String _keyRoleType = 'user_role_type';
  static const String _keyCompanyHq = 'company_hq_location';
  static const String _keyCompanyIndustry = 'company_industry';
  static const String _keyCompanySize = 'company_size';
  static const String _keyCompanyCode = 'company_code';
  static const String _keyTeamCode = 'team_code';
  static const String _keyIsLeader = 'is_leader';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';

  // In-memory sync fallback cache
  static String _nameCache = '';
  static String _roleCache = 'Employee';
  static String _roleTypeCache = 'employee';
  static String _teamCache = 'General';
  static String _strengthsCache = '';
  static String _focusAreaCache = '';
  static String _currentChallengesCache = '';
  static String _communicationPreferenceCache = '';
  static String _bioCache = '';
  static String _companyCache = '';
  static String _companyHqCache = '';
  static String _companyIndustryCache = '';
  static String _companySizeCache = '';
  static String _companyCodeCache = '';
  static String _teamCodeCache = '';
  static bool _isLeaderCache = false;
  static bool _isLoggedInCache = false;
  static bool _hasCompletedOnboardingCache = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _nameCache = prefs.getString(_keyUserName) ?? '';
    _roleCache = prefs.getString(_keyUserRole) ?? 'Employee';
    _roleTypeCache = prefs.getString(_keyRoleType) ?? 'employee';
    _teamCache = prefs.getString(_keyUserTeam) ?? 'General';
    _bioCache = prefs.getString(_keyUserBio) ?? '';
    _companyCache = prefs.getString(_keyUserCompany) ?? '';
    _companyHqCache = prefs.getString(_keyCompanyHq) ?? '';
    _companyIndustryCache = prefs.getString(_keyCompanyIndustry) ?? '';
    _companySizeCache = prefs.getString(_keyCompanySize) ?? '';
    _companyCodeCache = prefs.getString(_keyCompanyCode) ?? '';
    _teamCodeCache = prefs.getString(_keyTeamCode) ?? '';
    _isLeaderCache = prefs.getBool(_keyIsLeader) ?? false;
    _avatarUrlCache = prefs.getString(_keyUserAvatarUrl);
    _isLoggedInCache = prefs.getBool(_keyIsLoggedIn) ?? false;
    _hasCompletedOnboardingCache = prefs.getBool(_keyHasCompletedOnboarding) ?? false;

    if (SupabaseService.instance.currentUser != null) {
      _isLoggedInCache = true;
      _hasCompletedOnboardingCache = true;
    }
  }

  static Future<void> setIsLoggedIn(bool val) async {
    _isLoggedInCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, val);
    if (val) {
      _hasCompletedOnboardingCache = true;
      await prefs.setBool(_keyHasCompletedOnboarding, true);
    }
  }

  static bool isLoggedIn() {
    if (SupabaseService.instance.currentUser != null) return true;
    return _isLoggedInCache;
  }

  static Future<void> setHasCompletedOnboarding(bool val) async {
    _hasCompletedOnboardingCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasCompletedOnboarding, val);
  }

  static bool hasCompletedOnboarding() => _hasCompletedOnboardingCache;

  static Future<void> logout() async {
    _isLoggedInCache = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await SupabaseService.instance.signOut();
  }

  // Clock-in preferences
  static Future<bool> isClockedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsClockedIn) ?? false;
  }

  static Future<void> setClockedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsClockedIn, value);
  }

  static Future<bool> isOnBreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsOnBreak) ?? false;
  }

  static Future<void> setOnBreak(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsOnBreak, value);
  }

  static Future<String?> getLastClockInTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastClockInTime);
  }

  static Future<void> setLastClockInTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastClockInTime, time);
  }

  static Future<String?> getLastClockInLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastClockInLocation);
  }

  static Future<void> setLastClockInLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastClockInLocation, location);
  }

  // User profile preferences
  static String getUserName() => _nameCache;
  static String getUserRole() => _roleCache;
  static String getUserTeam() => _teamCache;
  static String getUserStrengths() => _strengthsCache;
  static String getUserFocusArea() => _focusAreaCache;
  static String getUserCurrentChallenges() => _currentChallengesCache;
  static String getUserCommunicationPreference() => _communicationPreferenceCache;
  static String getUserBio() => _bioCache;
  static String getCompany() => _companyCache;

  static Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _nameCache = prefs.getString(_keyUserName) ?? '';
    _roleCache = prefs.getString(_keyUserRole) ?? 'Employee';
    _roleTypeCache = prefs.getString(_keyRoleType) ?? 'employee';
    _teamCache = prefs.getString(_keyUserTeam) ?? 'General';
    _strengthsCache = prefs.getString(_keyUserStrengths) ?? '';
    _focusAreaCache = prefs.getString(_keyUserFocusArea) ?? '';
    _currentChallengesCache = prefs.getString(_keyUserCurrentChallenges) ?? '';
    _communicationPreferenceCache = prefs.getString(_keyUserCommunicationPreference) ?? '';
    _bioCache = prefs.getString(_keyUserBio) ?? '';
    _companyCache = prefs.getString(_keyUserCompany) ?? '';
    _companyHqCache = prefs.getString(_keyCompanyHq) ?? '';
    _companyIndustryCache = prefs.getString(_keyCompanyIndustry) ?? '';
    _companySizeCache = prefs.getString(_keyCompanySize) ?? '';
    _avatarUrlCache = prefs.getString(_keyUserAvatarUrl);
    _isLoggedInCache = prefs.getBool(_keyIsLoggedIn) ?? false;
    _hasCompletedOnboardingCache = prefs.getBool(_keyHasCompletedOnboarding) ?? false;
    _isLeaderCache = prefs.getBool(_keyIsLeader) ?? false;
    _companyCodeCache = prefs.getString(_keyCompanyCode) ?? '';
    _teamCodeCache = prefs.getString(_keyTeamCode) ?? '';
  }

  static Future<void> setUserName(String val) async {
    _nameCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, val);
  }

  static Future<void> setUserRole(String val) async {
    _roleCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserRole, val);
  }

  static Future<void> setUserBio(String val) async {
    _bioCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserBio, val);
  }

  static String? _avatarUrlCache;
  static const String _keyUserAvatarUrl = 'user_avatar_url';

  static Future<void> setUserAvatarUrl(String val) async {
    _avatarUrlCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserAvatarUrl, val);
  }

  static String? getUserAvatarUrl() => _avatarUrlCache;

  static Future<void> setCompany(String val) async {
    _companyCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserCompany, val);
  }

  static Future<void> setUserTeam(String val) async {
    _teamCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserTeam, val);
  }

  static Future<void> setUserStrengths(String val) async {
    _strengthsCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserStrengths, val);
  }

  static Future<void> setUserFocusArea(String val) async {
    _focusAreaCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserFocusArea, val);
  }

  static Future<void> setUserCurrentChallenges(String val) async {
    _currentChallengesCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserCurrentChallenges, val);
  }

  static Future<void> setUserCommunicationPreference(String val) async {
    _communicationPreferenceCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserCommunicationPreference, val);
  }

  static Future<void> setUserProfile({
    required String name,
    required String role,
    required String team,
    String? strengths,
    String? focusArea,
    String? currentChallenges,
    String? communicationPreference,
    String? bio,
    String? company,
  }) async {
    _nameCache = name;
    _roleCache = role;
    _teamCache = team;
    if (strengths != null) _strengthsCache = strengths;
    if (focusArea != null) _focusAreaCache = focusArea;
    if (currentChallenges != null) _currentChallengesCache = currentChallenges;
    if (communicationPreference != null) {
      _communicationPreferenceCache = communicationPreference;
    }
    if (bio != null) _bioCache = bio;
    if (company != null) _companyCache = company;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyUserTeam, team);
    if (strengths != null) await prefs.setString(_keyUserStrengths, strengths);
    if (focusArea != null) await prefs.setString(_keyUserFocusArea, focusArea);
    if (currentChallenges != null) {
      await prefs.setString(_keyUserCurrentChallenges, currentChallenges);
    }
    if (communicationPreference != null) {
      await prefs.setString(
        _keyUserCommunicationPreference,
        communicationPreference,
      );
    }
    if (bio != null) await prefs.setString(_keyUserBio, bio);
    if (company != null) await prefs.setString(_keyUserCompany, company);
  }

  static Future<void> setRoleType(String val) async {
    _roleTypeCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRoleType, val);
  }

  static String getRoleType() => _roleTypeCache;

  static bool getIsFounder() =>
      _roleTypeCache == 'founder' ||
      _roleCache.toLowerCase().contains('founder');

  static Future<void> setCompanyDetails({
    required String companyName,
    String? hqLocation,
    String? industry,
    String? companySize,
  }) async {
    _companyCache = companyName;
    if (hqLocation != null) _companyHqCache = hqLocation;
    if (industry != null) _companyIndustryCache = industry;
    if (companySize != null) _companySizeCache = companySize;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserCompany, companyName);
    if (hqLocation != null) await prefs.setString(_keyCompanyHq, hqLocation);
    if (industry != null) await prefs.setString(_keyCompanyIndustry, industry);
    if (companySize != null) await prefs.setString(_keyCompanySize, companySize);
  }

  static String getCompanyHq() => _companyHqCache;
  static String getCompanyIndustry() => _companyIndustryCache;
  static String getCompanySize() => _companySizeCache;

  static Future<void> setCompanyCode(String code) async {
    _companyCodeCache = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCompanyCode, code);
  }

  static String getCompanyCode() => _companyCodeCache;

  static Future<void> setTeamCode(String code) async {
    _teamCodeCache = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTeamCode, code);
  }

  static String getTeamCode() => _teamCodeCache;

  static Future<void> setIsLeader(bool val) async {
    _isLeaderCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLeader, val);
  }

  static bool getIsLeader() => _isLeaderCache;

  // Notification preferences
  static Future<bool> getMasterNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMasterNotifications) ?? true;
  }

  static Future<void> setMasterNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMasterNotifications, value);
  }

  static Future<bool> getNglJarAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNglJarAlerts) ?? true;
  }

  static Future<void> setNglJarAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNglJarAlerts, value);
  }

  static Future<bool> getCoffeeInvites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCoffeeInvites) ?? true;
  }

  static Future<void> setCoffeeInvites(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCoffeeInvites, value);
  }

  static Future<bool> getHeroNominations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHeroNominations) ?? true;
  }

  static Future<void> setHeroNominations(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHeroNominations, value);
  }

  // Mochi Mindful Check-ins & Streak
  static const String _keyMochiCheckIns = 'mochi_checkins_count';

  static Future<int> getMochiCheckIns() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMochiCheckIns) ?? 3;
  }

  static Future<void> incrementMochiCheckIns() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyMochiCheckIns) ?? 3;
    await prefs.setInt(_keyMochiCheckIns, count + 1);
  }

  // Mochi session memory, style prefs, and mood logs
  static const String _keyMochiSessionSummary = 'mochi_session_summary';
  static const String _keyMochiStylePreference = 'mochi_style_preference';
  static const String _keyMochiMoodLogs = 'mochi_mood_logs';

  static Future<String?> getMochiContextSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMochiContextSummary);
  }

  static Future<void> setMochiContextSummary(String summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMochiContextSummary, summary);
  }

  static Future<List<MochiFeedbackLog>> getMochiFeedbackHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMochiFeedbackHistory);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => MochiFeedbackLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> appendMochiFeedback(MochiFeedbackLog log) async {
    final logs = await getMochiFeedbackHistory();
    logs.add(log);
    final trimmed = logs.length > 50 ? logs.sublist(logs.length - 50) : logs;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyMochiFeedbackHistory,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  static Future<String?> getMochiFeedbackSummary() async {
    final logs = await getMochiFeedbackHistory();
    if (logs.isEmpty) return null;

    final helpfulCount = logs.where((entry) => entry.helpful).length;
    final total = logs.length;
    return 'Recent user feedback: $helpfulCount of $total responses were marked helpful.';
  }

  static Future<String?> getMochiSessionSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMochiSessionSummary);
  }

  static Future<void> setMochiSessionSummary(String summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMochiSessionSummary, summary);
  }

  // Leave Requests & History Context
  static const String _keyUserLeaveRequests = 'user_leave_requests';

  static Future<List<String>> getLeaveRequests() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyUserLeaveRequests) ?? [
      'Casual Leave (Jul 29 – Jul 30) - Approved',
      'Sick Leave (Aug 02 – Aug 03) - Approved',
    ];
  }

  static Future<void> addLeaveRequest(String leaveSummary) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getLeaveRequests();
    final updated = List<String>.from(list);
    updated.insert(0, leaveSummary);
    await prefs.setStringList(_keyUserLeaveRequests, updated);
  }

  static Future<String> getLeaveSummary() async {
    final requests = await getLeaveRequests();
    return 'Casual Leave balance: 8 days remaining; Sick Leave balance: 5 days remaining. Recent leave requests: ${requests.take(2).join("; ")}.';
  }

  static String getFullUserProfileSummary() {
    final parts = <String>[];
    if (getUserName().isNotEmpty) parts.add('Name: ${getUserName()}');
    if (getUserRole().isNotEmpty) parts.add('Role: ${getUserRole()}');
    if (getUserTeam().isNotEmpty) parts.add('Team: ${getUserTeam()}');
    if (getCompany().isNotEmpty) parts.add('Company: ${getCompany()}');
    if (getUserBio().isNotEmpty) parts.add('Bio: ${getUserBio()}');
    if (getUserStrengths().isNotEmpty) parts.add('Strengths: ${getUserStrengths()}');
    if (getUserFocusArea().isNotEmpty) parts.add('Focus Area: ${getUserFocusArea()}');
    if (getUserCurrentChallenges().isNotEmpty) parts.add('Past Issues / Current Challenges: ${getUserCurrentChallenges()}');
    if (getUserCommunicationPreference().isNotEmpty) parts.add('Communication Pref: ${getUserCommunicationPreference()}');
    return parts.join(' | ');
  }

  static Future<String?> getMochiStylePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMochiStylePreference);
  }

  static Future<void> setMochiStylePreference(String preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMochiStylePreference, preference);
  }

  static Future<List<MochiMoodLog>> getMochiMoodLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMochiMoodLogs);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => MochiMoodLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> appendMochiMoodLog(MochiMoodLog log) async {
    final logs = await getMochiMoodLogs();
    logs.add(log);
    final trimmed = logs.length > 50 ? logs.sublist(logs.length - 50) : logs;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyMochiMoodLogs,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  static Future<String?> getMochiMoodTrendSummary() async {
    final logs = await getMochiMoodLogs();
    if (logs.isEmpty) return null;

    final recent = logs.length > 7 ? logs.sublist(logs.length - 7) : logs;
    final avgScore =
        recent.map((e) => e.score).reduce((a, b) => a + b) / recent.length;
    final labels = recent.map((e) => e.label).toSet().take(3).join(', ');

    return 'Last ${recent.length} check-ins avg ${avgScore.toStringAsFixed(1)}/10; recent moods: $labels.';
  }

  // Mochi CBT Thought Log Tracking
  static const String _keyMochiCbtLogs = 'mochi_cbt_logs';

  static Future<List<MochiCbtLog>> getMochiCbtLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMochiCbtLogs);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => MochiCbtLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> appendMochiCbtLog(MochiCbtLog log) async {
    final logs = await getMochiCbtLogs();
    logs.add(log);
    final trimmed = logs.length > 50 ? logs.sublist(logs.length - 50) : logs;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyMochiCbtLogs,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  static Future<String?> getMochiCbtTrendSummary() async {
    final logs = await getMochiCbtLogs();
    if (logs.isEmpty) return null;

    final recent = logs.length > 5 ? logs.sublist(logs.length - 5) : logs;
    final distortions = recent.map((e) => e.distortionTag).toSet().join(', ');
    return 'Recent CBT Reframings (${recent.length}): Distortions addressed include $distortions.';
  }

  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  static Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  // Medical Disclaimer Preference
  static const String _keyMedicalDisclaimerAccepted = 'medical_disclaimer_accepted';

  static Future<bool> isMedicalDisclaimerAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMedicalDisclaimerAccepted) ?? false;
  }

  static Future<void> setMedicalDisclaimerAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMedicalDisclaimerAccepted, value);
  }

  /// Complete Data Wipe on Account Deletion
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isLoggedInCache = false;
    _nameCache = '';
    _roleCache = 'Employee';
    _roleTypeCache = 'employee';
    _teamCache = 'General';
    _companyCache = '';
  }
}

class MochiFeedbackLog {
  final bool helpful;
  final String? note;
  final DateTime loggedAt;

  MochiFeedbackLog({
    required this.helpful,
    this.note,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'helpful': helpful,
    'note': note,
    'loggedAt': loggedAt.toIso8601String(),
  };

  factory MochiFeedbackLog.fromJson(Map<String, dynamic> json) {
    return MochiFeedbackLog(
      helpful: json['helpful'] as bool? ?? false,
      note: json['note'] as String?,
      loggedAt: json['loggedAt'] != null
          ? DateTime.tryParse(json['loggedAt'] as String)
          : null,
    );
  }
}

class MochiCbtLog {
  final String trigger;
  final String distortionTag;
  final int preScore;
  final int postScore;
  final String reframeText;
  final DateTime loggedAt;

  MochiCbtLog({
    required this.trigger,
    required this.distortionTag,
    required this.preScore,
    required this.postScore,
    required this.reframeText,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'trigger': trigger,
    'distortionTag': distortionTag,
    'preScore': preScore,
    'postScore': postScore,
    'reframeText': reframeText,
    'loggedAt': loggedAt.toIso8601String(),
  };

  factory MochiCbtLog.fromJson(Map<String, dynamic> json) {
    return MochiCbtLog(
      trigger: json['trigger'] as String? ?? '',
      distortionTag: json['distortionTag'] as String? ?? 'General Stress',
      preScore: (json['preScore'] as num?)?.toInt() ?? 7,
      postScore: (json['postScore'] as num?)?.toInt() ?? 4,
      reframeText: json['reframeText'] as String? ?? '',
      loggedAt: json['loggedAt'] != null
          ? DateTime.tryParse(json['loggedAt'] as String)
          : null,
    );
  }
}
