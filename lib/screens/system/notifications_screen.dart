import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/coffee_notification_store.dart';
import '../../widgets/multi_coffee_reset_modal.dart';
import '../../widgets/brand_logo_widget.dart';
import '../../services/supabase_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _broadcastFeedItems = [];

  @override
  void initState() {
    super.initState();
    CoffeeNotificationStore.markAllAsRead();
    _loadTeamBroadcastFeed();
  }

  Future<void> _loadTeamBroadcastFeed() async {
    final items = await SupabaseService.instance.getTeamBroadcastFeed();
    if (items.isNotEmpty && mounted) {
      setState(() {
        _broadcastFeedItems = items;
      });
    }
  }

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
              // Top Header Row with Logo (Size 54)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                      const SizedBox(width: 10),
                      const BrandLogoWidget(height: 54),
                      const SizedBox(width: 10),
                      Text(
                        'Notifications',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.titleDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => MultiCoffeeResetModal.show(context),
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
                    tooltip: 'Coffee Break Reset',
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

              // Dynamic Live Notifications from Coffee Store and Supabase Broadcast Feed
              ValueListenableBuilder<List<CoffeeNotificationItem>>(
                valueListenable:
                    CoffeeNotificationStore.notificationsNotifier,
                builder: (context, coffeeItems, child) {
                  final filteredCoffee = coffeeItems.where((item) {
                    if (_selectedFilter == 'All') return true;
                    if (_selectedFilter == 'Coffee Breaks') return true;
                    return false;
                  }).toList();

                  final filteredBroadcasts = _broadcastFeedItems.where((feedItem) {
                    final eventType = feedItem['event_type'] ?? 'general';
                    if (_selectedFilter == 'All') return true;
                    if (_selectedFilter == 'Clock-Ins' && eventType == 'clock_in') return true;
                    if (_selectedFilter == 'Leaves' && eventType == 'leave_approved') return true;
                    if (_selectedFilter == 'Kudos' && eventType == 'hero_win') return true;
                    return false;
                  }).toList();

                  if (filteredCoffee.isEmpty && filteredBroadcasts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5F2),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFFF0EB)),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                size: 48,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Notifications Yet',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.titleDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Live broadcasts and coffee break invites will appear here.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...filteredCoffee.map((item) {
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
                                  if (item.isAccepted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6F7F0),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Accepted',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF047857),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (item.isRejected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0EB),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFFFC4B0)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.cancel_rounded, color: Color(0xFFC84B1A), size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Declined',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFC84B1A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else ...[
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        CoffeeNotificationStore.acceptInvite(item.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Accepted! Coffee break scheduled with ${item.senderName}.',
                                              style: GoogleFonts.beVietnamPro(),
                                            ),
                                            backgroundColor: const Color(0xFF047857),
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
                                      icon: const Icon(Icons.local_cafe_rounded, size: 16),
                                      label: Text(
                                        'Join Break',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        CoffeeNotificationStore.rejectInvite(item.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Declined coffee break invitation from ${item.senderName}.',
                                              style: GoogleFonts.beVietnamPro(),
                                            ),
                                            backgroundColor: const Color(0xFFC84B1A),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        side: const BorderSide(color: Color(0xFFC84B1A)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFC84B1A)),
                                      label: Text(
                                        'Decline',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFC84B1A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      ...filteredBroadcasts.map((feedItem) {
                        final eventType = feedItem['event_type'] ?? 'general';
                        final title = feedItem['title'] ?? feedItem['sender_name'] ?? 'Broadcast';
                        final body = feedItem['body'] ?? '';
                        final timeRaw = feedItem['created_at']?.toString() ?? '';
                        final timeStr = timeRaw.isNotEmpty ? timeRaw.split('T').last.substring(0, 5) : 'Recently';

                        IconData iconData = Icons.campaign_rounded;
                        Color iconBg = const Color(0xFFEFF6FF);
                        Color iconColor = const Color(0xFF2563EB);

                        if (eventType == 'clock_in') {
                          iconData = Icons.location_on_rounded;
                          iconBg = const Color(0xFFFFF0EB);
                          iconColor = AppTheme.primaryRust;
                        } else if (eventType == 'leave_approved') {
                          iconData = Icons.event_available_rounded;
                          iconBg = const Color(0xFFEDFDF5);
                          iconColor = const Color(0xFF00AE88);
                        } else if (eventType == 'hero_win') {
                          iconData = Icons.emoji_events_rounded;
                          iconBg = const Color(0xFFFFFBEB);
                          iconColor = const Color(0xFFD97706);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: _buildNotificationCard(
                            icon: iconData,
                            iconBg: iconBg,
                            iconColor: iconColor,
                            title: title,
                            time: timeStr,
                            body: body,
                          ),
                        );
                      }),
                    ],
                  );
                },
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
