import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/feature_badge_card.dart';
import '../widgets/page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onNextPressed;
  final VoidCallback? onLoginPressed;
  final String imagePath;
  final int pageIndex;
  final int totalPages;

  const OnboardingScreen({
    super.key,
    this.onNextPressed,
    this.onLoginPressed,
    this.imagePath = 'assets/images/onboarding.png',
    this.pageIndex = 0,
    this.totalPages = 3,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000), // Smooth 6s revolving cycle
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8), // Warm soft background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Top Header Bar: Bigger Transparent Logo & Skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Brand Logo (assets/brand/logo_removedbg.png - Bigger height 46)
                  Image.asset(
                    'assets/brand/logo_removedbg.png',
                    height: 46,
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

              // Revolving Organic Blob Image Container (Fixed Place Smooth Rotation)
              Expanded(
                flex: 5,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final progress = _animationController.value;
                      // Gentle back-and-forth revolving orbital angle in fixed position
                      final revolveAngle = math.sin(progress * math.pi * 2) * 0.06;
                      final breathScale = 1.0 + (math.sin(progress * math.pi * 2) * 0.02);

                      return Transform.rotate(
                        angle: revolveAngle,
                        child: Transform.scale(
                          scale: breathScale,
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 310),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE6DD), // Soft organic peach background
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(160),
                                topRight: Radius.circular(160),
                                bottomLeft: Radius.circular(140),
                                bottomRight: Radius.circular(140),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF652F).withValues(alpha: 0.16),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(150),
                                topRight: Radius.circular(150),
                                bottomLeft: Radius.circular(130),
                                bottomRight: Radius.circular(130),
                              ),
                              child: Transform.scale(
                                scale: 1.18, // Zoomed in so side edges fit seamlessly without sharp cuts
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
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

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

              // Feature Badges Row (Anonymous & Weekly Heroes)
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
                      iconBackgroundColor: Color(0xFFD1FAE5),
                      iconColor: Color(0xFF10B981),
                      icon: Icons.emoji_events_rounded,
                      title: 'Weekly Heroes',
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

              const SizedBox(height: 16),

              // Secondary Action: Log in link
              GestureDetector(
                onTap: widget.onLoginPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        const TextSpan(text: 'Already part of a team? '),
                        TextSpan(
                          text: 'Log in',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFC84B1A),
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Page Indicator Dots
              PageIndicatorDots(
                currentIndex: widget.pageIndex,
                count: widget.totalPages,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
