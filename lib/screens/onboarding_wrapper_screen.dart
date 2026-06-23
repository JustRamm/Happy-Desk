import 'package:flutter/material.dart';
import 'splash_loading_screen.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';
import 'main_navigation_screen.dart';

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

  void _resetToSplash() {
    setState(() {
      _isLoading = true;
      _currentPageIndex = 0;
    });
  }

  void _navigateToAuth({bool isLogin = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuthScreen(initialIsLogin: isLogin),
      ),
    );
  }

  void _navigateToMainHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
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
                pageIndex: _currentPageIndex,
                totalPages: 3,
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
                pageIndex: _currentPageIndex,
                totalPages: 3,
                imagePath: 'assets/images/office_appreciation.png',
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
                pageIndex: _currentPageIndex,
                totalPages: 3,
                imagePath: 'assets/images/office_appreciation.png',
                onNextPressed: () => _navigateToAuth(isLogin: false),
                onLoginPressed: () => _navigateToAuth(isLogin: true),
              ),
            ],
          ),

          // Top Action Controls (Jump to Home & Replay Splash)
          Positioned(
            top: 10,
            right: 16,
            child: SafeArea(
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _navigateToMainHome,
                    icon: const Icon(Icons.home_outlined, size: 18, color: Color(0xFFC84B1A)),
                    label: const Text(
                      'Home',
                      style: TextStyle(color: Color(0xFFC84B1A), fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _resetToSplash,
                    tooltip: 'View Splash Screen',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.replay_rounded,
                        size: 20,
                        color: Color(0xFFC84B1A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
