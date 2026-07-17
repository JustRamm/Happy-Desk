import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _masterNotifications = true;
  bool _nglJarAlerts = true;
  bool _coffeeInvites = true;
  bool _heroNominations = true;
  bool _clockInReminders = true;
  bool _teamPulseDigest = false;
  bool _soundFeedback = true;
  bool _vibrationFeedback = true;

  void _savePreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Notification preferences saved successfully!',
                style: GoogleFonts.beVietnamPro(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006C53),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF171B2B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF171B2B),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master Switch Container
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFAB3500),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFAB3500).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allow All Notifications',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Receive instant team updates & breaks',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: const Color(0xFFFFDBD0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _masterNotifications,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFFFF6B35),
                    onChanged: (val) {
                      setState(() {
                        _masterNotifications = val;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Activity & Event Channels',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4E7FE)),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.favorite_rounded,
                    color: const Color(0xFFAB3500),
                    title: 'NGL Jar Appreciation Notes',
                    subtitle: 'Alert when a note is deposited into your jar',
                    value: _nglJarAlerts && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (val) => setState(() => _nglJarAlerts = val)
                        : null,
                  ),
                  const Divider(height: 1, color: Color(0xFFE4E7FE)),
                  _buildSwitchTile(
                    icon: Icons.local_cafe_rounded,
                    color: const Color(0xFF95416C),
                    title: 'Coffee Break Reset Invites',
                    subtitle: 'Alert when a teammate invites you for a coffee break',
                    value: _coffeeInvites && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (val) => setState(() => _coffeeInvites = val)
                        : null,
                  ),
                  const Divider(height: 1, color: Color(0xFFE4E7FE)),
                  _buildSwitchTile(
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFF006C53),
                    title: 'Weekly Hero Nominations',
                    subtitle: 'Alert when you are nominated as Weekly Hero',
                    value: _heroNominations && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (val) => setState(() => _heroNominations = val)
                        : null,
                  ),
                  const Divider(height: 1, color: Color(0xFFE4E7FE)),
                  _buildSwitchTile(
                    icon: Icons.access_time_filled_rounded,
                    color: const Color(0xFFFF9F1C),
                    title: 'Work Session Reminders',
                    subtitle: 'Reminder to clock in at start of workday',
                    value: _clockInReminders && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (val) => setState(() => _clockInReminders = val)
                        : null,
                  ),
                  const Divider(height: 1, color: Color(0xFFE4E7FE)),
                  _buildSwitchTile(
                    icon: Icons.mark_email_read_rounded,
                    color: const Color(0xFF00AE88),
                    title: 'Weekly Morale Digest Email',
                    subtitle: 'Weekly summary email of team happiness metrics',
                    value: _teamPulseDigest && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (val) => setState(() => _teamPulseDigest = val)
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Sounds & Haptics',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4E7FE)),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.volume_up_rounded,
                    color: const Color(0xFF95416C),
                    title: 'In-App Sound Effects',
                    subtitle: 'Play gentle sound effect on paper shred & notes',
                    value: _soundFeedback,
                    onChanged: (val) => setState(() => _soundFeedback = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFE4E7FE)),
                  _buildSwitchTile(
                    icon: Icons.vibration_rounded,
                    color: const Color(0xFFAB3500),
                    title: 'Haptic Vibration',
                    subtitle: 'Vibrate on button taps and breathing reset steps',
                    value: _vibrationFeedback,
                    onChanged: (val) => setState(() => _vibrationFeedback = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAB3500),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Save Notification Preferences',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF171B2B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.beVietnamPro(
          fontSize: 12,
          color: const Color(0xFF594139),
        ),
      ),
      trailing: Switch(
        value: value,
        activeThumbColor: color,
        onChanged: onChanged,
      ),
    );
  }
}
