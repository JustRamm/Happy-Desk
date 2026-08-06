import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'leave_history_screen.dart';
import '../services/supabase_service.dart';

class WorkSessionDetailsScreen extends StatefulWidget {
  final int initialTabIndex;
  const WorkSessionDetailsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<WorkSessionDetailsScreen> createState() =>
      _WorkSessionDetailsScreenState();
}

class _WorkSessionDetailsScreenState extends State<WorkSessionDetailsScreen> {
  bool _isClockedIn = false;
  String _reliability = '100.0%';
  String _avgWorkhour = '8h 00m';
  final List<Map<String, String>> _attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    _checkClockInStatus();
    _loadWorkSessionHistory();
  }

  Future<void> _checkClockInStatus() async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        final profile = await SupabaseService.instance.client
            .from('profiles')
            .select('is_clocked_in')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null && mounted) {
          setState(() {
            _isClockedIn = profile['is_clocked_in'] == true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking clock-in status: $e');
    }
  }

  Future<void> _loadWorkSessionHistory() async {
    final history = await SupabaseService.instance.getWorkSessionHistory();
    if (mounted) {
      setState(() {
        _attendanceHistory.clear();
        double totalHours = 0;
        int completedCount = 0;
        int totalCount = history.length;

        for (var sess in history) {
          final inTime = sess['clock_in_time'] != null ? sess['clock_in_time'].toString().split('T').last.substring(0, 5) : '09:00 AM';
          final outTime = sess['clock_out_time'] != null ? sess['clock_out_time'].toString().split('T').last.substring(0, 5) : (sess['status'] == 'active' ? 'In Progress' : '05:00 PM');
          final loc = sess['clock_in_location_name'] ?? 'Office HQ';
          
          String hoursText = '8h 00m';
          if (sess['clock_in_time'] != null && sess['clock_out_time'] != null) {
            final start = DateTime.parse(sess['clock_in_time'].toString());
            final end = DateTime.parse(sess['clock_out_time'].toString());
            final diff = end.difference(start);
            final hours = diff.inMinutes / 60.0;
            totalHours += hours;
            completedCount++;
            hoursText = '${diff.inHours}h ${diff.inMinutes % 60}m';
          }

          _attendanceHistory.add({
            'date': sess['clock_in_time'] != null ? sess['clock_in_time'].toString().split('T').first : 'Today',
            'in': inTime,
            'out': outTime,
            'location': loc,
            'hours': sess['status'] == 'active' ? 'Active' : hoursText,
            'status': sess['status'] == 'active' ? 'Active Shift' : 'Completed',
          });
        }

        if (completedCount > 0) {
          final avg = totalHours / completedCount;
          final avgMinutes = (avg * 60).round();
          _avgWorkhour = '${avgMinutes ~/ 60}h ${avgMinutes % 60}m';
        } else {
          _avgWorkhour = '8h 00m';
        }

        if (totalCount > 0) {
          final rel = (completedCount.toDouble() / totalCount.toDouble()) * 100.0;
          _reliability = '${rel.toStringAsFixed(1)}%';
        } else {
          _reliability = '100.0%';
        }
      });
    }
  }

  void _toggleShift() async {
    try {
      if (_isClockedIn) {
        await SupabaseService.instance.clockOutWorkSession();
        if (!mounted) return;
        setState(() {
          _isClockedIn = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Shift ended. Clocked out successfully!',
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF006C53),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      } else {
        final session = await SupabaseService.instance.clockInWithLocation();
        if (!mounted) return;
        setState(() {
          _isClockedIn = true;
        });
        final loc = session?['clock_in_location_name'] ?? 'Office HQ';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Clocked in successfully from $loc! Broadcast sent to team.',
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: const Color(0xFFAB3500),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
      _loadWorkSessionHistory();
    } catch (e) {
      debugPrint('Error toggling shift: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF171B2B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Work Session Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF171B2B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.beach_access_rounded,
              color: Color(0xFFFF6B35),
              size: 24,
            ),
            tooltip: 'My Leave Status & History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaveHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildShiftHistoryTab(),
    );
  }

  Widget _buildShiftHistoryTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Current Shift Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _isClockedIn
                  ? const Color(0xFFAB3500)
                  : const Color(0xFF171B2B),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (_isClockedIn
                          ? const Color(0xFFAB3500)
                          : const Color(0xFF171B2B))
                      .withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isClockedIn
                                  ? const Color(0xFF64FBCE)
                                  : Colors.orangeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isClockedIn ? 'ON SHIFT' : 'OFF SHIFT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '09:00 AM - 05:00 PM',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  _isClockedIn ? 'Shift Active' : 'Shift Not Started',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isClockedIn
                      ? 'You are currently clocked in and active.'
                      : 'Tap below to log time & location',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _toggleShift,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _isClockedIn
                          ? const Color(0xFFAB3500)
                          : const Color(0xFF171B2B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isClockedIn ? 'Clock Out of Shift' : 'Clock In Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Weekly Metrics Grid
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4E7FE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF006C53), size: 22),
                      const SizedBox(height: 10),
                      Text(
                        _reliability,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF171B2B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Weekly Reliability',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF006C53),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4E7FE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.schedule_rounded,
                          color: Color(0xFFAB3500), size: 22),
                      const SizedBox(height: 10),
                      Text(
                        _avgWorkhour,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF171B2B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Average Workhour',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFAB3500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Daily Clock-In History Timeline (With Saved Location)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Daily Shift History & Location Logs',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF171B2B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFFAB3500)),
                    const SizedBox(width: 4),
                    Text(
                      'Location Saved',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFAB3500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._attendanceHistory.map((item) {
            final isActive = item['status'] == 'Active Shift';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : const Color(0xFFF3F2FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFFFD6C7)
                      : const Color(0xFFDEE1F8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFFFF0EB)
                              : const Color(0xFFEBEDFF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isActive
                              ? Icons.timer_rounded
                              : Icons.history_rounded,
                          color: isActive
                              ? const Color(0xFFAB3500)
                              : const Color(0xFF594139),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['date']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF171B2B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'In: ${item['in']} • Out: ${item['out']}',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: const Color(0xFF594139),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['location']!,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFAB3500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFFFF0EB)
                          : const Color(0xFFEBF7F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['hours']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? const Color(0xFFAB3500)
                            : const Color(0xFF006C53),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
