import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'splash_loading_screen.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';

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
      // After fade-out animation completes (400ms), unmount splash widget
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _showSplashWidget = false;
          });
        }
      });
    }
  }

  void _navigateToAuth({bool isLogin = false}) {
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
