import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import '../../services/supabase_service.dart';

class CallScreen extends StatefulWidget {
  final Map<String, dynamic> teammate;
  final bool isVideoCall;
  final Map<String, dynamic>? callInviteData;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.teammate,
    this.isVideoCall = false,
    this.callInviteData,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  // WebRTC Peer Connection & Renderers
  webrtc.RTCPeerConnection? _peerConnection;
  webrtc.MediaStream? _localStream;
  webrtc.MediaStream? _remoteStream;
  final webrtc.RTCVideoRenderer _localRenderer = webrtc.RTCVideoRenderer();
  final webrtc.RTCVideoRenderer _remoteRenderer = webrtc.RTCVideoRenderer();
  RealtimeChannel? _signalingChannel;
  RealtimeChannel? _callStatusChannel;

  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  int _secondsElapsed = 0;
  Timer? _callTimer;
  bool _isConnected = false;
  bool _isDeclined = false;

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

    _initWebRTC();

    if (widget.isIncoming) {
      _isConnected = true;
      _startCallTimer();
    } else {
      _startRinging();
      _listenToCallStatus();
    }
  }

  Future<void> _initWebRTC() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      await Permission.microphone.request();
      if (widget.isVideoCall) {
        await Permission.camera.request();
      }

      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': widget.isVideoCall
            ? {
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': [],
              }
            : false,
      };

      try {
        _localStream = await webrtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
        _localRenderer.srcObject = _localStream;
      } catch (e) {
        debugPrint('[WebRTC] Error obtaining local audio/video media stream: $e');
      }

      final configuration = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'},
          {'urls': 'stun:stun3.l.google.com:19302'},
          {'urls': 'stun:stun4.l.google.com:19302'},
        ]
      };

      _peerConnection = await webrtc.createPeerConnection(configuration);

      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection?.addTrack(track, _localStream!);
        });
      }

      _peerConnection?.onTrack = (event) {
        if (event.track.kind == 'audio' || event.track.kind == 'video') {
          if (event.streams.isNotEmpty) {
            _remoteStream = event.streams[0];
            _remoteRenderer.srcObject = _remoteStream;
            if (mounted) setState(() {});
          }
        }
      };

      _peerConnection?.onIceCandidate = (candidate) {
        _sendSignalingMessage('candidate', {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMlineIndex': candidate.sdpMLineIndex,
        });
      };

      _subscribeToSignaling();
    } catch (e) {
      debugPrint('[WebRTC] Init error: $e');
    }
  }

  void _subscribeToSignaling() {
    final callId = widget.callInviteData?['id']?.toString() ?? 'call_${widget.teammate['name']}';
    _signalingChannel = SupabaseService.instance.client.channel('webrtc_signaling_$callId');

    _signalingChannel?.onBroadcast(
      event: 'webrtc_signal',
      callback: (payload) async {
        if (!mounted) return;
        final type = payload['type'];
        final data = payload['data'];
        if (data == null) return;

        if (type == 'offer' && widget.isIncoming) {
          await _handleOffer(Map<String, dynamic>.from(data as Map));
        } else if (type == 'answer' && !widget.isIncoming) {
          await _handleAnswer(Map<String, dynamic>.from(data as Map));
        } else if (type == 'candidate') {
          await _handleCandidate(Map<String, dynamic>.from(data as Map));
        }
      },
    ).subscribe();
  }

  Future<void> _sendSignalingMessage(String type, Map<String, dynamic> data) async {
    try {
      await _signalingChannel?.sendBroadcastMessage(
        event: 'webrtc_signal',
        payload: {
          'type': type,
          'data': data,
        },
      );
    } catch (e) {
      debugPrint('[WebRTC] Signaling send error: $e');
    }
  }

  Future<void> _createAndSendOffer() async {
    if (_peerConnection == null) return;
    try {
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': widget.isVideoCall ? 1 : 0,
      });
      await _peerConnection!.setLocalDescription(offer);
      await _sendSignalingMessage('offer', {'sdp': offer.sdp, 'type': offer.type});
    } catch (e) {
      debugPrint('[WebRTC] Create offer error: $e');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;
    try {
      final sdp = data['sdp'] as String?;
      final type = data['type'] as String?;
      if (sdp == null || type == null) return;

      await _peerConnection!.setRemoteDescription(webrtc.RTCSessionDescription(sdp, type));

      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': widget.isVideoCall ? 1 : 0,
      });
      await _peerConnection!.setLocalDescription(answer);
      await _sendSignalingMessage('answer', {'sdp': answer.sdp, 'type': answer.type});
    } catch (e) {
      debugPrint('[WebRTC] Handle offer error: $e');
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;
    try {
      final sdp = data['sdp'] as String?;
      final type = data['type'] as String?;
      if (sdp == null || type == null) return;

      await _peerConnection!.setRemoteDescription(webrtc.RTCSessionDescription(sdp, type));
    } catch (e) {
      debugPrint('[WebRTC] Handle answer error: $e');
    }
  }

  Future<void> _handleCandidate(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;
    try {
      final candidateStr = data['candidate'] as String?;
      final sdpMid = data['sdpMid'] as String?;
      final sdpMLineIndex = data['sdpMlineIndex'] as int?;
      if (candidateStr == null) return;

      final candidate = webrtc.RTCIceCandidate(candidateStr, sdpMid, sdpMLineIndex);
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      debugPrint('[WebRTC] Handle candidate error: $e');
    }
  }

  void _listenToCallStatus() {
    final callId = widget.callInviteData?['id']?.toString();
    if (callId == null || callId.isEmpty) return;

    _callStatusChannel = SupabaseService.instance.subscribeToCallStatus(
      callId: callId,
      onStatusChange: (status) async {
        if (!mounted) return;
        if (status == 'accepted') {
          await _ringtonePlayer.stop();
          try {
            final beepPlayer = AudioPlayer();
            await beepPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3'));
          } catch (_) {}

          setState(() {
            _isConnected = true;
            _secondsElapsed = 0;
          });
          _startCallTimer();
          _createAndSendOffer();
        } else if (status == 'rejected' || status == 'ended') {
          await _ringtonePlayer.stop();
          setState(() {
            _isDeclined = true;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      },
    );
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  Future<void> _startRinging() async {
    try {
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/1359/1359-preview.mp3'));
    } catch (e) {
      debugPrint('Error playing calling ringtone: $e');
    }
  }

  Future<void> _endCall() async {
    await _ringtonePlayer.stop();
    final callId = widget.callInviteData?['id']?.toString();
    if (callId != null && callId.isNotEmpty) {
      await SupabaseService.instance.updateCallStatus(
        callId: callId,
        status: _isConnected ? 'ended' : 'rejected',
      );
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _switchCamera() async {
    if (_localStream != null && widget.isVideoCall) {
      final videoTrack = _localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        await webrtc.Helper.switchCamera(videoTrack);
      }
    }
  }

  void _toggleVideo() {
    HapticFeedback.selectionClick();
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
      if (_localStream != null) {
        for (var track in _localStream!.getVideoTracks()) {
          track.enabled = _isVideoEnabled;
        }
      }
    });
  }

  void _toggleMute() {
    HapticFeedback.selectionClick();
    setState(() {
      _isMuted = !_isMuted;
      if (_localStream != null) {
        for (var track in _localStream!.getAudioTracks()) {
          track.enabled = !_isMuted;
        }
      }
    });
  }

  void _toggleSpeaker() {
    HapticFeedback.selectionClick();
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
      webrtc.Helper.setSpeakerphoneOn(_isSpeakerOn);
    });
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _ringtonePlayer.stop();
    _ringtonePlayer.dispose();
    _callTimer?.cancel();
    _pulseController.dispose();

    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
    _remoteStream?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();

    if (_signalingChannel != null) {
      SupabaseService.instance.client.removeChannel(_signalingChannel!);
    }
    if (_callStatusChannel != null) {
      SupabaseService.instance.client.removeChannel(_callStatusChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.teammate['name'] ?? 'Teammate';
    final String role = widget.teammate['role'] ?? 'Colleague';
    final String avatar = widget.teammate['avatar'] ?? '';

    final bool showRemoteVideo = _isVideoEnabled && _remoteRenderer.srcObject != null;
    final bool showLocalVideo = _isVideoEnabled && _localRenderer.srcObject != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF), // Warm light ambient background
      body: SafeArea(
        child: Stack(
          children: [
            // Soft Ambient Background Gradient Glows (Only shown in Audio Mode)
            if (!showRemoteVideo && !showLocalVideo) ...[
              Positioned(
                top: -60,
                left: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFF0EB).withValues(alpha: 0.7),
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                right: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF3F2FF).withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],

            // Video Stream Views or Voice Call Avatar Center Screen
            if (showRemoteVideo)
              Positioned.fill(
                child: webrtc.RTCVideoView(
                  _remoteRenderer,
                  objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else if (showLocalVideo)
              Positioned.fill(
                child: webrtc.RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFAB3500).withValues(alpha: 0.25),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFAB3500).withValues(alpha: 0.12),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 64,
                          backgroundColor: const Color(0xFFFFF0EB),
                          child: (avatar.startsWith('http') || (avatar.isNotEmpty && File(avatar).existsSync()))
                              ? ClipOval(
                                  child: avatar.startsWith('http')
                                      ? Image.network(
                                          avatar,
                                          fit: BoxFit.cover,
                                          width: 128,
                                          height: 128,
                                          errorBuilder: (context, error, stackTrace) => Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 48,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFFAB3500),
                                            ),
                                          ),
                                        )
                                      : Image.file(
                                          File(avatar),
                                          fit: BoxFit.cover,
                                          width: 128,
                                          height: 128,
                                          errorBuilder: (context, error, stackTrace) => Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 48,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFFAB3500),
                                            ),
                                          ),
                                        ),
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
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF171B2B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8D7168),
                      ),
                    ),
                  ],
                ),
              ),

            // Inset Picture-in-Picture Local Video View (When Remote Video active)
            if (showRemoteVideo && showLocalVideo)
              Positioned(
                top: 70,
                right: 20,
                width: 100,
                height: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: webrtc.RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
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
                    onPressed: _endCall,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF171B2B),
                        size: 22,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE4E7FE)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF95416C).withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isConnected
                                ? const Color(0xFF10B981)
                                : (_isDeclined ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected
                              ? _formatDuration(_secondsElapsed)
                              : (_isDeclined ? 'Call Declined' : 'Ringing...'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF171B2B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isVideoEnabled)
                    IconButton(
                      onPressed: _switchCamera,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: Color(0xFF95416C),
                          size: 20,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 44),
                ],
              ),
            ),

            // Bottom Call Control Bar
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFE4E7FE), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF95416C).withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute / Unmute
                    GestureDetector(
                      onTap: _toggleMute,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isMuted ? const Color(0xFFFEE2E2) : const Color(0xFFFFF0EB),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          color: _isMuted ? const Color(0xFFEF4444) : const Color(0xFFAB3500),
                          size: 22,
                        ),
                      ),
                    ),
                    // Video Toggle
                    GestureDetector(
                      onTap: _toggleVideo,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: !_isVideoEnabled ? const Color(0xFFFEE2E2) : const Color(0xFFF3F2FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isVideoEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                          color: !_isVideoEnabled ? const Color(0xFFEF4444) : const Color(0xFF95416C),
                          size: 22,
                        ),
                      ),
                    ),
                    // Speaker Toggle
                    GestureDetector(
                      onTap: _toggleSpeaker,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: !_isSpeakerOn ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: !_isSpeakerOn ? const Color(0xFF64748B) : const Color(0xFF1D4ED8),
                          size: 22,
                        ),
                      ),
                    ),
                    // End Call
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x40EF4444),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 24,
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
