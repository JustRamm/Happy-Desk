import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../services/sound_service.dart';
import 'call_screen.dart';
import 'chat_settings_screen.dart';
import '../../services/offline_sync_service.dart';
import '../../theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DirectChatScreen extends StatefulWidget {
  final Map<String, dynamic> teammate;

  const DirectChatScreen({super.key, required this.teammate});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  // Currently staged attachment preview before sending
  Map<String, dynamic>? _stagedAttachment;
  bool _isPlayingVoice = false;
  final bool _isTeammateTyping = false;
  bool _isPartnerClockedIn = false;
  String? _partnerAvatarUrl;

  RealtimeChannel? _chatChannel;
  bool _isMuted = false;
  bool _isBlocked = false;

  void _toggleMute() {
    final name = widget.teammate['name'] ?? 'Teammate';
    setState(() => _isMuted = !_isMuted);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isMuted ? 'Muted notifications for $name' : 'Unmuted notifications for $name',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2D3142),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmBlockUser() {
    final name = widget.teammate['name'] ?? 'Teammate';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF171B2B),
        title: Text(
          _isBlocked ? 'Unblock $name?' : 'Block $name?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        content: Text(
          _isBlocked
              ? 'You will be able to send and receive messages with $name again.'
              : 'They will not be able to message or call you on Happy Desk.',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isBlocked ? const Color(0xFF00C49A) : const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isBlocked = !_isBlocked);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isBlocked ? '$name has been blocked' : '$name has been unblocked'),
                  backgroundColor: _isBlocked ? const Color(0xFFDC2626) : const Color(0xFF00C49A),
                ),
              );
            },
            child: Text(_isBlocked ? 'Unblock' : 'Block', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChat() {
    final name = widget.teammate['name'] ?? 'Teammate';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF171B2B),
        title: Text(
          'Delete Chat?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        content: Text(
          'This will permanently delete all messages in your conversation with $name.',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.instance.deleteDirectMessageConversation(partnerName: name);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SoundService.playMessageOpenSound();
    _loadSupabaseMessages();
    _subscribeToMessages();
  }

  void _subscribeToMessages() {
    final partnerName = (widget.teammate['name'] ?? 'Teammate').toString().trim();
    _chatChannel = SupabaseService.instance.subscribeToDirectMessages(
      partnerName: partnerName,
      onNewMessage: (msgData) {
        if (!mounted) return;
        final sender = (msgData['sender_name'] as String? ?? '').trim();
        final text = msgData['message'] ?? '';
        final isUser = sender.toLowerCase() != partnerName.toLowerCase();

        // Avoid adding duplicate messages if we already showed it locally when sending
        final isDuplicate = _messages.any((m) =>
            m['text'] == text &&
            m['isUser'] == isUser &&
            (m['time'] == 'Now' || m['time'] == (msgData['created_at'] != null ? msgData['created_at'].toString().split('T').last.substring(0, 5) : '')));

        if (!isDuplicate) {
          setState(() {
            _messages.add({
              'text': text,
              'isUser': isUser,
              'time': msgData['created_at'] != null
                  ? msgData['created_at'].toString().split('T').last.substring(0, 5)
                  : 'Now',
              'status': msgData['is_read'] == true ? 'read' : 'delivered',
              if (msgData['media_url'] != null) 'attachmentType': 'image',
              if (msgData['media_url'] != null) 'attachmentUrl': msgData['media_url'],
            });
          });
        } else {
          // Update status of our local message to delivered/read
          setState(() {
            final idx = _messages.indexWhere((m) =>
                m['text'] == text &&
                m['isUser'] == isUser &&
                m['status'] == 'sent');
            if (idx != -1) {
              _messages[idx]['status'] = msgData['is_read'] == true ? 'read' : 'delivered';
            }
          });
        }
      },
    );
  }

  Future<void> _loadSupabaseMessages() async {
    final name = (widget.teammate['name'] ?? 'Teammate').toString().trim();
    await SupabaseService.instance.markDirectMessagesAsRead(name);

    final cleanName = name.toLowerCase();
    try {
      final teammates = await SupabaseService.instance.getCompanyTeammates();
      final partnerProfile = teammates.firstWhere(
        (t) => (t['name'] as String? ?? '').trim().toLowerCase() == cleanName,
        orElse: () => {},
      );
      if (partnerProfile.isNotEmpty && mounted) {
        setState(() {
          _isPartnerClockedIn = partnerProfile['is_clocked_in'] == true;
          final av = (partnerProfile['avatar_url'] as String? ?? '').trim();
          if (av.isNotEmpty) {
            _partnerAvatarUrl = av;
          }
        });
      }
    } catch (_) {}

    final dbMessages = await SupabaseService.instance.getDirectMessages();
    if (dbMessages.isNotEmpty) {
      final filtered = dbMessages.where((m) {
        final sender = (m['sender_name'] as String? ?? '').trim().toLowerCase();
        final receiver = (m['receiver_name'] as String? ?? '').trim().toLowerCase();
        return sender == cleanName || receiver == cleanName;
      }).toList();

      if (filtered.isNotEmpty && mounted) {
        setState(() {
          _messages.clear();
          for (var m in filtered) {
            final isRead = m['is_read'] == true;
            final sender = (m['sender_name'] as String? ?? '').trim().toLowerCase();
            _messages.add({
              'text': m['message'] ?? '',
              'isUser': sender != cleanName,
              'time': m['created_at'] != null ? m['created_at'].toString().split('T').last.substring(0, 5) : 'Now',
              'status': isRead ? 'read' : 'delivered',
              if (m['media_url'] != null) 'attachmentType': 'image',
              if (m['media_url'] != null) 'attachmentUrl': m['media_url'],
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    if (_chatChannel != null) {
      SupabaseService.instance.client.removeChannel(_chatChannel!);
    }
    _messageController.dispose();
    super.dispose();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share Content',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF8D7168)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentTile(
                    icon: Icons.image_rounded,
                    label: 'Image / Media',
                    color: const Color(0xFFFF6B35),
                    onTap: () {
                      Navigator.pop(context);
                      _stageAttachment({
                        'type': 'image',
                        'name': 'office_presentation.png',
                        'url':
                            'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=600&q=80',
                      });
                    },
                  ),
                  _buildAttachmentTile(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Document',
                    color: const Color(0xFF00C49A),
                    onTap: () {
                      Navigator.pop(context);
                      _stageAttachment({
                        'type': 'file',
                        'name': 'Q3_Happiness_Metrics_Report.pdf',
                        'size': '1.8 MB',
                      });
                    },
                  ),
                  _buildAttachmentTile(
                    icon: Icons.mic_rounded,
                    label: 'Voice Note',
                    color: const Color(0xFFFF99C8),
                    onTap: () {
                      Navigator.pop(context);
                      _stageAttachment({
                        'type': 'voice',
                        'name': 'Voice Note',
                        'duration': '0:15',
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  void _stageAttachment(Map<String, dynamic> attachment) {
    setState(() {
      _stagedAttachment = attachment;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _stagedAttachment == null) return;

    SoundService.playMessageSentSound();
    final name = widget.teammate['name'] ?? 'Teammate';
    final String? mediaUrl = _stagedAttachment != null ? _stagedAttachment!['url'] : null;

    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'time': 'Now',
        'status': 'sent',
        if (_stagedAttachment != null) 'attachmentType': _stagedAttachment!['type'],
        if (_stagedAttachment != null) 'attachmentName': _stagedAttachment!['name'],
        if (_stagedAttachment != null) 'attachmentUrl': _stagedAttachment!['url'],
      });
      _stagedAttachment = null;
    });

    _messageController.clear();

    try {
      await SupabaseService.instance.sendDirectMessage(
        receiverName: name,
        message: text,
        mediaUrl: mediaUrl,
      );
      if (mounted) {
        setState(() {
          _messages.last['status'] = 'delivered';
        });
      }
    } catch (e, stack) {
      final String errorDetails = '$e\n\nStacktrace:\n$stack';
      debugPrint('[DirectChatScreen] Error sending direct message: $errorDetails');

      await OfflineSyncService.instance.enqueueAction(
        actionType: 'send_message',
        payload: {
          'receiver_name': name,
          'message': text,
          'media_url': mediaUrl,
        },
      );

      if (mounted) {
        setState(() {
          _messages.last['status'] = 'sent';
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to send message live',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626), // Error Red
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'View More',
              textColor: const Color(0xFFFFD8CC),
              onPressed: () => _showErrorDiagnosticsModal(context, e.toString(), errorDetails),
            ),
          ),
        );
      }
    }
  }

  void _showErrorDiagnosticsModal(BuildContext context, String shortErr, String fullDetails, {String title = 'Message Delivery Error'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bug_report_rounded, color: Color(0xFFDC2626), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF171B2B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Diagnostic Details:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Dark terminal blue
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    fullDetails,
                    style: GoogleFonts.firaCode(
                      fontSize: 11.5,
                      color: const Color(0xFFF8FAFC),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: fullDetails));
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error details copied to clipboard!',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC84B1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(
                    'Copy Diagnostics',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.teammate['name'] ?? 'David Kim';
    final role = widget.teammate['role'] ?? 'Frontend Architect';
    final avatar = (_partnerAvatarUrl != null && _partnerAvatarUrl!.isNotEmpty)
        ? _partnerAvatarUrl!
        : (widget.teammate['avatar'] as String? ?? widget.teammate['avatar_url'] as String? ?? '');
    final isOnline = _isPartnerClockedIn || (widget.teammate['is_clocked_in'] == true);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2D3142), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatSettingsScreen(teammate: widget.teammate),
              ),
            );
          },
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFFFDBD0),
                    child: (avatar.startsWith('http') || (avatar.isNotEmpty && File(avatar).existsSync()))
                        ? ClipOval(
                            child: avatar.startsWith('http')
                                ? Image.network(
                                    avatar,
                                    fit: BoxFit.cover,
                                    width: 36,
                                    height: 36,
                                    errorBuilder: (context, error, stackTrace) => Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFAB3500),
                                      ),
                                    ),
                                  )
                                : Image.file(
                                    File(avatar),
                                    fit: BoxFit.cover,
                                    width: 36,
                                    height: 36,
                                    errorBuilder: (context, error, stackTrace) => Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFAB3500),
                                      ),
                                    ),
                                  ),
                          )
                        : Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
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
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C49A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                    Text(
                      role,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11.5,
                        color: const Color(0xFF4A4E69),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Audio Call',
            onPressed: () async {
              final receiverId = widget.teammate['id']?.toString() ?? '';
              final partnerName = widget.teammate['name']?.toString() ?? 'Teammate';
              Map<String, dynamic>? callRes;
              try {
                callRes = await SupabaseService.instance.createCallInvite(
                  receiverId: receiverId,
                  isVideo: false,
                  receiverName: partnerName,
                );
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallScreen(
                      teammate: widget.teammate,
                      isVideoCall: false,
                      callInviteData: callRes,
                    ),
                  ),
                );
              } catch (e, stack) {
                final String errorDetails = '$e\n\nStacktrace:\n$stack';
                debugPrint('[DirectChatScreen] Error starting voice call: $errorDetails');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Failed to initiate voice call',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      action: SnackBarAction(
                        label: 'View More',
                        textColor: const Color(0xFFFFD8CC),
                        onPressed: () => _showErrorDiagnosticsModal(
                          context,
                          e.toString(),
                          errorDetails,
                          title: 'Voice Call Error',
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_rounded,
                color: Color(0xFFAB3500),
                size: 18,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Video Call',
            onPressed: () async {
              final receiverId = widget.teammate['id']?.toString() ?? '';
              final partnerName = widget.teammate['name']?.toString() ?? 'Teammate';
              Map<String, dynamic>? callRes;
              try {
                callRes = await SupabaseService.instance.createCallInvite(
                  receiverId: receiverId,
                  isVideo: true,
                  receiverName: partnerName,
                );
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallScreen(
                      teammate: widget.teammate,
                      isVideoCall: true,
                      callInviteData: callRes,
                    ),
                  ),
                );
              } catch (e, stack) {
                final String errorDetails = '$e\n\nStacktrace:\n$stack';
                debugPrint('[DirectChatScreen] Error starting video call: $errorDetails');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Failed to initiate video call',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      action: SnackBarAction(
                        label: 'View More',
                        textColor: const Color(0xFFFFD8CC),
                        onPressed: () => _showErrorDiagnosticsModal(
                          context,
                          e.toString(),
                          errorDetails,
                          title: 'Video Call Error',
                        ),
                      ),
                    ),
                  );
                }
              }
            },
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
          ),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF9F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF2D3142),
                size: 20,
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF171B2B),
            onSelected: (val) {
              if (val == 'mute') _toggleMute();
              if (val == 'block') _confirmBlockUser();
              if (val == 'delete') _confirmDeleteChat();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(
                      _isMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                      color: const Color(0xFFFF9E7A),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isMuted ? 'Unmute Notifications' : 'Mute Notifications',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(
                      _isBlocked ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                      color: const Color(0xFFFF99C8),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isBlocked ? 'Unblock Teammate' : 'Block Teammate',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Delete Chat',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFFEF4444), fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Messages Feed
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFFF6B35),
              backgroundColor: Colors.white,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 1000));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                itemCount: _messages.length + (_isTeammateTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTeammateTyping && index == _messages.length) {
                    return _buildTypingIndicatorBubble();
                  }
                  final msg = _messages[index];
                  final isUser = msg['isUser'] == true;
                  final attachmentType = msg['attachmentType'];

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      constraints: BoxConstraints(
                        minWidth: 48,
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFFFF6B35) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        border: isUser
                            ? null
                            : Border.all(color: const Color(0xFFE4E7FE)),
                        boxShadow: [
                          BoxShadow(
                            color: isUser
                                ? const Color(0x33FF6B35)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          // Text Content (if present)
                          if (msg['text'] != null &&
                              (msg['text'] as String).isNotEmpty) ...[
                            Text(
                              msg['text'],
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                color: isUser
                                    ? Colors.white
                                    : const Color(0xFF2D3142),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Attachment Renderers
                          if (attachmentType == 'file')
                            _buildFileBubble(msg, isUser),
                          if (attachmentType == 'image')
                            _buildImageBubble(msg, isUser),
                          if (attachmentType == 'voice')
                            _buildVoiceBubble(msg, isUser),

                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                msg['time'],
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 10.5,
                                  color: isUser ? Colors.white70 : const Color(0xFF8D7168),
                                ),
                              ),
                              if (isUser) ...[
                                const SizedBox(width: 4),
                                _buildStatusIcon(msg['status'] ?? 'sent'),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Staged Attachment Preview Bar (if an item is selected to send)
          if (_stagedAttachment != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF3F2FF),
              child: Row(
                children: [
                  Icon(
                    _stagedAttachment!['type'] == 'file'
                        ? Icons.insert_drive_file_rounded
                        : _stagedAttachment!['type'] == 'image'
                            ? Icons.image_rounded
                            : Icons.mic_rounded,
                    color: const Color(0xFFFF6B35),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Attachment: ${_stagedAttachment!['name'] ?? 'Media Item'}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3142),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _stagedAttachment = null;
                      });
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),

          // Bottom Input Bar with Attachment (+) and Send Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE4E7FE)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment (+) Button
                  IconButton(
                    tooltip: 'Attach File or Media',
                    onPressed: _showAttachmentOptions,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAF8FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFFFF6B35),
                        size: 24,
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Text Field Input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF8FF),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE4E7FE)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.beVietnamPro(fontSize: 14),
                        onTap: () {
                          SystemChannels.textInput.invokeMethod('TextInput.show');
                        },
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: GoogleFonts.beVietnamPro(
                            fontSize: 13.5,
                            color: const Color(0xFF8D7168),
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// File Document Attachment Card
  Widget _buildFileBubble(Map<String, dynamic> msg, bool isUser) {
    final fileName = msg['attachmentName'] ?? 'Document.pdf';
    final fileSize = msg['attachmentSize'] ?? '1.2 MB';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUser
              ? Colors.white.withValues(alpha: 0.3)
              : const Color(0xFFE4E7FE),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUser ? Colors.white : const Color(0xFFFF6B35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color: isUser ? const Color(0xFFFF6B35) : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isUser ? Colors.white : const Color(0xFF2D3142),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fileSize,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: isUser ? Colors.white70 : const Color(0xFF8D7168),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.download_rounded,
            color: isUser ? Colors.white : const Color(0xFFFF6B35),
            size: 20,
          ),
        ],
      ),
    );
  }

  /// Image Media Preview Card
  Widget _buildImageBubble(Map<String, dynamic> msg, bool isUser) {
    final url = msg['attachmentUrl'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        width: double.infinity,
        color: Colors.grey[200],
        child: Image.network(
          url ??
              'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=600&q=80',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFF3F2FF),
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_rounded,
                        color: Color(0xFF95416C), size: 28),
                    const SizedBox(height: 6),
                    Text(
                      'Image Attachment (Offline Preview)',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF594139),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Voice Note Player Card
  Widget _buildVoiceBubble(Map<String, dynamic> msg, bool isUser) {
    final duration = msg['voiceDuration'] ?? '0:18';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _isPlayingVoice = !_isPlayingVoice;
              });
            },
            icon: Icon(
              _isPlayingVoice
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: isUser ? Colors.white : const Color(0xFFFF6B35),
              size: 32,
            ),
          ),
          const SizedBox(width: 4),
          // Waveform bars simulation
          Row(
            children: List.generate(12, (index) {
              final heights = [12.0, 20.0, 14.0, 26.0, 18.0, 30.0, 16.0, 24.0, 12.0, 20.0, 28.0, 14.0];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 3,
                height: heights[index % heights.length],
                decoration: BoxDecoration(
                  color: isUser ? Colors.white70 : const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(width: 10),
          Text(
            duration,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isUser ? Colors.white : const Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'sent') {
      return const Icon(
        Icons.check_rounded,
        size: 13,
        color: Colors.white60,
      );
    } else if (status == 'delivered') {
      return const Icon(
        Icons.done_all_rounded,
        size: 13,
        color: Colors.white60,
      );
    } else {
      // 'read'
      return const Icon(
        Icons.done_all_rounded,
        size: 13,
        color: Color(0xFF64FBCE),
      );
    }
  }

  Widget _buildTypingIndicatorBubble() {
    final name = widget.teammate['name'] ?? 'Teammate';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: const Color(0xFFE4E7FE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$name is typing',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: const Color(0xFF8D7168),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 8),
            const _BouncingDots(),
          ],
        ),
      ),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final double value = (math.sin((_controller.value * math.pi * 2) - (delay * math.pi)) + 1.0) / 2.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 5,
              height: 5,
              transform: Matrix4.translationValues(0, -value * 4, 0),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
