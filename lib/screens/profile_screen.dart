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
import '../theme/app_theme.dart';

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
      final uploadedUrl = await SupabaseService.instance.uploadAvatarImage(
        file,
      );

      if (uploadedUrl != null) {
        await UserPreferencesStore.setUserAvatarUrl(uploadedUrl);
        final user = SupabaseService.instance.currentUser;
        if (user != null) {
          await SupabaseService.instance.client
              .from('profiles')
              .update({'avatar_url': uploadedUrl})
              .eq('id', user.id);
        }
      } else {
        await UserPreferencesStore.setUserAvatarUrl(picked.path);
      }

      setState(() {
        _isUploadingAvatar = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Profile photo updated successfully!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
        errorBuilder: (context, error, stackTrace) =>
            _buildInitialsAvatar(userName),
      );
    } else if (avatarUrl.isNotEmpty && File(avatarUrl).existsSync()) {
      return Image.file(
        File(avatarUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildInitialsAvatar(userName),
      );
    }
    return _buildInitialsAvatar(userName);
  }

  Widget _buildInitialsAvatar(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0EB), Color(0xFFFFDBD0)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryRust,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getDynamicProjects() {
    final name = UserPreferencesStore.getUserName();
    final role = UserPreferencesStore.getUserRole();
    final company = UserPreferencesStore.getCompany();
    final hq = UserPreferencesStore.getCompanyHq();

    int filledFields = 0;
    if (name.isNotEmpty) filledFields++;
    if (role.isNotEmpty) filledFields++;
    if (company.isNotEmpty) filledFields++;
    if (hq.isNotEmpty) filledFields++;

    final double profileProgress =
        ((filledFields / 4.0) * 100).clamp(25.0, 100.0) / 100.0;

    final int totalWellbeingSessions =
        _mochiChatCount + _boxBreathingCount + _deskStretchesCount;
    final double wellbeingProgress =
        ((totalWellbeingSessions / 15.0) * 100).clamp(20.0, 100.0) / 100.0;

    return [
      {
        'title': 'Profile Setup & Workspace Identity',
        'role': 'Member',
        'progress': profileProgress,
        'status': profileProgress >= 1.0 ? 'Completed' : 'In Progress',
        'color': AppTheme.primaryRust,
        'bgColor': const Color(0xFFFFF0EB),
      },
      {
        'title': 'Employee Joy & Emotional Wellbeing',
        'role': 'Active Participant',
        'progress': wellbeingProgress,
        'status': wellbeingProgress >= 0.8
            ? 'Excellent Rhythm'
            : 'Building Habit',
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
        'count': '$_mochiChatCount Chats Logged',
        'subtitle': 'Personalized Emotional Support Routine',
        'icon': Icons.self_improvement_rounded,
        'color': const Color(0xFF95416C),
        'bgColor': const Color(0xFFF3F2FF),
      },
      {
        'title': 'Daily Stress-Buster Lessons',
        'count': '$_stressLessonsCount Completed',
        'subtitle': 'Mastering Workplace Mindfulness',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF7C3AED),
        'bgColor': const Color(0xFFF0EBFE),
      },
      {
        'title': '60s Box Breathing Sessions',
        'count': '$_boxBreathingCount Logged',
        'subtitle': 'Consistent Anxiety Relief Routine',
        'icon': Icons.air_rounded,
        'color': const Color(0xFF0284C7),
        'bgColor': const Color(0xFFE0F2FE),
      },
      {
        'title': 'Desk Stretch Micro-Habit',
        'count': '$_deskStretchesCount Logged',
        'subtitle': 'Postural Health & Energy Boost',
        'icon': Icons.fitness_center_rounded,
        'color': const Color(0xFFD97706),
        'bgColor': const Color(0xFFFFF7ED),
      },
    ];
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 10),
            Text(
              '$label copied to clipboard!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2D3142),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = UserPreferencesStore.getUserName();
    final userRole = UserPreferencesStore.getUserRole();
    final company = UserPreferencesStore.getCompany();
    final userAvatar = UserPreferencesStore.getUserAvatarUrl() ?? '';
    final isFounder = UserPreferencesStore.getIsFounder();
    final isLeader = UserPreferencesStore.getIsLeader();

    final roleTitle = isFounder
        ? 'Founder'
        : (isLeader
              ? (userRole.isNotEmpty ? userRole : 'Team Leader')
              : (userRole.isNotEmpty ? userRole : 'Team Member'));



    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Logo, Analytics Action & Settings Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandLogoWidget(height: 54),
                  Row(
                    children: [
                      if (isFounder || isLeader) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE4E7FE)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const FounderTeamAnalyticsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.analytics_outlined,
                              color: AppTheme.primaryRust,
                              size: 22,
                            ),
                            tooltip: 'Team Analytics',
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE4E7FE)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
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
                            color: AppTheme.primaryRust,
                            size: 22,
                          ),
                          tooltip: 'Settings',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Executive Profile Hero Card (Clean Solid Background — No Gradient Banner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE4E7FE)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRust.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar with Pen Edit Icon
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: _pickAndUploadAvatar,
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFFFF0EB),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryRust.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _isUploadingAvatar
                                  ? const Center(
                                      child: SizedBox(
                                        width: 26,
                                        height: 26,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppTheme.primaryRust,
                                        ),
                                      ),
                                    )
                                  : _buildAvatarWidget(userAvatar, userName),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
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
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRust,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Name & Designation
                    Text(
                      userName.isNotEmpty ? userName : 'User Profile',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF171B2B),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roleTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryRust,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Company Name & Company Domain in the SAME Horizontal Line
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryRust.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.business_rounded,
                            size: 14,
                            color: AppTheme.primaryRust,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              UserPreferencesStore.getCompanyIndustry()
                                      .isNotEmpty
                                  ? '${company.isNotEmpty ? company : "Workspace"} • ${UserPreferencesStore.getCompanyIndustry()}'
                                  : (UserPreferencesStore.getCompanyHq()
                                            .isNotEmpty
                                        ? '${company.isNotEmpty ? company : "Workspace"} • ${UserPreferencesStore.getCompanyHq()}'
                                        : (company.isNotEmpty
                                              ? company
                                              : "MindEmpowered Inc.")),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryRust,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: Workspace Access Codes (Founder & Leader)
              if (isFounder || isLeader) ...[
                Text(
                  'Workspace Access Codes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF171B2B),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    if (isFounder)
                      Expanded(
                        child: _buildCompactCodeCard(
                          title: 'Company Code',
                          code: UserPreferencesStore.getCompanyCode().isNotEmpty
                              ? UserPreferencesStore.getCompanyCode()
                              : 'COMP-89241',
                          icon: Icons.vpn_key_rounded,
                          color: const Color(0xFF7C3AED),
                          bgColor: const Color(0xFFF0EBFE),
                          onCopy: () {
                            final code =
                                UserPreferencesStore.getCompanyCode().isNotEmpty
                                ? UserPreferencesStore.getCompanyCode()
                                : 'COMP-89241';
                            _copyToClipboard(code, 'Company Join Code');
                          },
                        ),
                      ),

                    if (isFounder && isLeader) const SizedBox(width: 12),

                    if (isLeader)
                      Expanded(
                        child: _buildCompactCodeCard(
                          title: 'Team Code',
                          code: UserPreferencesStore.getTeamCode().isNotEmpty
                              ? UserPreferencesStore.getTeamCode()
                              : 'TEAM-54912',
                          icon: Icons.group_work_rounded,
                          color: const Color(0xFF047857),
                          bgColor: const Color(0xFFE6F7F0),
                          onCopy: () {
                            final code =
                                UserPreferencesStore.getTeamCode().isNotEmpty
                                ? UserPreferencesStore.getTeamCode()
                                : 'TEAM-54912';
                            _copyToClipboard(code, 'Team Join Code');
                          },
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),
              ],

              // Section 1: Workplace Schedule & Shift Overview
              Text(
                'Shift & Work Overview',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171B2B),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
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
                  children: [
                    _buildScheduleRow(
                      icon: Icons.access_time_filled_rounded,
                      iconColor: AppTheme.primaryRust,
                      bgColor: const Color(0xFFFFF0EB),
                      title: 'Core Shift Hours',
                      value: '9:00 AM - 5:30 PM (EST)',
                    ),
                    const Divider(height: 22, color: Color(0xFFF3F2FF)),
                    _buildScheduleRow(
                      icon: Icons.chat_bubble_rounded,
                      iconColor: const Color(0xFF047857),
                      bgColor: const Color(0xFFE6F7F0),
                      title: 'Preferred Contact Window',
                      value: '10:00 AM - 4:00 PM EST',
                    ),
                    const Divider(height: 22, color: Color(0xFFF3F2FF)),
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

              // Section 2: Current Focus Projects & Objectives
              Text(
                'Current Focus Objectives',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171B2B),
                ),
              ),
              const SizedBox(height: 10),

              ..._getDynamicProjects().map((project) {
                final Color color = project['color'];
                final Color bgColor = project['bgColor'];
                final double progress = project['progress'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE4E7FE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF171B2B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
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
                      const SizedBox(height: 4),
                      Text(
                        'Role: ${project['role']}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: const Color(0xFF594139),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFF3F2FF),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
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

              // Section 3: Wellbeing & Learning Milestones
              Text(
                'Wellbeing & Growth Milestones',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171B2B),
                ),
              ),
              const SizedBox(height: 10),

              ..._getWellbeingMilestones().map((item) {
                final Color color = item['color'];
                final Color bgColor = item['bgColor'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE4E7FE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'], color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF171B2B),
                              ),
                            ),
                            Text(
                              item['subtitle'],
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11.5,
                                color: const Color(0xFF594139),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item['count'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildCompactCodeCard({
    required String title,
    required String code,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7FE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF594139),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SelectableText(
                code,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.0,
                ),
              ),
              InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.copy_rounded, size: 14, color: color),
                ),
              ),
            ],
          ),
        ],
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
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
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
                  fontSize: 13,
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
