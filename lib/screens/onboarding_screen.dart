import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/feature_badge_card.dart';
import '../widgets/page_indicator.dart';
import '../widgets/brand_logo_widget.dart';

/// Main Onboarding Screen featuring stationary Header, Button, and Slider (Dots),
/// where only the middle page content swiping animates smoothly.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onNextPressed;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onSignUpPressed;
  final ValueChanged<int>? onDotTapped;
  final ValueChanged<bool>? onNavigateToAuth;
  final String imagePath;
  final int pageIndex;
  final int totalPages;

  const OnboardingScreen({
    super.key,
    this.onNextPressed,
    this.onLoginPressed,
    this.onSignUpPressed,
    this.onDotTapped,
    this.onNavigateToAuth,
    this.imagePath = 'assets/images/onboarding.png',
    this.pageIndex = 0,
    this.totalPages = 3,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.pageIndex;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (widget.onNextPressed != null) {
      widget.onNextPressed!();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 550),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _animateToPage(int index) {
    if (widget.onDotTapped != null) {
      widget.onDotTapped!(index);
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 550),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _handleSkip() {
    const finalPageIndex = 2; // Final onboarding page (index 2)
    if (_currentPage < finalPageIndex) {
      _pageController.animateToPage(
        finalPageIndex,
        duration: const Duration(milliseconds: 550),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      if (widget.onLoginPressed != null) {
        widget.onLoginPressed!();
      } else if (widget.onNavigateToAuth != null) {
        widget.onNavigateToAuth!(true);
      }
    }
  }

  void _handleSignUp() {
    if (widget.onSignUpPressed != null) {
      widget.onSignUpPressed!();
    } else if (widget.onNavigateToAuth != null) {
      widget.onNavigateToAuth!(false);
    }
  }

  void _handleLogin() {
    if (widget.onLoginPressed != null) {
      widget.onLoginPressed!();
    } else if (widget.onNavigateToAuth != null) {
      widget.onNavigateToAuth!(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFAF9F8),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // 1. FIXED TOP HEADER BAR (Logo on Left, Skip on Right)
            // Header stays stationary while only middle content animates.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandLogoWidget(height: 54),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _currentPage < 2 ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: _currentPage >= 2,
                      child: GestureDetector(
                        onTap: _handleSkip,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF594139),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // 2. MIDDLE CONTENT AREA (PageView switches only the content smoothly)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  OnboardingPageOneContent(),
                  OnboardingPageTwoContent(),
                  OnboardingPageThreeContent(),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. FIXED BOTTOM FOOTER (Button & Slider Dots stay stationary)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Button transition (Next CTA for p0/p1 vs Sign Up / Sign In for p2)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: _currentPage < 2
                        ? SizedBox(
                            key: const ValueKey('next_button'),
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC84B1A),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor:
                                    const Color(0xFFC84B1A).withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Next',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            key: const ValueKey('auth_buttons'),
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _handleSignUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFC84B1A),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: const Color(0xFFC84B1A)
                                        .withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign Up',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: _handleLogin,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFFC84B1A), width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign In',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFC84B1A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Slider / Page Indicator Dots
                  PageIndicatorDots(
                    currentIndex: _currentPage,
                    count: 3,
                    onDotTapped: _animateToPage,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Page 1 Content — "Build a happier office together."
// ---------------------------------------------------------------------------
class OnboardingPageOneContent extends StatefulWidget {
  final String imagePath;
  const OnboardingPageOneContent({
    super.key,
    this.imagePath = 'assets/images/onboarding.png',
  });

  @override
  State<OnboardingPageOneContent> createState() =>
      _OnboardingPageOneContentState();
}

class _OnboardingPageOneContentState extends State<OnboardingPageOneContent>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _rotationController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30000),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 4),

          // Enlarged Hero Pick Shape (285px)
          SizedBox(
            height: 285,
            child: Center(
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  final angle = _rotationController.value * 2 * math.pi;
                  return Transform.rotate(
                    angle: angle,
                    child: Container(
                      width: double.infinity,
                      constraints:
                          const BoxConstraints(maxHeight: 285, maxWidth: 285),
                      child: ClipPath(
                        clipper: SmoothOrganicPickClipper(),
                        child: Container(
                          color: const Color(0xFFFFE6DD),
                          padding: const EdgeInsets.all(4),
                          child: ClipPath(
                            clipper: SmoothOrganicPickClipper(),
                            child: Transform.rotate(
                              angle: -angle,
                              child: Transform.scale(
                                scale: 1.25,
                                child: Image.asset(
                                  widget.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.groups_rounded,
                                        size: 80,
                                        color: Color(0xFFFF652F),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title Section — Positioned comfortably lower
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: AppTheme.titleDark,
                letterSpacing: -0.4,
              ),
              children: [
                const TextSpan(text: 'Build a happier '),
                TextSpan(
                  text: 'office\ntogether.',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFC84B1A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle Text
          Text(
            'Share anonymous appreciation and\ncelebrate weekly heroes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 24),

          // Feature Badges Row — Lower positioning
          Row(
            children: const [
              Expanded(
                child: FeatureBadgeCard(
                  backgroundColor: Color(0xFFF4F4FD),
                  iconBackgroundColor: Color(0xFFFCE7F3),
                  iconColor: Color(0xFFEC4899),
                  icon: Icons.volunteer_activism_rounded,
                  title: 'Anonymous',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: FeatureBadgeCard(
                  backgroundColor: Color(0xFFF4F4FD),
                  iconBackgroundColor: Color(0xFFFFEDD5),
                  iconColor: Color(0xFFF97316),
                  icon: Icons.emoji_events_rounded,
                  title: 'Weekly Recognition & Awards',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Page 2 Content — "Spread positivity & boost morale."
// ---------------------------------------------------------------------------
class OnboardingPageTwoContent extends StatefulWidget {
  final String imagePath;
  const OnboardingPageTwoContent({
    super.key,
    this.imagePath = 'assets/images/onboarding_page_2.png',
  });

  @override
  State<OnboardingPageTwoContent> createState() =>
      _OnboardingPageTwoContentState();
}

class _OnboardingPageTwoContentState extends State<OnboardingPageTwoContent>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _rotationController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30000),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Widget _buildHeroImage() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final angle = _rotationController.value * 2 * math.pi;
        return Transform.rotate(
          angle: angle,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 285, maxWidth: 285),
            child: ClipPath(
              clipper: SmoothOrganicPickClipper(),
              child: Container(
                color: const Color(0xFFFFE6DD),
                padding: const EdgeInsets.all(4),
                child: ClipPath(
                  clipper: SmoothOrganicPickClipper(),
                  child: Transform.rotate(
                    angle: -angle,
                    child: Transform.scale(
                      scale: 1.25,
                      child: Image.asset(
                        widget.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.handshake_rounded,
                              size: 72,
                              color: Color(0xFFFF652F),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 4),

          // Enlarged Hero Pick Shape (285px)
          SizedBox(
            height: 285,
            child: Center(child: _buildHeroImage()),
          ),

          const SizedBox(height: 24),

          // Title Section — Positioned comfortably lower
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: AppTheme.titleDark,
                letterSpacing: -0.4,
              ),
              children: [
                const TextSpan(text: 'Spread positivity & '),
                TextSpan(
                  text: '\nboost morale.',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFC84B1A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle Text
          Text(
            'Send encouraging notes, celebrate daily wins,\nand keep your team inspired.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 24),

          // Feature Badges Row — Lower positioning
          Row(
            children: const [
              Expanded(
                child: FeatureBadgeCard(
                  backgroundColor: Color(0xFFF4F4FD),
                  iconBackgroundColor: Color(0xFFFEF3C7),
                  iconColor: Color(0xFFD97706),
                  icon: Icons.bolt_rounded,
                  title: 'Real-time Feed',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: FeatureBadgeCard(
                  backgroundColor: Color(0xFFF4F4FD),
                  iconBackgroundColor: Color(0xFFEDE9FE),
                  iconColor: Color(0xFF7C3AED),
                  icon: Icons.favorite_rounded,
                  title: 'Boost Morale',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Page 3 Content — "Ready to bring joy to your team?"
// ---------------------------------------------------------------------------
class OnboardingPageThreeContent extends StatefulWidget {
  final String imagePath;
  const OnboardingPageThreeContent({
    super.key,
    this.imagePath = 'assets/images/onboarding_page_3.png',
  });

  @override
  State<OnboardingPageThreeContent> createState() =>
      _OnboardingPageThreeContentState();
}

class _OnboardingPageThreeContentState
    extends State<OnboardingPageThreeContent>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _rotationController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30000),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Widget _buildHeroImage() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final angle = _rotationController.value * 2 * math.pi;
        return Transform.rotate(
          angle: angle,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 285, maxWidth: 285),
            child: ClipPath(
              clipper: SmoothOrganicPickClipper(),
              child: Container(
                color: const Color(0xFFFFE6DD),
                padding: const EdgeInsets.all(4),
                child: ClipPath(
                  clipper: SmoothOrganicPickClipper(),
                  child: Transform.rotate(
                    angle: -angle,
                    child: Transform.scale(
                      scale: 1.25,
                      child: Image.asset(
                        widget.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.groups_rounded,
                              size: 80,
                              color: Color(0xFFFF652F),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 4),

          // Enlarged Hero Pick Shape (285px)
          SizedBox(
            height: 285,
            child: Center(child: _buildHeroImage()),
          ),

          const SizedBox(height: 24),

          // Title Section — Positioned comfortably lower
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: AppTheme.titleDark,
                letterSpacing: -0.4,
              ),
              children: [
                const TextSpan(text: 'Ready to bring '),
                TextSpan(
                  text: '\njoy to your team?',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFC84B1A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle Text
          Text(
            'Create an account or sign in to start\ncelebrating your team today.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 24),

          // Feature Badges Row — Lower positioning
          Row(
            children: const [
              Expanded(
                child: FeatureBadgeCard(
                  backgroundColor: Color(0xFFF4F4FD),
                  iconBackgroundColor: Color(0xFFFCE7F3),
                  iconColor: Color(0xFFEC4899),
                  icon: Icons.stars_rounded,
                  title: 'Easy Setup',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: FeatureBadgeCard(
                  backgroundColor: Color(0xFFF4F4FD),
                  iconBackgroundColor: Color(0xFFD1FAE5),
                  iconColor: Color(0xFF10B981),
                  icon: Icons.workspace_premium_rounded,
                  title: 'Instant Rewards',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Smooth Organic Pick Shape Clipper
class SmoothOrganicPickClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.04, h * 0.5);
    path.cubicTo(w * 0.04, h * 0.18, w * 0.35, 0, w * 0.68, 0);
    path.cubicTo(w * 0.94, 0, w, h * 0.22, w, h * 0.5);
    path.cubicTo(w, h * 0.78, w * 0.94, h, w * 0.68, h);
    path.cubicTo(w * 0.35, h, w * 0.04, h * 0.82, w * 0.04, h * 0.5);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldDelegate) => false;
}

// Compatibility wrappers for legacy constructors if needed
class OnboardingScreenTwo extends StatelessWidget {
  final VoidCallback? onNextPressed;
  final VoidCallback? onContinuePressed;
  final VoidCallback? onSkipPressed;
  final VoidCallback? onLoginPressed;
  final ValueChanged<int>? onDotTapped;
  final String imagePath;
  final int pageIndex;
  final int totalPages;

  const OnboardingScreenTwo({
    super.key,
    this.onNextPressed,
    this.onContinuePressed,
    this.onSkipPressed,
    this.onLoginPressed,
    this.onDotTapped,
    this.imagePath = 'assets/images/onboarding_page_2.png',
    this.pageIndex = 1,
    this.totalPages = 3,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingPageTwoContent(imagePath: imagePath);
  }
}

class OnboardingScreenThree extends StatelessWidget {
  final VoidCallback? onSignUpPressed;
  final VoidCallback? onLoginPressed;
  final ValueChanged<int>? onDotTapped;
  final String imagePath;
  final int pageIndex;
  final int totalPages;

  const OnboardingScreenThree({
    super.key,
    this.onSignUpPressed,
    this.onLoginPressed,
    this.onDotTapped,
    this.imagePath = 'assets/images/onboarding_page_3.png',
    this.pageIndex = 2,
    this.totalPages = 3,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingPageThreeContent(imagePath: imagePath);
  }
}
