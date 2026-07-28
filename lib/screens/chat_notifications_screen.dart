import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/multi_coffee_reset_modal.dart';
import '../widgets/brand_logo_widget.dart';
import 'direct_chat_screen.dart';
import 'notifications_screen.dart';
import 'new_chat_selector_screen.dart';

class ChatNotificationsScreen extends StatefulWidget {
  const ChatNotificationsScreen({super.key});

  @override
  State<ChatNotificationsScreen> createState() =>
      _ChatNotificationsScreenState();
}

class _ChatNotificationsScreenState extends State<ChatNotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Alex Miller',
      'role': 'Product Designer',
      'lastMessage': 'Great job on the design system updates today!',
      'time': '10:14 AM',
      'unread': true,
      'isOnline': true,
      'avatar': 'assets/avatars/user_avatar.png',
    },
    {
      'name': 'Sarah Chen',
      'role': 'Lead Engineer',
      'lastMessage': 'Let\'s catch up after the team sync call.',
      'time': 'Yesterday',
      'unread': false,
      'isOnline': true,
      'avatar': 'assets/avatars/avatar_1.png',
    },
    {
      'name': 'David Kim',
      'role': 'Frontend Architect',
      'lastMessage': 'Sent the pull request for review.',
      'time': 'July 25',
      'unread': false,
      'isOnline': false,
      'avatar': 'assets/avatars/avatar_2.png',
    },
    {
      'name': 'Marcus Vance',
      'role': 'Community Lead',
      'lastMessage': 'Weekly Hero nominations are looking awesome!',
      'time': 'July 24',
      'unread': false,
      'isOnline': false,
      'avatar': 'assets/avatars/avatar_3.png',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewChatSelectorScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFFAB3500),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
        label: Text(
          'New Chat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFAB3500),
          backgroundColor: Colors.white,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 1000));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Bar (1:1 Pixel Alignment with HomeScreen Header)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand Logo SVG
                      const BrandLogoWidget(height: 54),

                      // Right Header Action Bar
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
                ),

                const SizedBox(height: 8),

                // Search Messages Input Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE4E7FE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFAB3500),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: const Color(0xFF171B2B),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search team messages & conversations...',
                              hintStyle: GoogleFonts.beVietnamPro(
                                fontSize: 12.5,
                                color: const Color(0xFF8D7168),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Section Label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Direct & Group Messages',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF171B2B),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Teammate Conversations List
                ..._chats.asMap().entries.map((entry) {
                  final chat = entry.value;
                  final isOnline = chat['isOnline'] == true;
                  final isUnread = chat['unread'] == true;

                  return Column(
                    children: [
                      Material(
                        color: isUnread ? const Color(0xFFFFF6F3) : Colors.white,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DirectChatScreen(teammate: chat),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: const Color(0xFFFFF0EB),
                                      backgroundImage: AssetImage(chat['avatar']),
                                    ),
                                    if (isOnline)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 11,
                                          height: 11,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00C49A),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            chat['name'],
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14.5,
                                              fontWeight: isUnread
                                                  ? FontWeight.w800
                                                  : FontWeight.w700,
                                              color: const Color(0xFF171B2B),
                                            ),
                                          ),
                                          Text(
                                            chat['time'],
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 11.5,
                                              color: isUnread
                                                  ? const Color(0xFFAB3500)
                                                  : const Color(0xFF8D7168),
                                              fontWeight: isUnread
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        chat['role'],
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 11.5,
                                          color: const Color(0xFFAB3500),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        chat['lastMessage'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 12.5,
                                          color: isUnread
                                              ? const Color(0xFF171B2B)
                                              : const Color(0xFF594139),
                                          fontWeight: isUnread
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF0EFF8)),
                    ],
                  );
                }),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
