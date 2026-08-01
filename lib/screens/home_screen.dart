import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/apply_leave_modal.dart';
import '../widgets/founder_leave_approvals_modal.dart';
import 'jar_screen.dart';
import 'hero_screen.dart';
import 'work_session_details_screen.dart';
import '../widgets/jar_icon_widget.dart';
import '../widgets/brand_logo_widget.dart';
import '../widgets/box_breathing_modal.dart';
import '../widgets/desk_stretches_modal.dart';
import '../widgets/daily_stress_buster_card.dart';
import '../widgets/teammate_profile_modal.dart';
import '../services/user_preferences_store.dart';
import '../services/sound_service.dart';
import '../services/supabase_service.dart';
import 'stress_vent_sounding_board_screen.dart';
import 'founder_team_analytics_screen.dart';
import '../widgets/notification_bell_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isClockedIn = false;
  bool _isOnBreak = false;
  String? _lastClockInTime;
  String? _lastClockInLocation;
  String? _breakStartTime;
  int _nglEntries = 13;

  final int _targetEntries = 20;

  int _currentQuestIndex = 0;
  bool _isQuestCompleted = false;

  List<Map<String, dynamic>> _realTeamMembers = [];
  bool _isLoadingTeam = false;

  final List<Map<String, String>> _quests = const [
    {
      'title': 'Thank a teammate for their help this week',
      'description':
          'Send an appreciation note or shoutout to a colleague who supported you.',
      'reward': '+1 NGL Note',
    },
    {
      'title': 'Take a 5-minute hydration and stretch break',
      'description':
          'Step away from your desk, stretch your shoulders, and drink a glass of water.',
      'reward': '+5% Reliability',
    },
    {
      'title': 'Share a win in the NGL Jar',
      'description':
          'Drop a positive workplace accomplishment into the team appreciation jar.',
      'reward': '+1 NGL Note',
    },
  ];

  void _completeQuest() {
    setState(() {
      _isQuestCompleted = true;
      _nglEntries++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Quest completed! Reward claimed: ${_quests[_currentQuestIndex]['reward']}',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _nextQuest() {
    setState(() {
      _currentQuestIndex = (_currentQuestIndex + 1) % _quests.length;
      _isQuestCompleted = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadTeamStatus();
    _requestNeededPermissions();
  }

  Future<void> _requestNeededPermissions() async {
    try {
      await [
        Permission.location,
        Permission.camera,
        Permission.microphone,
      ].request();
      _loadTeamStatus();
      _loadPreferences();
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  Future<void> _loadPreferences() async {
    final clockedIn = await UserPreferencesStore.isClockedIn();
    final onBreak = await UserPreferencesStore.isOnBreak();
    final time = await UserPreferencesStore.getLastClockInTime();
    final location = await UserPreferencesStore.getLastClockInLocation();

    if (mounted) {
      setState(() {
        _isClockedIn = clockedIn;
        _isOnBreak = onBreak;
        _lastClockInTime = time;
        _lastClockInLocation = location;
      });
    }

    if (clockedIn) {
      try {
        final user = SupabaseService.instance.currentUser;
        if (user != null) {
          final activeSession = await SupabaseService.instance.client
              .from('work_sessions')
              .select('clock_in_location_name, clock_in_time')
              .eq('user_id', user.id)
              .eq('status', 'active')
              .order('clock_in_time', ascending: false)
              .limit(1)
              .maybeSingle();

          if (activeSession != null && activeSession['clock_in_location_name'] != null) {
            final locName = activeSession['clock_in_location_name'] as String;
            final dbTimeStr = activeSession['clock_in_time'] as String?;
            
            String formattedTime = time ?? '';
            if (dbTimeStr != null) {
              try {
                final parsed = DateTime.parse(dbTimeStr).toLocal();
                final hr = parsed.hour > 12 ? parsed.hour - 12 : (parsed.hour == 0 ? 12 : parsed.hour);
                final min = parsed.minute.toString().padLeft(2, '0');
                final period = parsed.hour >= 12 ? 'PM' : 'AM';
                formattedTime = '$hr:$min $period';
              } catch (_) {}
            }

            if (mounted) {
              setState(() {
                _lastClockInLocation = locName;
                _lastClockInTime = formattedTime;
              });
            }
            await UserPreferencesStore.setLastClockInLocation(locName);
            await UserPreferencesStore.setLastClockInTime(formattedTime);
          }
        }
      } catch (e) {
        debugPrint('Error syncing active session location: $e');
      }
    }
  }

  Future<void> _loadTeamStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTeam = true;
    });
    try {
      final teammates = await SupabaseService.instance.getCompanyTeammates();
      final myName = UserPreferencesStore.getUserName();

      final mapped = teammates.map((t) {
        final isMe = t['name'] == myName;
        final clocked = isMe ? _isClockedIn : (t['is_clocked_in'] == true);
        return {
          'id': t['id'],
          'name': isMe ? 'You' : (t['name'] ?? 'Teammate'),
          'avatar': t['avatar_url'] ?? '',
          'isClockedIn': clocked,
          'timeText': clocked ? 'Active Now' : 'Offline',
          'isCurrentUser': isMe,
        };
      }).toList();

      final hasMe = mapped.any((m) => m['isCurrentUser'] == true);
      if (!hasMe) {
        mapped.add({
          'id': SupabaseService.instance.currentUser?.id ?? '',
          'name': 'You',
          'avatar': UserPreferencesStore.getUserAvatarUrl() ?? '',
          'isClockedIn': _isClockedIn,
          'timeText': _isClockedIn ? 'Active Now' : 'Offline',
          'isCurrentUser': true,
        });
      }

      mapped.sort((a, b) {
        if (a['isCurrentUser'] == true) return 1;
        if (b['isCurrentUser'] == true) return -1;
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      if (mounted) {
        setState(() {
          _realTeamMembers = mapped;
          _isLoadingTeam = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading team status: $e');
      if (mounted) {
        setState(() {
          _isLoadingTeam = false;
        });
      }
    }
  }

  Future<void> _toggleClockIn() async {
    if (!_isClockedIn) {
      // Seek permission from the phone for location services
      final status = await Permission.location.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location permission is required to fetch your work location details.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.primaryRust,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Clocking IN: Request Location & Save GPS to Supabase
      SoundService.playClockInSound();
      final session = await SupabaseService.instance.clockInWithLocation();
      final locationName = session?['clock_in_location_name'] ?? 'Office HQ';

      final now = DateTime.now();
      final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final minute = now.minute.toString().padLeft(2, '0');
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final formattedTime = '$hour:$minute $period';

      setState(() {
        _isClockedIn = true;
        _isOnBreak = false;
        _lastClockInTime = formattedTime;
        _lastClockInLocation = locationName;
      });

      await UserPreferencesStore.setClockedIn(true);
      await UserPreferencesStore.setOnBreak(false);
      await UserPreferencesStore.setLastClockInTime(formattedTime);
      await UserPreferencesStore.setLastClockInLocation(locationName);

      await _loadTeamStatus();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Clocked IN with live GPS location: $locationName',
                  style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Clocking OUT
      SoundService.playClockOutSound();
      final outSession = await SupabaseService.instance.clockOutWorkSession();
      final outLocation = outSession?['clock_out_location_name'] ?? 'Work Location';

      setState(() {
        _isClockedIn = false;
        _isOnBreak = false;
      });

      await UserPreferencesStore.setClockedIn(false);
      await UserPreferencesStore.setOnBreak(false);

      await _loadTeamStatus();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Clocked OUT at: $outLocation',
                  style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryRust,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleBreak() {
    setState(() {
      _isOnBreak = !_isOnBreak;
      if (_isOnBreak) {
        _breakStartTime =
            '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}';
      }
    });

    UserPreferencesStore.setOnBreak(_isOnBreak);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isOnBreak
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isOnBreak
                    ? 'Work timer paused for break at $_breakStartTime!'
                    : 'Shift resumed! Work timer active.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            _isOnBreak ? const Color(0xFFFF9F1C) : const Color(0xFFFF6B35),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand Logo SVG
                  const BrandLogoWidget(height: 54),

                  // Notifications Bell Icon with live unread superscript count
                  const NotificationBellWidget(),
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

              // CARD 1: WORK SESSION / CLOCK-IN CARD (FIRST POSITION MANDATORY)
              _buildWorkSessionCard(),

              const SizedBox(height: 20),

              // DE-STRESS & WELLBEING HUB (Consolidated 60s Breathing, Stretches, Daily Stress Lesson & Sounding Board)
              _buildDeStressAndWellbeingHub(context),

              const SizedBox(height: 20),

              // Card 2: Daily Joy Quest Card (Golden Cream)
              _buildDailyJoyQuestCard(),

              const SizedBox(height: 20),

              // Card 3: Your NGL Jar Card (Soft Lavender)
              _buildNglJarCard(),

              const SizedBox(height: 20),

              // Card 3: Weekly Hero Card (Teal/Emerald with Hashtags)
              _buildWeeklyHeroCard(),

              const SizedBox(height: 20),

              // Card 4: Your Week Summary Card (Productivity & Vibe Check)
              _buildYourWeekCard(),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  // Unified De-Stress & Wellbeing Hub Container (Clubs 60s Breathing, Stretches, Stress-Buster Card & Sounding Board)
  Widget _buildDeStressAndWellbeingHub(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FF), // Soft serene lavender surface
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE4E7FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF95416C).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0F7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: Color(0xFF95416C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'De-Stress & Wellbeing Hub',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                    Text(
                      'Micro-resets for your mind, body & stress relief',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: const Color(0xFF8D7168),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 1. Quick Resets Action Buttons Row (60s Breathing + Desk Stretches)
          Row(
            children: [
              // 60s Breathing Pill
              Expanded(
                child: GestureDetector(
                  onTap: () => BoxBreathingModal.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF7F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD1FAE5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.air_rounded,
                          size: 18,
                          color: Color(0xFF006C53),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '60s Breathing',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF006C53),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Desk Stretches Pill
              Expanded(
                child: GestureDetector(
                  onTap: () => DeskStretchesModal.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD6C7)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.accessibility_rounded,
                          size: 18,
                          color: Color(0xFFAB3500),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Desk Stretches',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFAB3500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Daily Stress-Buster Micro-Lesson Card
          const DailyStressBusterCard(),

          const SizedBox(height: 14),

          // 3. Anonymous Sounding Board & Vent Shortcut Banner
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StressVentSoundingBoardScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE4E7FE)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF95416C),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anonymous Stress Vent & Sounding Board',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D3142),
                          ),
                        ),
                        Text(
                          'Encrypted Vent Shredder & Peer Mentor Chat',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11.5,
                            color: const Color(0xFF8D7168),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF95416C),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card 1: Work Session Card
  Widget _buildWorkSessionCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WorkSessionDetailsScreen(),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Row: Status Pill on Left, Leave Stats + Clock Badge on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Tag Pill
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isOnBreak
                          ? 'Status: On Break\n(Paused at $_breakStartTime • $_lastClockInLocation)'
                          : (_isClockedIn
                              ? 'Status: Clocked In\n($_lastClockInTime • $_lastClockInLocation)'
                              : 'Status: Not Clocked In'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A1500),
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Modern Clock Badge
                _ModernClockBadge(
                    isClockedIn: _isClockedIn, isOnBreak: _isOnBreak),
              ],
            ),

            const SizedBox(height: 14),

            // Headline
            Text(
              _isOnBreak
                  ? 'Shift on pause'
                  : (_isClockedIn
                      ? 'Work session in progress!'
                      : 'Ready to start your\nwork session?'),
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
              _isOnBreak
                  ? 'Enjoy your break! Tap Resume Shift when you are back at your desk.'
                  : "Every minute counts toward the team's\nweekly happiness target!",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B1D00),
                height: 1.35,
              ),
            ),

            const SizedBox(height: 18),

            // Action Buttons Row: Clock In/Out + Take Break + Apply Leave
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // 1. Clock In / Out Button
                ElevatedButton(
                  onPressed: _toggleClockIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D1200), // Dark Brown
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isClockedIn
                            ? Icons.stop_circle_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                // 2. Take Break / Resume Shift Button (Only when Clocked In)
                if (_isClockedIn)
                  ElevatedButton.icon(
                    onPressed: _toggleBreak,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isOnBreak
                          ? const Color(0xFF007A5A)
                          : const Color(0xFFFF9F1C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: Icon(
                      _isOnBreak
                          ? Icons.play_circle_fill_rounded
                          : Icons.pause_circle_filled_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isOnBreak ? 'Resume Shift' : 'Take Break',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                // 3. Founder Actions OR Team Leader Actions OR Employee Apply for Leave Button
                if (UserPreferencesStore.getIsFounder()) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FounderTeamAnalyticsScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF4A1500),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(
                      Icons.analytics_rounded,
                      size: 18,
                      color: Color(0xFF4A1500),
                    ),
                    label: Text(
                      'Team Hours & Analytics',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A1500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  OutlinedButton.icon(
                    onPressed: () => FounderLeaveApprovalsModal.show(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF4A1500),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(
                      Icons.task_alt_rounded,
                      size: 18,
                      color: Color(0xFF4A1500),
                    ),
                    label: Text(
                      'Approve Leaves',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A1500),
                      ),
                    ),
                  ),
                ] else if (UserPreferencesStore.getIsLeader()) ...[
                  OutlinedButton.icon(
                    onPressed: () => ApplyLeaveModal.show(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF4A1500),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(
                      Icons.beach_access_rounded,
                      size: 18,
                      color: Color(0xFF4A1500),
                    ),
                    label: Text(
                      'Apply for Leave',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A1500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  OutlinedButton.icon(
                    onPressed: () => FounderLeaveApprovalsModal.show(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF4A1500),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(
                      Icons.task_alt_rounded,
                      size: 18,
                      color: Color(0xFF4A1500),
                    ),
                    label: Text(
                      'Approve Leaves',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A1500),
                      ),
                    ),
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: () => ApplyLeaveModal.show(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF4A1500),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(
                      Icons.beach_access_rounded,
                      size: 18,
                      color: Color(0xFF4A1500),
                    ),
                    label: Text(
                      'Apply for Leave',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A1500),
                      ),
                    ),
                  ),
              ],
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
                                const Icon(
                                  Icons.people_alt_rounded,
                                  size: 16,
                                  color: Color(0xFF4A1500),
                                ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007A5A), // Emerald Green Pill
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _realTeamMembers.isNotEmpty
                                  ? '${_realTeamMembers.where((m) => m['isClockedIn'] == true).length}/${_realTeamMembers.length} Clocked In'
                                  : (_isClockedIn ? '1/1 Clocked In' : '0/1 Clocked In'),
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
                      _isLoadingTeam
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF4A1500),
                                  ),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: _realTeamMembers.isEmpty
                                    ? [
                                        _buildTeammateStatusAvatar(
                                          name: 'You',
                                          assetPath: UserPreferencesStore.getUserAvatarUrl() ?? '',
                                          isClockedIn: _isClockedIn,
                                          timeText: _isClockedIn ? 'Active Now' : 'Offline',
                                          isCurrentUser: true,
                                          teammateId: SupabaseService.instance.currentUser?.id ?? '',
                                        ),
                                      ]
                                    : _realTeamMembers.map((member) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 14.0),
                                          child: _buildTeammateStatusAvatar(
                                            name: member['name'],
                                            assetPath: member['avatar'],
                                            isClockedIn: member['isClockedIn'],
                                            timeText: member['timeText'],
                                            isCurrentUser: member['isCurrentUser'] == true,
                                            teammateId: member['id'],
                                          ),
                                        );
                                      }).toList(),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
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
    String? teammateId,
  }) {
    return GestureDetector(
      onTap: () {
        TeammateProfileModal.show(context, {
          'id': teammateId,
          'name': isCurrentUser ? UserPreferencesStore.getUserName() : name,
          'role': isCurrentUser ? UserPreferencesStore.getUserRole() : 'Team Member',
          'avatar': assetPath,
          'isOnline': isClockedIn,
          'isCurrentUser': isCurrentUser,
        });
      },
      child: Column(
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
                        : (isClockedIn
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5)),
                    width: isCurrentUser ? 2.5 : 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: (assetPath.startsWith('http') || (assetPath.isNotEmpty && File(assetPath).existsSync()))
                      ? (assetPath.startsWith('http')
                          ? Image.network(assetPath, fit: BoxFit.cover)
                          : Image.file(File(assetPath), fit: BoxFit.cover))
                      : Container(
                          color: isCurrentUser
                              ? const Color(0xFFC84B1A)
                              : const Color(0xFF594139),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
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

              // Active Status Dot Indicator (Green for Clocked In, Grey for Not Clocked In)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: isClockedIn
                        ? const Color(0xFF10B981)
                        : const Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: isClockedIn
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.6),
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
              color: isClockedIn
                  ? const Color(0xFF007A5A)
                  : const Color(0xFF8B2600),
            ),
          ),
        ],
      ),
    );
  }

  // Card 2: Daily Joy Quest Card
  Widget _buildDailyJoyQuestCard() {
    final currentQuest = _quests[_currentQuestIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Soft Golden Cream
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFD8A8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Tag Pill & Reward Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRust.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 14,
                      color: AppTheme.primaryRust,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'DAILY JOY QUEST',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryRust,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Reward Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentQuest['reward']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Quest Title
          Text(
            currentQuest['title']!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.titleDark,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 6),

          // Quest Description
          Text(
            currentQuest['description']!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 18),

          // Action Row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isQuestCompleted ? null : _completeQuest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isQuestCompleted
                          ? const Color(0xFF10B981)
                          : AppTheme.primaryRust,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isQuestCompleted
                              ? Icons.check_circle_rounded
                              : Icons.task_alt_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isQuestCompleted
                              ? 'Quest Completed'
                              : 'Mark Quest Complete',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Skip / Next Quest Button
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: const Color(0xFFFFD8A8),
                    width: 1.2,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppTheme.titleDark,
                  ),
                  onPressed: _nextQuest,
                  tooltip: 'Next Quest',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 3: NGL Jar Card
  // Card 3: NGL Jar Card (Soft Lavender Brand Design Palette)
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

          const SizedBox(height: 18),

          // Action Buttons: Add Entry & Open Jar Notes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _showAddEntryModal,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Add Entry',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8C436E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const JarScreen(showBackButton: true),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFF8C436E),
                ),
                label: Text(
                  'Open Jar Notes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8C436E),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  side: const BorderSide(color: Color(0xFF8C436E), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 3: Weekly Hero Card (Non-competitive peer recognition)
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
            padding: const EdgeInsets.fromLTRB(22, 34, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                Text(
                  'PEER APPRECIATION',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: const Color(0xFF064E3B),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Nominate Someone Who Helped You',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Did a teammate or founder step up to support you last week? Nominate 1 person anonymously to brighten their week. No competitions or public rankings.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: const Color(0xFFE6F7F0),
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHeroHashtag('#Supportive'),
                    _buildHeroHashtag('#ProblemSolver'),
                    _buildHeroHashtag('#TeamPlayer'),
                  ],
                ),

                const SizedBox(height: 18),

                // CTA Button to open HeroScreen
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HeroScreen(showBackButton: true),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF007A5A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nominate Your Weekly Hero',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Color(0xFF007A5A),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Anonymous Weekly Hero Rules CTA Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF044E38),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFFA7F3D0),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '1 Nomination per week • 100% Anonymous & Private',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
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
        border: Border.all(color: const Color(0xFFFFF0F5), width: 1.5),
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
                  const SnackBar(
                    content: Text('Opening Weekly Analytics Report'),
                  ),
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

// ---------------------------------------------------------------------------
// Modern Glassmorphic Clock Badge Widget & Painter
// ---------------------------------------------------------------------------
class _ModernClockBadge extends StatelessWidget {
  final bool isClockedIn;
  final bool isOnBreak;

  const _ModernClockBadge({
    required this.isClockedIn,
    this.isOnBreak = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor = isOnBreak
        ? const Color(0xFFFF9F1C)
        : (isClockedIn ? const Color(0xFF00C49A) : const Color(0xFFFF6B35));

    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isClockedIn
              ? [
                  Colors.white.withValues(alpha: 0.40),
                  Colors.white.withValues(alpha: 0.15),
                ]
              : [
                  Colors.white.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: 0.10),
                ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.50),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Clock Face Custom Painter (Tick marks + Minimalist Hands)
          CustomPaint(
            size: const Size(78, 78),
            painter: _ClockFacePainter(
                isClockedIn: isClockedIn, isOnBreak: isOnBreak),
          ),

          // Center Live Status Indicator Dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockFacePainter extends CustomPainter {
  final bool isClockedIn;
  final bool isOnBreak;

  _ClockFacePainter({required this.isClockedIn, this.isOnBreak = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Outer Ring
    final outerRingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 6, outerRingPaint);

    // 2. Tick Marks for 12, 3, 6, 9
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final p1 = Offset(
        center.dx + (radius - 14) * math.cos(angle),
        center.dy + (radius - 14) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 8) * math.cos(angle),
        center.dy + (radius - 8) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // 3. Hour Hand (pointing at 10 o'clock)
    final hourHandPaint = Paint()
      ..color = const Color(0xFF2D3142)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final hourAngle = -math.pi * 0.75; // 10:00 position
    final hourHandEnd = Offset(
      center.dx + (radius * 0.38) * math.cos(hourAngle),
      center.dy + (radius * 0.38) * math.sin(hourAngle),
    );
    canvas.drawLine(center, hourHandEnd, hourHandPaint);

    // 4. Minute Hand (pointing at 2 o'clock)
    final minuteHandPaint = Paint()
      ..color = const Color(0xFF2D3142)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final minuteAngle = -math.pi * 0.25; // 2:00 position
    final minuteHandEnd = Offset(
      center.dx + (radius * 0.55) * math.cos(minuteAngle),
      center.dy + (radius * 0.55) * math.sin(minuteAngle),
    );
    canvas.drawLine(center, minuteHandEnd, minuteHandPaint);
  }

  @override
  bool shouldRepaint(covariant _ClockFacePainter oldDelegate) {
    return oldDelegate.isClockedIn != isClockedIn;
  }
}
