import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/coffee_notification_store.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'Coffee Breaks',
    'Clock-Ins',
    'Leaves',
    'Kudos'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row
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
                    'Team Notifications',
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
                'Live broadcast of team clock-ins, approved leaves & appreciation wins.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        showCheckmark: false,
                        label: Text(filter),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.titleDark,
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryRust,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.primaryRust
                                : const Color(0xFFE4E7FE),
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = filter);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Section 1: LIVE TEAM BROADCASTS
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE BROADCASTS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF006C53),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Dynamic Coffee Break Invitations from Store
              if (_selectedFilter == 'All' ||
                  _selectedFilter == 'Coffee Breaks')
                ValueListenableBuilder<List<CoffeeNotificationItem>>(
                  valueListenable:
                      CoffeeNotificationStore.notificationsNotifier,
                  builder: (context, coffeeItems, child) {
                    if (coffeeItems.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: coffeeItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: _buildNotificationCard(
                            icon: Icons.local_cafe_rounded,
                            iconBg: const Color(0xFFFFF0F7),
                            iconColor: const Color(0xFFFF6B35),
                            title: item.title,
                            time: item.time,
                            body: item.body,
                            actionWidget: Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: item.isAccepted
                                        ? null
                                        : () {
                                            CoffeeNotificationStore.acceptInvite(
                                                item.id);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Accepted! Coffee break scheduled with ${item.senderName}.',
                                                  style:
                                                      GoogleFonts.beVietnamPro(),
                                                ),
                                                backgroundColor:
                                                    const Color(0xFFFF6B35),
                                              ),
                                            );
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6B35),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                    ),
                                    icon: Icon(
                                      item.isAccepted
                                          ? Icons.check_circle_rounded
                                          : Icons.local_cafe_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      item.isAccepted
                                          ? 'Accepted'
                                          : 'Join Break',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

              // Card 1: Clock-In Broadcast
              if (_selectedFilter == 'All' || _selectedFilter == 'Clock-Ins') ...[
                _buildNotificationCard(
                  icon: Icons.location_on_rounded,
                  iconBg: const Color(0xFFFFF0EB),
                  iconColor: AppTheme.primaryRust,
                  title: 'Sarah Jenkins clocked in from HQ - Floor 3',
                  time: 'Just now',
                  body:
                      'Sarah started her shift at 09:15 AM from HQ Floor 3. Send her a quick greeting!',
                  actionWidget: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Location: HQ - Floor 3 • 09:15 AM',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryRust,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Card 2: Approved Leave Broadcast (Teammates' Approved Leaves)
              if (_selectedFilter == 'All' || _selectedFilter == 'Leaves') ...[
                _buildNotificationCard(
                  icon: Icons.beach_access_rounded,
                  iconBg: const Color(0xFFEBF7F5),
                  iconColor: const Color(0xFF006C53),
                  title: 'Leave Approved: Alex Chen',
                  time: '10m ago',
                  body:
                      'Alex Chen\'s Casual Leave application for Jul 29 – Jul 30 was approved by management. Wish them a restful break!',
                  actionWidget: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF7F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Casual Leave • Jul 29 – Jul 30 (Approved by HR)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF006C53),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildNotificationCard(
                  icon: Icons.beach_access_rounded,
                  iconBg: const Color(0xFFEBF7F5),
                  iconColor: const Color(0xFF006C53),
                  title: 'Leave Approved: Sarah Jenkins',
                  time: '1 hour ago',
                  body:
                      'Sarah Jenkins\' Sick Leave application for Aug 02 – Aug 03 was approved by management.',
                  actionWidget: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF7F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Sick Leave • Aug 02 – Aug 03 (Approved by HR)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF006C53),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildNotificationCard(
                  icon: Icons.beach_access_rounded,
                  iconBg: const Color(0xFFEBF7F5),
                  iconColor: const Color(0xFF006C53),
                  title: 'Leave Approved: Marcus Vance',
                  time: 'Yesterday',
                  body:
                      'Marcus Vance\'s Annual Rest & Reset application for Aug 10 – Aug 15 was approved.',
                  actionWidget: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF7F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Annual Leave • Aug 10 – Aug 15 (Approved by HR)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF006C53),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Card 3: Jar Note Appreciation
              if (_selectedFilter == 'All' || _selectedFilter == 'Kudos') ...[
                _buildNotificationCard(
                  icon: Icons.layers_rounded,
                  iconBg: const Color(0xFFFFF0EB),
                  iconColor: AppTheme.primaryRust,
                  title: 'Someone just added a note to your Jar!',
                  time: '30m ago',
                  body:
                      'Open it up to read some anonymous appreciation from the team. You\'re doing great!',
                  actionWidget: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Jar...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRust,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Open Jar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Card 4: Hero Update
              if (_selectedFilter == 'All' || _selectedFilter == 'Kudos') ...[
                _buildNotificationCard(
                  icon: Icons.military_tech_rounded,
                  iconBg: const Color(0xFFFCE7F3),
                  iconColor: const Color(0xFFEC4899),
                  title: 'Sarah Jenkins was named this week\'s Hero!',
                  time: '1h ago',
                  body:
                      'She crushed the sprint goals and helped three teammates with their blockers. Show some love!',
                  actionWidget: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              const SizedBox(height: 14),

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
        color: isLightCard
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
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
