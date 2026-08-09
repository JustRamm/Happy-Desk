import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/brand_logo_widget.dart';
import '../widgets/notification_bell_widget.dart';
import 'direct_chat_screen.dart';
import 'new_chat_selector_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final List<Map<String, dynamic>> _chats = [];
  dynamic _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _loadLiveChats();
    _subscribeToRealtimeChats();
  }

  void _subscribeToRealtimeChats() {
    try {
      _realtimeSubscription = SupabaseService.instance.client
          .channel('public:direct_messages_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'direct_messages',
            callback: (payload) {
              if (mounted) {
                _loadLiveChats();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error subscribing to realtime direct messages: $e');
    }
  }

  Future<void> _loadLiveChats() async {
    final dbMessages = await SupabaseService.instance.getDirectMessages();
    final currentUserName = UserPreferencesStore.getUserName();
    final Map<String, Map<String, dynamic>> latestByPerson = {};

    if (dbMessages.isNotEmpty) {
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
    }

    if (mounted) {
      setState(() {
        _chats.clear();
        _chats.addAll(latestByPerson.values);
      });
    }
  }

  @override
  void dispose() {
    if (_realtimeSubscription != null) {
      try {
        SupabaseService.instance.client.removeChannel(_realtimeSubscription);
      } catch (_) {}
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewChatSelectorScreen(),
            ),
          );
          _loadLiveChats();
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
                 // Top Header Bar with Logo, Searchbar, and Notification Bell
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                   child: Row(
                     children: [
                       // Brand Logo Widget
                       const BrandLogoWidget(height: 54),
                       const SizedBox(width: 10),

                       // Header Search Bar
                       Expanded(
                         child: Container(
                           height: 38,
                           padding: const EdgeInsets.symmetric(horizontal: 10),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(19),
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
                                   onTap: () {
                                     SystemChannels.textInput.invokeMethod('TextInput.show');
                                   },
                                   style: GoogleFonts.beVietnamPro(
                                     fontSize: 12,
                                     color: const Color(0xFF171B2B),
                                   ),
                                   decoration: InputDecoration(
                                     hintText: 'Search...',
                                     hintStyle: GoogleFonts.beVietnamPro(
                                       fontSize: 11.5,
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
                       const SizedBox(width: 10),

                       // Right Header Action Bar (Notification Bell Icon)
                       const NotificationBellWidget(),
                     ],
                   ),
                 ),

                 const SizedBox(height: 16),

                if (_chats.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: const Color(0xFFAB3500).withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No active conversations yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF171B2B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the "New Chat" button to start chatting.',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12.5,
                              color: const Color(0xFF8D7168),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

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
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DirectChatScreen(teammate: chat),
                              ),
                            );
                            _loadLiveChats();
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
