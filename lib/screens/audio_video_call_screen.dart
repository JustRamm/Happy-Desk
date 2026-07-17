import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AudioVideoCallScreen extends StatefulWidget {
  final Map<String, dynamic> teammate;
  final bool isVideoCall;

  const AudioVideoCallScreen({
    super.key,
    required this.teammate,
    this.isVideoCall = false,
  });

  @override
  State<AudioVideoCallScreen> createState() => _AudioVideoCallScreenState();
}

class _AudioVideoCallScreenState extends State<AudioVideoCallScreen>
    with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  int _secondsElapsed = 0;
  Timer? _callTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _isVideoEnabled = widget.isVideoCall;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.teammate['name'] ?? 'Sarah Chen';
    final String role = widget.teammate['role'] ?? 'Lead Engineer';
    final String avatar =
        widget.teammate['avatar'] ?? 'assets/avatars/user_avatar.png';

    return Scaffold(
      backgroundColor: const Color(0xFF171B2B),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF00AE88),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'End-to-End Encrypted',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance spacer
                ],
              ),
            ),

            const Spacer(),

            // Main Call View Avatar Pulse Container
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFAB3500)
                                  .withValues(alpha: 0.6),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFAB3500)
                                    .withValues(alpha: 0.25),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(70),
                            child: Image.asset(
                              avatar,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    role,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: const Color(0xFFDEE1F8),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Call Status Timer Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAB3500).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFAB3500).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _formatDuration(_secondsElapsed),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFB59D),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Action Bar Controls
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3041),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Mute Mic Button
                  _buildCallControlButton(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    isActive: _isMuted,
                    activeColor: Colors.red.shade400,
                    onTap: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                    },
                  ),

                  // Camera Toggle Button
                  _buildCallControlButton(
                    icon: _isVideoEnabled
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: _isVideoEnabled ? 'Video On' : 'Video Off',
                    isActive: !_isVideoEnabled,
                    activeColor: Colors.grey.shade600,
                    onTap: () {
                      setState(() {
                        _isVideoEnabled = !_isVideoEnabled;
                      });
                    },
                  ),

                  // Speakerphone Button
                  _buildCallControlButton(
                    icon: _isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: 'Speaker',
                    isActive: _isSpeakerOn,
                    activeColor: const Color(0xFF00AE88),
                    onTap: () {
                      setState(() {
                        _isSpeakerOn = !_isSpeakerOn;
                      });
                    },
                  ),

                  // End Call Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            color: Color(0xFFBA1A1A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'End',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDEE1F8),
            ),
          ),
        ],
      ),
    );
  }
}
