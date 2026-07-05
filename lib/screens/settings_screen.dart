import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailUpdates = true;
  bool _soundEffects = true;
  bool _darkMode = false;

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Text(
          'Log Out',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppTheme.titleDark,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of Happy Desk?',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(initialIsLogin: true),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRust,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Log Out',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8), // Warm soft ambient background
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.titleDark,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.titleDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section 1: Account Settings
              _buildSectionTitle('ACCOUNT & PROFILE'),
              const SizedBox(height: 10),
              _buildSettingsCard(
                children: [
                  _buildListTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Name, job role, profile picture',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Security & Password',
                    subtitle: 'Change password, 2FA',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Workspace Preferences',
                    subtitle: 'Team invite code, role settings',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section 2: Notifications & Sounds
              _buildSectionTitle('NOTIFICATIONS'),
              const SizedBox(height: 10),
              _buildSettingsCard(
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Daily shift reminders & kudos',
                    value: _pushNotifications,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.mark_email_unread_outlined,
                    title: 'Email Updates',
                    subtitle: 'Weekly team joy digest',
                    value: _emailUpdates,
                    onChanged: (val) => setState(() => _emailUpdates = val),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.volume_up_outlined,
                    title: 'Sound Effects & Haptics',
                    subtitle: 'Feedback on task completion',
                    value: _soundEffects,
                    onChanged: (val) => setState(() => _soundEffects = val),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section 3: Appearance
              _buildSectionTitle('APPEARANCE'),
              const SizedBox(height: 10),
              _buildSettingsCard(
                children: [
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Switch theme appearance',
                    value: _darkMode,
                    onChanged: (val) => setState(() => _darkMode = val),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section 4: Support & About
              _buildSectionTitle('SUPPORT & LEGAL'),
              const SizedBox(height: 10),
              _buildSettingsCard(
                children: [
                  _buildListTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center & FAQ',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Log Out Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _showLogoutDialog,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    foregroundColor: const Color(0xFFE53E3E),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(
                    'Log Out',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // App Version
              Center(
                child: Text(
                  'Happy Desk v1.0.0 • Workplace Joy Reinvented',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryRust,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryRust.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryRust, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.titleDark,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9CA3AF),
        size: 20,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryRust.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryRust, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.titleDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.primaryRust,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 18,
      endIndent: 18,
    );
  }
}
