import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'apply_leave_modal.dart';

class MyLeaveStatsModal extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                      remaining: '3 Days Left',
                      usedText: '9/12 Used',
                      progress: 0.75,
                      color: const Color(0xFFFF6B35),
                      bgColor: const Color(0xFFFFF0EB),
                      icon: Icons.beach_access_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuotaCard(
                      label: 'Sick Leave',
                      remaining: '5 Days Left',
                      usedText: '2/7 Used',
                      progress: 0.28,
                      color: const Color(0xFF00C49A),
                      bgColor: const Color(0xFFEBF7F5),
                      icon: Icons.healing_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuotaCard(
                      label: 'Annual Rest',
                      remaining: '10 Days Left',
                      usedText: '5/15 Used',
                      progress: 0.33,
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
                      '3 Records',
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

              _buildHistoryCard(
                type: 'Casual Leave (2 Days)',
                dates: 'Jul 29 – Jul 30, 2026',
                reason: 'Family gathering & personal errands',
                status: 'Approved',
                statusColor: const Color(0xFF00C49A),
                statusBg: const Color(0xFFEBF7F5),
                icon: Icons.beach_access_rounded,
              ),
              const SizedBox(height: 10),
              _buildHistoryCard(
                type: 'Sick Leave (1 Day)',
                dates: 'Jun 14, 2026',
                reason: 'Dental checkup & rest',
                status: 'Approved',
                statusColor: const Color(0xFF00C49A),
                statusBg: const Color(0xFFEBF7F5),
                icon: Icons.healing_rounded,
              ),
              const SizedBox(height: 10),
              _buildHistoryCard(
                type: 'Annual Rest (4 Days)',
                dates: 'May 02 – May 05, 2026',
                reason: 'Summer vacation trip',
                status: 'Completed',
                statusColor: const Color(0xFFFF6B35),
                statusBg: const Color(0xFFFFF0EB),
                icon: Icons.flight_takeoff_rounded,
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
                        '✓ $status',
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
