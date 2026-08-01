import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../onboarding_wrapper_screen.dart';

class GlobalCrashScreen extends StatefulWidget {
  final FlutterErrorDetails errorDetails;

  const GlobalCrashScreen({super.key, required this.errorDetails});

  @override
  State<GlobalCrashScreen> createState() => _GlobalCrashScreenState();
}

class _GlobalCrashScreenState extends State<GlobalCrashScreen> {
  bool _showDetails = false;

  void _restartApp() {
    // Clean redirect to initial onboarding wrapper screen, clearing history
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingWrapperScreen()),
      (route) => false,
    );
  }

  void _copyErrorToClipboard() {
    Clipboard.setData(ClipboardData(
      text: '${widget.errorDetails.exception}\n\n${widget.errorDetails.stack}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostics copied to clipboard!'),
        backgroundColor: AppTheme.primaryRust,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Alert Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EC),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryRust.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.primaryRust,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),

                // Main Heading
                Text(
                  'Something Went Wrong',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.titleDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'The application encountered an unexpected error. Don\'t worry, your data is safe.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _restartApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRust,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: AppTheme.primaryRust.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      'Restart Application',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Copy diagnostics button
                OutlinedButton.icon(
                  onPressed: _copyErrorToClipboard,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    side: const BorderSide(color: Color(0xFFDCDAF0), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.titleDark),
                  label: Text(
                    'Copy Diagnostic Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.titleDark,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Expandable details drawer
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showDetails = !_showDetails),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showDetails ? 'Hide Diagnostics' : 'Show Diagnostics',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryRust,
                              ),
                            ),
                            Icon(
                              _showDetails ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: AppTheme.primaryRust,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showDetails) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EEFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2DEEE)),
                        ),
                        child: SelectableText(
                          '${widget.errorDetails.exception}\n\n${widget.errorDetails.stack}',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 12,
                            color: const Color(0xFF3B2A66),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
