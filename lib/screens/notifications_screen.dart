import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8), // Warm soft ambient background matching rest of app
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row (Matching Settings & detail screens header style)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.titleDark,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Notifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.titleDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                'Catch up on all the joy and team wins.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Section 1: NEW
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF652F),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'NEW',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.brandTitleOrange,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Card 1: Someone just added a note to your Jar!
              _buildNotificationCard(
                icon: Icons.layers_rounded,
                iconBg: const Color(0xFFFFF0EB),
                iconColor: AppTheme.primaryRust,
                title: 'Someone just added a note to your Jar!',
                time: 'Just now',
                body:
                    'Open it up to read some anonymous appreciation from the team. You\'re doing great!',
                actionWidget: Padding(
                  padding: const EdgeInsets.only(top: 14.0),
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Jar...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRust,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Open Jar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Card 2: Sarah Jenkins was named this week's Hero!
              _buildNotificationCard(
                icon: Icons.military_tech_rounded,
                iconBg: const Color(0xFFFCE7F3),
                iconColor: const Color(0xFFEC4899),
                title: 'Sarah Jenkins was named this week\'s Hero!',
                time: '15m ago',
                body:
                    'She crushed the sprint goals and helped three teammates with their blockers. Show some love!',
                actionWidget: Padding(
                  padding: const EdgeInsets.only(top: 14.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Hero Update',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF047857),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE7F3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Celebrate',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF9D174D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Section 2: EARLIER
              Text(
                'EARLIER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.brandTitleOrange,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 14),

              // Card 3: Don't forget to clock in!
              _buildNotificationCard(
                icon: Icons.access_time_rounded,
                iconBg: const Color(0xFFFFF0EB),
                iconColor: AppTheme.primaryRust,
                title: 'Don\'t forget to clock in!',
                time: '2h ago',
                body:
                    'Your shift started 10 minutes ago. Tap here to start your Happy Day.',
                isLightCard: true,
              ),

              const SizedBox(height: 14),

              // Card 4: Streak milestone
              _buildNotificationCard(
                icon: Icons.local_fire_department_rounded,
                iconBg: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF10B981),
                title: 'You have a new streak milestone: 8 Days!',
                time: '5h ago',
                body:
                    'You\'re on fire! 8 consecutive days of positive desk vibes. Keep it up!',
                isLightCard: true,
              ),

              const SizedBox(height: 14),

              // Card 5: System Update Completed
              _buildNotificationCard(
                icon: Icons.info_outline_rounded,
                iconBg: const Color(0xFFEEF0FF),
                iconColor: const Color(0xFF6B5B95),
                title: 'System Update Completed',
                time: 'Yesterday',
                body:
                    'Happy Desk is now faster and includes new emojis for your Jar notes!',
                isLightCard: true,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String time,
    required String body,
    Widget? actionWidget,
    bool isLightCard = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            isLightCard
                ? const Color(0xFFF3F2FF).withValues(alpha: 0.6)
                : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),

          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.titleDark,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (actionWidget != null) ...[actionWidget],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
