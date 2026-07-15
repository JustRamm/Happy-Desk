import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/coffee_notification_store.dart';

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

  @override
  void initState() {
    super.initState();

    // Rich mock conversation history with file, image, and voice notes
    _messages.addAll([
      {
        'text': 'Hey there! How is the project going today?',
        'isUser': false,
        'time': '10:10 AM',
      },
      {
        'text':
            'Going great! Just wrapping up the new U & ME design architecture.',
        'isUser': true,
        'time': '10:12 AM',
      },
      {
        'text': 'Sent the pull request for review.',
        'isUser': false,
        'time': '10:14 AM',
        'attachmentType': 'file',
        'attachmentName': 'U_ME_Architecture_Spec.pdf',
        'attachmentSize': '2.4 MB',
      },
      {
        'text': 'Here is the preliminary UI mockup screenshot:',
        'isUser': false,
        'time': '10:15 AM',
        'attachmentType': 'image',
        'attachmentName': 'dashboard_v2_mockup.png',
        'attachmentUrl':
            'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=600&q=80',
      },
      {
        'text': '',
        'isUser': true,
        'time': '10:18 AM',
        'attachmentType': 'voice',
        'voiceDuration': '0:22',
      },
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _stagedAttachment == null) return;

    setState(() {
      final newMsg = <String, dynamic>{
        'text': text,
        'isUser': true,
        'time': 'Just now',
      };

      if (_stagedAttachment != null) {
        newMsg['attachmentType'] = _stagedAttachment!['type'];
        newMsg['attachmentName'] = _stagedAttachment!['name'];
        newMsg['attachmentSize'] = _stagedAttachment!['size'];
        newMsg['attachmentUrl'] = _stagedAttachment!['url'];
        newMsg['voiceDuration'] = _stagedAttachment!['duration'];
      }

      _messages.add(newMsg);
      _messageController.clear();
      _stagedAttachment = null;
    });
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
                  _buildAttachmentTile(
                    icon: Icons.poll_rounded,
                    label: 'Team Poll',
                    color: const Color(0xFF95416C),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Quick Poll tool opened!',
                            style: GoogleFonts.beVietnamPro(),
                          ),
                          backgroundColor: const Color(0xFF95416C),
                        ),
                      );
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

  void _triggerIndividualCoffeeReset() {
    final name = widget.teammate['name'] ?? 'Teammate';
    final avatar = widget.teammate['avatar'];

    CoffeeNotificationStore.addCoffeeInvite(
      senderName: name,
      senderAvatar: avatar,
      message: '$name sent you a 1-on-1 coffee break invitation!',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.local_cafe_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Coffee break invitation sent to $name! Added to notifications.',
                style: GoogleFonts.beVietnamPro(fontSize: 13.5),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B35),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.teammate['name'] ?? 'David Kim';
    final role = widget.teammate['role'] ?? 'Frontend Architect';
    final avatar =
        widget.teammate['avatar'] ?? 'assets/avatars/user_avatar.png';
    final isOnline = widget.teammate['isOnline'] == true;

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
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFFDBD0),
                  backgroundImage: AssetImage(avatar),
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
        actions: [
          IconButton(
            tooltip: 'Send Coffee Break Invite',
            onPressed: _triggerIndividualCoffeeReset,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_cafe_rounded,
                color: Color(0xFFFF6B35),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Messages Feed
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] == true;
                final attachmentType = msg['attachmentType'];

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
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
                        Text(
                          msg['time'],
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 10.5,
                            color:
                                isUser ? Colors.white70 : const Color(0xFF8D7168),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
            return const Center(
              child: Icon(Icons.image_not_supported_rounded, color: Colors.grey),
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
}
