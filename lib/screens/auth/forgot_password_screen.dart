import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo_widget.dart';
import '../../services/sound_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                'Please enter a valid work email address.',
                style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFC84B1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    SoundService.playClockInSound();
    setState(() {
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with Back Button and Brand Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0EB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFFAB3500),
                        size: 18,
                      ),
                    ),
                    tooltip: 'Back to Log In',
                  ),
                  const BrandLogoWidget(height: 50),
                ],
              ),

              const SizedBox(height: 32),

              if (!_isSubmitted) ...[
                // Title & Subtitle Header
                Text(
                  'Reset Your Password',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.titleDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the work email associated with your U & ME account, and we\'ll send you a password reset link.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: const Color(0xFF594139),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                // Form Container Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE4E7FE)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFAB3500).withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Work Email Address',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF171B2B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          color: const Color(0xFF171B2B),
                        ),
                        decoration: InputDecoration(
                          hintText: 'alex.miller@company.com',
                          hintStyle: GoogleFonts.beVietnamPro(
                            fontSize: 13.5,
                            color: const Color(0xFF8D7168),
                          ),
                          prefixIcon: const Icon(
                            Icons.mail_outline_rounded,
                            color: Color(0xFFAB3500),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAF9F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE4E7FE)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE4E7FE)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFAB3500), width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _handleResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFAB3500),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Send Reset Link',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Success Confirmation State
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF047857).withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE6F7F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          color: Color(0xFF047857),
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Check Your Email',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF171B2B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'We sent a password reset link to:\n${_emailController.text.trim()}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          color: const Color(0xFF594139),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF9F8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE4E7FE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFAB3500),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Didn\'t receive the email? Check your spam folder or try resending.',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12.5,
                                  color: const Color(0xFF594139),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Return to Login CTA
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF171B2B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Back to Log In',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
