import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';
import '../main/main_navigation_screen.dart';
import '../../main.dart';
import '../../services/user_preferences_store.dart';

class OnboardingWrapperScreen extends StatefulWidget {
  const OnboardingWrapperScreen({super.key});

  @override
  State<OnboardingWrapperScreen> createState() => _OnboardingWrapperScreenState();
}

class _OnboardingWrapperScreenState extends State<OnboardingWrapperScreen> {
  bool _isLoading = true;
  bool _showSplashWidget = true;

  /// True only for genuine first-timers: no prior onboarding AND not logged in.
  /// Avoids building OnboardingScreen for returning/signed-in users (Scenario 12).
  bool get _isFirstTimeUser =>
      !UserPreferencesStore.hasCompletedOnboarding() &&
      !UserPreferencesStore.isLoggedIn();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only precache onboarding assets if the user will actually see onboarding.
    // Skip for returning users and signed-in users to avoid wasted I/O.
    if (_isFirstTimeUser) {
      precacheImage(const AssetImage('assets/images/onboarding.png'), context);
      precacheImage(const AssetImage('assets/images/onboarding_page_2.png'), context);
      precacheImage(const AssetImage('assets/images/onboarding_page_3.png'), context);
      vg.loadPicture(const SvgAssetLoader('assets/brand/U&ME.svg'), null);
    }
  }

  Future<void> _finishLoading() async {
    // Await background initialization to ensure user profile/session state is loaded
    await appInitFuture;

    if (!mounted) return;

    // Route seamlessly based on user session state
    if (UserPreferencesStore.isLoggedIn()) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigationScreen(),
          transitionDuration: Duration.zero,
        ),
      );
    } else if (UserPreferencesStore.hasCompletedOnboarding()) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthScreen(initialIsLogin: true),
          transitionDuration: Duration.zero,
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _showSplashWidget = false;
      });
    }
  }

  void _navigateToAuth({bool isLogin = false}) {
    UserPreferencesStore.setHasCompletedOnboarding(true);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuthScreen(initialIsLogin: isLogin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Pre-loaded Onboarding Screen (only for first-time users — Scenario 12)
          //    Returning or signed-in users get an invisible placeholder to avoid
          //    unnecessary widget tree builds during the splash animation.
          if (_isFirstTimeUser)
            OnboardingScreen(
              onNavigateToAuth: (isLogin) => _navigateToAuth(isLogin: isLogin),
            )
          else
            const SizedBox.shrink(),

          // 2. Splash Loading Screen Overlay (fades out seamlessly upon completion)
          if (_showSplashWidget)
            AnimatedOpacity(
              opacity: _isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: SplashScreen(
                onLoadingComplete: _finishLoading,
              ),
            ),
        ],
      ),
    );
  }
}

