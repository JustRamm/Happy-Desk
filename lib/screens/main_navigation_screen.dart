import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'ai_wellness_bot_screen.dart';
import 'chat_notifications_screen.dart';
import 'profile_screen.dart';
import 'audio_video_call_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../services/supabase_service.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final GlobalKey<AiWellnessBotScreenState> _mochiScreenKey = GlobalKey();
  RealtimeChannel? _callSubscription;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _listenForIncomingCalls();
  }

  void _listenForIncomingCalls() {
    _callSubscription = SupabaseService.instance.subscribeToIncomingCalls(
      onIncomingCall: (callData) {
        if (!mounted) return;
        final callerName = callData['caller_name'] ?? 'Teammate';
        final isVideo = callData['is_video'] ?? true;
        final callId = callData['id'];

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1F2438),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Text(
              '$callerName is calling you...',
              style: GoogleFonts.beVietnamPro(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  SupabaseService.instance.updateCallStatus(callId: callId, status: 'rejected');
                  Navigator.pop(ctx);
                },
                child: const Text('Decline', style: TextStyle(color: Colors.redAccent)),
              ),
              ElevatedButton(
                onPressed: () {
                  SupabaseService.instance.updateCallStatus(callId: callId, status: 'accepted');
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AudioVideoCallScreen(
                        teammate: {
                          'name': callerName,
                          'role': 'Teammate',
                        },
                        isVideoCall: isVideo,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                child: const Text('Accept', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _callSubscription?.unsubscribe();
    super.dispose();
  }

  late final List<Widget> _screens = [
    const HomeScreen(),
    AiWellnessBotScreen(key: _mochiScreenKey),
    const ChatNotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
          }
        },
      ),
    );
  }
}
