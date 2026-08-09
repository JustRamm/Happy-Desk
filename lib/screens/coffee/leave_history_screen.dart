import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apply_leave_modal.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: Text(
          'Leave Stats & Log',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: AppTheme.titleDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.titleDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance quotas heading
              Text(
                'LEAVE BALANCE QUOTAS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildQuotaCard(
                      label: 'Casual Leave',
                      remaining: '$casualLeft Days Left',
                      usedText: '$_casualUsed/$casualTotal Used',
                      progress: casualProgress,
                      color: AppTheme.primaryRust,
                      bgColor: const Color(0xFFFFF0EB),
                      icon: Icons.beach_access_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 8),
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
              const SizedBox(height: 28),

              // Leave history heading
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MY LEAVE HISTORY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_leaveRequests.length} Records',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5B3FF2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryRust,
                        ),
                      ),
                    )
                  : _leaveRequests.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Text(
                              'No leave requests found.',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
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
                              statusColor = AppTheme.primaryRust;
                              statusBg = const Color(0xFFFFF0EB);
                            }

                            final days = _calculateLeaveDays(start, end);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEFF1F7))),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () async {
              await ApplyLeaveModal.show(context);
              _loadLeaveData(); // reload on return
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRust,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(
              'Apply New Leave',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
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
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
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
              color: AppTheme.titleDark,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF3F2FF),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            usedText,
            style: GoogleFonts.beVietnamPro(
              fontSize: 10,
              color: AppTheme.textSecondary,
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
                          color: AppTheme.titleDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryRust,
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
