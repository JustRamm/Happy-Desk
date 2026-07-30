import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/brand_logo_widget.dart';
import 'direct_chat_screen.dart';
import 'new_chat_selector_screen.dart';
import '../services/supabase_service.dart';
import '../services/user_preferences_store.dart';
import '../services/sound_service.dart';

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
      'avatar': '',
    },
    {
      'name': 'Sarah Chen',
      'role': 'Lead Engineer',
      'lastMessage': 'Let\'s catch up after the team sync call.',
      'time': 'Yesterday',
      'unread': false,
      'isOnline': true,
      'avatar': '',
    },
    {
      'name': 'David Kim',
      'role': 'Frontend Architect',
      'lastMessage': 'Sent the pull request for review.',
      'time': 'July 25',
      'unread': false,
      'isOnline': false,
      'avatar': '',
    },
    {
      'name': 'Marcus Vance',
      'role': 'Community Lead',
      'lastMessage': 'Weekly Hero nominations are looking awesome!',
      'time': 'July 24',
      'unread': false,
      'isOnline': false,
      'avatar': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLiveChats();
  }

  Future<void> _loadLiveChats() async {
    final dbMessages = await SupabaseService.instance.getDirectMessages();
    if (dbMessages.isNotEmpty && mounted) {
      final currentUserName = UserPreferencesStore.getUserName();
      final Map<String, Map<String, dynamic>> latestByPerson = {};

      for (var msg in dbMessages) {
        final sender = msg['sender_name'] as String? ?? 'Unknown';
        final receiver = msg['receiver_name'] as String? ?? 'Unknown';
        final isMeSender = (sender == currentUserName);
        final otherPerson = isMeSender ? receiver : sender;

        if (otherPerson.isEmpty || otherPerson == currentUserName) continue;

        final isUnread = !isMeSender && (msg['is_read'] == false);
        final timeRaw = msg['created_at']?.toString() ?? '';
        final timeStr = timeRaw.isNotEmpty ? timeRaw.split('T').last.substring(0, 5) : 'Now';

        latestByPerson[otherPerson] = {
          'name': otherPerson,
          'role': 'Teammate',
          'lastMessage': msg['message'] ?? '',
          'time': timeStr,
          'unread': isUnread,
          'isOnline': true,
          'avatar': msg['avatar_url'] as String? ?? '',
        };
      }

      if (latestByPerson.isNotEmpty) {
        setState(() {
          _chats.clear();
          _chats.addAll(latestByPerson.values);
        });
      }
    }
  }

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

                      // Right Header Action Bar (History & New Chat Icons)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Upcoming feature: Chat History',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF171B2B),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
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
                                Icons.history_rounded,
                                color: Color(0xFFAB3500),
                                size: 20,
                              ),
                            ),
                            tooltip: 'History',
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Upcoming feature: Create New Chat',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF171B2B),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3F2FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Color(0xFF95416C),
                                size: 20,
                              ),
                            ),
                            tooltip: 'New Chat',
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
                          onTap: () async {
                            SoundService.playMessageOpenSound();
                            setState(() {
                              chat['unread'] = false;
                            });
                            await SupabaseService.instance
                                .markDirectMessagesAsRead(chat['name'] ?? '');
                            if (!context.mounted) return;
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
                                      child: ((chat['avatar'] as String? ?? '').startsWith('http') ||
                                              ((chat['avatar'] as String? ?? '').isNotEmpty && File(chat['avatar']).existsSync()))
                                          ? ClipOval(
                                              child: (chat['avatar'] as String).startsWith('http')
                                                  ? Image.network(chat['avatar'], fit: BoxFit.cover, width: 44, height: 44)
                                                  : Image.file(File(chat['avatar']), fit: BoxFit.cover, width: 44, height: 44),
                                            )
                                          : Text(
                                              (chat['name'] as String? ?? '?').isNotEmpty
                                                  ? (chat['name'] as String)[0].toUpperCase()
                                                  : '?',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFFAB3500),
                                              ),
                                            ),
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
