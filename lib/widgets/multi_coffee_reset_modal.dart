import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final List<Map<String, dynamic>> _teammates = [
    {
      'name': 'Alex Miller',
      'role': 'Product Designer',
      'avatar': 'assets/avatars/user_avatar.png',
      'selected': true,
    },
    {
      'name': 'Sarah Chen',
      'role': 'Lead Engineer',
      'avatar': 'assets/avatars/avatar_1.png',
      'selected': true,
    },
    {
      'name': 'David Kim',
      'role': 'Frontend Architect',
      'avatar': 'assets/avatars/avatar_2.png',
      'selected': false,
    },
    {
      'name': 'Marcus Vance',
      'role': 'Community Lead',
      'avatar': 'assets/avatars/avatar_3.png',
      'selected': false,
    },
  ];

  final TextEditingController _noteController = TextEditingController(
    text: "Hey team! Let's take a quick 5-min coffee break reset together.",
  );

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
            ConstrainedBox(
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
                        backgroundImage: AssetImage(t['avatar']),
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
                    : () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Group coffee break invite sent to $selectedCount teammates!',
                              style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                            ),
                            backgroundColor: const Color(0xFF95416C),
                            duration: const Duration(seconds: 3),
                          ),
                        );
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
