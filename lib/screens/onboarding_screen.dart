import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/feature_badge_card.dart';
import '../widgets/page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onNextPressed;
  final VoidCallback? onLoginPressed;
  final ValueChanged<int>? onDotTapped;
  final String imagePath;
  final int pageIndex;
  final int totalPages;

  const OnboardingScreen({
    super.key,
    this.onNextPressed,
    this.onLoginPressed,
    this.onDotTapped,
    this.imagePath = 'assets/images/onboarding.png',
    this.pageIndex = 0,
    this.totalPages = 3,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  AnimationController? _rotationController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _rotationController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30000), // Slow 30s clockwise rotation
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8), // Warm soft background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Top Header Bar: Transparent Logo & Skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Brand Logo (assets/brand/logo_removedbg.png)
                  Image.asset(
                    'assets/brand/logo_removedbg.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),

                  // Skip Link
                  GestureDetector(
                    onTap: widget.onLoginPressed,
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
                ],
              ),

              const SizedBox(height: 16),

              // Clockwise Revolving Organic Smooth Pick Container with Upright Artwork Image
              Expanded(
                flex: 4,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _rotationController ?? AnimationController(vsync: this),
                    builder: (context, child) {
                      _initController();
                      final angle = (_rotationController?.value ?? 0) * 2 * math.pi; // 360 deg Clockwise

                      return Transform.rotate(
                        angle: angle, // Outer organic pick shape rotates Clockwise
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 270, maxWidth: 270),
                          child: ClipPath(
                            clipper: SmoothOrganicPickClipper(),
                            child: Container(
                              color: const Color(0xFFFFE6DD), // Solid soft peach shape background (no blur)
                              padding: const EdgeInsets.all(4),
                              child: ClipPath(
                                clipper: SmoothOrganicPickClipper(),
                                child: Transform.rotate(
                                  angle: -angle, // Counter-rotate artwork so people illustration stays upright!
                                  child: Transform.scale(
                                    scale: 1.25, // Zoomed in so artwork covers smooth pick shape perfectly
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

              const SizedBox(height: 36),

              // Title Section
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
                        color: const Color(0xFFC84B1A), // Deep Rust Orange
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

              // Feature Badges Row (Anonymous & Weekly Recognition & Awards)
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

              const Spacer(flex: 2),

              // Primary Action CTA Button: Next ->
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: widget.onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC84B1A),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFFC84B1A).withValues(alpha: 0.4),
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
              ),

              const SizedBox(height: 20),

              // Page Indicator Dots
              PageIndicatorDots(
                currentIndex: widget.pageIndex,
                count: widget.totalPages,
                onDotTapped: widget.onDotTapped,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Smooth Organic Pick Shape Clipper (Tip at Left)
class SmoothOrganicPickClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Smooth rounded tip pointing to left at (w * 0.04, h * 0.5)
    path.moveTo(w * 0.04, h * 0.5);

    // Top curve extending up and right to broad rounded top-right shoulder
    path.cubicTo(w * 0.04, h * 0.18, w * 0.35, 0, w * 0.68, 0);
    path.cubicTo(w * 0.94, 0, w, h * 0.22, w, h * 0.5);

    // Bottom curve extending down and left back to left tip
    path.cubicTo(w, h * 0.78, w * 0.94, h, w * 0.68, h);
    path.cubicTo(w * 0.35, h, w * 0.04, h * 0.82, w * 0.04, h * 0.5);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldDelegate) => false;
}

// ---------------------------------------------------------------------------
//  Interest tile data model (used by OnboardingScreenTwo)
// ---------------------------------------------------------------------------
class _InterestOption {
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _InterestOption({
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

const List<_InterestOption> _interests = [
  _InterestOption(
    label: 'Appreciation',
    icon: Icons.favorite_rounded,
    iconBg: Color(0xFFFCE7F3),
    iconColor: Color(0xFFEC4899),
  ),
  _InterestOption(
    label: 'Team Building',
    icon: Icons.groups_rounded,
    iconBg: Color(0xFFF3E8FF),
    iconColor: Color(0xFF9333EA),
  ),
  _InterestOption(
    label: 'Growth',
    icon: Icons.trending_up_rounded,
    iconBg: Color(0xFFD1FAE5),
    iconColor: Color(0xFF10B981),
  ),
  _InterestOption(
    label: 'Wellness',
    icon: Icons.spa_rounded,
    iconBg: Color(0xFFEDE9FE),
    iconColor: Color(0xFF7C3AED),
  ),
];

// ---------------------------------------------------------------------------
//  Onboarding Screen 2 — "What brings you joy?"
// ---------------------------------------------------------------------------
class OnboardingScreenTwo extends StatefulWidget {
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
  State<OnboardingScreenTwo> createState() => _OnboardingScreenTwoState();
}

class _OnboardingScreenTwoState extends State<OnboardingScreenTwo>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final Set<int> _selected = {};
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

  void _toggleInterest(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  // ── Hero blob image (same revolving organic shape as screen 1) ────────────
  Widget _buildHeroImage() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final angle = _rotationController.value * 2 * math.pi;
        return Transform.rotate(
          angle: angle, // Outer organic pick shape rotates Clockwise
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 270, maxWidth: 270),
            child: ClipPath(
              clipper: SmoothOrganicPickClipper(),
              child: Container(
                color: const Color(0xFFFFE6DD), // Solid soft peach shape background
                padding: const EdgeInsets.all(4),
                child: ClipPath(
                  clipper: SmoothOrganicPickClipper(),
                  child: Transform.rotate(
                    angle: -angle, // Counter-rotate artwork so people illustration stays upright!
                    child: Transform.scale(
                      scale: 1.25, // Zoomed in so artwork covers smooth pick shape perfectly
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

  // ── Single compact interest tile ──────────────────────────────────────────
  Widget _buildInterestTile(int index, _InterestOption option) {
    final isSelected = _selected.contains(index);
    return GestureDetector(
      onTap: () => _toggleInterest(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0EB) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC84B1A)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: isSelected ? 0.05 : 0.02),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected
                    ? option.iconBg
                    : option.iconBg.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(option.icon, color: option.iconColor, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                option.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(0xFF1F1F1F)
                      : const Color(0xFF374151),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFC84B1A),
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Compact 2x2 Interest Grid (4 options) ─────────────────────────────────
  Widget _buildInterestGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemCount: _interests.length,
      itemBuilder: (context, index) =>
          _buildInterestTile(index, _interests[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final skipCallback = widget.onSkipPressed ?? widget.onLoginPressed;
    final nextCallback =
        widget.onNextPressed ?? widget.onContinuePressed;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Top Header Bar: Transparent Logo & Skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/brand/logo_removedbg.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  GestureDetector(
                    onTap: skipCallback,
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
                ],
              ),

              const SizedBox(height: 16),

              // Hero Image (Expanded flex 4 matching Page 1)
              Expanded(
                flex: 4,
                child: Center(child: _buildHeroImage()),
              ),

              const SizedBox(height: 24),

              // Title
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
                    const TextSpan(text: 'What brings '),
                    TextSpan(
                      text: 'you joy?',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFC84B1A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Select your interests to personalize\nyour dashboard.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 18),

              // Compact Interest Tiles Grid (No Vertical Scrolling)
              _buildInterestGrid(),

              const Spacer(flex: 2),

              // Primary Action CTA Button: Next → (Aligned with Page 1)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: nextCallback,
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
              ),

              const SizedBox(height: 20),

              // Page Indicator Dots
              PageIndicatorDots(
                currentIndex: widget.pageIndex,
                count: widget.totalPages,
                onDotTapped: widget.onDotTapped,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Onboarding Screen 3 — Final Onboarding Screen ("Ready to bring joy to your team?")
// ---------------------------------------------------------------------------
class OnboardingScreenThree extends StatefulWidget {
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
  State<OnboardingScreenThree> createState() => _OnboardingScreenThreeState();
}

class _OnboardingScreenThreeState extends State<OnboardingScreenThree>
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
          angle: angle, // Outer organic pick shape rotates Clockwise
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 270, maxWidth: 270),
            child: ClipPath(
              clipper: SmoothOrganicPickClipper(),
              child: Container(
                color: const Color(0xFFFFE6DD), // Solid soft peach shape background
                padding: const EdgeInsets.all(4),
                child: ClipPath(
                  clipper: SmoothOrganicPickClipper(),
                  child: Transform.rotate(
                    angle: -angle, // Counter-rotate artwork so people illustration stays upright!
                    child: Transform.scale(
                      scale: 1.25, // Zoomed in so artwork covers smooth pick shape perfectly
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Top Header Bar: Logo (Skip removed on final screen)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/brand/logo_removedbg.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Hero Image
              Expanded(
                flex: 4,
                child: Center(child: _buildHeroImage()),
              ),

              const SizedBox(height: 24),

              // Title Section: Ready to bring joy to your team?
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
                      text: 'joy\nto your team?',
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // Feature Badges Row
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

              const Spacer(flex: 2),

              // Primary Action: Sign Up Button (Routes to Auth Sign Up)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.onSignUpPressed,
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

              // Secondary Action: Sign In Button (Routes to Auth Login)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: widget.onLoginPressed,
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

              const SizedBox(height: 20),

              // Page Indicator Dots
              PageIndicatorDots(
                currentIndex: widget.pageIndex,
                count: widget.totalPages,
                onDotTapped: widget.onDotTapped,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
