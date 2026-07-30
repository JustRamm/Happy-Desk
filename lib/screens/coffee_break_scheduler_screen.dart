import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/coffee_notification_store.dart';
import '../services/user_preferences_store.dart';

class CoffeeBreakSchedulerScreen extends StatefulWidget {
  final Map<String, dynamic>? initialTeammate;

  const CoffeeBreakSchedulerScreen({
    super.key,
    this.initialTeammate,
  });

  @override
  State<CoffeeBreakSchedulerScreen> createState() =>
      _CoffeeBreakSchedulerScreenState();
}

class _CoffeeBreakSchedulerScreenState
    extends State<CoffeeBreakSchedulerScreen> {
  int _selectedDurationMinutes = 15;
  String _selectedLocation = 'Office Cafeteria (HQ Floor 2)';
  bool _syncWithCalendar = true;
  String _searchQuery = '';

  final TextEditingController _noteController = TextEditingController(
    text: "Hey team! Let's take a quick 5-min coffee break reset together.",
  );
  final TextEditingController _searchController = TextEditingController();

  final List<int> _durations = [5, 15, 30];

  final List<Map<String, dynamic>> _locations = [
    {
      'title': 'Office Cafeteria (HQ Floor 2)',
      'subtitle': 'In-person coffee nook',
      'icon': Icons.local_cafe_rounded,
    },
    {
      'title': 'Virtual Coffee Lounge',
      'subtitle': 'Audio/Video call break',
      'icon': Icons.video_call_rounded,
    },
    {
      'title': 'Rooftop Terrace',
      'subtitle': 'Fresh air & sun reset',
      'icon': Icons.wb_sunny_rounded,
    },
  ];

  final List<Map<String, dynamic>> _teammates = [
    {
      'name': 'Alex Miller',
      'role': 'Product Designer',
      'avatar': '',
      'selected': true,
    },
    {
      'name': 'Sarah Chen',
      'role': 'Lead Engineer',
      'avatar': '',
      'selected': false,
    },
    {
      'name': 'David Kim',
      'role': 'Frontend Architect',
      'avatar': '',
      'selected': false,
    },
    {
      'name': 'Marcus Vance',
      'role': 'Community Lead',
      'avatar': '',
      'selected': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTeammate != null) {
      final name = widget.initialTeammate!['name'];
      for (var t in _teammates) {
        if (t['name'] == name) {
          t['selected'] = true;
        } else {
          t['selected'] = false;
        }
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _submitCoffeeBreak() {
    final selectedCount = _teammates.where((t) => t['selected'] == true).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least 1 teammate for the coffee break.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: const Color(0xFFAB3500),
        ),
      );
      return;
    }

    final selectedNames = _teammates
        .where((t) => t['selected'] == true)
        .map((t) => t['name'])
        .join(', ');

    CoffeeNotificationStore.addCoffeeInvite(
      senderName: selectedNames,
      senderAvatar: UserPreferencesStore.getUserAvatarUrl() ?? '',
      message:
          'Coffee reset scheduled at $_selectedLocation for $_selectedDurationMinutes mins with $selectedNames.',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Coffee break invitation sent to $selectedNames!',
                style: GoogleFonts.beVietnamPro(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006C53),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF171B2B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Coffee Break Scheduler',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF171B2B),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF95416C), Color(0xFF7B2C56)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF95416C).withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_cafe_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step Away & De-Stress',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Invite teammates for a quick coffee reset or watercooler chat.',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            color: const Color(0xFFFFD8E6),
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

            // Section 1: Duration
            Text(
              'Select Duration',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _durations.map((mins) {
                final isSelected = _selectedDurationMinutes == mins;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDurationMinutes = mins;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFAB3500)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFAB3500)
                              : const Color(0xFFE4E7FE),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$mins Mins',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF171B2B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mins == 5
                                ? 'Quick Reset'
                                : (mins == 15 ? 'Coffee Break' : 'Social Lounge'),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : const Color(0xFF594139),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Section 2: Meeting Location
            Text(
              'Choose Meeting Spot',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 12),
            ..._locations.map((loc) {
              final isSelected = _selectedLocation == loc['title'];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF006C53)
                        : const Color(0xFFE4E7FE),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    setState(() {
                      _selectedLocation = loc['title'];
                    });
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEBF7F5)
                          : const Color(0xFFF3F2FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      loc['icon'],
                      color: isSelected
                          ? const Color(0xFF006C53)
                          : const Color(0xFF95416C),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    loc['title'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF171B2B),
                    ),
                  ),
                  subtitle: Text(
                    loc['subtitle'],
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: const Color(0xFF594139),
                    ),
                  ),
                  trailing: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF006C53) : const Color(0xFF8D7168),
                        width: isSelected ? 6.5 : 2,
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Section 3: Search & Select Teammates
            Text(
              'Search Teammates',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name or role...',
                hintStyle: GoogleFonts.beVietnamPro(
                  fontSize: 12.5,
                  color: const Color(0xFF8D7168),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE4E7FE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE4E7FE)),
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFAB3500)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE4E7FE)),
              ),
              child: Column(
                children: _teammates
                    .where((tm) {
                      final query = _searchQuery;
                      if (query.isEmpty) return true;
                      final name = (tm['name'] as String).toLowerCase();
                      final role = (tm['role'] as String).toLowerCase();
                      return name.contains(query) || role.contains(query);
                    })
                    .map((tm) {
                      return CheckboxListTile(
                        value: tm['selected'],
                        activeColor: const Color(0xFFAB3500),
                        onChanged: (val) {
                          setState(() {
                            tm['selected'] = val ?? false;
                          });
                        },
                        secondary: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFFFF0EB),
                          child: ((tm['avatar'] as String? ?? '').startsWith('http') ||
                                  ((tm['avatar'] as String? ?? '').isNotEmpty && File(tm['avatar']).existsSync()))
                              ? ClipOval(
                                  child: (tm['avatar'] as String).startsWith('http')
                                      ? Image.network(tm['avatar'], fit: BoxFit.cover, width: 36, height: 36)
                                      : Image.file(File(tm['avatar']), fit: BoxFit.cover, width: 36, height: 36),
                                )
                              : Text(
                                  (tm['name'] as String? ?? '?').isNotEmpty
                                      ? (tm['name'] as String)[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFAB3500),
                                  ),
                                ),
                        ),
                        title: Text(
                          tm['name'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF171B2B),
                          ),
                        ),
                        subtitle: Text(
                          tm['role'],
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11.5,
                            color: const Color(0xFF594139),
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Section 4: Optional Message
            Text(
              'Add Personal Note (Optional)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: GoogleFonts.beVietnamPro(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'e.g. Let\'s grab a quick espresso and chat about the product roadmap!',
                hintStyle: GoogleFonts.beVietnamPro(
                  fontSize: 12.5,
                  color: Colors.grey.shade500,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE4E7FE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE4E7FE)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Calendar Sync Option
            CheckboxListTile(
              value: _syncWithCalendar,
              activeColor: const Color(0xFF006C53),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (val) {
                setState(() {
                  _syncWithCalendar = val ?? true;
                });
              },
              title: Text(
                'Sync coffee reset to Google / Workplace Calendar',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF171B2B),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitCoffeeBreak,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAB3500),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  'Schedule & Send Coffee Invites',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
