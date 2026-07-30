import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'notifications_screen.dart';
import '../widgets/multi_coffee_reset_modal.dart';
import '../widgets/brand_logo_widget.dart';
import '../services/supabase_service.dart';
import '../services/user_preferences_store.dart';

class HeroScreen extends StatefulWidget {
  final bool showBackButton;

  const HeroScreen({super.key, this.showBackButton = false});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> with SingleTickerProviderStateMixin {
  bool _hasNominatedThisWeek = false;
  String? _selectedCoworker;
  final TextEditingController _storyController = TextEditingController();

  List<String> _coworkers = [];
  bool _isLoadingCoworkers = true;
  final List<Map<String, dynamic>> _receivedNominations = [];

  @override
  void initState() {
    super.initState();
    _loadSupabaseNominations();
    _loadCoworkers();
  }

  Future<void> _loadCoworkers() async {
    try {
      final list = await SupabaseService.instance.getCompanyTeammates();
      final myName = UserPreferencesStore.getUserName();
      // Exclude logged in user
      final names = list
          .where((t) => t['name'] != myName)
          .map((t) => '${t['name']} (${t['department'] ?? 'Team'})')
          .toList();
      if (mounted) {
        setState(() {
          _coworkers = names;
          _isLoadingCoworkers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading coworkers for nominations: $e');
      if (mounted) {
        setState(() {
          _isLoadingCoworkers = false;
        });
      }
    }
  }

  Future<void> _loadSupabaseNominations() async {
    final nominations = await SupabaseService.instance.getWeeklyHeroNominations();
    if (mounted) {
      setState(() {
        _receivedNominations.clear();
        for (var nom in nominations) {
          _receivedNominations.add({
            'time': nom['created_at'] != null ? nom['created_at'].toString().split('T').first : 'Recently',
            'tags': [nom['badge_type'] ?? '#CoffeeHero'],
            'reason': nom['reason'] ?? '',
          });
        }
      });
    }
  }

  final Set<String> _selectedSuperpowers = {'#Supportive', '#ProblemSolver'};

  final List<String> _allSuperpowers = [
    '#Supportive',
    '#ProblemSolver',
    '#LifeSaver',
    '#Clutch',
    '#TeamPlayer',
    '#Leader',
    '#Innovator',
  ];

  TabController? _tabController;
  bool _controllerInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllerInitialized) {
      _tabController = TabController(length: 2, vsync: this);
      _controllerInitialized = true;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _storyController.dispose();
    super.dispose();
  }

  void _submitNomination() {
    if (_hasNominatedThisWeek) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You have already submitted your 1 nomination for this week.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.primaryRust,
        ),
      );
      return;
    }

    if (_selectedCoworker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select the teammate who helped you.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.primaryRust,
        ),
      );
      return;
    }

    if (_storyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please explain how they helped you this week.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.primaryRust,
        ),
      );
      return;
    }

    final nominee = _selectedCoworker!;
    try {
      SupabaseService.instance.submitHeroNomination(
        nomineeName: nominee,
        reason: _storyController.text.trim(),
        badgeType: _selectedSuperpowers.isNotEmpty ? _selectedSuperpowers.first : 'Coffee Hero',
      );
    } catch (_) {}

    setState(() {
      _hasNominatedThisWeek = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Weekly Hero nomination anonymously delivered to $nominee.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF047857),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _generateAiStory() {
    final name = _selectedCoworker != null
        ? _selectedCoworker!.split(' ')[0]
        : 'My teammate';

    String aiStory;
    if (_selectedSuperpowers.contains('#LifeSaver')) {
      aiStory =
          '$name was an absolute lifesaver this week—staying late and taking full ownership when we hit a critical deadline!';
    } else if (_selectedSuperpowers.contains('#ProblemSolver')) {
      aiStory =
          '$name stepped up with brilliant problem-solving skills to resolve a complex blocker for the team when we were stuck.';
    } else if (_selectedSuperpowers.contains('#Supportive')) {
      aiStory =
          '$name went above and beyond to support me during a high-pressure week, making sure I had everything needed to succeed.';
    } else {
      aiStory =
          '$name demonstrated incredible teamwork, dedication, and uplifting energy this week that inspired our entire team!';
    }

    setState(() {
      _storyController.text = aiStory;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'AI nomination story generated for $name!',
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar & Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand Logo SVG or Back Button if pushed from Home
                      widget.showBackButton
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Color(0xFF171B2B), size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                            )
                          : const BrandLogoWidget(height: 48),

                      // Header Action Icons (Notification & Coffee icons matching Home & Messages)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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

                  const SizedBox(height: 10),

                  // Segmented Tab Bar (Nominate vs My Received Recognition)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFF6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: const Color(0xFFC84B1A),
                      unselectedLabelColor: const Color(0xFF6B7280),
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        const Tab(text: 'Nominate Hero'),
                        Tab(text: 'My Received (${_receivedNominations.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar View Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Submit Anonymous Nomination
                  _buildNominateTab(),

                  // Tab 2: View Private Received Recognition (Recipient View)
                  _buildReceivedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: Nominate a Teammate
  Widget _buildNominateTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Limit & Anonymity Rule Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _hasNominatedThisWeek
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFFF0EB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hasNominatedThisWeek
                    ? const Color(0xFF10B981)
                    : const Color(0xFFFF652F).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _hasNominatedThisWeek
                      ? Icons.check_circle_rounded
                      : Icons.favorite_border_rounded,
                  color: _hasNominatedThisWeek
                      ? const Color(0xFF047857)
                      : AppTheme.primaryRust,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasNominatedThisWeek
                            ? 'Weekly Nomination Submitted (1/1)'
                            : '1 Weekly Hero Nomination Allowed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _hasNominatedThisWeek
                              ? const Color(0xFF047857)
                              : AppTheme.brandTitleOrange,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasNominatedThisWeek
                            ? 'You have nominated your hero for this week. Thank you for appreciating your team.'
                            : 'Nominate 1 teammate or founder who helped you last week. Who nominated whom is never shown.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _hasNominatedThisWeek
                              ? const Color(0xFF065F46)
                              : const Color(0xFF6B1D00),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Main Form Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Field 1: Who helped you in need?
                Text(
                  'Who helped you last week?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.titleDark,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEF0FB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Row(
                        children: [
                          const Icon(
                            Icons.person_search_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isLoadingCoworkers
                                ? 'Loading coworkers...'
                                : _coworkers.isEmpty
                                    ? 'No coworkers found...'
                                    : 'Select a teammate or founder...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      value: _selectedCoworker,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey,
                      ),
                      items: _coworkers.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.titleDark,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (_hasNominatedThisWeek || _coworkers.isEmpty)
                          ? null
                          : (val) {
                              setState(() {
                                _selectedCoworker = val;
                              });
                            },
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Field 2: What did they do to help?
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'How did they help you?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.titleDark,
                      ),
                    ),
                    GestureDetector(
                      onTap: _hasNominatedThisWeek ? null : _generateAiStory,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: Color(0xFF047857),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'AI Draft Assistant',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Shared anonymously with only the nominated person.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEF0FB)),
                  ),
                  child: TextField(
                    controller: _storyController,
                    enabled: !_hasNominatedThisWeek,
                    maxLines: 4,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.titleDark,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Explain what happened (e.g. Marcus stayed late on Tuesday to help me debug the production deployment pipeline).',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        height: 1.4,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Field 3: Superpower Tags
                Text(
                  'Select Appreciation Tags',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.titleDark,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _allSuperpowers.map((tag) {
                    final isSelected = _selectedSuperpowers.contains(tag);
                    return ChoiceChip(
                      label: Text(
                        tag,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFF047857)
                              : const Color(0xFF065F46),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: _hasNominatedThisWeek
                          ? null
                          : (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSuperpowers.add(tag);
                                } else {
                                  _selectedSuperpowers.remove(tag);
                                }
                              });
                            },
                      selectedColor: const Color(0xFFD1FAE5),
                      backgroundColor: const Color(0xFFE6F4F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _hasNominatedThisWeek ? null : _submitNomination,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC84B1A),
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _hasNominatedThisWeek
                              ? 'Nomination Submitted This Week'
                              : 'Nominate Anonymously',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Privacy Reassurance Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEFFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF2E3A59),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '100% Private: Only the nominated person sees their nomination. No public leaderboards or rankings.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E3A59),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // TAB 2: Received Nominations (The Recipient View)
  Widget _buildReceivedTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Private Recipient Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF047857), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF047857).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
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
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Weekly Hero Nominations',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_receivedNominations.length} Teammates nominated you as their hero',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your teammates appreciated your help when they were in need last week. Only you can see these nominations.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Private Appreciations For You:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.titleDark,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 12,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Private',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // List of Anonymous Received Cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _receivedNominations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final nom = _receivedNominations[index];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF0F0F8)),
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
                    // Header Row: Anonymous Teammate Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF4F4FD),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_pin_rounded,
                                color: Color(0xFFC84B1A),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Anonymous Teammate',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF4A1500),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          nom['time'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Superpower Tags
                    Wrap(
                      spacing: 6,
                      children: (nom['tags'] as List<String>).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 10),

                    // Shared Reason Text
                    Text(
                      '"${nom['reason']}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.titleDark,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
