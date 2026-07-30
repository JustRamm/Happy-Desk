import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../services/user_preferences_store.dart';

class CoffeeResetModal extends StatefulWidget {
  const CoffeeResetModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const CoffeeResetModal(),
      ),
    );
  }

  @override
  State<CoffeeResetModal> createState() => _CoffeeResetModalState();
}

class _CoffeeResetModalState extends State<CoffeeResetModal> {
  List<Map<String, dynamic>> _teammatesList = [];
  bool _isLoading = true;
  String? _selectedTeammate;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeammates();
  }

  Future<void> _loadTeammates() async {
    try {
      final list = await SupabaseService.instance.getCompanyTeammates();
      final myName = UserPreferencesStore.getUserName();
      final filtered = list.where((t) => t['name'] != myName).toList();
      if (mounted) {
        setState(() {
          _teammatesList = filtered;
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

  void _sendInvite() async {
    if (_selectedTeammate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a teammate first.',
            style: GoogleFonts.beVietnamPro(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFAB3500),
        ),
      );
      return;
    }

    final teammate = _teammatesList.firstWhere(
      (t) => t['name'] == _selectedTeammate,
      orElse: () => {},
    );
    final recipientId = teammate['id'];
    final text = _noteController.text.trim().isEmpty
        ? '${UserPreferencesStore.getUserName()} invited you for a 5-min walk break reset!'
        : _noteController.text.trim();

    if (recipientId != null) {
      try {
        await SupabaseService.instance.sendCoffeeInvite(
          message: text,
          receiverId: recipientId,
        );
      } catch (e) {
        debugPrint('Error sending coffee invite: $e');
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coffee & Reset invite sent to $_selectedTeammate!',
            style: GoogleFonts.beVietnamPro(fontSize: 14),
          ),
          backgroundColor: const Color(0xFF006C53),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // Top Header
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
                          size: 16, color: Color(0xFF95416C)),
                      const SizedBox(width: 6),
                      Text(
                        'Peer Reset Lifeline',
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
              'Coffee & 5-Min Walk Break',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Feeling overwhelmed? Invite a teammate for a quick 5-minute coffee or walk break to clear your head.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF594139),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            // Select Teammate Dropdown
            Text(
              'Select Teammate',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFAB3500),
                        ),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4E7FE)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTeammate,
                        hint: Text(
                          _teammatesList.isEmpty
                              ? 'No coworkers found...'
                              : 'Choose a coworker...',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            color: const Color(0xFF8D7168),
                          ),
                        ),
                        isExpanded: true,
                        items: _teammatesList.map((teammate) {
                          final name = teammate['name'] ?? 'Teammate';
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(
                              name,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF171B2B),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: _teammatesList.isEmpty
                            ? null
                            : (val) {
                                setState(() {
                                  _selectedTeammate = val;
                                });
                              },
                      ),
                    ),
                  ),
            const SizedBox(height: 16),

            // Optional note
            Text(
              'Optional Note',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4E7FE)),
              ),
              child: TextField(
                controller: _noteController,
                style: GoogleFonts.beVietnamPro(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Up for a quick water break reset?',
                  hintStyle: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: const Color(0xFF8D7168),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _teammatesList.isEmpty ? null : _sendInvite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAB3500),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Send Reset Invitation',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
