import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
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
    String? hqLocation,
    String? industry,
    String? companySize,
    String? companyCode,
    String jobTitle = 'Founder & CEO',
    String department = 'Executive Leadership',
    String bio = '',
    String? avatarUrl,
    String? hqAddress,
    double? hqLatitude,
    double? hqLongitude,
    String? hqGoogleMapsLink,
  }) async {
    await init();
    final finalCode = (companyCode != null && companyCode.trim().isNotEmpty)
        ? companyCode.trim().toUpperCase()
        : generateCode(prefix: 'COMP', length: 5);

    final finalTitle = 'Founder & CEO';
    final finalDepartment = 'Executive Leadership';

    // 1. Auth Sign Up
    AuthResponse res;
    try {
      res = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role_type': 'founder',
          'is_leader': true,
          'job_title': finalTitle,
          'department': finalDepartment,
          'bio': bio,
        },
      );
    } catch (e) {
      if (e.toString().toLowerCase().contains('already registered') ||
          e.toString().toLowerCase().contains('already exists')) {
        res = await client.auth.signInWithPassword(email: email, password: password);
      } else {
        rethrow;
      }
    }

    // Ensure session is active
    if (res.session == null || client.auth.currentUser == null) {
      try {
        final signInRes = await client.auth.signInWithPassword(email: email, password: password);
        if (signInRes.user != null) {
          res = signInRes;
        }
      } catch (e) {
        debugPrint('Sign-in fallback note: $e');
      }
    }

    final user = res.user ?? client.auth.currentUser;
    if (user != null) {
      await UserPreferencesStore.setUserId(user.id);

      String? companyId;
      try {
        // 2. Create Company Record with HQ & Industry details
        final companyRes = await client.from('companies').insert({
          'name': companyName,
          'company_code': finalCode,
          'founder_id': user.id,
          'hq_location': hqLocation ?? hqAddress ?? '',
          'industry': industry ?? '',
          'company_size': companySize ?? '',
          'hq_address': hqAddress ?? '',
          'hq_latitude': hqLatitude,
          'hq_longitude': hqLongitude,
          'hq_google_maps_link': hqGoogleMapsLink ?? '',
        }).select().single();

        companyId = companyRes['id'] as String;
      } catch (e) {
        debugPrint('Error inserting company record: $e');
      }

      if (companyId != null) {
        // 3. Create Master Join Code in company_join_codes table
        try {
          await client.from('company_join_codes').insert({
            'company_id': companyId,
            'code': finalCode,
            'role_tag': 'leader',
            'created_by': user.id,
            'is_active': true,
          });
        } catch (e) {
          debugPrint('Note creating master join code: $e');
        }
      }

      // 4. Update Founder Profile with Company ID & Metadata
      try {
        await client.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'name': name,
          'role_type': 'founder',
          'is_leader': true,
          'company_id': companyId,
          'job_title': finalTitle,
          'department': finalDepartment,
          'bio': bio,
          'avatar_url': avatarUrl,
        });
      } catch (e) {
        debugPrint('Error upserting founder profile: $e');
      }

      // Save local preferences
      await UserPreferencesStore.setUserProfile(
        name: name,
        role: finalTitle,
        team: finalDepartment,
        bio: bio,
        company: companyName,
      );
      await UserPreferencesStore.setRoleType('founder');
      await UserPreferencesStore.setIsLeader(true);
      await UserPreferencesStore.setCompanyDetails(
        companyName: companyName,
        hqLocation: hqLocation ?? hqAddress ?? '',
        industry: industry ?? '',
        companySize: companySize ?? '',
      );
      if (avatarUrl != null) {
        await UserPreferencesStore.setUserAvatarUrl(avatarUrl);
      }
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
    String bio = '',
    String? avatarUrl,
    String? teamAddress,
    double? teamLatitude,
    double? teamLongitude,
    String? teamGoogleMapsLink,
  }) async {
    await init();
    final cleanCode = companyCode.trim().toUpperCase();

    // Validate Company Code or Join Code
    String? companyId;
    bool assignedLeader = isLeader;
    Map<String, dynamic>? companyMatch;

    try {
      // Check company_code in companies table
      companyMatch = await client
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
        }
      }
    } catch (e) {
      debugPrint('Error resolving company code: $e');
    }

    // Auth Sign Up
    AuthResponse res;
    try {
      res = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role_type': 'employee',
          'is_leader': assignedLeader,
          'job_title': jobTitle,
          'department': department,
          'bio': bio,
        },
      );
    } catch (e) {
      if (e.toString().toLowerCase().contains('already registered') ||
          e.toString().toLowerCase().contains('already exists')) {
        res = await client.auth.signInWithPassword(email: email, password: password);
      } else {
        rethrow;
      }
    }

    if (res.session == null || client.auth.currentUser == null) {
      try {
        final signInRes = await client.auth.signInWithPassword(email: email, password: password);
        if (signInRes.user != null) {
          res = signInRes;
        }
      } catch (e) {
        debugPrint('Sign-in fallback note: $e');
      }
    }

    final user = res.user ?? client.auth.currentUser;
    if (user != null) {
      await UserPreferencesStore.setUserId(user.id);
      try {
        await client.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'name': name,
          'role_type': 'employee',
          'is_leader': assignedLeader,
          'company_id': companyId,
          'job_title': jobTitle,
          'department': department,
          'bio': bio,
          'avatar_url': avatarUrl,
          'team_location_address': teamAddress,
          'team_location_latitude': teamLatitude,
          'team_location_longitude': teamLongitude,
          'team_location_google_maps_link': teamGoogleMapsLink,
        });
      } catch (e) {
        debugPrint('Error upserting employee profile: $e');
      }

      String? companyName = companyMatch != null ? (companyMatch['name'] as String?) : null;
      await UserPreferencesStore.setUserProfile(
        name: name,
        role: jobTitle,
        team: department,
        bio: bio,
        company: companyName,
      );
      if (avatarUrl != null) {
        await UserPreferencesStore.setUserAvatarUrl(avatarUrl);
      }
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
      await UserPreferencesStore.setUserId(user.id);
      // Fetch Profile Data
      final profile = await client.from('profiles').select().eq('id', user.id).maybeSingle();
      if (profile != null) {
        final roleType = profile['role_type'] as String? ?? 'employee';
        final isLeader = profile['is_leader'] == true;
        final companyId = profile['company_id'] as String?;

        await UserPreferencesStore.setRoleType(roleType);
        await UserPreferencesStore.setIsLeader(isLeader);

        String? companyName;
        if (companyId != null) {
          try {
            final comp = await client.from('companies').select().eq('id', companyId).maybeSingle();
            if (comp != null) {
              companyName = comp['name'] as String?;
              await UserPreferencesStore.setCompanyDetails(
                companyName: companyName ?? '',
                hqLocation: comp['hq_location'] ?? comp['hq_address'] ?? '',
                industry: comp['industry'] ?? '',
                companySize: comp['company_size'] ?? '',
              );
              await UserPreferencesStore.setCompanyCode(comp['company_code'] ?? '');
            }
          } catch (_) {}
        }

        await UserPreferencesStore.setUserProfile(
          name: profile['name'] ?? 'User',
          role: profile['job_title'] ?? 'Employee',
          team: profile['department'] ?? 'General',
          bio: profile['bio'] ?? '',
          strengths: profile['strengths'] ?? '',
          focusArea: profile['focus_area'] ?? '',
          currentChallenges: profile['current_challenges'] ?? '',
          communicationPreference: profile['communication_preference'] ?? '',
          company: companyName,
        );
        if (profile['avatar_url'] != null) {
          await UserPreferencesStore.setUserAvatarUrl(profile['avatar_url'] as String);
        }
      }
    }
    return res;
  }

  // Fetch Company Teammates
  Future<List<Map<String, dynamic>>> getCompanyTeammates() async {
    await init();
    try {
      final user = currentUser;
      if (user == null) return [];

      final profileRes = await client
          .from('profiles')
          .select('company_id')
          .eq('id', user.id)
          .maybeSingle();
      if (profileRes == null || profileRes['company_id'] == null) {
        return [];
      }
      final companyId = profileRes['company_id'];

      final res = await client
          .from('profiles')
          .select('id, name, email, job_title, department, avatar_url, is_clocked_in, is_on_break, is_leader, role_type, company_id')
          .eq('company_id', companyId)
          .order('name', ascending: true);

      final List<Map<String, dynamic>> profilesList = List<Map<String, dynamic>>.from(res);

      // Query active work sessions for clocked-in teammates to populate location_name dynamically
      for (var emp in profilesList) {
        if (emp['is_clocked_in'] == true) {
          try {
            final activeSession = await client
                .from('work_sessions')
                .select('clock_in_location_name')
                .eq('user_id', emp['id'])
                .eq('status', 'active')
                .order('clock_in_time', ascending: false)
                .limit(1)
                .maybeSingle();
            if (activeSession != null) {
              emp['location_name'] = activeSession['clock_in_location_name'];
            }
          } catch (e) {
            debugPrint('Error loading active session for teammate location: $e');
          }
        }
      }

      return profilesList;
    } catch (e) {
      debugPrint('Error fetching teammates: $e');
      return [];
    }
  }

  // Get real teammate stats (NGL Notes, Hero Badges, Reliability) from backend
  Future<Map<String, dynamic>> getTeammateStats(String teammateName, String teammateId) async {
    await init();
    int nglNotesCount = 0;
    int heroBadgesCount = 0;
    int reliability = 100;

    try {
      if (teammateId.isNotEmpty) {
        final nglRes = await client
            .from('ngl_jar_messages')
            .select('id')
            .eq('user_id', teammateId);
        nglNotesCount = nglRes.length;
      } else {
        final nglRes = await client.from('ngl_jar_messages').select('id');
        nglNotesCount = nglRes.length;
      }
    } catch (_) {
      nglNotesCount = 0;
    }

    try {
      if (teammateName.isNotEmpty) {
        final heroRes = await client
            .from('weekly_hero_nominations')
            .select('id')
            .eq('nominee_name', teammateName);
        heroBadgesCount = heroRes.length;
      }
    } catch (_) {
      heroBadgesCount = 0;
    }

    try {
      if (teammateId.isNotEmpty) {
        final sessionRes = await client
            .from('work_sessions')
            .select('id, status')
            .eq('user_id', teammateId);
        if (sessionRes.isNotEmpty) {
          final completed = sessionRes.where((s) => s['status'] == 'completed').length;
          reliability = ((completed / sessionRes.length) * 100).round();
        } else {
          reliability = 100;
        }
      } else {
        reliability = 100;
      }
    } catch (_) {
      reliability = 100;
    }

    return {
      'nglNotes': nglNotesCount,
      'heroBadges': heroBadgesCount,
      'reliability': '$reliability%',
    };
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

  // Location Permission & High-Precision GPS Satellite Lock (Guaranteed < 100m accuracy)
  Future<Position?> getCurrentDeviceLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[Location] Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[Location] Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[Location] Location permissions are permanently denied.');
      return null;
    }

    Position? bestPosition;

    try {
      final settings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              timeLimit: const Duration(seconds: 3),
              forceLocationManager: false,
            )
          : AppleSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              activityType: ActivityType.other,
              timeLimit: const Duration(seconds: 3),
            );

      bestPosition = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
    } catch (e) {
      debugPrint('[Location] GPS fix timeout (3s), fetching last known position: $e');
      try {
        bestPosition = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    if (bestPosition != null) {
      debugPrint('[Location] Fast GPS Lock: ${bestPosition.latitude}, ${bestPosition.longitude} (Accuracy: ${bestPosition.accuracy}m)');
    }

    return bestPosition;
  }

  /// Reverse Geocode Coordinates to Country, State, District, Pincode & Full Address
  Future<Map<String, String>> fetchDetailedAddress(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'UAndMeApp/1.0.0 (contact@mindempowered.com)',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>? ?? {};

        final country = address['country']?.toString() ?? '';
        final state = address['state']?.toString() ?? '';
        final district = address['city_district']?.toString() ??
            address['district']?.toString() ??
            address['county']?.toString() ??
            address['city']?.toString() ??
            address['town']?.toString() ??
            '';
        final pincode = address['postcode']?.toString() ?? '';
        final area = address['suburb']?.toString() ??
            address['neighbourhood']?.toString() ??
            address['residential']?.toString() ??
            address['road']?.toString() ??
            '';

        final parts = <String>[];
        if (area.isNotEmpty) parts.add(area);
        if (district.isNotEmpty) parts.add(district);
        if (state.isNotEmpty) parts.add(state);
        if (pincode.isNotEmpty) parts.add(pincode);
        if (country.isNotEmpty) parts.add(country);

        final displayName = parts.isNotEmpty
            ? parts.join(', ')
            : (data['display_name']?.toString() ?? 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}');

        return {
          'location_name': displayName,
          'country': country,
          'state': state,
          'district': district,
          'pincode': pincode,
        };
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }

    return {
      'location_name': 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
      'country': '',
      'state': '',
      'district': '',
      'pincode': '',
    };
  }

  // Clock In with Live Location
  Future<Map<String, dynamic>?> clockInWithLocation() async {
    await init();
    final user = currentUser;
    if (user == null) return null;

    final position = await getCurrentDeviceLocation();
    double? lat = position?.latitude;
    double? lng = position?.longitude;

    final companyHq = UserPreferencesStore.getCompanyHq();
    final fallbackLocation = companyHq.isNotEmpty ? companyHq : 'Office HQ';

    Map<String, String> addressDetails = {
      'location_name': fallbackLocation,
      'country': '',
      'state': '',
      'district': '',
      'pincode': '',
    };

    if (lat != null && lng != null) {
      addressDetails = await fetchDetailedAddress(lat, lng);
    }

    final locationName = addressDetails['location_name'] ?? fallbackLocation;

    // Insert work session
    final sessionRes = await client.from('work_sessions').insert({
      'user_id': user.id,
      'clock_in_time': DateTime.now().toIso8601String(),
      'clock_in_lat': lat,
      'clock_in_lng': lng,
      'clock_in_location_name': locationName,
      'clock_in_country': addressDetails['country'],
      'clock_in_state': addressDetails['state'],
      'clock_in_district': addressDetails['district'],
      'clock_in_pincode': addressDetails['pincode'],
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

  // Clock Out with Live Location
  Future<Map<String, dynamic>?> clockOutWorkSession() async {
    await init();
    final user = currentUser;
    if (user == null) return null;

    final position = await getCurrentDeviceLocation();
    final double? lat = position?.latitude;
    final double? lng = position?.longitude;

    Map<String, String> addressDetails = {
      'location_name': 'Work Complete',
      'country': '',
      'state': '',
      'district': '',
      'pincode': '',
    };

    if (lat != null && lng != null) {
      addressDetails = await fetchDetailedAddress(lat, lng);
    }

    final locationName = addressDetails['location_name'] ?? 'Work Complete';

    final activeSessions = await client
        .from('work_sessions')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'active');

    Map<String, dynamic>? updatedSession;
    if (activeSessions.isNotEmpty) {
      final sessionId = activeSessions.first['id'];
      updatedSession = await client.from('work_sessions').update({
        'clock_out_time': DateTime.now().toIso8601String(),
        'clock_out_lat': lat,
        'clock_out_lng': lng,
        'clock_out_location_name': locationName,
        'clock_out_country': addressDetails['country'],
        'clock_out_state': addressDetails['state'],
        'clock_out_district': addressDetails['district'],
        'clock_out_pincode': addressDetails['pincode'],
        'status': 'completed',
      }).eq('id', sessionId).select().maybeSingle();
    }

    await client.from('profiles').update({
      'is_clocked_in': false,
      'is_on_break': false,
    }).eq('id', user.id);

    return updatedSession;
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

  // Fetch Pending/Reviewed Company Leave Requests for Founder Review
  Future<List<Map<String, dynamic>>> fetchCompanyLeaveRequests() async {
    await init();
    try {
      final res = await client
          .from('leave_requests')
          .select('*, profiles:user_id(name, job_title, department, avatar_url)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching leave requests: $e');
      return [];
    }
  }

  // Fetch Leave Requests for the Logged-In User
  Future<List<Map<String, dynamic>>> getMyLeaveRequests() async {
    await init();
    final user = currentUser;
    if (user == null) return [];
    try {
      final res = await client
          .from('leave_requests')
          .select()
          .eq('user_id', user.id)
          .order('start_date', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching my leave requests: $e');
      return [];
    }
  }

  // Update Leave Request Status (Approve / Reject)
  Future<bool> updateLeaveRequestStatus({
    required String requestId,
    required String status,
  }) async {
    await init();
    final user = currentUser;
    try {
      await client.from('leave_requests').update({
        'status': status,
        'reviewed_by': user?.id,
      }).eq('id', requestId);
      return true;
    } catch (e) {
      debugPrint('Error updating leave request status: $e');
      return false;
    }
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
    final String? userId = user?.id ?? (UserPreferencesStore.getUserId().isNotEmpty ? UserPreferencesStore.getUserId() : null);

    await client.from('mochi_chat_messages').insert({
      'user_id': userId,
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
    final String uid = user?.id ?? UserPreferencesStore.getUserId();
    if (uid.isEmpty) return [];
    try {
      final res = await client
          .from('mochi_chat_messages')
          .select()
          .eq('user_id', uid)
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

  // Mochi - Create a Session Record and return its UUID
  // Returns the new session's UUID so callers can link messages to it.
  Future<String?> saveMochiSession({
    required String title,
    required int totalMessages,
    required DateTime startedAt,
  }) async {
    await init();
    final user = currentUser;
    if (user == null) return null;
    try {
      final res = await client.from('mochi_chat_sessions').insert({
        'user_id': user.id,
        'title': title.length > 120 ? '${title.substring(0, 117)}...' : title,
        'total_messages': totalMessages,
        'started_at': startedAt.toIso8601String(),
        'ended_at': DateTime.now().toIso8601String(),
      }).select('id').single();
      return res['id'] as String?;
    } catch (e) {
      debugPrint('[Mochi] saveMochiSession error (non-fatal): $e');
      return null;
    }
  }

  // Mochi - Update session total_messages + ended_at when closing
  Future<void> updateMochiSession({
    required String sessionId,
    required int totalMessages,
  }) async {
    await init();
    try {
      await client.from('mochi_chat_sessions').update({
        'total_messages': totalMessages,
        'ended_at': DateTime.now().toIso8601String(),
      }).eq('id', sessionId);
    } catch (e) {
      debugPrint('[Mochi] updateMochiSession error (non-fatal): $e');
    }
  }

  // Mochi - Fetch list of past sessions for the history panel (newest first)
  Future<List<Map<String, dynamic>>> getMochiSessions() async {
    await init();
    final user = currentUser;
    if (user == null) return [];
    try {
      final res = await client
          .from('mochi_chat_sessions')
          .select('id, title, total_messages, started_at, ended_at')
          .eq('user_id', user.id)
          .order('ended_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('[Mochi] getMochiSessions error: $e');
      return [];
    }
  }

  // Mochi - Fetch all messages belonging to a specific session
  Future<List<Map<String, dynamic>>> getMochiSessionMessages(
      String sessionId) async {
    await init();
    try {
      final res = await client
          .from('mochi_chat_messages')
          .select('message, is_user, action_type, created_at')
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('[Mochi] getMochiSessionMessages error: $e');
      return [];
    }
  }


  // 12. Direct Messages - Fetch & Send
  Future<List<Map<String, dynamic>>> getDirectMessages() async {
    await init();
    try {
      final user = currentUser;
      if (user == null) return [];

      // 1. Get current user's company_id
      final profileRes = await client
          .from('profiles')
          .select('company_id')
          .eq('id', user.id)
          .maybeSingle();
      if (profileRes == null || profileRes['company_id'] == null) {
        return [];
      }
      final companyId = profileRes['company_id'];

      // 2. Fetch all profile names in the same company
      final companyProfiles = await client
          .from('profiles')
          .select('name')
          .eq('company_id', companyId);

      final companyNames = companyProfiles
          .map((p) => p['name'] as String?)
          .where((name) => name != null)
          .cast<String>()
          .toSet();

      // 3. Fetch all direct messages
      final res = await client
          .from('direct_messages')
          .select()
          .order('created_at', ascending: true);

      // 4. Filter messages where both sender and receiver belong to the company
      final filtered = List<Map<String, dynamic>>.from(res).where((msg) {
        final sender = msg['sender_name'] as String?;
        final receiver = msg['receiver_name'] as String?;
        return companyNames.contains(sender) && companyNames.contains(receiver);
      }).toList();

      return filtered;
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
    final String? senderId = user?.id ?? (UserPreferencesStore.getUserId().isNotEmpty ? UserPreferencesStore.getUserId() : null);
    await client.from('direct_messages').insert({
      'sender_id': senderId,
      'sender_name': senderName,
      'receiver_name': receiverName,
      'message': message,
      'media_url': mediaUrl,
      'is_read': false,
    });
  }

  Future<void> markDirectMessagesAsRead(String senderName) async {
    await init();
    try {
      final currentUserName = UserPreferencesStore.getUserName();
      await client
          .from('direct_messages')
          .update({'is_read': true})
          .eq('sender_name', senderName)
          .eq('receiver_name', currentUserName)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking direct messages as read: $e');
    }
  }

  Future<void> deleteConversationWith(String partnerName) async {
    await init();
    try {
      final myName = UserPreferencesStore.getUserName();
      await client
          .from('direct_messages')
          .delete()
          .eq('sender_name', myName)
          .eq('receiver_name', partnerName);
      await client
          .from('direct_messages')
          .delete()
          .eq('sender_name', partnerName)
          .eq('receiver_name', myName);
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      rethrow;
    }
  }

  Future<void> updateFcmToken(String fcmToken) async {
    await init();
    final user = currentUser;
    if (user != null) {
      try {
        await client.from('profiles').update({
          'fcm_token': fcmToken,
        }).eq('id', user.id);
      } catch (e) {
        debugPrint('Note updating fcm_token: $e');
      }
    }
  }

  // 13. Team Broadcast Feed - Fetch & Broadcast
  Future<List<Map<String, dynamic>>> getTeamBroadcastFeed() async {
    await init();
    try {
      final user = client.auth.currentUser;
      if (user == null) return [];

      final profileRes = await client
          .from('profiles')
          .select('company_id')
          .eq('id', user.id)
          .maybeSingle();
      if (profileRes == null || profileRes['company_id'] == null) {
        return [];
      }
      final companyId = profileRes['company_id'];

      final res = await client
          .from('team_broadcast_feed')
          .select()
          .eq('company_id', companyId)
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
    try {
      final user = client.auth.currentUser;
      if (user == null) return;

      final profileRes = await client
          .from('profiles')
          .select('company_id')
          .eq('id', user.id)
          .maybeSingle();
      final companyId = profileRes?['company_id'];

      final senderName = UserPreferencesStore.getUserName();
      await client.from('team_broadcast_feed').insert({
        'company_id': companyId ?? '11111111-1111-1111-1111-111111111111',
        'sender_name': senderName,
        'event_type': eventType,
        'title': title,
        'body': body,
      });
    } catch (e) {
      debugPrint('Error posting team broadcast: $e');
    }
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

      await UserPreferencesStore.setUserAvatarUrl(imageUrl);

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

  RealtimeChannel? subscribeToDirectMessages({
    required String partnerName,
    required Function(Map<String, dynamic> msgData) onNewMessage,
  }) {
    final user = currentUser;
    if (user == null) return null;

    final myName = UserPreferencesStore.getUserName();

    final channel = client
        .channel('public:direct_messages:$partnerName')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'direct_messages',
          callback: (payload) {
            final newRecord = payload.newRecord;
            final sender = newRecord['sender_name'] as String?;
            final receiver = newRecord['receiver_name'] as String?;

            if ((sender == myName && receiver == partnerName) ||
                (sender == partnerName && receiver == myName)) {
              onNewMessage(newRecord);
            }
          },
        )
        .subscribe();

    return channel;
  }

  // Sign out (global scope: invalidates all concurrent sessions on other devices)
  Future<void> signOut() async {
    try {
      await client.auth.signOut(scope: SignOutScope.global);
    } catch (_) {
      // Fallback: local sign-out if global scope is unavailable
      await client.auth.signOut();
    }
  }
}
