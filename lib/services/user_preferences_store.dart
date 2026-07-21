import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _keyMasterNotifications = 'master_notifications';
  static const String _keyNglJarAlerts = 'ngl_jar_alerts';
  static const String _keyCoffeeInvites = 'coffee_invites';
  static const String _keyHeroNominations = 'hero_nominations';

  // In-memory sync fallback cache
  static String _nameCache = 'Rownok Ahmed';
  static String _roleCache = 'Senior Product Architect';
  static String _teamCache = 'U & ME Engineering';
  static String _bioCache = 'Building delightful, human-centric workplace software.';
  static String _companyCache = 'U & ME HQ';

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
  static String getUserBio() => _bioCache;
  static String getCompany() => _companyCache;

  static Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _nameCache = prefs.getString(_keyUserName) ?? _nameCache;
    _roleCache = prefs.getString(_keyUserRole) ?? _roleCache;
    _teamCache = prefs.getString(_keyUserTeam) ?? _teamCache;
    _bioCache = prefs.getString(_keyUserBio) ?? _bioCache;
    _companyCache = prefs.getString(_keyUserCompany) ?? _companyCache;
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

  static Future<void> setCompany(String val) async {
    _companyCache = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserCompany, val);
  }

  static Future<void> setUserProfile({
    required String name,
    required String role,
    required String team,
    String? bio,
    String? company,
  }) async {
    _nameCache = name;
    _roleCache = role;
    _teamCache = team;
    if (bio != null) _bioCache = bio;
    if (company != null) _companyCache = company;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyUserTeam, team);
    if (bio != null) await prefs.setString(_keyUserBio, bio);
    if (company != null) await prefs.setString(_keyUserCompany, company);
  }

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
}
