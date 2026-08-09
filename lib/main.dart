import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/mochi_prompt_service.dart';
import 'services/supabase_service.dart';
import 'services/user_preferences_store.dart';
import 'services/session_manager_service.dart';
import 'services/offline_sync_service.dart';
import 'services/sign_out_flag.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/error/global_crash_screen.dart';
import 'screens/error/no_connectivity_screen.dart';
import 'screens/auth_screen.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_wrapper_screen.dart';

List<CameraDescription> availableDeviceCameras = [];

/// Global navigator key — allows navigation from outside the widget tree
/// (used by the Supabase auth-state listener in Scenarios 7 & 9).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// Scenario 6: markUserInitiatedSignOut() and userInitiatedSignOut flag
// are now located in services/sign_out_flag.dart.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  try {
    availableDeviceCameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera initialization info: $e');
  }

  await SupabaseService.instance.init();
  await UserPreferencesStore.loadProfileData();
  await MochiPromptService.instance.ensureLoaded();

  // Initialize Background-to-Foreground Resume Session Manager
  SessionManagerService.instance.initialize();

  // Initialize Background Offline Caching & Sync Queue
  OfflineSyncService.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Intercept known Flutter Web engine browser window resize assertion errors
  // (e.g. ViewInsets cannot be negative when resizing devtools or browser viewport)
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    if (msg.contains('ViewInsets') || msg.contains('isNonNegative')) {
      return;
    }
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    final msg = error.toString();
    if (msg.contains('ViewInsets') || msg.contains('isNonNegative')) {
      return true; // Suppress web engine window resize calculation assertion
    }
    return false;
  };

  // Global Crash Catcher boundary
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return GlobalCrashScreen(errorDetails: details);
  };

  runApp(const HappyDeskApp());
}

class HappyDeskApp extends StatefulWidget {
  const HappyDeskApp({super.key});

  @override
  State<HappyDeskApp> createState() => _HappyDeskAppState();
}

class _HappyDeskAppState extends State<HappyDeskApp> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();

    // ── Connectivity Listener ─────────────────────────────────────────────
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isOffline = results.isEmpty || results.contains(ConnectivityResult.none);
        if (isOffline != _isOffline) {
          setState(() => _isOffline = isOffline);
        }
      },
    );

    // ── Scenarios 7 & 9: Global Auth State Listener ───────────────────────
    // Listens for JWT expiry, remote session revocation, and admin bans.
    // Fires silently for the full app lifetime — no polling required.
    _authSubscription = SupabaseService.instance.client.auth.onAuthStateChange.listen(
      (AuthState authState) async {
        final event = authState.event;
        debugPrint('[HappyDeskApp] onAuthStateChange: $event');

        switch (event) {
          // ── Scenario 7 / 9: Unexpected sign-out ─────────────────────────
          case AuthChangeEvent.signedOut:
            if (userInitiatedSignOut) {
              // User tapped "Log Out" themselves — suppress duplicate handling
              userInitiatedSignOut = false;
              return;
            }
            // JWT expired beyond auto-refresh, remote revocation, or account ban.
            await UserPreferencesStore.setIsLoggedIn(false);
            final nav = appNavigatorKey.currentState;
            if (nav != null) {
              nav.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(initialIsLogin: true),
                ),
                (route) => false,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final ctx = appNavigatorKey.currentContext;
                if (ctx != null && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Your session has ended. Please sign in again.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              });
            }
            break;

          // ── Scenario 7 (success path): Silent token refresh ──────────────
          case AuthChangeEvent.tokenRefreshed:
            await UserPreferencesStore.setIsLoggedIn(true);
            debugPrint('[HappyDeskApp] Token refreshed silently — session active.');
            break;

          // ── Any new sign-in: keep local cache in sync ────────────────────
          case AuthChangeEvent.signedIn:
            await UserPreferencesStore.setIsLoggedIn(true);
            break;

          default:
            break;
        }
      },
      onError: (Object error) {
        debugPrint('[HappyDeskApp] Auth stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'U & ME',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      navigatorKey: appNavigatorKey, // Enables navigation from auth listener
      home: const OnboardingWrapperScreen(),
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            // ── Scenario 13: Offline banner (overlay, never blocks routing) ─
            if (_isOffline)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Offline Mode — Cache is Active',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => NoConnectivityScreen(
                                  onReconnected: () {
                                    setState(() => _isOffline = false);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Details',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
