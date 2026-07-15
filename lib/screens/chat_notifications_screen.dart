import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/multi_coffee_reset_modal.dart';
import '../widgets/brand_logo_widget.dart';
import 'direct_chat_screen.dart';
import 'notifications_screen.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            // Brand Logo SVG in place of back button
            const BrandLogoWidget(height: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE4E7FE)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFFAB3500),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12.5,
                          color: const Color(0xFF171B2B),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search messages...',
                          hintStyle: GoogleFonts.beVietnamPro(
                            fontSize: 12,
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
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
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
                size: 20,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Group Coffee Break Reset',
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
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teammate Conversations List (Stretched Edge-to-Edge, Gap: 0, Separated by Divider)
            ..._chats.asMap().entries.map((entry) {
              final idx = entry.key;
              final chat = entry.value;
              final isOnline = chat['isOnline'] == true;
              final isUnread = chat['unread'] == true;

              return Column(
                children: [
                  Material(
                    color: isUnread
                        ? const Color(0xFFFFF6F3)
                        : Colors.white,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DirectChatScreen(teammate: chat),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
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
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00AE88),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Name, Message & Time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                chat['name'],
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF171B2B),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isUnread) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFAB3500),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'NEW',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        chat['time'],
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 11.5,
                                          color: const Color(0xFF8D7168),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    chat['lastMessage'],
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12.5,
                                      fontWeight: isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isUnread
                                          ? const Color(0xFF171B2B)
                                          : const Color(0xFF594139),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (idx < _chats.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0EFF8),
                    ),
                ],
              );
            }),


            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
