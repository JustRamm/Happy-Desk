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
import '../services/user_preferences_store.dart';

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
  bool _showShiftRestoredBanner = false;

  @override
  void initState() {
    super.initState();
    // Scenario 4 & 8: Restore last active tab.
    // -1 means caller didn't specify → use what's persisted in SharedPreferences.
    _currentIndex = widget.initialIndex >= 0
        ? widget.initialIndex
        : UserPreferencesStore.getLastActiveTabIndex();
    _listenForIncomingCalls();
    _checkShiftRestoredBanner();
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
