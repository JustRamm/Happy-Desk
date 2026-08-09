import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Local Notification Init Note: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'happy_desk_channel',
      'Happy Desk Notifications',
      channelDescription: 'Alerts for direct messages and workplace updates',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Show high-priority incoming voice or video call notification on phone system notification bar
  Future<void> showCallNotification({
    required String callerName,
    required bool isVideo,
    required String callId,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      'happy_desk_calls',
      'Incoming Calls',
      channelDescription: 'High priority alert channel for incoming voice and video calls',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      timeoutAfter: 60000,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final int notifId = callId.hashCode.abs();
      await _localNotifications.show(
        id: notifId,
        title: isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
        body: '$callerName is calling you on Happy Desk',
        notificationDetails: details,
        payload: 'call:$callId',
      );
    } catch (e) {
      debugPrint('Error showing call notification: $e');
    }
  }

  /// Cancel active call notification from system tray when call is answered or rejected
  Future<void> cancelCallNotification(String callId) async {
    try {
      final int notifId = callId.hashCode.abs();
      await _localNotifications.cancel(id: notifId);
    } catch (e) {
      debugPrint('Error canceling call notification: $e');
    }
  }

  /// Sync device FCM token to Supabase profiles table
  Future<void> syncDeviceToken(String fcmToken) async {
    if (fcmToken.isEmpty) return;
    await SupabaseService.instance.updateFcmToken(fcmToken);
  }
}
