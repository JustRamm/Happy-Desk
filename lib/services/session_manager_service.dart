import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'user_preferences_store.dart';
import 'supabase_service.dart';

/// Manages background-to-foreground app resume sessions,
/// verifying auth tokens, tracking background duration, and syncing GPS/clock-in states.
class SessionManagerService with WidgetsBindingObserver {
  static final SessionManagerService instance = SessionManagerService._internal();
  SessionManagerService._internal();

  bool _isInitialized = false;
  DateTime? _lastPausedTime;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[SessionManagerService] Background-to-Foreground Resume Session observer initialized.');
  }

  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _lastPausedTime = DateTime.now();
      debugPrint('[SessionManagerService] App paused (backgrounded) at $_lastPausedTime');
    } else if (state == AppLifecycleState.resumed) {
      final resumeTime = DateTime.now();
      debugPrint('[SessionManagerService] App resumed (foregrounded) at $resumeTime');
      _handleAppResume(resumeTime);
    }
  }

  Future<void> _handleAppResume(DateTime resumeTime) async {
    try {
      // 1. Calculate time spent in background
      if (_lastPausedTime != null) {
        final durationInBackground = resumeTime.difference(_lastPausedTime!);
        debugPrint('[SessionManagerService] App was in background for ${durationInBackground.inSeconds} seconds');
      }

      // 2. Refresh Supabase Session Token if user is logged in
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser != null) {
        final currentSession = SupabaseService.instance.client.auth.currentSession;
        if (currentSession != null && currentSession.isExpired) {
          await SupabaseService.instance.client.auth.refreshSession();
        }
        debugPrint('[SessionManagerService] Supabase session verified on resume.');
      }

      // 3. Shift & Work Location Sync: Refresh GPS location if user is clocked in
      final isClockedIn = await UserPreferencesStore.isClockedIn();
      if (isClockedIn) {
        try {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
            );
            await UserPreferencesStore.setLastClockInLocation(
              '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
            );
            debugPrint('[SessionManagerService] Refreshed GPS on resume: ${pos.latitude}, ${pos.longitude}');
          }
        } catch (e) {
          debugPrint('[SessionManagerService] Note refreshing location on resume: $e');
        }
      }
    } catch (e) {
      debugPrint('[SessionManagerService] Error handling app resume: $e');
    }
  }
}
