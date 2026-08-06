import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo_widget.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          'About',
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero App Header
              const SizedBox(height: 10),
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE4E7FE), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRust.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const BrandLogoWidget(height: 48),
              ),
              const SizedBox(height: 14),
              Text(
                'U & ME',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.titleDark,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Version 1.0.0+49 • Happy Desk Edition',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Empowering Emotional Resilience at Work & Life',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryRust,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 1. FIRST: About U & ME App
              _buildSectionCard(
                title: 'About U & ME App',
                icon: Icons.spa_rounded,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'U & ME (Happy Desk) bridges employee workplace productivity with deep emotional destressing and psychological safety:',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        height: 1.55,
                        color: const Color(0xFF171B2B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureBullet(
                      icon: Icons.location_on_rounded,
                      text: 'Location-Aware Work Sessions: Real device GPS geocoded clock-in logs for shift verification.',
                    ),
                    _buildFeatureBullet(
                      icon: Icons.psychology_rounded,
                      text: 'Mochi Emotional Companion: 1-on-1 empathetic listening, CBT thought reframing, and breathing resets.',
                    ),
                    _buildFeatureBullet(
                      icon: Icons.forum_rounded,
                      text: 'NGL Venting Jar: Safe, anonymous space for sharing workplace thoughts and peer encouragement.',
                    ),
                    _buildFeatureBullet(
                      icon: Icons.emoji_events_rounded,
                      text: 'Weekly Hero Shoutouts: Celebrating everyday workplace wins and peer appreciation.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. SECOND: About Mind Empowered (ME) Organisation
              _buildSectionCard(
                title: 'About Mind Empowered (ME)',
                icon: Icons.volunteer_activism_rounded,
                iconColor: const Color(0xFFAB3500),
                bgColor: const Color(0xFFFFF7F5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mind Empowered logo (ME.png) showcase
                    Center(
                      child: Image.asset(
                        'assets/about/ME.png',
                        height: 54,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Large Showcase Founder Image
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/about/founders.png',
                          width: double.infinity,
                          height: 230, // Bigger size to showcase founders
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Maya Menon & Srila Menon\nCo-Founders of Mind Empowered (ME)',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFAB3500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mind Empowered (ME) is a charitable organization based in India, born from compassion, empathy, and deep understanding.',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13.5,
                        height: 1.55,
                        color: const Color(0xFF171B2B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The Story Behind ME:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFAB3500),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ME is the brainchild of Maya Menon and Srila Menon, two sisters who radiate positivity and happiness wherever they go. During the lockdown, the sisters began conducting free online classes on Spoken English and Interview Skills for college students.\n\nThrough this close interaction, they realized Gen-Z and young professionals were grappling with severe mental health issues — from anxiety, depression, and workplace burnout to loneliness and cyberbullying — in ways previous generations never experienced.',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        height: 1.55,
                        color: const Color(0xFF594139),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 3. THIRD: People Who Made Them (Co-Founders & Tech Leadership)
              _buildSectionCard(
                title: 'People Behind U & ME',
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF171B2B),
                bgColor: const Color(0xFFF3F4F6),
                child: Column(
                  children: [
                    // Lead Developer Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F2FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE4E7FE)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/about/abiram.png',
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 72,
                                height: 72,
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                child: const Icon(Icons.code_rounded, color: Color(0xFF7C3AED), size: 36),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Abiram T. Bijoy',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF171B2B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mind Empowered Dev Team Lead',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Full stack developer.',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 11.5,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Footer Note
              Center(
                child: Text(
                  'Crafted with Care by Mind Empowered (ME)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E7FE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171B2B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }



  Widget _buildFeatureBullet({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.5,
                height: 1.4,
                color: const Color(0xFF594139),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
