import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkSessionDetailsScreen extends StatefulWidget {
  const WorkSessionDetailsScreen({super.key});

  @override
  State<WorkSessionDetailsScreen> createState() =>
      _WorkSessionDetailsScreenState();
}

class _WorkSessionDetailsScreenState extends State<WorkSessionDetailsScreen> {
  bool _isClockedIn = true;

  final List<Map<String, String>> _attendanceHistory = [
    {
      'date': 'Today (Mon, Jul 27)',
      'in': '09:00 AM',
      'out': 'In Progress',
      'hours': '4h 22m',
      'status': 'Active Shift',
    },
    {
      'date': 'Fri, Jul 24',
      'in': '08:55 AM',
      'out': '05:15 PM',
      'hours': '8h 20m',
      'status': 'Completed',
    },
    {
      'date': 'Thu, Jul 23',
      'in': '09:02 AM',
      'out': '05:00 PM',
      'hours': '7h 58m',
      'status': 'Completed',
    },
    {
      'date': 'Wed, Jul 22',
      'in': '08:50 AM',
      'out': '05:10 PM',
      'hours': '8h 20m',
      'status': 'Completed',
    },
    {
      'date': 'Tue, Jul 21',
      'in': '09:00 AM',
      'out': '05:05 PM',
      'hours': '8h 05m',
      'status': 'Completed',
    },
  ];

  void _toggleShift() {
    setState(() {
      _isClockedIn = !_isClockedIn;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isClockedIn ? 'Clocked in for work session.' : 'Shift ended. Great work!',
          style: GoogleFonts.beVietnamPro(fontSize: 13.5),
        ),
        backgroundColor:
            _isClockedIn ? const Color(0xFFAB3500) : const Color(0xFF006C53),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF171B2B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Work Session & Shift Insights',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF171B2B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Current Shift Card (Clocked In/Out Live Status)
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
                    _isClockedIn ? '4h 22m Elapsed' : 'Shift Not Started',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isClockedIn
                        ? 'Clocked in at 09:00 AM • Healthy pace'
                        : 'Tap below when you begin your workday',
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

            // 2. Weekly Metrics Grid (Weekly Reliability + Average Workhours)
            Row(
              children: [
                // Metric 1: Weekly Reliability (98.4%)
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
                          '98.4%',
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
                        Text(
                          'Punctual attendance',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: const Color(0xFF8D7168),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Metric 2: Average Workhours (8h 12m)
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
                          '8h 12m',
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
                        Text(
                          'Optimal work-rest ratio',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: const Color(0xFF8D7168),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Weekly Attendance Breakdown Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE4E7FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weekly Attendance',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF171B2B),
                        ),
                      ),
                      Text(
                        '5 of 5 Days Logged',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: const Color(0xFF006C53),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Weekly Days Progress Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'].map((day) {
                      return Column(
                        children: [
                          Container(
                            width: 38,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF7F5),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFF64FBCE)),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF006C53),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            day,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF171B2B),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Daily Clock-In History Timeline
            Text(
              'Daily Shift History',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
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
                            Text(
                              'In: ${item['in']} • Out: ${item['out']}',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: const Color(0xFF594139),
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
      ),
    );
  }
}
