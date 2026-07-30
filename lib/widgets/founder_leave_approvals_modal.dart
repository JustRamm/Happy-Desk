import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../services/sound_service.dart';

class FounderLeaveApprovalsModal extends StatefulWidget {
  const FounderLeaveApprovalsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FounderLeaveApprovalsModal(),
    );
  }

  @override
  State<FounderLeaveApprovalsModal> createState() =>
      _FounderLeaveApprovalsModalState();
}

class _FounderLeaveApprovalsModalState
    extends State<FounderLeaveApprovalsModal> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _leaveRequests = [];

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await SupabaseService.instance.fetchCompanyLeaveRequests();
      if (mounted) {
        setState(() {
          _leaveRequests = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _leaveRequests = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDecision(String requestId, String newStatus) async {
    SoundService.playMessageOpenSound();

    setState(() {
      final index = _leaveRequests.indexWhere((item) => item['id'] == requestId);
      if (index != -1) {
        _leaveRequests[index]['status'] = newStatus;
      }
    });

    if (!requestId.startsWith('mock-')) {
      await SupabaseService.instance.updateLeaveRequestStatus(
        requestId: requestId,
        status: newStatus,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == 'approved'
              ? 'Leave request approved successfully!'
              : 'Leave request rejected.',
        ),
        backgroundColor: newStatus == 'approved'
            ? const Color(0xFF047857)
            : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _leaveRequests.where((r) => r['status'] == 'pending').length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9FE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E7FE),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),

          // Modal Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employee Leave Approvals',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF171B2B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$pendingCount Pending Review',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFAB3500),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF171B2B)),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Divider(height: 1, color: Color(0xFFE4E7FE)),
          ),

          // Leave Request Cards List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFAB3500)),
                  )
                : _leaveRequests.isEmpty
                    ? Center(
                        child: Text(
                          'No leave requests found.',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            color: const Color(0xFF8D7168),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        itemCount: _leaveRequests.length,
                        itemBuilder: (context, index) {
                          final item = _leaveRequests[index];
                          final id = item['id'] as String;

                          final profiles = item['profiles'] as Map<String, dynamic>?;
                          final name = profiles != null
                              ? (profiles['name'] as String? ?? 'Employee')
                              : (item['user_name'] as String? ?? 'Employee');
                          final role = profiles != null
                              ? (profiles['job_title'] as String? ?? 'Team Member')
                              : (item['job_title'] as String? ?? 'Team Member');
                          final avatar = profiles != null
                              ? (profiles['avatar_url'] as String? ?? '')
                              : (item['avatar_url'] as String? ?? '');

                          final leaveType = item['leave_type'] ?? 'Casual Leave';
                          final startDate = item['start_date'] ?? 'Today';
                          final endDate = item['end_date'] ?? 'Tomorrow';
                          final reason = item['reason'] ?? 'Personal reasons.';
                          final status = item['status'] ?? 'pending';

                          Color statusColor = const Color(0xFFD97706);
                          Color statusBg = const Color(0xFFFEF3C7);
                          String statusText = 'Pending Approval';

                          if (status == 'approved') {
                            statusColor = const Color(0xFF047857);
                            statusBg = const Color(0xFFD1FAE5);
                            statusText = 'Approved';
                          } else if (status == 'rejected') {
                            statusColor = const Color(0xFFDC2626);
                            statusBg = const Color(0xFFFEE2E2);
                            statusText = 'Rejected';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE4E7FE)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: const Color(0xFFFFF0EB),
                                      child: (avatar.startsWith('http') || (avatar.isNotEmpty && File(avatar).existsSync()))
                                          ? ClipOval(
                                              child: avatar.startsWith('http')
                                                  ? Image.network(avatar, fit: BoxFit.cover, width: 44, height: 44)
                                                  : Image.file(File(avatar), fit: BoxFit.cover, width: 44, height: 44),
                                            )
                                          : Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFFAB3500),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF171B2B),
                                            ),
                                          ),
                                          Text(
                                            role,
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 12,
                                              color: const Color(0xFF594139),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0EB),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        leaveType,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFAB3500),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '$startDate – $endDate',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF171B2B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Reason: $reason',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12.5,
                                    color: const Color(0xFF594139),
                                  ),
                                ),
                                if (status == 'pending') ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _handleDecision(id, 'approved'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF047857),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                                          label: Text(
                                            'Approve',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _handleDecision(id, 'rejected'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFDC2626),
                                            side: const BorderSide(color: Color(0xFFDC2626)),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          icon: const Icon(Icons.cancel_rounded, size: 16),
                                          label: Text(
                                            'Reject',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
