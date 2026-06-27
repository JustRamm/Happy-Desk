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
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();

  void _finishLoading() {
    if (mounted) {
      setState(() {
        _isLoading = false;
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SplashLoadingScreen(
        onLoadingComplete: _finishLoading,
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: [
              // Page 1 - Onboarding Screen
              OnboardingScreen(
                key: const ValueKey('onboarding_page_1'),
                pageIndex: _currentPageIndex,
                totalPages: 3,
                imagePath: 'assets/images/onboarding.png',
                onNextPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                onLoginPressed: () => _navigateToAuth(isLogin: true),
              ),

              // Page 2 - Team Recognition
              OnboardingScreen(
                key: const ValueKey('onboarding_page_2'),
                pageIndex: _currentPageIndex,
                totalPages: 3,
                imagePath: 'assets/images/onboarding.png',
                onNextPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                onLoginPressed: () => _navigateToAuth(isLogin: true),
              ),

              // Page 3 - Get Started (Navigates to Join the Team Auth Screen)
              OnboardingScreen(
                key: const ValueKey('onboarding_page_3'),
                pageIndex: _currentPageIndex,
                totalPages: 3,
                imagePath: 'assets/images/onboarding.png',
                onNextPressed: () => _navigateToAuth(isLogin: false),
                onLoginPressed: () => _navigateToAuth(isLogin: true),
              ),
            ],
          ),


        ],
      ),
    );
  }
}
