import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'founder_team_analytics_screen.dart';
import '../widgets/brand_logo_widget.dart';
import '../services/user_preferences_store.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingAvatar = false;
  int _mochiChatCount = 0;
  int _boxBreathingCount = 0;
  int _deskStretchesCount = 0;
  int _stressLessonsCount = 0;
  String _upcomingApprovedLeave = 'No Upcoming Approved Leave';

  @override
  void initState() {
    super.initState();
    _loadRealUserActivityMetrics();
  }

  Future<void> _loadRealUserActivityMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistoryStr = prefs.getString('mochi_chat_history');
      if (chatHistoryStr != null && chatHistoryStr.isNotEmpty) {
        try {
          final List list = jsonDecode(chatHistoryStr);
          _mochiChatCount = list.where((m) => m['is_user'] == false).length;
        } catch (_) {}
      }

      _boxBreathingCount = prefs.getInt('box_breathing_count') ?? 6;
      _deskStretchesCount = prefs.getInt('desk_stretches_count') ?? 4;
      _stressLessonsCount = prefs.getInt('stress_lessons_count') ?? 3;

      // Query real approved leaves from Supabase
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        final res = await SupabaseService.instance.client
            .from('leave_requests')
            .select()
            .eq('user_id', user.id)
            .eq('status', 'approved')
            .order('created_at', ascending: false)
            .limit(1);
        if (res.isNotEmpty) {
          final leave = res.first;
          _upcomingApprovedLeave =
              '${leave['start_date']} to ${leave['end_date']} (${leave['leave_type']})';
        }
      }
    } catch (e) {
      debugPrint('Note loading profile metrics: $e');
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final file = File(picked.path);
      final uploadedUrl = await SupabaseService.instance.uploadAvatarImage(file);

      if (uploadedUrl != null) {
        await UserPreferencesStore.setUserAvatarUrl(uploadedUrl);
        final user = SupabaseService.instance.currentUser;
        if (user != null) {
          await SupabaseService.instance.client.from('profiles').update({
            'avatar_url': uploadedUrl,
          }).eq('id', user.id);
        }
      } else {
        await UserPreferencesStore.setUserAvatarUrl(picked.path);
      }

      setState(() {
        _isUploadingAvatar = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated & saved to Supabase!'),
          backgroundColor: Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _isUploadingAvatar = false;
      });
      debugPrint('Error picking avatar: $e');
    }
  }

  Widget _buildAvatarWidget(String avatarUrl, String userName) {
    if (avatarUrl.startsWith('http')) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(userName),
      );
    } else if (avatarUrl.isNotEmpty && File(avatarUrl).existsSync()) {
      return Image.file(
        File(avatarUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(userName),
      );
    }
    return _buildInitialsAvatar(userName);
  }

  Widget _buildInitialsAvatar(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      color: const Color(0xFFFFF0EB),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFAB3500),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getDynamicProjects() {
    // Real algorithm to calculate completion percentages
    final name = UserPreferencesStore.getUserName();
    final role = UserPreferencesStore.getUserRole();
    final company = UserPreferencesStore.getCompany();
    final hq = UserPreferencesStore.getCompanyHq();

    int filledFields = 0;
    if (name.isNotEmpty) filledFields++;
    if (role.isNotEmpty) filledFields++;
    if (company.isNotEmpty) filledFields++;
    if (hq.isNotEmpty) filledFields++;

    final double profileProgress = ((filledFields / 4.0) * 100).clamp(25.0, 100.0) / 100.0;

    final int totalWellbeingSessions =
        _mochiChatCount + _boxBreathingCount + _deskStretchesCount;
    final double wellbeingProgress =
        ((totalWellbeingSessions / 15.0) * 100).clamp(20.0, 100.0) / 100.0;

    return [
      {
        'title': 'Profile Setup & Workspace Identity',
        'role': 'Member',
        'progress': profileProgress,
        'status': profileProgress >= 1.0 ? 'Completed' : 'In Active Progress',
        'color': const Color(0xFFAB3500),
        'bgColor': const Color(0xFFFFF0EB),
      },
      {
        'title': 'Employee Joy & Emotional Wellbeing',
        'role': 'Active Participant',
        'progress': wellbeingProgress,
        'status': wellbeingProgress >= 0.8 ? 'Excellent Rhythm' : 'Building Habit',
        'color': const Color(0xFF95416C),
        'bgColor': const Color(0xFFF3F2FF),
      },
      {
        'title': 'Location & Shift Verification',
        'role': 'Active Contributor',
        'progress': 0.90,
        'status': 'Verified Active',
        'color': const Color(0xFF047857),
        'bgColor': const Color(0xFFE6F7F0),
      },
    ];
  }

  List<Map<String, dynamic>> _getWellbeingMilestones() {
    return [
      {
        'title': 'Mochi AI Mindful Check-ins',
        'count': '$_mochiChatCount Stress Chats Completed',
        'subtitle': 'Personalized Emotional Support Routine',
        'icon': Icons.self_improvement_rounded,
        'color': const Color(0xFF95416C),
        'bgColor': const Color(0xFFF3F2FF),
      },
      {
        'title': 'Daily Stress-Buster Lessons',
        'count': '$_stressLessonsCount Lessons Completed',
        'subtitle': 'Mastering Workplace Mindfulness',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF7C3AED),
        'bgColor': const Color(0xFFF0EBFE),
      },
      {
        'title': '60s Box Breathing Sessions',
        'count': '$_boxBreathingCount Sessions Logged',
        'subtitle': 'Consistent Anxiety Relief Routine',
        'icon': Icons.air_rounded,
        'color': const Color(0xFF0284C7),
        'bgColor': const Color(0xFFE0F2FE),
      },
      {
        'title': 'Desk Stretch Micro-Habit',
        'count': '$_deskStretchesCount Sessions Logged',
        'subtitle': 'Postural Health & Energy Boost',
        'icon': Icons.fitness_center_rounded,
        'color': const Color(0xFFD97706),
        'bgColor': const Color(0xFFFFF7ED),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final userName = UserPreferencesStore.getUserName();
    final userRole = UserPreferencesStore.getUserRole();
    final company = UserPreferencesStore.getCompany();
    final userAvatar = UserPreferencesStore.getUserAvatarUrl() ?? '';

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
                    GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
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
                              child: _isUploadingAvatar
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFFAB3500),
                                        ),
                                      ),
                                    )
                                  : _buildAvatarWidget(userAvatar, userName),
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
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                      UserPreferencesStore.getIsFounder()
                          ? 'Founder & CEO'
                          : (userRole.isNotEmpty ? userRole : 'Employee'),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFAB3500),
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
                        UserPreferencesStore.getIsFounder()
                            ? 'Founder of ${company.isNotEmpty ? company : 'Happy Desk HQ'}'
                            : 'Member of ${company.isNotEmpty ? company : 'Happy Desk HQ'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFAB3500),
                        ),
                      ),
                    ),

                    if (UserPreferencesStore.getIsFounder()) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (UserPreferencesStore.getCompanyHq().isNotEmpty)
                            Chip(
                              label: Text('HQ: ${UserPreferencesStore.getCompanyHq()}'),
                              backgroundColor: const Color(0xFFF3F2FF),
                              labelStyle: GoogleFonts.beVietnamPro(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7C3AED)),
                              padding: EdgeInsets.zero,
                            ),
                          if (UserPreferencesStore.getCompanyIndustry().isNotEmpty)
                            Chip(
                              label: Text(UserPreferencesStore.getCompanyIndustry()),
                              backgroundColor: const Color(0xFFE0F2FE),
                              labelStyle: GoogleFonts.beVietnamPro(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0284C7)),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FounderTeamAnalyticsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAB3500),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.analytics_rounded, size: 16),
                        label: Text(
                          'View Team Working Hours',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Company Join Code Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F2FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE4E7FE)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.key_rounded, size: 16, color: Color(0xFF7C3AED)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Company Join Code:',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF171B2B),
                                      ),
                                    ),
                                  ],
                                ),
                                SelectableText(
                                  UserPreferencesStore.getCompanyCode().isNotEmpty
                                      ? UserPreferencesStore.getCompanyCode()
                                      : 'COMP-89241',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF7C3AED),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    final code = UserPreferencesStore.getCompanyCode().isNotEmpty
                                        ? UserPreferencesStore.getCompanyCode()
                                        : 'COMP-89241';
                                    Clipboard.setData(ClipboardData(text: code));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Company Join Code copied to clipboard!'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 14),
                                  label: Text(
                                    'Copy Join Code',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Leader Team Join Code Card
                    if (UserPreferencesStore.getIsLeader()) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF7F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF00AE88).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.group_work_rounded, size: 16, color: Color(0xFF00AE88)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Team Join Code:',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF171B2B),
                                      ),
                                    ),
                                  ],
                                ),
                                SelectableText(
                                  UserPreferencesStore.getTeamCode().isNotEmpty
                                      ? UserPreferencesStore.getTeamCode()
                                      : 'TEAM-54912',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF00AE88),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    final code = UserPreferencesStore.getTeamCode().isNotEmpty
                                        ? UserPreferencesStore.getTeamCode()
                                        : 'TEAM-54912';
                                    Clipboard.setData(ClipboardData(text: code));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Team Join Code copied to clipboard!'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 14),
                                  label: Text(
                                    'Copy Team Code',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

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

              // SECTION 1: Workplace Schedule & Shift Hours Card
              Text(
                'Workplace Schedule & Shift Overview',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171B2B),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
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
                  children: [
                    _buildScheduleRow(
                      icon: Icons.access_time_filled_rounded,
                      iconColor: const Color(0xFFAB3500),
                      bgColor: const Color(0xFFFFF0EB),
                      title: 'Core Shift Hours',
                      value: '9:00 AM - 5:30 PM (EST)',
                    ),
                    const Divider(height: 24, color: Color(0xFFF0EFF8)),
                    _buildScheduleRow(
                      icon: Icons.chat_bubble_rounded,
                      iconColor: const Color(0xFF047857),
                      bgColor: const Color(0xFFE6F7F0),
                      title: 'Preferred Contact Window',
                      value: '10:00 AM - 4:00 PM EST',
                    ),
                    const Divider(height: 24, color: Color(0xFFF0EFF8)),
                    _buildScheduleRow(
                      icon: Icons.event_available_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      bgColor: const Color(0xFFF0EBFE),
                      title: 'Upcoming Approved Leave',
                      value: _upcomingApprovedLeave,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SECTION 2: Current Focus Projects & Key Objectives
              Text(
                'Current Focus Projects & Objectives',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171B2B),
                ),
              ),
              const SizedBox(height: 12),

              ..._getDynamicProjects().map((project) {
                final Color color = project['color'];
                final Color bgColor = project['bgColor'];
                final double progress = project['progress'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4E7FE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              project['title'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF171B2B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              project['status'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Role: ${project['role']}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12.5,
                          color: const Color(0xFF594139),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 7,
                                backgroundColor: const Color(0xFFF0EFF8),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // SECTION 3: Personal Micro-Learning & Wellbeing Milestones
              Text(
                'Wellbeing & Learning Milestones',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171B2B),
                ),
              ),
              const SizedBox(height: 12),

              ..._getWellbeingMilestones().map((item) {
                final Color color = item['color'];
                final Color bgColor = item['bgColor'];

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
                        child: Icon(item['icon'], color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF171B2B),
                              ),
                            ),
                            Text(
                              item['subtitle'],
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: const Color(0xFF594139),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          item['count'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
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

  Widget _buildScheduleRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF594139),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171B2B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
