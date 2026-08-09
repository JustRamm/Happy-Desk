import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'audio_video_call_screen.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  List<Map<String, dynamic>> _callLogs = [];
  bool _isLoading = true;
  RealtimeChannel? _historySubscription;

  @override
  void initState() {
    super.initState();
    _fetchCallHistory();
    _subscribeToLiveUpdates();
  }

  void _subscribeToLiveUpdates() {
    _historySubscription = SupabaseService.instance.subscribeToCallHistory(
      onHistoryChanged: () {
        if (mounted) {
          _fetchCallHistory(showLoading: false);
        }
      },
    );
  }

  @override
  void dispose() {
    if (_historySubscription != null) {
      SupabaseService.instance.client.removeChannel(_historySubscription!);
    }
    super.dispose();
  }

  Future<void> _fetchCallHistory({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    final logs = await SupabaseService.instance.getCallHistory();
    if (mounted) {
      setState(() {
        _callLogs = logs;
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(rawTime).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dt);

      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final timeStr = '$hour:$minute $period';

      if (difference.inDays == 0 && dt.day == now.day) {
        return 'Today at $timeStr';
      } else if (difference.inDays == 1 || (difference.inDays == 0 && dt.day != now.day)) {
        return 'Yesterday at $timeStr';
      } else {
        return '${dt.day}/${dt.month}/${dt.year} at $timeStr';
      }
    } catch (_) {
      return 'Recent';
    }
  }

  void _startCall({required Map<String, dynamic> partnerData, required bool isVideo}) {
    final partnerName = partnerData['partner_name'] ?? 'Teammate';
    final partnerAvatar = partnerData['partner_avatar'] ?? '';
    final partnerId = partnerData['partner_id'] ?? '';
    final partnerRole = partnerData['partner_role'] ?? 'Teammate';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioVideoCallScreen(
          teammate: {
            'id': partnerId,
            'name': partnerName,
            'avatar': partnerAvatar,
            'role': partnerRole,
          },
          isVideoCall: isVideo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3142), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Call History',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF171B2B),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchCallHistory,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryRust),
            tooltip: 'Refresh Call History',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRust),
            )
          : _callLogs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchCallHistory,
                  color: AppTheme.primaryRust,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemCount: _callLogs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildCallLogTile(_callLogs[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildCallLogTile(Map<String, dynamic> call) {
    final String partnerName = call['partner_name'] ?? 'Teammate';
    final String partnerAvatar = call['partner_avatar'] ?? '';
    final String partnerRole = call['partner_role'] ?? 'Teammate';
    final bool isVideo = call['is_video'] == true;
    final bool isOutgoing = call['is_outgoing'] == true;
    final String status = (call['status'] as String? ?? 'ended').toLowerCase();
    final String timeText = _formatTimestamp(call['created_at']?.toString());

    final bool isDeclinedOrMissed = status == 'rejected' || status == 'missed' || (status == 'ringing' && !isOutgoing);

    // Call direction icon & status color
    IconData directionIcon;
    Color directionColor;
    String statusLabel;

    if (isDeclinedOrMissed) {
      directionIcon = isOutgoing ? Icons.call_missed_outgoing_rounded : Icons.call_missed_rounded;
      directionColor = const Color(0xFFEF4444); // Red
      statusLabel = status == 'rejected' ? 'Declined' : 'Missed';
    } else if (isOutgoing) {
      directionIcon = Icons.call_made_rounded;
      directionColor = const Color(0xFF3B82F6); // Blue
      statusLabel = status == 'accepted' ? 'Accepted' : 'Outgoing';
    } else {
      directionIcon = Icons.call_received_rounded;
      directionColor = const Color(0xFF10B981); // Emerald Green
      statusLabel = status == 'accepted' ? 'Accepted' : 'Incoming';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7FE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Teammate Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFFF0EB),
                child: (partnerAvatar.startsWith('http') || (partnerAvatar.isNotEmpty && File(partnerAvatar).existsSync()))
                    ? ClipOval(
                        child: partnerAvatar.startsWith('http')
                            ? Image.network(partnerAvatar, fit: BoxFit.cover, width: 48, height: 48)
                            : Image.file(File(partnerAvatar), fit: BoxFit.cover, width: 48, height: 48),
                      )
                    : Text(
                        partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFAB3500),
                        ),
                      ),
              ),

              // Call Type Pill Overlay (Video camera vs Phone icon)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryRust,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF171B2B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (partnerRole.isNotEmpty)
                  Text(
                    partnerRole,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11.5,
                      color: const Color(0xFF8D7168),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    Icon(directionIcon, size: 14, color: directionColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: directionColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '•  $timeText',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11.5,
                        color: const Color(0xFF8D7168),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Return Call Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Voice Call Return
              IconButton(
                onPressed: () => _startCall(partnerData: call, isVideo: false),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_rounded,
                    color: AppTheme.primaryRust,
                    size: 18,
                  ),
                ),
                tooltip: 'Return Voice Call',
              ),

              // Video Call Return
              IconButton(
                onPressed: () => _startCall(partnerData: call, isVideo: true),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Color(0xFF95416C),
                    size: 18,
                  ),
                ),
                tooltip: 'Return Video Call',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_disabled_rounded,
                size: 54,
                color: AppTheme.primaryRust,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Call History Yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your incoming and outgoing voice and video call logs with your teammates will automatically appear here in real time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.5,
                color: const Color(0xFF8D7168),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
