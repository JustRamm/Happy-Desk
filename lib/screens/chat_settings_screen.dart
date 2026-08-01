import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ChatSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> teammate;

  const ChatSettingsScreen({super.key, required this.teammate});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  bool _isMuted = false;
  bool _isBlocked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final partnerName = widget.teammate['name'] ?? 'Teammate';
      setState(() {
        _isMuted = prefs.getBool('mute_chat_$partnerName') ?? false;
        _isBlocked = prefs.getBool('block_chat_$partnerName') ?? false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading chat settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMute(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final partnerName = widget.teammate['name'] ?? 'Teammate';
    await prefs.setBool('mute_chat_$partnerName', value);
    if (!mounted) return;
    setState(() {
      _isMuted = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Chat muted.' : 'Chat unmuted.'),
        backgroundColor: AppTheme.primaryRust,
      ),
    );
  }

  Future<void> _toggleBlock() async {
    final prefs = await SharedPreferences.getInstance();
    final partnerName = widget.teammate['name'] ?? 'Teammate';
    final newValue = !_isBlocked;
    await prefs.setBool('block_chat_$partnerName', newValue);
    if (!mounted) return;
    setState(() {
      _isBlocked = newValue;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newValue ? '$partnerName blocked.' : '$partnerName unblocked.'),
        backgroundColor: AppTheme.primaryRust,
      ),
    );
  }

  Future<void> _clearChatHistory() async {
    final partnerName = widget.teammate['name'] ?? 'Teammate';

    // Show confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Clear Chat History?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.titleDark),
        ),
        content: Text(
          'This will permanently delete all messages in this conversation. This action cannot be undone.',
          style: GoogleFonts.beVietnamPro(fontSize: 14, color: AppTheme.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRust,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Clear', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.instance.deleteConversationWith(partnerName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat history cleared!'),
              backgroundColor: Color(0xFF00AE88),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error clearing chat history: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.teammate['name'] ?? 'Teammate';
    final role = widget.teammate['role'] ?? widget.teammate['job_title'] ?? 'Employee';
    final dept = widget.teammate['department'] ?? widget.teammate['team'] ?? 'General';
    final avatar = widget.teammate['avatar'] ?? widget.teammate['avatar_url'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: Text(
          'Contact Info',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: AppTheme.titleDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.titleDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryRust,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Profile Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE4E7FE)),
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: const Color(0xFFFFF0EB),
                            backgroundImage: avatar.isNotEmpty && avatar.startsWith('http')
                                ? NetworkImage(avatar)
                                : null,
                            child: avatar.isEmpty || !avatar.startsWith('http')
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryRust,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Name
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.titleDark,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Role
                          Text(
                            role,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryRust,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Department Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              dept,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF5B3FF2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Configuration Options
                    Text(
                      'CONVERSATION OPTIONS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE4E7FE)),
                      ),
                      child: Column(
                        children: [
                          // Mute Toggle
                          SwitchListTile.adaptive(
                            title: Text(
                              'Mute Notifications',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.titleDark,
                              ),
                            ),
                            subtitle: Text(
                              'Silence alerts from this contact',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            secondary: const Icon(Icons.notifications_off_outlined, color: AppTheme.titleDark),
                            activeTrackColor: AppTheme.primaryRust,
                            value: _isMuted,
                            onChanged: _toggleMute,
                          ),
                          const Divider(height: 1, indent: 56),

                          // Clear Chat
                          ListTile(
                            leading: const Icon(Icons.delete_sweep_outlined, color: AppTheme.titleDark),
                            title: Text(
                              'Clear Chat History',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.titleDark,
                              ),
                            ),
                            subtitle: Text(
                              'Delete all messages permanently',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            onTap: _clearChatHistory,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Block Section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE4E7FE)),
                      ),
                      child: ListTile(
                        leading: Icon(
                          _isBlocked ? Icons.lock_open_rounded : Icons.block_flipped,
                          color: AppTheme.primaryRust,
                        ),
                        title: Text(
                          _isBlocked ? 'Unblock Contact' : 'Block Contact',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryRust,
                          ),
                        ),
                        subtitle: Text(
                          _isBlocked
                              ? 'Allow receiving messages from this user'
                              : 'Stop receiving messages from this user',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        onTap: _toggleBlock,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
