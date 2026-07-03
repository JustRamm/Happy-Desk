import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class JarScreen extends StatefulWidget {
  const JarScreen({super.key});

  @override
  State<JarScreen> createState() => _JarScreenState();
}

class _JarScreenState extends State<JarScreen> {
  int _userContributions = 2; // e.g. 2 written out of 5 required to unlock
  final int _targetContributions = 5;

  void _showWriteAppreciationModal() {
    final noteController = TextEditingController();
    String selectedCategory = 'Kindness';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Write Appreciation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brandTitleOrange,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Drop an anonymous note into the Community Jar to spread joy!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Chips
                  Wrap(
                    spacing: 8,
                    children: ['Kindness', 'Great Job', 'Teamwork', 'Shoutout'].map((cat) {
                      final isSel = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedCategory = cat;
                            });
                          }
                        },
                        selectedColor: AppTheme.primaryRustLight,
                        labelStyle: TextStyle(
                          color: isSel ? AppTheme.primaryRust : Colors.black87,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Spread some love... (e.g. Thanks for bringing delicious cookies to the team sync today!)',
                      filled: true,
                      fillColor: const Color(0xFFF9F6F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (noteController.text.trim().isNotEmpty) {
                          setState(() {
                            if (_userContributions < _targetContributions) {
                              _userContributions++;
                            }
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Note added! Community Jar updated.'),
                              backgroundColor: AppTheme.primaryRust,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRust,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Send to Jar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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
            );
          },
        );
      },
    );
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: AppTheme.primaryRust.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppTheme.primaryRust,
                      size: 22,
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
                  'COMMUNITY JOY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryRust,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Headline & Subtitle
              Text(
                'Today\'s Dose of Appreciation',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
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

              // Main Elevated Card Container with Padlock & Progress
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
                    // Pink Circle Padlock Graphic with 'New!' Tag
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
                            child: Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 54,
                            ),
                          ),
                        ),

                        // New! Orange Tag Badge
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
                              'New!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Progress Messages
                    Text(
                      remaining > 0
                          ? 'Write $remaining more for others to open!'
                          : 'Community Jar Unlocked!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8C436E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Spread some love to unlock\ntoday\'s dose.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Progress Bar
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EEFF),
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
                  onPressed: _showWriteAppreciationModal,
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
}
