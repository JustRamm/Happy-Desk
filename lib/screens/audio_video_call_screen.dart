import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart';

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
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;

  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  int _secondsElapsed = 0;
  Timer? _callTimer;
  bool _isConnected = false;
  final AudioPlayer _ringtonePlayer = AudioPlayer();

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

    _startRinging();

    if (_isVideoEnabled) {
      _initCamera();
    }
  }

  Future<void> _startRinging() async {
    try {
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/1359/1359-preview.mp3'));
    } catch (e) {
      debugPrint('Error playing calling ringtone: $e');
    }

    Timer(const Duration(milliseconds: 4500), () async {
      if (mounted) {
        try {
          await _ringtonePlayer.stop();
          final beepPlayer = AudioPlayer();
          await beepPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3'));
        } catch (_) {}

        setState(() {
          _isConnected = true;
          _secondsElapsed = 0;
        });

        _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _secondsElapsed++;
            });
          }
        });
      }
    });
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    await Permission.microphone.request();

    if (availableDeviceCameras.isEmpty) {
      try {
        availableDeviceCameras = await availableCameras();
      } catch (e) {
        debugPrint('Camera fetch error: $e');
      }
    }

    if (availableDeviceCameras.isNotEmpty) {
      final frontIdx = availableDeviceCameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _selectedCameraIndex = frontIdx != -1 ? frontIdx : 0;

      await _setupCameraController(availableDeviceCameras[_selectedCameraIndex]);
    }
  }

  Future<void> _setupCameraController(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('CameraController init error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (availableDeviceCameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % availableDeviceCameras.length;
    setState(() {
      _isCameraInitialized = false;
    });
    await _setupCameraController(availableDeviceCameras[_selectedCameraIndex]);
  }

  void _toggleVideo() async {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    if (_isVideoEnabled) {
      await _initCamera();
    } else {
      await _cameraController?.dispose();
      _cameraController = null;
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _ringtonePlayer.dispose();
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.teammate['name'] ?? 'Teammate';
    final String role = widget.teammate['role'] ?? 'Colleague';
    final String avatar = widget.teammate['avatar'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF171B2B),
      body: SafeArea(
        child: Stack(
          children: [
            // Background Video Stream or Audio Pulse
            if (_isVideoEnabled && _isCameraInitialized && _cameraController != null)
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF95416C).withValues(alpha: 0.5),
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 64,
                          backgroundColor: const Color(0xFFFFF0EB),
                          child: (avatar.startsWith('http') || (avatar.isNotEmpty && File(avatar).existsSync()))
                              ? ClipOval(
                                  child: avatar.startsWith('http')
                                      ? Image.network(avatar, fit: BoxFit.cover, width: 128, height: 128)
                                      : Image.file(File(avatar), fit: BoxFit.cover, width: 128, height: 128),
                                )
                              : Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFAB3500),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

            // Top Header Bar
            Positioned(
              top: 12,
              left: 16,
              right: 16,
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
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isConnected ? const Color(0xFF10B981) : Colors.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected ? _formatDuration(_secondsElapsed) : 'Ringing...',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isVideoEnabled && availableDeviceCameras.length > 1)
                    IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(
                        Icons.flip_camera_ios_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Bottom Call Control Bar
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2438).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute / Unmute
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                        });
                      },
                      icon: Icon(
                        _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: _isMuted ? Colors.redAccent : Colors.white,
                        size: 26,
                      ),
                    ),
                    // Video Toggle
                    IconButton(
                      onPressed: _toggleVideo,
                      icon: Icon(
                        _isVideoEnabled
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        color: _isVideoEnabled ? const Color(0xFF10B981) : Colors.white,
                        size: 26,
                      ),
                    ),
                    // Speaker Toggle
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isSpeakerOn = !_isSpeakerOn;
                        });
                      },
                      icon: Icon(
                        _isSpeakerOn
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    // End Call
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
