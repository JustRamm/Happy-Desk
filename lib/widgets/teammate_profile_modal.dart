import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/direct_chat_screen.dart';
import '../services/coffee_notification_store.dart';

class TeammateProfileModal extends StatelessWidget {
  final Map<String, dynamic> teammate;

  const TeammateProfileModal({
    super.key,
    required this.teammate,
  });

  static void show(BuildContext context, Map<String, dynamic> teammate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => TeammateProfileModal(teammate: teammate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = teammate['name'] ?? 'Alex Miller';
    final String role = teammate['role'] ?? 'Product Designer';
    final String avatar = teammate['avatar'] ?? 'assets/avatars/user_avatar.png';
    final bool isOnline = teammate['isOnline'] == true;

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar with Drag Indicator & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEE1F8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF594139),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Avatar Stack with Online Badge
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFAB3500), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFAB3500).withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(45),
                  child: Image.asset(
                    avatar,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF00AE88) : const Color(0xFF8D7168),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Name and Role
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF171B2B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13.5,
              color: const Color(0xFF594139),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFFEBF7F5) : const Color(0xFFF3F2FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOnline ? const Color(0xFF00AE88).withValues(alpha: 0.3) : const Color(0xFFDEE1F8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOnline ? Icons.check_circle_rounded : Icons.access_time_rounded,
                  size: 14,
                  color: isOnline ? const Color(0xFF006C53) : const Color(0xFF95416C),
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? 'Clocked In • Active Work Session' : 'Offline • Shift Ended',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isOnline ? const Color(0xFF006C53) : const Color(0xFF95416C),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Kudos & Stats Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE4E7FE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFFAB3500),
                  value: '18',
                  label: 'NGL Notes',
                ),
                Container(width: 1, height: 36, color: const Color(0xFFE4E7FE)),
                _buildStatColumn(
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFF95416C),
                  value: '6',
                  label: 'Hero Badges',
                ),
                Container(width: 1, height: 36, color: const Color(0xFFE4E7FE)),
                _buildStatColumn(
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFF006C53),
                  value: '98%',
                  label: 'Reliability',
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DirectChatScreen(teammate: teammate),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAB3500),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text(
                    'Direct Message',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    CoffeeNotificationStore.addCoffeeInvite(
                      senderName: name,
                      senderAvatar: avatar,
                      message: '$name sent you a 1-on-1 coffee break invitation!',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.local_cafe_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Coffee break invite sent to $name!',
                                style: GoogleFonts.beVietnamPro(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFFAB3500),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF95416C), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon: const Icon(Icons.local_cafe_rounded, size: 18, color: Color(0xFF95416C)),
                  label: Text(
                    'Coffee Break',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF95416C),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 11.5,
            color: const Color(0xFF594139),
          ),
        ),
      ],
    );
  }
}
