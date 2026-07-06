import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'jar_screen.dart';
import 'notifications_screen.dart';
import '../widgets/jar_icon_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isClockedIn = false;
  int _nglEntries = 13;
  final int _targetEntries = 20;

  void _toggleClockIn() {
    setState(() {
      _isClockedIn = !_isClockedIn;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isClockedIn
              ? 'Clocked in successfully! Have a joyful session.'
              : 'Clocked out. Great work today!',
        ),
        backgroundColor: AppTheme.primaryRust,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddEntryModal() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
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
                    'Add Anonymous Note',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF7C3A68),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Share a kind word or secret appreciation to fill the team NGL Jar!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write something uplifting...',
                  filled: true,
                  fillColor: const Color(0xFFF9F5F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (textController.text.trim().isNotEmpty) {
                      setState(() {
                        if (_nglEntries < _targetEntries) {
                          _nglEntries++;
                        }
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Appreciation added to the jar!'),
                          backgroundColor: AppTheme.primaryRust,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C436E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Drop in Jar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FE), // Warm ambient light background
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

                  // Jar + Notification icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Jar Icon
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const JarScreen()),
                          );
                        },
                        icon: const JarIconWidget(
                          size: 24,
                          mainColor: Color(0xFF8B2600),
                          lidColor: Color(0xFFC84B1A),
                        ),
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
                ],
              ),

              const SizedBox(height: 20),

              // Greeting Headline
              Text(
                "Let's spread some joy\ntoday.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: AppTheme.titleDark,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 20),

              // Card 1: Work Session Card (Orange)
              _buildWorkSessionCard(),

              const SizedBox(height: 20),

              // Card 2: Your NGL Jar Card (Soft Lavender)
              _buildNglJarCard(),

              const SizedBox(height: 20),

              // Card 3: Weekly Hero Card (Teal/Emerald with Hashtags)
              _buildWeeklyHeroCard(),

              const SizedBox(height: 20),

              // Card 4: Your Week Summary Card (Productivity & Vibe Check)
              _buildYourWeekCard(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Card 1: Work Session Card
  Widget _buildWorkSessionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFF652F), // Vibrant Coral Orange
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF652F).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Watermark Clock Graphic
          Positioned(
            right: -10,
            top: 10,
            child: Opacity(
              opacity: 0.15,
              child: Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A1500),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_filled_rounded,
                    size: 84,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Card Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Tag Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isClockedIn ? 'Status: Clocked In (Active)' : 'Status: Not Clocked In',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A1500),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Headline
              Text(
                _isClockedIn ? 'Work session in progress!' : 'Ready to start your\nwork session?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4A1500),
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle Text
              Text(
                "Every minute counts toward the team's\nweekly happiness target!",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B1D00),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 20),

              // Primary Action Button (Clock In / Clock Out)
              ElevatedButton(
                onPressed: _toggleClockIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D1200), // Dark Brown
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isClockedIn ? 'Clock Out' : 'Clock In',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isClockedIn ? Icons.stop_circle_rounded : Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Team Clocked-In Status Live Hub
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF4A1500)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Team Status Today',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF4A1500),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007A5A), // Emerald Green Pill
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isClockedIn ? '4/5 Clocked In' : '3/5 Clocked In',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Teammate Avatars Row with Live Active Status Dots
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          // Teammate 1 - Sarah (Clocked In)
                          _buildTeammateStatusAvatar(
                            name: 'Sarah M.',
                            assetPath: 'assets/avatars/avatar_1.png',
                            isClockedIn: true,
                            timeText: '9:15 AM',
                          ),
                          const SizedBox(width: 14),

                          // Teammate 2 - Alex C. (Clocked In)
                          _buildTeammateStatusAvatar(
                            name: 'Alex C.',
                            assetPath: 'assets/avatars/avatar_2.png',
                            isClockedIn: true,
                            timeText: '9:30 AM',
                          ),
                          const SizedBox(width: 14),

                          // Teammate 3 - David R. (Clocked In)
                          _buildTeammateStatusAvatar(
                            name: 'David R.',
                            assetPath: 'assets/avatars/avatar_3.png',
                            isClockedIn: true,
                            timeText: '9:45 AM',
                          ),
                          const SizedBox(width: 14),

                          // Teammate 4 - Elena R. (Not Clocked In)
                          _buildTeammateStatusAvatar(
                            name: 'Elena R.',
                            assetPath: 'assets/avatars/avatar_4.png',
                            isClockedIn: false,
                            timeText: 'Offline',
                          ),
                          const SizedBox(width: 14),

                          // User (Dynamic live status!)
                          _buildTeammateStatusAvatar(
                            name: 'You',
                            assetPath: 'assets/avatars/user_avatar.png',
                            isClockedIn: _isClockedIn,
                            timeText: _isClockedIn ? 'Active Now' : 'Not Yet',
                            isCurrentUser: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Teammate Avatar Status Helper Widget
  Widget _buildTeammateStatusAvatar({
    required String name,
    required String assetPath,
    required bool isClockedIn,
    required String timeText,
    bool isCurrentUser = false,
  }) {
    return Column(
      children: [
        Stack(
          children: [
            // Avatar Circle with Border
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentUser
                      ? const Color(0xFFFFD166)
                      : (isClockedIn ? Colors.white : Colors.white.withValues(alpha: 0.5)),
                  width: isCurrentUser ? 2.5 : 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: isCurrentUser ? const Color(0xFFC84B1A) : const Color(0xFF594139),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Active Status Dot Indicator (Green for Clocked In, Grey for Not Clocked In)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: isClockedIn ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: isClockedIn
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Teammate Name
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w700,
            color: const Color(0xFF4A1500),
          ),
        ),

        // Status Time Text
        Text(
          timeText,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: isClockedIn ? const Color(0xFF007A5A) : const Color(0xFF8B2600),
          ),
        ),
      ],
    );
  }

  // Card 2: NGL Jar Card
  Widget _buildNglJarCard() {
    return Container(
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
            color: const Color(0xFF7C3A68).withValues(alpha: 0.05),
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
                fontSize: 15.5,
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
            height: 140,
            child: Center(
              child: JarIconWidget(
                size: 130,
                mainColor: Color(0xFF7C3A68),
                lidColor: Color(0xFF9D4B85),
                liquidColor: Color(0xFFFF8EA9),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Subtitle / Progress Counter
          Text(
            '$_nglEntries/$_targetEntries entries',
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

          // Button: Add Entry
          ElevatedButton(
            onPressed: _showAddEntryModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8C436E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              'Add Entry',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card 3: Weekly Hero Card
  Widget _buildWeeklyHeroCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF00B887), // Rich Emerald/Teal
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B887).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 32, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image frame
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/avatars/user_avatar.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Team Spotlight Tag
                Text(
                  'TEAM SPOTLIGHT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: const Color(0xFF064E3B),
                  ),
                ),

                const SizedBox(height: 4),

                // Name: Sarah Chen
                Text(
                  'Sarah Chen',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF06372B),
                  ),
                ),

                const SizedBox(height: 8),

                // Description Text
                Text(
                  'Helped 12 coworkers this week with the \'Neon Project\' launch. True legend!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: const Color(0xFF06372B),
                  ),
                ),

                const SizedBox(height: 16),

                // Hashtags Row (#Supportive, #ProblemSolver)
                Row(
                  children: [
                    _buildHeroHashtag('#Supportive'),
                    const SizedBox(width: 8),
                    _buildHeroHashtag('#ProblemSolver'),
                  ],
                ),

                const SizedBox(height: 16),

                // Anonymous Weekly Hero Rules CTA Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF044E38),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFFA7F3D0), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '1 Nomination per week • 100% Anonymous',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFA7F3D0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top Yellow Badge: WEEKLY HERO
          Positioned(
            top: 0,
            left: 24,
            child: Transform.rotate(
              angle: -0.04,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD000), // Vibrant Yellow
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  'WEEKLY HERO',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: const Color(0xFF1E1B18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHashtag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF044E38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  // Card 4: Your Week Summary Card
  Widget _buildYourWeekCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFFF0F5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Week',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF524036),
            ),
          ),

          const SizedBox(height: 16),

          // Productivity Row & Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Productivity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.titleDark,
                ),
              ),
              Text(
                '88%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.brandTitleOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.88,
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

          const SizedBox(height: 18),

          // Vibe Check Row & Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vibe Check',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.titleDark,
                ),
              ),
              Text(
                'High',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF8C436E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.70,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8C436E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // View Full Report Outlined Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Weekly Analytics Report')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF524036), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: const Color(0xFF524036),
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: 'View '),
                    TextSpan(
                      text: 'Full ',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(text: 'Report'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
