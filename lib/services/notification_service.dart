import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String type; // 'coffee', 'ngl', 'hero', 'shift'
  final DateTime timestamp;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final List<AppNotificationItem> _notifications = [];
  final _notificationsController = StreamController<List<AppNotificationItem>>.broadcast();

  Stream<List<AppNotificationItem>> get notificationStream => _notificationsController.stream;
  List<AppNotificationItem> get currentNotifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification({
    required String title,
    required String body,
    required String type,
    BuildContext? context,
  }) {
    final item = AppNotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
    );

    _notifications.insert(0, item);
    _notificationsController.add(_notifications);

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF171B2B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type == 'coffee'
                      ? Icons.coffee_rounded
                      : type == 'ngl'
                          ? Icons.mark_email_unread_rounded
                          : type == 'hero'
                              ? Icons.emoji_events_rounded
                              : Icons.access_time_filled_rounded,
                  color: const Color(0xFFAB3500),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    _notificationsController.add(_notifications);
  }

  void clearAll() {
    _notifications.clear();
    _notificationsController.add(_notifications);
  }
}
