import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HeroScreen extends StatefulWidget {
  const HeroScreen({super.key});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> {
  String? _selectedCoworker;
  final TextEditingController _storyController = TextEditingController();

  final List<String> _coworkers = [
    'Marcus Vance (Engineering)',
    'Sarah Chen (Design)',
    'Mary Jane (Product)',
    'Alex Miller (Marketing)',
    'Elena Rostova (Customer Success)',
  ];

  final Set<String> _selectedSuperpowers = {'#Supportive', '#TeamPlayer'};

  final List<String> _allSuperpowers = [
    '#Supportive',
    '#ProblemSolver',
    '#Creative',
    '#Reliable',
    '#TeamPlayer',
    '#Leader',
    '#Innovator',
  ];

  void _submitNomination() {
    if (_storyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please share a quick story of what they did!'),
          backgroundColor: AppTheme.primaryRust,
        ),
      );
      return;
    }

    final nominee = _selectedCoworker ?? 'your teammate';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Nominated $nominee for Weekly Hero! +5 Team Points added.'),
        backgroundColor: const Color(0xFF007A5A),
        duration: const Duration(seconds: 3),
      ),
    );

    setState(() {
      _storyController.clear();
      _selectedSuperpowers.clear();
      _selectedCoworker = null;
    });
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
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
                  // Brand Logo Asset
                  Image.asset(
                    'assets/brand/logo_removedbg.png',
                    height: 32,
                    fit: BoxFit.contain,
                  ),

                  Row(
                    children: [
                      // User Avatar
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: Image.asset(
                            'assets/images/user_avatar.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Notification Bell
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: AppTheme.primaryRust.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppTheme.primaryRust,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Top Headline with Mint Ambient Backdrop Circle Accent
              Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1FAE5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team Spotlight',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandTitleOrange,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Shine a light on a coworker\'s amazing work\nand let the whole office celebrate their wins!\n🌟',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Main Nomination Form Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
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
                    // Field 1: Who's your hero?
                    Text(
                      'Who\'s your hero?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
                              const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Search for a coworker...',
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
                          onChanged: (val) {
                            setState(() {
                              _selectedCoworker = val;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Field 2: What did they do that was awesome?
                    Text(
                      'What did they do that was awesome?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
                        maxLines: 4,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.titleDark,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Share the story... (e.g. Marcus stayed late to help me debug the launch script, and even ordered pizza!)',
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

                    const SizedBox(height: 20),

                    // Field 3: Pick their superpowers
                    Text(
                      'Pick their superpowers',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.titleDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Superpower Tag Pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _allSuperpowers.map((tag) {
                        final isSelected = _selectedSuperpowers.contains(tag);
                        return ChoiceChip(
                          label: Text(
                            tag,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF047857)
                                  : const Color(0xFF065F46),
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
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
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Weekly Hero Curved Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F2), // Light Teal Curved Oval container
                  borderRadius: BorderRadius.circular(100), // Curved stadium shape
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFF007A5A),
                      size: 36,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Weekly Hero',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF047857),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nominations close Friday at 4 PM!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF065F46),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Last Week Winner Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF8C436E),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              'MJ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Week: Mary Jane',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.titleDark,
                                ),
                              ),
                              Text(
                                'Nominated 12 times!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tip Card (Pink)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFEC4899),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tip: Be specific!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF9D174D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Detailed stories have a 40% higher chance of winning Weekly Hero status.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: const Color(0xFF831843),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Community Impact Card (Soft Peach)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.volunteer_activism_rounded,
                      color: AppTheme.primaryRust,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community Impact',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.brandTitleOrange,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Each nomination adds 5 points to your team\'s monthly goal.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: const Color(0xFF6B1D00),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Main CTA Nominate Hero Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitNomination,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRust,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppTheme.primaryRust.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_fix_high_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Nominate Hero',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
