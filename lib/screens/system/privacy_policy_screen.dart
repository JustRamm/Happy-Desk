import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                  color: const Color(0xFFE6F7F0),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF047857),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100% Data Protection',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF047857),
                            ),
                          ),
                          Text(
                            'Last updated: July 2026 • Version 1.0',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11.5,
                              color: const Color(0xFF065F46),
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
                title: '1. Overview & Commitment',
                body:
                    'U & ME respects your personal and workplace privacy. This policy outlines how we handle data within the U & ME platform. We design all social bonding and wellness tools with end-to-end encryption and psychological safety as core principles.',
              ),

              _buildSection(
                title: '2. Anonymous NGL Jar Encryption',
                body:
                    'Appreciation notes dropped into recipient NGL Jars are strictly anonymous by default. Sender identity metadata is never stored or exposed in client payloads unless you explicitly choose to sign your name.',
              ),

              _buildSection(
                title: '3. Work Session & Location Logging',
                body:
                    'Work session clock-in timestamps and location tags (e.g. HQ Floor 3 or WFH) are collected solely to calculate personal focus metrics and share team presence broadcasts. We never track your continuous background GPS position.',
              ),

              _buildSection(
                title: '4. Stress Vent Shredder Privacy',
                body:
                    'Text written inside the Stress Vent Shredder is ephemeral. Once you tap "Shred Vent", the content is purged immediately from device memory and is never transmitted to cloud servers.',
              ),

              _buildSection(
                title: '5. Third-Party Data Selling Policy',
                body:
                    'We never sell, monetize, or share your personal information or workplace productivity insights with third-party advertisers or data brokers.',
              ),

              _buildSection(
                title: '6. Contact Privacy Team',
                body:
                    'If you have questions regarding data retention, export requests, or security policies, please contact privacy@u-and-me.com.',
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  'U & ME Security & Privacy Standard',
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
