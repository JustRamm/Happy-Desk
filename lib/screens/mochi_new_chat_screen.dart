import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/mochi_chat_storage_service.dart';

class MochiNewChatScreen extends StatefulWidget {
  const MochiNewChatScreen({super.key});

  @override
  State<MochiNewChatScreen> createState() => _MochiNewChatScreenState();
}

class _MochiNewChatScreenState extends State<MochiNewChatScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedTopic = 'General Workplace Support';
  bool _isCreating = false;

  final List<Map<String, String>> _topicPresets = [
    {
      'title': 'General Workplace Support',
      'desc': 'Talk through stress, daily friction, or just check in.',
      'icon': 'chat',
    },
    {
      'title': 'Stress & Burnout Reset',
      'desc': 'Unpack heavy workload, pressure, or physical fatigue.',
      'icon': 'fire',
    },
    {
      'title': 'Manager & Team Dynamics',
      'desc': 'Discuss boundary setting, awkward situations, or conflict.',
      'icon': 'people',
    },
    {
      'title': 'Quiet Vent & Decompress',
      'desc': 'Express feelings safely without judgment or forced fixes.',
      'icon': 'shield',
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = 'New Chat Session';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    setState(() => _isCreating = true);
    final customName = _nameController.text.trim();
    final topic = customName.isNotEmpty ? customName : _selectedTopic;

    final newSession = await MochiChatStorageService.instance.createNewSession(
      initialTopic: topic,
    );

    if (mounted) {
      Navigator.pop(context, newSession.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF171B2B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Start New Chat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF171B2B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Name Field
            Text(
              'CHAT NAME',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF171B2B),
              ),
              decoration: InputDecoration(
                hintText: 'e.g., Mindful Break, Project Stress...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFAB3500), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Select Topic Template
            Text(
              'SELECT CHAT FOCUS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            ..._topicPresets.map((preset) {
              final isSelected = _selectedTopic == preset['title'];
              IconData iconData = Icons.chat_bubble_outline_rounded;
              if (preset['icon'] == 'fire') iconData = Icons.local_fire_department_rounded;
              if (preset['icon'] == 'people') iconData = Icons.people_outline_rounded;
              if (preset['icon'] == 'shield') iconData = Icons.shield_outlined;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFAB3500) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    setState(() {
                      _selectedTopic = preset['title']!;
                      if (_nameController.text == 'New Chat Session' ||
                          _topicPresets.any((p) => p['title'] == _nameController.text)) {
                        _nameController.text = preset['title']!;
                      }
                    });
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFF0EB) : const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: isSelected ? const Color(0xFFAB3500) : const Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    preset['title']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: const Color(0xFF171B2B),
                    ),
                  ),
                  subtitle: Text(
                    preset['desc']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  trailing: Radio<String>(
                    value: preset['title']!,
                    groupValue: _selectedTopic,
                    activeColor: const Color(0xFFAB3500),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedTopic = val;
                        });
                      }
                    },
                  ),
                ),
              );
            }),

            const SizedBox(height: 28),

            // Start Chat Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAB3500),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isCreating ? null : _handleCreate,
                child: _isCreating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Start Conversation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
