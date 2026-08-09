import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'home_screen.dart';
import '../mochi/mochi_bot_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/call_screen.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../services/supabase_service.dart';
import '../../services/user_preferences_store.dart';
import '../../services/push_notification_service.dart';

class MainNavigationScreen extends StatefulWidget {
  /// Pass a specific tab index to override the persisted tab.
  /// Leave as -1 (default) to restore the last active tab from SharedPreferences.
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = -1,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final GlobalKey<AiWellnessBotScreenState> _mochiScreenKey = GlobalKey();
  RealtimeChannel? _callSubscription;
  RealtimeChannel? _messageSubscription;
  bool _showShiftRestoredBanner = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex >= 0 ? widget.initialIndex : 0;
    _checkShiftRestoredBanner();
    _listenForIncomingCalls();
    _listenForIncomingMessages();
  }

  void _listenForIncomingMessages() {
    _messageSubscription = SupabaseService.instance.subscribeToAllIncomingMessages(
      onNewMessage: (msgData) {
        final senderName = msgData['sender_name'] ?? 'Teammate';
        final content = msgData['content'] ?? 'Sent you a message';
        final senderFirstName = senderName.toString().split(' ').first;

        PushNotificationService.instance.showNotification(
          title: 'New Message from $senderFirstName',
          body: content.toString(),
          payload: 'chat_$senderName',
        );
      },
    );
  }

  /// Scenario 8: If user was clocked in before a force-kill, greet them
  /// with a subtle "Shift Restored" banner instead of losing their context.
  Future<void> _checkShiftRestoredBanner() async {
    final wasClockedIn = await UserPreferencesStore.isClockedIn();
    if (wasClockedIn && mounted) {
      setState(() => _showShiftRestoredBanner = true);
      // Auto-dismiss after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showShiftRestoredBanner = false);
      });
    }
  }

  void _listenForIncomingCalls() {
    _callSubscription = SupabaseService.instance.subscribeToIncomingCalls(
      onIncomingCall: (callData) {
        if (!mounted) return;
        final callerName = callData['caller_name'] ?? 'Teammate';
        final isVideo = callData['is_video'] ?? true;
        final callId = callData['id']?.toString() ?? '';

        // Show native phone system tray notification outside the app!
        if (callId.isNotEmpty) {
          PushNotificationService.instance.showCallNotification(
            callerName: callerName,
            isVideo: isVideo,
            callId: callId,
          );
        }

        final ringtonePlayer = AudioPlayer();
        try {
          ringtonePlayer.setReleaseMode(ReleaseMode.loop);
          ringtonePlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/1359/1359-preview.mp3'));
        } catch (e) {
          debugPrint('Error playing incoming call ringtone: $e');
        }

        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: const Color(0xFF171B2B),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (isVideo ? const Color(0xFF95416C) : const Color(0xFFAB3500)).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isVideo ? Icons.videocam_rounded : Icons.phone_in_talk_rounded,
                    color: isVideo ? const Color(0xFFFF99C8) : const Color(0xFFFF9E7A),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  callerName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        ringtonePlayer.stop();
                        ringtonePlayer.dispose();
                        if (callId.isNotEmpty) {
                          PushNotificationService.instance.cancelCallNotification(callId);
                        }
                        SupabaseService.instance.updateCallStatus(callId: callId, status: 'rejected');
                        Navigator.pop(ctx);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 8),
                          Text('Decline', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ringtonePlayer.stop();
                        ringtonePlayer.dispose();
                        if (callId.isNotEmpty) {
                          PushNotificationService.instance.cancelCallNotification(callId);
                        }
                        SupabaseService.instance.updateCallStatus(callId: callId, status: 'accepted');
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              teammate: {
                                'name': callerName,
                                'role': 'Teammate',
                              },
                              isVideoCall: isVideo,
                              isIncoming: true,
                              callInviteData: callData,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(isVideo ? Icons.videocam_rounded : Icons.call_rounded, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 8),
                          Text('Accept', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (_callSubscription != null) {
      SupabaseService.instance.client.removeChannel(_callSubscription!);
    }
    if (_messageSubscription != null) {
      SupabaseService.instance.client.removeChannel(_messageSubscription!);
    }
    super.dispose();
  }

  late final List<Widget> _screens = [
    const HomeScreen(),
    MochiBotScreen(key: _mochiScreenKey),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // ── Scenario 8: Shift Restored Banner ─────────────────────────────
          if (_showShiftRestoredBanner)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: _showShiftRestoredBanner ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 350),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.restore_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Shift session restored from last session',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showShiftRestoredBanner = false),
                          child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) {
          if (_currentIndex == 1 && index != 1) {
            _mochiScreenKey.currentState?.summarizeSessionIfNeeded();
          }
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
            // Scenario 4: Immediately persist the newly selected tab
            UserPreferencesStore.setLastActiveTabIndex(index);
          }
        },
      ),
    );
  }
}
