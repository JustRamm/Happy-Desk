import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/multi_coffee_reset_modal.dart';
import 'direct_chat_screen.dart';

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

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New Appreciation Note Added',
      'time': '10 Mins Ago',
      'body':
          'An anonymous teammate dropped an appreciation note into your private NGL Jar.',
      'type': 'jar',
      'isNew': true,
    },
    {
      'title': 'Sarah Chen Named Weekly Hero',
      'time': '2 Hours Ago',
      'body': 'Sarah received 8 peer nominations for outstanding support!',
      'type': 'hero',
      'isNew': true,
    },
    {
      'title': 'Attendance Streak Milestone',
      'time': 'Yesterday',
      'body': 'You reached a 7-day joyful clock-in streak!',
      'type': 'streak',
      'isNew': false,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF171B2B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 42,
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
                    fontSize: 13.5,
                    color: const Color(0xFF171B2B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search messages or alerts...',
                    hintStyle: GoogleFonts.beVietnamPro(
                      fontSize: 13,
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
        actions: [
          // TOP RIGHT COFFEE ICON: Multi-Select Group Coffee Reset Selector!
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Section 1: Direct Messages
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Direct Messages',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF171B2B),
                  ),
                ),
                Text(
                  '${_chats.length} Teammates',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8D7168),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Teammate Conversations List
            ..._chats.map((chat) {
              final isOnline = chat['isOnline'] == true;
              final isUnread = chat['unread'] == true;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DirectChatScreen(teammate: chat),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUnread
                          ? const Color(0xFFFFD6C7)
                          : const Color(0xFFE4E7FE),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFAB3500).withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar with Online Status Indicator
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      chat['name'],
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF171B2B),
                                      ),
                                    ),
                                    if (isUnread) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFAB3500),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'NEW',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
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
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF8D7168), size: 20),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Section 2: Recent Workplace Alerts
            Text(
              'Recent Workplace Alerts',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 12),

            ..._notifications.map((notif) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      notif['isNew'] ? Colors.white : const Color(0xFFF3F2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: notif['isNew']
                        ? const Color(0xFFFFD6C7)
                        : const Color(0xFFDEE1F8),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0EB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notif['type'] == 'jar'
                            ? Icons.mark_email_unread_rounded
                            : notif['type'] == 'hero'
                                ? Icons.emoji_events_rounded
                                : Icons.workspace_premium_rounded,
                        color: const Color(0xFFAB3500),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notif['title'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF171B2B),
                                  ),
                                ),
                              ),
                              Text(
                                notif['time'],
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11,
                                  color: const Color(0xFF8D7168),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notif['body'],
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12.5,
                              color: const Color(0xFF594139),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
