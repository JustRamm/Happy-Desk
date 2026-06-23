import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/feature_badge_card.dart';
import '../widgets/page_indicator.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback? onNextPressed;
  final VoidCallback? onLoginPressed;
  final String imagePath;
  final int pageIndex;
  final int totalPages;

  const OnboardingScreen({
    super.key,
    this.onNextPressed,
    this.onLoginPressed,
    this.imagePath = 'assets/images/office_appreciation.png',
    this.pageIndex = 0,
    this.totalPages = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              
              // Top Illustration Container with Soft Peach Blob background
              Expanded(
                flex: 5,
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 320),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRustLight,
                      borderRadius: BorderRadius.circular(160),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRust.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(140),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.groups_rounded,
                              size: 80,
                              color: AppTheme.primaryRust.withValues(alpha: 0.5),
                            ),
                          );
                        },
                      ),
                    ),
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
                  ),
                  children: [
                    const TextSpan(text: 'Build a happier '),
                    TextSpan(
                      text: 'office\ntogether.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primaryRust,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

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
                      backgroundColor: AppTheme.pinkBadgeBg,
                      iconBackgroundColor: AppTheme.pinkIconBg,
                      iconColor: AppTheme.pinkIconColor,
                      icon: Icons.volunteer_activism_rounded,
                      title: 'Anonymous',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: FeatureBadgeCard(
                      backgroundColor: AppTheme.mintBadgeBg,
                      iconBackgroundColor: AppTheme.mintIconBg,
                      iconColor: AppTheme.mintIconColor,
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
                  onPressed: onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRust,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppTheme.primaryRust.withValues(alpha: 0.4),
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
                onTap: onLoginPressed,
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
                            color: AppTheme.primaryRust,
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
                currentIndex: pageIndex,
                count: totalPages,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
