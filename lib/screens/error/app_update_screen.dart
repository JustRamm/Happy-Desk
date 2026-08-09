import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../auth/onboarding_wrapper_screen.dart';

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  bool _isComplete = false;

  void _startUpdateDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _isComplete = false;
    });

    // Simulate progress updates for premium UX
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _progress = i / 100.0;
      });
    }

    setState(() {
      _isComplete = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    // Reset app state and restart onboarding
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingWrapperScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Upgrading Rocket Icon
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EE),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryRust.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: AppTheme.primaryRust,
                  size: 64,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Critical Update Required',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.titleDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'To maintain database sync stability, real-time message delivery, and branch geo-fencing accuracy, please download the latest version of U & ME.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Download widget
              if (_isDownloading) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE4E7FE)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isComplete ? 'Download Complete!' : 'Downloading Update...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.titleDark,
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryRust,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFF1EEFA),
                          color: AppTheme.primaryRust,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isComplete
                            ? 'Installing packages & relaunching...'
                            : 'Optimizing modules for your device...',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Primary CTA
              if (!_isDownloading)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _startUpdateDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRust,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: AppTheme.primaryRust.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      'Download & Install Update',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
