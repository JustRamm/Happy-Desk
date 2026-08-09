import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../services/user_preferences_store.dart';

class MultiCoffeeResetModal extends StatefulWidget {
  const MultiCoffeeResetModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const MultiCoffeeResetModal(),
      ),
    );
  }

  @override
  State<MultiCoffeeResetModal> createState() => _MultiCoffeeResetModalState();
}

class _MultiCoffeeResetModalState extends State<MultiCoffeeResetModal> {
  List<Map<String, dynamic>> _teammates = [];
  bool _isLoading = true;

  final TextEditingController _noteController = TextEditingController(
    text: "Hey team! Let's take a quick 5-min coffee break reset together.",
  );

  @override
  void initState() {
    super.initState();
    _loadTeammates();
  }

  Future<void> _loadTeammates() async {
    try {
      final list = await SupabaseService.instance.getCompanyTeammates();
      final myName = UserPreferencesStore.getUserName();
      // Exclude logged in user
      final filtered = list.where((t) => t['name'] != myName).map((t) => {
        'id': t['id'],
        'name': t['name'] ?? 'Teammate',
        'role': t['job_title'] ?? 'Employee',
        'avatar': t['avatar_url'] ?? '',
        'selected': false,
      }).toList();
      
      if (mounted) {
        setState(() {
          _teammates = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading teammates for coffee break: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount =
        _teammates.where((t) => t['selected'] == true).length;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_cafe_rounded,
                          size: 18, color: Color(0xFF95416C)),
                      const SizedBox(width: 8),
                      Text(
                        'Group Coffee Break Reset',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF95416C),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF594139)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Select Teammates for Coffee Reset',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Invite multiple colleagues for a synchronized 5-minute break to unwind and boost team morale.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.5,
                color: const Color(0xFF594139),
              ),
            ),
            const SizedBox(height: 16),

            // Teammates Selection List
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(
                        color: Color(0xFF95416C),
                      ),
                    ),
                  )
                : _teammates.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No teammates found in your company.',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8D7168),
                            ),
                          ),
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _teammates.length,
                          itemBuilder: (context, index) {
                            final t = _teammates[index];
                            final isSelected = t['selected'] == true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF95416C)
                                      : const Color(0xFFE4E7FE),
                                ),
                              ),
                              child: CheckboxListTile(
                                value: isSelected,
                                activeColor: const Color(0xFF95416C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    t['selected'] = val;
                                  });
                                },
                                secondary: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFFFF0EB),
                                  child: ((t['avatar'] as String? ?? '').startsWith('http') ||
                                          ((t['avatar'] as String? ?? '').isNotEmpty && File(t['avatar']).existsSync()))
                                      ? ClipOval(
                                          child: (t['avatar'] as String).startsWith('http')
                                              ? Image.network(t['avatar'], fit: BoxFit.cover, width: 36, height: 36)
                                              : Image.file(File(t['avatar']), fit: BoxFit.cover, width: 36, height: 36),
                                        )
                                      : Text(
                                          (t['name'] as String? ?? '?').isNotEmpty
                                              ? (t['name'] as String)[0].toUpperCase()
                                              : '?',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFAB3500),
                                          ),
                                        ),
                                ),
                                title: Text(
                                  t['name'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF171B2B),
                                  ),
                                ),
                                subtitle: Text(
                                  t['role'],
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    color: const Color(0xFF594139),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            const SizedBox(height: 16),

            // Note TextField
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4E7FE)),
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 2,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.5,
                  color: const Color(0xFF171B2B),
                ),
                decoration: InputDecoration(
                  hintText: 'Add an optional break invite note...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: const Color(0xFF8D7168),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: selectedCount == 0
                    ? null
                    : () async {
                        final text = _noteController.text.trim().isEmpty
                            ? 'Group 5-min coffee break reset started!'
                            : _noteController.text.trim();
                            
                        for (var teammate in _teammates) {
                          if (teammate['selected'] == true && teammate['id'] != null) {
                            try {
                              await SupabaseService.instance.sendCoffeeInvite(
                                message: text,
                                receiverId: teammate['id'],
                                isGroup: true,
                              );
                            } catch (e) {
                              debugPrint('Error sending coffee invite: $e');
                            }
                          }
                        }

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Group coffee break invite sent to $selectedCount teammates!',
                                style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                              ),
                              backgroundColor: const Color(0xFFFF6B35),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF95416C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  selectedCount == 0
                      ? 'Select Teammates'
                      : 'Send Invite ($selectedCount Teammates)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
