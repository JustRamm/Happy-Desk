import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:camera/camera.dart';
import 'services/mochi_prompt_service.dart';
import 'services/supabase_service.dart';
import 'services/user_preferences_store.dart';
import 'services/session_manager_service.dart';
import 'services/offline_sync_service.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/error/global_crash_screen.dart';
import 'screens/error/no_connectivity_screen.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_wrapper_screen.dart';

List<CameraDescription> availableDeviceCameras = [];

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
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOffline = results.isEmpty || results.contains(ConnectivityResult.none);
      if (isOffline != _isOffline) {
        setState(() {
          _isOffline = isOffline;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'U & ME',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const OnboardingWrapperScreen(),
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
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
