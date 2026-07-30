import 'package:flutter/material.dart';

class CoffeeNotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final String senderName;
  final String senderAvatar;
  final bool isGroup;
  bool isAccepted;
  bool isRejected;
  bool isUnread;

  CoffeeNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.senderName,
    required this.senderAvatar,
    this.isGroup = false,
    this.isAccepted = false,
    this.isRejected = false,
    this.isUnread = true,
  });
}

class CoffeeNotificationStore {
  static final ValueNotifier<List<CoffeeNotificationItem>> notificationsNotifier =
      ValueNotifier<List<CoffeeNotificationItem>>([]);

  static void addCoffeeInvite({
    required String senderName,
    String? senderAvatar,
    required String message,
    bool isGroup = false,
  }) {
    final newItem = CoffeeNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: isGroup
          ? 'Group Coffee Break Reset'
          : 'Coffee Break Invite from $senderName',
      body: message,
      time: 'Just now',
      senderName: senderName,
      senderAvatar: senderAvatar ?? '',
      isGroup: isGroup,
      isUnread: true,
    );

    final currentList = List<CoffeeNotificationItem>.from(notificationsNotifier.value);
    currentList.insert(0, newItem);
    notificationsNotifier.value = currentList;
  }

  static void acceptInvite(String id) {
    final currentList = List<CoffeeNotificationItem>.from(notificationsNotifier.value);
    final index = currentList.indexWhere((item) => item.id == id);
    if (index != -1) {
      currentList[index].isAccepted = true;
      currentList[index].isRejected = false;
      notificationsNotifier.value = currentList;
    }
  }

  static void rejectInvite(String id) {
    final currentList = List<CoffeeNotificationItem>.from(notificationsNotifier.value);
    final index = currentList.indexWhere((item) => item.id == id);
    if (index != -1) {
      currentList[index].isRejected = true;
      currentList[index].isAccepted = false;
      notificationsNotifier.value = currentList;
    }
  }

  static void markAllAsRead() {
    final currentList = List<CoffeeNotificationItem>.from(notificationsNotifier.value);
    for (final item in currentList) {
      item.isUnread = false;
    }
    notificationsNotifier.value = currentList;
  }
}
