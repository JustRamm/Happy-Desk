import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo_widget.dart';
import '../widgets/jar_icon_widget.dart';
import '../widgets/multi_coffee_reset_modal.dart';
import 'jar_screen.dart';
import 'hero_screen.dart';
import 'notifications_screen.dart';

class KudosScreen extends StatelessWidget {
  const KudosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Bar (Exact match with Home Screen)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand Logo SVG
                  const BrandLogoWidget(height: 54),

                  // Notification Bell & Coffee Break icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notifications Bell Icon
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF0EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            color: Color(0xFFAB3500),
                            size: 22,
                          ),
                        ),
                        tooltip: 'Notifications',
                      ),

                      // Coffee Break Icon
                      IconButton(
                        onPressed: () => MultiCoffeeResetModal.show(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F2FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_cafe_rounded,
                            color: Color(0xFF95416C),
                            size: 22,
                          ),
                        ),
                        tooltip: 'Coffee Break',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Title Section
              Text(
                'Kudos & Teammate\nRecognition',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.titleDark,
                  letterSpacing: -0.5,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Celebrate teammate wins, drop anonymous notes, and vote for your Weekly Hero.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.5,
                  color: const Color(0xFF594139),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 22),

              // SECTION 1: NGL APPRECIATION JAR CARD (Soft Lavender Brand Design Colors)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FF), // Soft Lavender/Purple
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3A68).withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Title: "Your NGL Jar"
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C3A68),
                        ),
                        children: [
                          const TextSpan(text: 'Your '),
                          TextSpan(
                            text: 'NGL Jar',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Jar Graphic Illustration
                    const SizedBox(
                      height: 130,
                      child: Center(
                        child: JarIconWidget(
                          size: 120,
                          mainColor: Color(0xFF7C3A68),
                          lidColor: Color(0xFF9D4B85),
                          liquidColor: Color(0xFFFF8EA9),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle / Progress Counter
                    Text(
                      '13/20 entries',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2A2050),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unlock the jar by Friday!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B5B95),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Open Jar Notes Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JarScreen(showBackButton: true),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(
                          'Open NGL Jar Notes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8C436E),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SECTION 2: WEEKLY HERO NOMINATIONS CARD (Soft Emerald Design Colors)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5), // Soft Emerald Mint
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFA7F3D0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006C53).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006C53).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'WEEKLY HERO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF006C53),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'Nominate Someone Who Helped You',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF004D3B),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Did a teammate step up to support you? Nominate 1 person anonymously to brighten their week.',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: const Color(0xFF005E48),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadgeChip('#Supportive'),
                        _buildBadgeChip('#ProblemSolver'),
                        _buildBadgeChip('#TeamPlayer'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Nominate Hero Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HeroScreen(showBackButton: true),
                            ),
                          );
                        },
                        icon: const Icon(Icons.star_rounded, size: 18),
                        label: Text(
                          'Nominate Your Weekly Hero',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006C53),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF006C53).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF004D3B),
        ),
      ),
    );
  }
}
