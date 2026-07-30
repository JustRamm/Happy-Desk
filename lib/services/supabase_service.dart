import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'user_preferences_store.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;

  Future<void> init() async {
    if (_initialized) return;

    final url = dotenv.env['SUPABASE_URL'] ?? 'https://fcqycmihbxbuocjohpkh.supabase.co';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_sn8nCqyBFhZhQ2ZqloCNJQ_hpuyZ5SI';

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
      );
      _initialized = true;
      debugPrint('Supabase initialized successfully.');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
    }
  }

  // Generate random company code (e.g., COMP-7842 or HD-E92A)
  String generateCode({String prefix = 'COMP', int length = 4}) {
    final rng = Random();
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final randomPart = List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
    return '$prefix-$randomPart';
  }

  // 1. Founder Sign Up
  Future<AuthResponse> signUpFounder({
    required String email,
    required String password,
    required String name,
    required String companyName,
    String? companyCode,
  }) async {
    await init();
    final finalCode = (companyCode != null && companyCode.trim().isNotEmpty)
        ? companyCode.trim().toUpperCase()
        : generateCode(prefix: 'COMP', length: 5);

    // 1. Auth Sign Up
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role_type': 'founder',
        'is_leader': true,
        'job_title': 'Founder & CEO',
        'department': 'Executive',
      },
    );

    final user = res.user;
    if (user != null) {
      // 2. Create Company Record
      final companyRes = await client.from('companies').insert({
        'name': companyName,
        'company_code': finalCode,
        'founder_id': user.id,
      }).select().single();

      final companyId = companyRes['id'] as String;

      // 3. Update Founder Profile with Company ID
      await client.from('profiles').upsert({
        'id': user.id,
        'email': email,
        'name': name,
        'role_type': 'founder',
        'is_leader': true,
        'company_id': companyId,
        'job_title': 'Founder & CEO',
        'department': 'Executive',
      });

      // Save local preferences
      await UserPreferencesStore.setUserProfile(
        name: name,
        role: 'Founder & CEO',
        team: 'Executive',
        company: companyName,
      );
    }
    return res;
  }

  // 2. Employee / Leader Sign Up
  Future<AuthResponse> signUpEmployee({
    required String email,
    required String password,
    required String name,
    required String companyCode,
    bool isLeader = false,
    String jobTitle = 'Employee',
    String department = 'Engineering',
  }) async {
    await init();
    final cleanCode = companyCode.trim().toUpperCase();

    // Validate Company Code or Join Code
    String? companyId;
    bool assignedLeader = isLeader;

    // Check company_code in companies table
    final companyMatch = await client
        .from('companies')
        .select('id, name')
        .eq('company_code', cleanCode)
        .maybeSingle();

    if (companyMatch != null) {
      companyId = companyMatch['id'] as String;
    } else {
      // Check company_join_codes table
      final joinCodeMatch = await client
          .from('company_join_codes')
          .select('company_id, role_tag, is_active')
          .eq('code', cleanCode)
          .maybeSingle();

      if (joinCodeMatch != null && joinCodeMatch['is_active'] == true) {
        companyId = joinCodeMatch['company_id'] as String;
        if (joinCodeMatch['role_tag'] == 'leader') {
          assignedLeader = true;
        }
      } else {
        throw Exception('Invalid company join code. Please check with your Founder or Team Leader.');
      }
    }

    // Auth Sign Up
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role_type': 'employee',
        'is_leader': assignedLeader,
        'job_title': jobTitle,
        'department': department,
      },
    );

    final user = res.user;
    if (user != null) {
      await client.from('profiles').upsert({
        'id': user.id,
        'email': email,
        'name': name,
        'role_type': 'employee',
        'is_leader': assignedLeader,
        'company_id': companyId,
        'job_title': jobTitle,
        'department': department,
      });

      await UserPreferencesStore.setUserProfile(
        name: name,
        role: jobTitle,
        team: department,
      );
    }
    return res;
  }

  // 3. User Login
  Future<AuthResponse> loginUser({
    required String email,
    required String password,
  }) async {
    await init();
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user != null) {
      // Fetch Profile Data
      final profile = await client.from('profiles').select().eq('id', user.id).maybeSingle();
      if (profile != null) {
        await UserPreferencesStore.setUserProfile(
          name: profile['name'] ?? 'User',
          role: profile['job_title'] ?? 'Employee',
          team: profile['department'] ?? 'General',
          bio: profile['bio'] ?? '',
          strengths: profile['strengths'] ?? '',
          focusArea: profile['focus_area'] ?? '',
          currentChallenges: profile['current_challenges'] ?? '',
          communicationPreference: profile['communication_preference'] ?? '',
        );
      }
    }
    return res;
  }

  // Fetch Company Teammates
  Future<List<Map<String, dynamic>>> getCompanyTeammates() async {
    await init();
    try {
      final res = await client
          .from('profiles')
          .select('id, name, email, job_title, department, avatar_url, is_clocked_in, is_on_break, is_leader, role_type')
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching teammates: $e');
      return [];
    }
  }

  // 4. Generate Join Code for Founders / Team Leaders
  Future<String> createJoinCode({
    required String roleTag, // 'employee' or 'leader'
  }) async {
    await init();
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated.');

    final profile = await client.from('profiles').select('company_id, is_leader, role_type').eq('id', user.id).single();
    final companyId = profile['company_id'] as String?;
    if (companyId == null) throw Exception('No company associated with profile.');

    final newCode = generateCode(prefix: roleTag == 'leader' ? 'LEAD' : 'EMP', length: 5);

    await client.from('company_join_codes').insert({
      'company_id': companyId,
      'code': newCode,
      'role_tag': roleTag,
      'created_by': user.id,
      'is_active': true,
    });

    return newCode;
  }

  // Location Permission & Current Position Helper
  Future<Position?> getCurrentDeviceLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint('Error getting location position: $e');
      return null;
    }
  }

  // Clock In with Live Location
  Future<Map<String, dynamic>?> clockInWithLocation() async {
    await init();
    final user = currentUser;
    if (user == null) return null;

    final position = await getCurrentDeviceLocation();
    final double? lat = position?.latitude;
    final double? lng = position?.longitude;
    final String locationName = position != null
        ? 'Lat: ${lat?.toStringAsFixed(4)}, Lng: ${lng?.toStringAsFixed(4)}'
        : 'Office HQ';

    // Insert work session
    final sessionRes = await client.from('work_sessions').insert({
      'user_id': user.id,
      'clock_in_time': DateTime.now().toIso8601String(),
      'clock_in_lat': lat,
      'clock_in_lng': lng,
      'clock_in_location_name': locationName,
      'status': 'active',
    }).select().single();

    // Update profile clock-in status
    await client.from('profiles').update({
      'is_clocked_in': true,
      'is_on_break': false,
      'last_clock_in_time': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    // Broadcast clock-in event
    final userName = UserPreferencesStore.getUserName();
    await postTeamBroadcast(
      eventType: 'clock_in',
      title: '$userName Clocked In',
      body: '$userName clocked in at $locationName.',
    );

    return sessionRes;
  }

  // Clock Out
  Future<void> clockOutWorkSession() async {
    await init();
    final user = currentUser;
    if (user == null) return;

    final activeSessions = await client
        .from('work_sessions')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'active');

    if (activeSessions.isNotEmpty) {
      final sessionId = activeSessions.first['id'];
      await client.from('work_sessions').update({
        'clock_out_time': DateTime.now().toIso8601String(),
        'status': 'completed',
      }).eq('id', sessionId);
    }

    await client.from('profiles').update({
      'is_clocked_in': false,
      'is_on_break': false,
    }).eq('id', user.id);
  }

  // Fetch Work Sessions History
  Future<List<Map<String, dynamic>>> getWorkSessionHistory() async {
    await init();
    final user = currentUser;
    if (user == null) return [];
    try {
      final res = await client
          .from('work_sessions')
          .select()
          .eq('user_id', user.id)
          .order('clock_in_time', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching work sessions: $e');
      return [];
    }
  }

  // 5. Submit Leave Request
  Future<void> submitLeaveRequest({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    await init();
    final user = currentUser;
    if (user == null) return;

    await client.from('leave_requests').insert({
      'user_id': user.id,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'reason': reason ?? '',
      'status': 'pending',
    });
  }

  // 6. Send Coffee Break Invite
  Future<void> sendCoffeeInvite({
    required String message,
    String? receiverId,
    bool isGroup = false,
  }) async {
    await init();
    final user = currentUser;
    if (user == null) return;

    final profile = await client.from('profiles').select('company_id').eq('id', user.id).single();

    await client.from('coffee_break_invites').insert({
      'sender_id': user.id,
      'receiver_id': receiverId,
      'company_id': profile['company_id'],
      'message': message,
      'is_group': isGroup,
      'status': 'pending',
    });
  }

  // 7. Save Mochi Mood Log
  Future<void> saveMochiMoodLog({
    required int score,
    required String label,
    required List<String> tags,
  }) async {
    await init();
    final user = currentUser;
    if (user == null) return;

    await client.from('mochi_mood_logs').insert({
      'user_id': user.id,
      'score': score,
      'label': label,
      'tags': tags,
    });
  }

  // 8. Save Mochi CBT Log
  Future<void> saveMochiCbtLog({
    required String trigger,
    required String distortionTag,
    required int preScore,
    required int postScore,
    required String reframeText,
  }) async {
    await init();
    final user = currentUser;
    if (user == null) return;

    await client.from('mochi_cbt_logs').insert({
      'user_id': user.id,
      'trigger': trigger,
      'distortion_tag': distortionTag,
      'pre_score': preScore,
      'post_score': postScore,
      'reframe_text': reframeText,
    });
  }

  // 9. NGL Jar - Fetch Messages
  Future<List<Map<String, dynamic>>> getNglJarMessages() async {
    await init();
    try {
      final res = await client
          .from('ngl_jar_messages')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching NGL messages: $e');
      return [];
    }
  }

  // NGL Jar - Post Message
  Future<void> postNglJarMessage({
    required String message,
    bool isAnonymous = true,
    String tag = 'vent',
  }) async {
    await init();
    final user = currentUser;
    await client.from('ngl_jar_messages').insert({
      'user_id': user?.id,
      'company_id': '11111111-1111-1111-1111-111111111111',
      'message': message,
      'is_anonymous': isAnonymous,
      'likes_count': 0,
      'tag': tag,
    });
  }

  // NGL Jar - Like Message
  Future<void> likeNglJarMessage(String messageId, int currentLikes) async {
    await init();
    await client.from('ngl_jar_messages').update({
      'likes_count': currentLikes + 1,
    }).eq('id', messageId);
  }

  // 10. Weekly Hero - Fetch Nominations
  Future<List<Map<String, dynamic>>> getWeeklyHeroNominations() async {
    await init();
    try {
      final res = await client
          .from('weekly_hero_nominations')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching Weekly Hero nominations: $e');
      return [];
    }
  }

  // Weekly Hero - Submit Nomination
  Future<void> submitHeroNomination({
    required String nomineeName,
    required String reason,
    String badgeType = 'Coffee Hero',
  }) async {
    await init();
    final nominatorName = UserPreferencesStore.getUserName();
    await client.from('weekly_hero_nominations').insert({
      'nominee_name': nomineeName,
      'nominator_name': nominatorName,
      'company_id': '11111111-1111-1111-1111-111111111111',
      'reason': reason,
      'badge_type': badgeType,
    });
  }

  // 11. Mochi - Save Chat Message with Timestamp
  Future<void> saveMochiChatMessage({
    required String message,
    required bool isUser,
    String? actionType,
    String? sessionId,
  }) async {
    await init();
    final user = currentUser;
    await client.from('mochi_chat_messages').insert({
      'user_id': user?.id,
      'message': message,
      'is_user': isUser,
      'action_type': actionType,
      'session_id': sessionId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Mochi - Fetch User Chat History
  Future<List<Map<String, dynamic>>> getMochiChatHistory() async {
    await init();
    final user = currentUser;
    if (user == null) return [];
    try {
      final res = await client
          .from('mochi_chat_messages')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching Mochi chat history: $e');
      return [];
    }
  }

  // Mochi - Save Session Summary
  Future<void> saveMochiSessionSummary({
    required String summaryText,
    required int totalTurns,
  }) async {
    await init();
    final user = currentUser;
    if (user == null) return;
    await client.from('mochi_session_summaries').insert({
      'user_id': user.id,
      'summary_text': summaryText,
      'total_turns': totalTurns,
    });
  }

  // 12. Direct Messages - Fetch & Send
  Future<List<Map<String, dynamic>>> getDirectMessages() async {
    await init();
    try {
      final res = await client
          .from('direct_messages')
          .select()
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching direct messages: $e');
      return [];
    }
  }

  Future<void> sendDirectMessage({
    required String receiverName,
    required String message,
    String? mediaUrl,
  }) async {
    await init();
    final user = currentUser;
    final senderName = UserPreferencesStore.getUserName();
    await client.from('direct_messages').insert({
      'sender_id': user?.id,
      'sender_name': senderName,
      'receiver_name': receiverName,
      'message': message,
      'media_url': mediaUrl,
      'is_read': false,
    });
  }

  // 13. Team Broadcast Feed - Fetch & Broadcast
  Future<List<Map<String, dynamic>>> getTeamBroadcastFeed() async {
    await init();
    try {
      final res = await client
          .from('team_broadcast_feed')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching team broadcast feed: $e');
      return [];
    }
  }

  Future<void> postTeamBroadcast({
    required String eventType,
    required String title,
    required String body,
  }) async {
    await init();
    final senderName = UserPreferencesStore.getUserName();
    await client.from('team_broadcast_feed').insert({
      'company_id': '11111111-1111-1111-1111-111111111111',
      'sender_name': senderName,
      'event_type': eventType,
      'title': title,
      'body': body,
    });
  }

  // 14. Upload Profile Avatar Image to Supabase 'avatars' Storage Bucket
  Future<String?> uploadAvatarImage(File imageFile) async {
    await init();
    final user = currentUser;
    if (user == null) return null;

    final fileExt = imageFile.path.split('.').last;
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      await client.storage.from('avatars').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final imageUrl = client.storage.from('avatars').getPublicUrl(fileName);

      await client.from('profiles').update({
        'avatar_url': imageUrl,
      }).eq('id', user.id);

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading avatar image: $e');
      return null;
    }
  }

  // 15. Upload Chat Attachment Image to Supabase 'chat_attachments' Storage Bucket
  Future<String?> uploadChatAttachment(File mediaFile) async {
    await init();
    final user = currentUser;
    if (user == null) return null;

    final fileExt = mediaFile.path.split('.').last;
    final fileName = 'chat_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      await client.storage.from('chat_attachments').upload(
        fileName,
        mediaFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      return client.storage.from('chat_attachments').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading chat attachment: $e');
      return null;
    }
  }

  // 16. Call Signaling & Realtime Calls
  Future<Map<String, dynamic>?> createCallInvite({
    required String receiverId,
    required bool isVideo,
  }) async {
    await init();
    final user = currentUser;
    if (user == null) return null;

    final callerName = UserPreferencesStore.getUserName();
    try {
      final res = await client.from('call_invites').insert({
        'caller_id': user.id,
        'receiver_id': receiverId,
        'caller_name': callerName,
        'is_video': isVideo,
        'status': 'ringing',
      }).select().single();
      return res;
    } catch (e) {
      debugPrint('Error creating call invite: $e');
      return null;
    }
  }

  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {
    await init();
    try {
      await client.from('call_invites').update({
        'status': status,
      }).eq('id', callId);
    } catch (e) {
      debugPrint('Error updating call status: $e');
    }
  }

  RealtimeChannel? subscribeToIncomingCalls({
    required Function(Map<String, dynamic> callData) onIncomingCall,
  }) {
    final user = currentUser;
    if (user == null) return null;

    final channel = client
        .channel('public:call_invites:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'call_invites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: user.id,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord['status'] == 'ringing') {
              onIncomingCall(newRecord);
            }
          },
        )
        .subscribe();

    return channel;
  }

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }
}
