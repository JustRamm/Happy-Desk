import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'splash_loading_screen.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';
import 'main_navigation_screen.dart';
import '../services/user_preferences_store.dart';

class OnboardingWrapperScreen extends StatefulWidget {
  const OnboardingWrapperScreen({super.key});

  @override
  State<OnboardingWrapperScreen> createState() => _OnboardingWrapperScreenState();
}

class _OnboardingWrapperScreenState extends State<OnboardingWrapperScreen> {
  bool _isLoading = true;
  bool _showSplashWidget = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache all assets during splash animation so OnboardingScreen is 100% pre-loaded!
    precacheImage(const AssetImage('assets/images/onboarding.png'), context);
    precacheImage(const AssetImage('assets/images/onboarding_page_2.png'), context);
    precacheImage(const AssetImage('assets/images/onboarding_page_3.png'), context);
    vg.loadPicture(const SvgAssetLoader('assets/brand/U&ME.svg'), null);
  }

  void _finishLoading() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      // After fade-out animation completes (400ms), route based on 4 user session scenarios
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _showSplashWidget = false;
        });

        // Scenario 4: Signed in -> Route Splash Screen -> Home (MainNavigationScreen)
        if (UserPreferencesStore.isLoggedIn()) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
          );
        }
        // Scenario 3: Logged out previously & closed app -> Route Splash Screen -> Signin (AuthScreen)
        else if (UserPreferencesStore.hasCompletedOnboarding()) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AuthScreen(initialIsLogin: true),
            ),
          );
        }
        // Scenario 1: First time install -> Show Splash Screen -> Onboarding Screen
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
          // 1. Fully Pre-Loaded Onboarding Screen with stationary Header, Button, and Slider
          OnboardingScreen(
            onNavigateToAuth: (isLogin) => _navigateToAuth(isLogin: isLogin),
          ),

          // 2. Splash Loading Screen Overlay (fades out seamlessly upon completion)
          if (_showSplashWidget)
            AnimatedOpacity(
              opacity: _isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: SplashLoadingScreen(
                onLoadingComplete: _finishLoading,
              ),
            ),
        ],
      ),
    );
  }
}
