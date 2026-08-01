import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'user_preferences_store.dart';

class OfflineSyncAction {
  final String id;
  final String actionType; // 'clock_in', 'clock_out', 'log_mood', 'send_message'
  final Map<String, dynamic> payload;
  final String timestamp;

  OfflineSyncAction({
    required this.id,
    required this.actionType,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'actionType': actionType,
        'payload': payload,
        'timestamp': timestamp,
      };

  factory OfflineSyncAction.fromJson(Map<String, dynamic> json) {
    return OfflineSyncAction(
      id: json['id'] as String,
      actionType: json['actionType'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      timestamp: json['timestamp'] as String,
    );
  }
}

class OfflineSyncService {
  static final OfflineSyncService instance = OfflineSyncService._();
  OfflineSyncService._();

  static const String _keyQueue = 'offline_sync_queue';
  bool _isProcessing = false;

  Future<void> initialize() async {
    // Listen to network changes
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        debugPrint('OfflineSyncService: Network recovered. Processing queue...');
        processQueue();
      }
    });

    // Run initial sync check
    final conn = await Connectivity().checkConnectivity();
    if (conn.isNotEmpty && !conn.contains(ConnectivityResult.none)) {
      processQueue();
    }
  }

  Future<List<OfflineSyncAction>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyQueue);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => OfflineSyncAction.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveQueue(List<OfflineSyncAction> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(queue.map((e) => e.toJson()).toList());
    await prefs.setString(_keyQueue, raw);
  }

  Future<void> enqueueAction({
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    final action = OfflineSyncAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      actionType: actionType,
      payload: payload,
      timestamp: DateTime.now().toIso8601String(),
    );

    final queue = await getQueue();
    queue.add(action);
    await _saveQueue(queue);

    debugPrint('OfflineSyncService: Action $actionType enqueued.');

    // Attempt to process immediately if online
    final conn = await Connectivity().checkConnectivity();
    if (conn.isNotEmpty && !conn.contains(ConnectivityResult.none)) {
      processQueue();
    }
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final queue = await getQueue();
      if (queue.isEmpty) {
        _isProcessing = false;
        return;
      }

      debugPrint('OfflineSyncService: Processing ${queue.length} pending actions.');

      final completedIds = <String>[];

      for (var action in queue) {
        final success = await _executeAction(action);
        if (success) {
          completedIds.add(action.id);
        } else {
          // Break on first failure (keep remaining actions in queue order)
          break;
        }
      }

      if (completedIds.isNotEmpty) {
        final remaining = queue.where((a) => !completedIds.contains(a.id)).toList();
        await _saveQueue(remaining);
        debugPrint('OfflineSyncService: Synced ${completedIds.length} actions. ${remaining.length} remaining.');
      }
    } catch (e) {
      debugPrint('OfflineSyncService: Error processing sync queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _executeAction(OfflineSyncAction action) async {
    try {
      final client = SupabaseService.instance.client;
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) return false;

      switch (action.actionType) {
        case 'clock_in':
          final lat = action.payload['lat'] as double?;
          final lng = action.payload['lng'] as double?;
          final locationName = action.payload['location_name'] as String? ?? 'Office HQ';

          await client.from('work_sessions').insert({
            'user_id': userId,
            'clock_in_time': action.timestamp,
            'clock_in_lat': lat,
            'clock_in_lng': lng,
            'clock_in_location_name': locationName,
            'status': 'active',
          });

          await client.from('profiles').update({
            'is_clocked_in': true,
            'is_on_break': false,
            'last_clock_in_time': action.timestamp,
          }).eq('id', userId);

          // Post broadcast
          final userName = UserPreferencesStore.getUserName();
          await SupabaseService.instance.postTeamBroadcast(
            eventType: 'clock_in',
            title: '$userName Clocked In (Offline Cached)',
            body: '$userName clocked in at $locationName.',
          );
          return true;

        case 'clock_out':
          final lat = action.payload['lat'] as double?;
          final lng = action.payload['lng'] as double?;
          final locationName = action.payload['location_name'] as String? ?? 'Work Complete';

          final activeSessions = await client
              .from('work_sessions')
              .select()
              .eq('user_id', userId)
              .eq('status', 'active');

          if (activeSessions.isNotEmpty) {
            final sessionId = activeSessions.first['id'];
            await client.from('work_sessions').update({
              'clock_out_time': action.timestamp,
              'clock_out_lat': lat,
              'clock_out_lng': lng,
              'clock_out_location_name': locationName,
              'status': 'completed',
            }).eq('id', sessionId);
          }

          await client.from('profiles').update({
            'is_clocked_in': false,
            'is_on_break': false,
          }).eq('id', userId);

          // Post broadcast
          final userName = UserPreferencesStore.getUserName();
          await SupabaseService.instance.postTeamBroadcast(
            eventType: 'clock_out',
            title: '$userName Clocked Out (Offline Cached)',
            body: '$userName completed shifts.',
          );
          return true;

        case 'log_mood':
          final score = action.payload['score'] as int;
          final label = action.payload['label'] as String;
          final tags = List<String>.from(action.payload['tags'] as List? ?? []);

          await client.from('mochi_mood_logs').insert({
            'user_id': userId,
            'score': score,
            'label': label,
            'tags': tags,
            'created_at': action.timestamp,
          });
          return true;

        case 'send_message':
          final receiverName = action.payload['receiver_name'] as String;
          final message = action.payload['message'] as String;
          final mediaUrl = action.payload['media_url'] as String?;
          final senderName = UserPreferencesStore.getUserName();

          await client.from('direct_messages').insert({
            'sender_id': userId,
            'sender_name': senderName,
            'receiver_name': receiverName,
            'message': message,
            'media_url': mediaUrl,
            'is_read': false,
            'created_at': action.timestamp,
          });
          return true;

        default:
          return false;
      }
    } catch (e) {
      debugPrint('OfflineSyncService: Failed to execute action ${action.actionType}: $e');
      return false;
    }
  }
}
