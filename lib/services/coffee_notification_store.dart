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
      ValueNotifier<List<CoffeeNotificationItem>>([
    CoffeeNotificationItem(
      id: '1',
      title: 'Coffee Break Invite from David Kim',
      body: 'David Kim invited you to a 5-minute coffee & chat break.',
      time: 'Just now',
      senderName: 'David Kim',
      senderAvatar: 'assets/avatars/avatar_2.png',
    ),
    CoffeeNotificationItem(
      id: '2',
      title: 'Group Coffee Break Reset',
      body: 'Sarah Chen started a group coffee break reset with 4 teammates!',
      time: '25m ago',
      senderName: 'Sarah Chen',
      senderAvatar: 'assets/avatars/avatar_1.png',
      isGroup: true,
    ),
  ]);

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
      senderAvatar: senderAvatar ?? 'assets/avatars/user_avatar.png',
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
