import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/brand_logo_widget.dart';
import '../services/user_preferences_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _currentVibeStatus = 'In Deep Focus';

  final List<String> _vibeOptions = [
    'In Deep Focus',
    'Available & Collaborative',
    'On 5-Min Desk Stretch',
    'WFH Coffee Break',
  ];

  final List<Map<String, dynamic>> _kudos = [
    {
      'title': 'Supportive Teammate',
      'category': 'Community Badge',
      'count': 14,
      'color': const Color(0xFF006C53),
      'bgColor': const Color(0xFFEBF7F5),
      'icon': Icons.favorite_rounded,
    },
    {
      'title': 'Problem Solver',
      'category': 'Peer Kudos',
      'count': 9,
      'color': const Color(0xFFAB3500),
      'bgColor': const Color(0xFFFFF0EB),
      'icon': Icons.lightbulb_rounded,
    },
    {
      'title': 'Joy Booster',
      'category': 'Weekly Hero Tag',
      'count': 22,
      'color': const Color(0xFF95416C),
      'bgColor': const Color(0xFFF3F2FF),
      'icon': Icons.auto_awesome_rounded,
    },
  ];

  final List<String> _superpowers = [
    '#ProblemSolver',
    '#LifeSaver',
    '#Supportive',
    '#CreativeSpark',
    '#ClutchPlayer',
  ];

  @override
  Widget build(BuildContext context) {
    final userName = UserPreferencesStore.getUserName();
    final userRole = UserPreferencesStore.getUserRole();
    final company = UserPreferencesStore.getCompany();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Bar: Logo & Settings Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandLogoWidget(height: 54),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Color(0xFF8B2600),
                      size: 28,
                    ),
                    tooltip: 'Settings',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // User Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE4E7FE)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFAB3500).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFAB3500),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFAB3500).withValues(alpha: 0.15),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/brand/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFAB3500),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF171B2B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userRole,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: const Color(0xFF594139),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Member of $company',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFAB3500),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Edit Profile CTA Button
                    OutlinedButton(
                      onPressed: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                        if (updated == true && mounted) {
                          setState(() {});
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        side: const BorderSide(color: Color(0xFFAB3500), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFAB3500)),
                          const SizedBox(width: 8),
                          Text(
                            'Edit Profile',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFAB3500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Live Work Vibe Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE4E7FE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Color(0xFF95416C), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Live Work Status',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF171B2B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _vibeOptions.map((vibe) {
                        final isSelected = _currentVibeStatus == vibe;
                        return GestureDetector(
                          onTap: () => setState(() => _currentVibeStatus = vibe),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF3F2FF) : const Color(0xFFFAF9F8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF95416C) : const Color(0xFFE5E7EB),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              vibe,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? const Color(0xFF95416C) : const Color(0xFF594139),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Weekly Impact & Joy Dashboard Summary
              Text(
                'Weekly Joy Impact',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171B2B),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatTile('14 Notes', 'NGL Received', Icons.all_inbox_rounded, const Color(0xFFFF652F), const Color(0xFFFFEBE6)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatTile('9 Badges', 'Hero Awards', Icons.workspace_premium_rounded, const Color(0xFF10B981), const Color(0xFFE6F7F0)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile('12 Days', 'Joy Streak', Icons.local_fire_department_rounded, const Color(0xFF7C3AED), const Color(0xFFF0EBFE)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatTile('38 Hours', 'Focus Clocked', Icons.timer_rounded, const Color(0xFFD97706), const Color(0xFFFFF7ED)),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Superpowers & Peer Endorsements
              Text(
                'Teammate Superpower Endorsements',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171B2B),
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: _superpowers.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7F0),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Peer Kudos & Appreciation Badges
              Text(
                'Peer Appreciation Badges',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171B2B),
                ),
              ),
              const SizedBox(height: 12),

              ..._kudos.map((kudo) {
                final Color color = kudo['color'];
                final Color bgColor = kudo['bgColor'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4E7FE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(kudo['icon'], color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kudo['title'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF171B2B),
                              ),
                            ),
                            Text(
                              kudo['category'],
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: const Color(0xFF594139),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${kudo['count']} Nominations',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String value, String label, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7FE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF171B2B),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11.5,
                    color: const Color(0xFF594139),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
