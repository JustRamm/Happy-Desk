import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/background_card_stack.dart';

class SplashLoadingScreen extends StatefulWidget {
  final VoidCallback? onLoadingComplete;

  const SplashLoadingScreen({
    super.key,
    this.onLoadingComplete,
  });

  @override
  State<SplashLoadingScreen> createState() => _SplashLoadingScreenState();
}

class _SplashLoadingScreenState extends State<SplashLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _progressController.forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onLoadingComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Background soft cards preview effect
          const BackgroundCardStack(),

          // Soft background gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.4),
                  const Color(0xFFF9F6F4).withValues(alpha: 0.85),
                  const Color(0xFFFAF9F8),
                ],
              ),
            ),
          ),

          // Main Screen Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Top Mascot / Logo Card Container
                Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppTheme.primaryRust.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/brand/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('assets/brand/logo_removedbg.png');
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // App Title & Tagline
                Text(
                  'Happy Desk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brandTitleOrange,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'WORKPLACE JOY REINVENTED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 2.2,
                  ),
                ),

                const Spacer(),

                // Bottom Progress Bar & Loading Label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      // Progress Bar
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Stack(
                            children: [
                              // Background Track
                              Container(
                                height: 6,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.progressTrack,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              // Active Progress Fill
                              FractionallySizedBox(
                                widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryRust,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryRust.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SETTING UP YOUR SPACE...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.08),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
