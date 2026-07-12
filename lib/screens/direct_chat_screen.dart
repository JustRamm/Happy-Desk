import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DirectChatScreen extends StatefulWidget {
  final Map<String, dynamic> teammate;

  const DirectChatScreen({super.key, required this.teammate});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Default conversation history for mock demonstration
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
        'text': widget.teammate['lastMessage'] ??
            'Let\'s catch up after the team sync call.',
        'isUser': false,
        'time': widget.teammate['time'] ?? '10:14 AM',
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
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'time': 'Just now',
      });
      _messageController.clear();
    });
  }

  void _triggerIndividualCoffeeReset() {
    final name = widget.teammate['name'] ?? 'Teammate';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.local_cafe_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Coffee break invitation sent to $name!',
                style: GoogleFonts.beVietnamPro(fontSize: 13.5),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF95416C),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.teammate['name'] ?? 'Teammate';
    final role = widget.teammate['role'] ?? 'Colleague';
    final avatar = widget.teammate['avatar'] ?? 'assets/avatars/user_avatar.png';
    final isOnline = widget.teammate['isOnline'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF171B2B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFFF0EB),
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
                        color: const Color(0xFF00AE88),
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
                      color: const Color(0xFF171B2B),
                    ),
                  ),
                  Text(
                    role,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11.5,
                      color: const Color(0xFF594139),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // TOP RIGHT COFFEE ICON: Sends 1-on-1 coffee break invitation!
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
                color: Color(0xFF95416C),
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

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.76,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFFAB3500)
                          : Colors.white,
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
                              ? const Color(0x33AB3500)
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
                        Text(
                          msg['text'],
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            color: isUser ? Colors.white : const Color(0xFF171B2B),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time'],
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 10.5,
                            color: isUser
                                ? Colors.white70
                                : const Color(0xFF8D7168),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE4E7FE)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
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
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFAB3500),
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
}
