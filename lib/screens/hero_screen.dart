import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'jar_screen.dart';
import 'notifications_screen.dart';
import '../widgets/jar_icon_widget.dart';

class HeroScreen extends StatefulWidget {
  const HeroScreen({super.key});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> with SingleTickerProviderStateMixin {
  bool _hasNominatedThisWeek = false;
  String? _selectedCoworker;
  final TextEditingController _storyController = TextEditingController();

  final List<String> _coworkers = [
    'Marcus Vance (Engineering)',
    'Sarah Chen (Design)',
    'Mary Jane (Product)',
    'Alex Miller (Marketing)',
    'Elena Rostova (Customer Success)',
  ];

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

  // Dummy list of nominations RECEIVED by current user (Anonymous)
  final List<Map<String, dynamic>> _receivedNominations = [
    {
      'time': '2 hours ago',
      'tags': ['#ProblemSolver', '#LifeSaver'],
      'reason':
          'Stayed late on Tuesday to help me debug the production deployment pipeline when I was stuck!',
    },
    {
      'time': 'Yesterday',
      'tags': ['#Supportive', '#Clutch'],
      'reason':
          'Stepped in to cover my client demo presentation when I had a sudden family emergency call.',
    },
    {
      'time': '3 days ago',
      'tags': ['#TeamPlayer'],
      'reason':
          'Brought coffee and walked me through the design system guidelines so patiently!',
    },
  ];

  TabController? _tabController;
  bool _controllerInitialized = false;

  @override
  void initState() {
    super.initState();
  }

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
        const SnackBar(
          content: Text('You have already submitted your 1 nomination for this week!'),
          backgroundColor: AppTheme.primaryRust,
        ),
      );
      return;
    }

    if (_selectedCoworker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the teammate who helped you!'),
          backgroundColor: AppTheme.primaryRust,
        ),
      );
      return;
    }

    if (_storyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please explain how they helped you in need this week!'),
          backgroundColor: AppTheme.primaryRust,
        ),
      );
      return;
    }

    final nominee = _selectedCoworker!;
    setState(() {
      _hasNominatedThisWeek = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Anonymous Hero nomination sent to $nominee! (+5 Team Points)'),
        backgroundColor: const Color(0xFF007A5A),
        duration: const Duration(seconds: 4),
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
                      // Brand Logo
                      Image.asset(
                        'assets/brand/logo_removedbg.png',
                        height: 70,
                        fit: BoxFit.contain,
                      ),

                      // Jar + Notification icons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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

                  const SizedBox(height: 10),

                  // Segmented Tab Bar (Nominate vs Received Nominations)
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        const Tab(text: 'Nominate Hero'),
                        Tab(text: 'Received (${_receivedNominations.length})'),
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

                  // Tab 2: View Received Nominations (Recipient View)
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
          // Weekly Limit Rule Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _hasNominatedThisWeek ? const Color(0xFFD1FAE5) : const Color(0xFFFFF0EB),
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
                      : Icons.info_outline_rounded,
                  color: _hasNominatedThisWeek ? const Color(0xFF047857) : AppTheme.primaryRust,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasNominatedThisWeek
                            ? 'Weekly Nomination Submitted! (1/1)'
                            : '1 Nomination Per Week Allowed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _hasNominatedThisWeek
                              ? const Color(0xFF047857)
                              : AppTheme.brandTitleOrange,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasNominatedThisWeek
                            ? 'You\'ve nominated your hero for this week. Thank you!'
                            : 'Nominate 1 teammate who helped you when in need this week.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _hasNominatedThisWeek
                              ? const Color(0xFF065F46)
                              : const Color(0xFF6B1D00),
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
                  'Who helped you when in need this week?',
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
                          const Icon(Icons.person_search_rounded, color: Colors.grey, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Select a coworker...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      value: _selectedCoworker,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      items: _coworkers.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.titleDark,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _hasNominatedThisWeek
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

                // Field 2: What did they do to help? (Reason shared with recipient)
                Text(
                  'How did they help you? (Shared with them anonymously)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.titleDark,
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
                          'Explain what happened... (e.g. Marcus stayed late to help me fix the deployment bug when I was struggling!)',
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
                  'Select Superpowers',
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
                          color: isSelected ? const Color(0xFF047857) : const Color(0xFF065F46),
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
                          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),

                // Submit Button (100% Anonymous)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _hasNominatedThisWeek ? null : _submitNomination,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC84B1A),
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          _hasNominatedThisWeek ? 'Already Nominated This Week' : 'Nominate Anonymously',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
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

          // Anonymity Guarantee Pill
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEFFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, color: Color(0xFF2E3A59), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '100% Anonymous: Your identity will never be revealed to your nominee.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E3A59),
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
          // Recipient Hero Summary Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007A5A), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007A5A).withValues(alpha: 0.25),
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
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You\'re a Hero This Week!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'You received ${_receivedNominations.length} Anonymous Nominations',
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
                  'Your teammates appreciated your help when they were in need! Read what they wrote below (sender identities stay anonymous).',
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

          Text(
            'Reasons Teammates Nominated You:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.titleDark,
            ),
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
                              child: const Icon(Icons.person_pin_rounded, color: Color(0xFFC84B1A), size: 16),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
