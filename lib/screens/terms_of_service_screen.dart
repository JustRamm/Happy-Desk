import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.titleDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms of Service',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppTheme.titleDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBFE),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD8C7FF)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C3AED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Terms & Agreement',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                          Text(
                            'Effective Date: July 2026 • Version 1.0',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11.5,
                              color: const Color(0xFF5B21B6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildSection(
                title: '1. Acceptance of Terms',
                body:
                    'By downloading, accessing, or using the U & ME application, you agree to be bound by these Terms of Service. If you do not agree with any part of these terms, you may not use the app.',
              ),

              _buildSection(
                title: '2. Psychological Safety & Community Conduct',
                body:
                    'U & ME is designed to foster psychological safety, mutual peer appreciation, and constructive communication. Harassment, hateful speech, cyberbullying, or abusive behavior in NGL notes, direct messages, or hero nominations is strictly prohibited and subject to account suspension.',
              ),

              _buildSection(
                title: '3. NGL Jar & Appreciation Guidelines',
                body:
                    'Anonymous features are provided to encourage authentic positive feedback and mentorship. Misusing anonymity to send deceptive, harmful, or spam messages violates our core community safety guidelines.',
              ),

              _buildSection(
                title: '4. Account Credentials & Security',
                body:
                    'You are responsible for maintaining the confidentiality of your account credentials and leader codes. Notify your workspace administrator immediately if you suspect unauthorized access to your workspace account.',
              ),

              _buildSection(
                title: '5. Intellectual Property Rights',
                body:
                    'All brand elements, original logos, micro-lesson content, vector artwork, and custom design systems in U & ME are proprietary intellectual property.',
              ),

              _buildSection(
                title: '6. Termination & Governing Law',
                body:
                    'We reserve the right to suspend or terminate accounts that violate community safety standards. These terms are governed by standard software service agreements.',
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  'U & ME Community Agreement',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String body}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7FE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.titleDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.titleDark,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
