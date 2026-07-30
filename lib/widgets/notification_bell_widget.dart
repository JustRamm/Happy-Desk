import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/coffee_notification_store.dart';
import '../screens/notifications_screen.dart';

class NotificationBellWidget extends StatelessWidget {
  const NotificationBellWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CoffeeNotificationItem>>(
      valueListenable: CoffeeNotificationStore.notificationsNotifier,
      builder: (context, notifications, child) {
        final unreadCount = notifications.where((n) => n.isUnread).length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Color(0xFFAB3500),
                  size: 22,
                ),
              ),
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
