import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesStore {
  static const String _keyIsClockedIn = 'is_clocked_in';
  static const String _keyIsOnBreak = 'is_on_break';
  static const String _keyLastClockInTime = 'last_clock_in_time';
  static const String _keyLastClockInLocation = 'last_clock_in_location';
  static const String _keyUserName = 'user_name';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserTeam = 'user_team';
  static const String _keyMasterNotifications = 'master_notifications';
  static const String _keyNglJarAlerts = 'ngl_jar_alerts';
  static const String _keyCoffeeInvites = 'coffee_invites';
  static const String _keyHeroNominations = 'hero_nominations';

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
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? 'Rownok Ahmed';
  }

  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole) ?? 'Senior Product Architect';
  }

  static Future<String> getUserTeam() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserTeam) ?? 'U & ME Engineering';
  }

  static Future<void> setUserProfile({
    required String name,
    required String role,
    required String team,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyUserTeam, team);
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
