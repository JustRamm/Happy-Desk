import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import 'apply_leave_modal.dart';

class MyLeaveStatsModal extends StatefulWidget {
  const MyLeaveStatsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const MyLeaveStatsModal(),
      ),
    );
  }

  @override
  State<MyLeaveStatsModal> createState() => _MyLeaveStatsModalState();
}

class _MyLeaveStatsModalState extends State<MyLeaveStatsModal> {
  List<Map<String, dynamic>> _leaveRequests = [];
  bool _isLoading = true;

  int _casualUsed = 0;
  int _sickUsed = 0;
  int _annualUsed = 0;

  @override
  void initState() {
    super.initState();
    _loadLeaveData();
  }

  Future<void> _loadLeaveData() async {
    try {
      final list = await SupabaseService.instance.getMyLeaveRequests();
      int casual = 0;
      int sick = 0;
      int annual = 0;

      for (var req in list) {
        final status = req['status'] as String? ?? 'pending';
        if (status == 'approved' || status == 'completed') {
          final type = req['leave_type'] as String? ?? '';
          final days = _calculateLeaveDays(req['start_date']?.toString() ?? '', req['end_date']?.toString() ?? '');
          if (type.toLowerCase().contains('casual')) {
            casual += days;
          } else if (type.toLowerCase().contains('sick')) {
            sick += days;
          } else {
            annual += days;
          }
        }
      }

      if (mounted) {
        setState(() {
          _leaveRequests = list;
          _casualUsed = casual;
          _sickUsed = sick;
          _annualUsed = annual;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading leave data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _calculateLeaveDays(String startStr, String endStr) {
    try {
      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);
      return end.difference(start).inDays + 1;
    } catch (_) {
      return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final casualTotal = 12;
    final sickTotal = 7;
    final annualTotal = 15;

    final casualLeft = (casualTotal - _casualUsed).clamp(0, casualTotal);
    final sickLeft = (sickTotal - _sickUsed).clamp(0, sickTotal);
    final annualLeft = (annualTotal - _annualUsed).clamp(0, annualTotal);

    final casualProgress = casualTotal > 0 ? (_casualUsed / casualTotal) : 0.0;
    final sickProgress = sickTotal > 0 ? (_sickUsed / sickTotal) : 0.0;
    final annualProgress = annualTotal > 0 ? (_annualUsed / annualTotal) : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle & Title Row
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4E7FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF0EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.beach_access_rounded,
                            color: Color(0xFFFF6B35),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Leave Stats & History',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2D3142),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Annual leave quotas & application history',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11.5,
                                  color: const Color(0xFF8D7168),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF8D7168)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section 1: Leave Quota & Balance Cards Grid
              Text(
                'LEAVE BALANCE QUOTAS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF8D7168),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildQuotaCard(
                      label: 'Casual Leave',
                      remaining: '$casualLeft Days Left',
                      usedText: '$_casualUsed/$casualTotal Used',
                      progress: casualProgress,
                      color: const Color(0xFFFF6B35),
                      bgColor: const Color(0xFFFFF0EB),
                      icon: Icons.beach_access_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuotaCard(
                      label: 'Sick Leave',
                      remaining: '$sickLeft Days Left',
                      usedText: '$_sickUsed/$sickTotal Used',
                      progress: sickProgress,
                      color: const Color(0xFF00C49A),
                      bgColor: const Color(0xFFEBF7F5),
                      icon: Icons.healing_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuotaCard(
                      label: 'Annual Rest',
                      remaining: '$annualLeft Days Left',
                      usedText: '$_annualUsed/$annualTotal Used',
                      progress: annualProgress,
                      color: const Color(0xFFFF99C8),
                      bgColor: const Color(0xFFFFF0F7),
                      icon: Icons.flight_takeoff_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section 2: Application History List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MY LEAVE HISTORY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8D7168),
                      letterSpacing: 1.1,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_leaveRequests.length} Records',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF95416C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    )
                  : _leaveRequests.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Text(
                              'No leave requests found.',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13.5,
                                color: const Color(0xFF8D7168),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _leaveRequests.map((req) {
                            final type = req['leave_type'] ?? 'Leave';
                            final start = req['start_date'] ?? '';
                            final end = req['end_date'] ?? '';
                            final reason = req['reason'] ?? 'No reason provided';
                            final status = req['status'] ?? 'pending';

                            IconData iconData = Icons.beach_access_rounded;
                            Color statusColor = const Color(0xFF00C49A);
                            Color statusBg = const Color(0xFFEBF7F5);

                            if (type.toString().toLowerCase().contains('sick')) {
                              iconData = Icons.healing_rounded;
                              statusColor = const Color(0xFF00AE88);
                            } else if (type.toString().toLowerCase().contains('annual')) {
                              iconData = Icons.flight_takeoff_rounded;
                              statusColor = const Color(0xFFFF99C8);
                            }

                            if (status == 'pending') {
                              statusColor = const Color(0xFFFF9F1C);
                              statusBg = const Color(0xFFFFF4E5);
                            } else if (status == 'rejected') {
                              statusColor = const Color(0xFFAB3500);
                              statusBg = const Color(0xFFFFF0EB);
                            }

                            final days = _calculateLeaveDays(start, end);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: _buildHistoryCard(
                                type: '$type ($days ${days == 1 ? "Day" : "Days"})',
                                dates: '$start – $end',
                                reason: reason,
                                status: status[0].toUpperCase() + status.substring(1),
                                statusColor: statusColor,
                                statusBg: statusBg,
                                icon: iconData,
                              ),
                            );
                          }).toList(),
                        ),

              const SizedBox(height: 24),

              // Bottom Button: Apply New Leave
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ApplyLeaveModal.show(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: Text(
                    'Apply New Leave',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotaCard({
    required String label,
    required String remaining,
    required String usedText,
    required double progress,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8D7168),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            remaining,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF3F2FF),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            usedText,
            style: GoogleFonts.beVietnamPro(
              fontSize: 10,
              color: const Color(0xFF8D7168),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required String type,
    required String dates,
    required String reason,
    required String status,
    required Color statusColor,
    required Color statusBg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        type,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dates,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Note: $reason',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: const Color(0xFF4A4E69),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
