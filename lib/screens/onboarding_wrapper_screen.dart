import 'package:flutter/material.dart';
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
  final PageController _pageController = PageController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache all assets during splash animation so OnboardingScreen is 100% pre-loaded!
    precacheImage(const AssetImage('assets/images/onboarding.png'), context);
    precacheImage(const AssetImage('assets/images/onboarding_page_2.png'), context);
    precacheImage(const AssetImage('assets/images/onboarding_page_3.png'), context);
    precacheImage(const AssetImage('assets/brand/logo_removedbg.png'), context);
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

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 550),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _animateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 550),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _navigateToAuth({bool isLogin = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuthScreen(initialIsLogin: isLogin),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fully Pre-Loaded Onboarding Screen (rendered in background during splash)
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            children: [
              // Page 1 - Build a happier office
              OnboardingScreen(
                key: const ValueKey('onboarding_page_1'),
                pageIndex: 0,
                totalPages: 3,
                imagePath: 'assets/images/onboarding.png',
                onNextPressed: _nextPage,
                onLoginPressed: () => _navigateToAuth(isLogin: true),
                onDotTapped: _animateToPage,
              ),

              // Page 2 - What brings you joy? (interest selector)
              OnboardingScreenTwo(
                key: const ValueKey('onboarding_page_2'),
                pageIndex: 1,
                totalPages: 3,
                imagePath: 'assets/images/onboarding_page_2.png',
                onNextPressed: _nextPage,
                onLoginPressed: () => _navigateToAuth(isLogin: true),
                onSkipPressed: () => _navigateToAuth(isLogin: true),
                onDotTapped: _animateToPage,
              ),

              // Page 3 - Ready to bring joy to your team? (final onboarding screen)
              OnboardingScreenThree(
                key: const ValueKey('onboarding_page_3'),
                pageIndex: 2,
                totalPages: 3,
                imagePath: 'assets/images/onboarding_page_3.png',
                onSignUpPressed: () => _navigateToAuth(isLogin: false),
                onLoginPressed: () => _navigateToAuth(isLogin: true),
                onDotTapped: _animateToPage,
              ),
            ],
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

