import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'notifications_screen.dart';
import 'compose_ngl_note_screen.dart';
import 'ngl_note_detail_screen.dart';
import '../widgets/jar_icon_widget.dart';

class JarScreen extends StatefulWidget {
  const JarScreen({super.key});

  @override
  State<JarScreen> createState() => _JarScreenState();
}

class _JarScreenState extends State<JarScreen> {
  int _userContributions = 2; // e.g. 2 written out of 5 required to unlock
  final int _targetContributions = 5;

  void _openComposeNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ComposeNglNoteScreen()),
    );
    if (result == true) {
      setState(() {
        if (_userContributions < _targetContributions) {
          _userContributions++;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progressFactor = (_userContributions / _targetContributions).clamp(0.0, 1.0);
    final int remaining = _targetContributions - _userContributions;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              // Top Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand Logo in Top Left Corner (Enlarged size 70)
                  Image.asset(
                    'assets/brand/logo_removedbg.png',
                    height: 70,
                    fit: BoxFit.contain,
                  ),

                  // Notification Bell
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF8B2600),
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Community Joy Tag Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAE2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Community Appreciation',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryRust,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Title Section: NGL Appreciation Jar
              Text(
                'NGL Appreciation Jar',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.titleDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'The Jar is filling up with kindness! Unlock it\nby spreading some joy yourself.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 24),

              // Main Elevated Card Container with Jar Graphic & Progress
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Pink Circle Badge with Jar Graphic
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8EA9), // Vibrant Pink Circle
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8EA9).withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: JarIconWidget(
                              size: 64,
                              mainColor: Colors.white,
                              lidColor: Color(0xFFC84B1A),
                              liquidColor: Color(0xFFFFD6C7),
                            ),
                          ),
                        ),

                        // Active Tag Badge
                        Positioned(
                          top: 0,
                          right: -10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF652F),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              'Active',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Progress Status Title
                    Text(
                      _userContributions >= _targetContributions
                          ? 'Jar Unlocked!'
                          : 'Write $remaining more notes to unlock',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.titleDark,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Subtitle progress count
                    Text(
                      '$_userContributions / $_targetContributions Notes Contributed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Linear Progress Bar Track
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progressFactor,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRust,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Primary Action Button: Write Appreciation
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _openComposeNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRust,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppTheme.primaryRust.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Write Appreciation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Card 1: TOTAL DOSES (Soft Lavender/Blue)
              _buildMetricCard(
                title: 'TOTAL DOSES',
                metric: '124',
                subtitle: 'Notes shared this week',
                icon: Icons.favorite_border_rounded,
                bgColor: const Color(0xFFF4F4FD),
                accentColor: AppTheme.primaryRust,
                titleColor: const Color(0xFF8E827A),
              ),

              const SizedBox(height: 16),

              // Card 2: LEADERBOARD (Mint/Teal Green)
              _buildMetricCard(
                title: 'LEADERBOARD',
                metric: '#2',
                subtitle: 'Top Giver rank',
                icon: Icons.emoji_events_outlined,
                bgColor: const Color(0xFF50E8B5),
                accentColor: const Color(0xFF044E38),
                titleColor: const Color(0xFF044E38),
              ),

              const SizedBox(height: 16),

              // Card 3: STREAK (Soft Pink)
              _buildMetricCard(
                title: 'STREAK',
                metric: '8 Days',
                subtitle: 'Keeping the joy alive!',
                icon: Icons.auto_awesome_outlined,
                bgColor: const Color(0xFFFDE0EC),
                accentColor: const Color(0xFF7C3A68),
                titleColor: const Color(0xFF7C3A68),
              ),

              const SizedBox(height: 28),

              // Section: Unlocked Recent Notes Preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT NOTES IN JAR',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryRust,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'Unlocked',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Note Preview Card 1
              _buildNotePreviewCard(
                recipient: 'Alex Miller',
                category: 'Kindness',
                snippet: 'Thank you for staying late to help me debug the design system...',
                date: 'Today at 10:45 AM',
                color: const Color(0xFFFFF0EB),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NglNoteDetailScreen(
                        recipientName: 'Alex Miller',
                        category: 'Kindness',
                        message:
                            'Thank you for staying late to help me debug the design system components before product release! Your support made all the difference.',
                        date: 'Today at 10:45 AM',
                        cardBgColor: Color(0xFFFFF0EB),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Note Preview Card 2
              _buildNotePreviewCard(
                recipient: 'Sarah Chen',
                category: 'Growth',
                snippet: 'Your presentation at the all-hands meeting was super inspiring...',
                date: 'Yesterday at 4:20 PM',
                color: const Color(0xFFE6F7F0),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NglNoteDetailScreen(
                        recipientName: 'Sarah Chen',
                        category: 'Growth',
                        message:
                            'Your presentation at the all-hands meeting was super inspiring! Loved how you explained the new workflow so clearly.',
                        date: 'Yesterday at 4:20 PM',
                        cardBgColor: Color(0xFFE6F7F0),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String metric,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color accentColor,
    required Color titleColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: accentColor, size: 22),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            metric,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.titleDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotePreviewCard({
    required String recipient,
    required String category,
    required String snippet,
    required String date,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'To $recipient',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.titleDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryRust,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              snippet,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.titleDark,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Read Note',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryRust,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.primaryRust),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
