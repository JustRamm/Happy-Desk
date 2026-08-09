import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamWellbeingScreen extends StatelessWidget {
  const TeamWellbeingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dailyStressData = [
      {'day': 'Mon', 'stress': 65, 'kudos': 12},
      {'day': 'Tue', 'stress': 42, 'kudos': 18},
      {'day': 'Wed', 'stress': 35, 'kudos': 24},
      {'day': 'Thu', 'stress': 28, 'kudos': 31},
      {'day': 'Fri', 'stress': 18, 'kudos': 42},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF171B2B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Team Wellbeing Analytics',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF171B2B),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anonymized Privacy Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD6C7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: Color(0xFFAB3500), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All metrics are 100% anonymized to protect individual employee privacy.',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFAB3500),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Top Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Team Morale',
                    value: '92%',
                    change: '+4.2% vs last week',
                    icon: Icons.sentiment_very_satisfied_rounded,
                    color: const Color(0xFF006C53),
                    bgColor: const Color(0xFFEBF7F5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Kudos Sent',
                    value: '127',
                    change: '32 notes this week',
                    icon: Icons.favorite_rounded,
                    color: const Color(0xFFAB3500),
                    bgColor: const Color(0xFFFFF0EB),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Burnout Index',
                    value: 'Low',
                    change: 'Optimal work pace',
                    icon: Icons.health_and_safety_rounded,
                    color: const Color(0xFF00AE88),
                    bgColor: const Color(0xFFEBF7F5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Shift Reliability',
                    value: '98.4%',
                    change: '142 total hours',
                    icon: Icons.access_time_rounded,
                    color: const Color(0xFF95416C),
                    bgColor: const Color(0xFFF3F2FF),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stress & Appreciation Weekly Velocity Chart
            Text(
              'Weekly Stress Index vs Kudos Velocity',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4E7FE)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFAB3500),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Stress Level (%)',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: const Color(0xFF594139),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFF006C53),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kudos Volume',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: const Color(0xFF594139),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...dailyStressData.map((d) {
                    final stress = d['stress'] as int;
                    final kudos = d['kudos'] as int;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                d['day'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF171B2B),
                                ),
                              ),
                              Text(
                                'Stress: $stress% • $kudos Kudos',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11.5,
                                  color: const Color(0xFF594139),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F2FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: stress / 100,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFAB3500),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Appreciation Category Breakdown Card
            Text(
              'Appreciation Categories Distribution',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4E7FE)),
              ),
              child: Column(
                children: [
                  _buildCategoryProgressTile(
                    label: 'Teamwork & Support',
                    count: '42 Notes (38%)',
                    percentage: 0.38,
                    color: const Color(0xFFAB3500),
                  ),
                  const SizedBox(height: 14),
                  _buildCategoryProgressTile(
                    label: 'Kindness & Empathy',
                    count: '31 Notes (28%)',
                    percentage: 0.28,
                    color: const Color(0xFF95416C),
                  ),
                  const SizedBox(height: 14),
                  _buildCategoryProgressTile(
                    label: 'Excellence & Growth',
                    count: '24 Notes (22%)',
                    percentage: 0.22,
                    color: const Color(0xFF006C53),
                  ),
                  const SizedBox(height: 14),
                  _buildCategoryProgressTile(
                    label: 'Innovation & Problem Solving',
                    count: '13 Notes (12%)',
                    percentage: 0.12,
                    color: const Color(0xFFFF9F1C),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF171B2B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF171B2B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgressTile({
    required String label,
    required String count,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF171B2B),
              ),
            ),
            Text(
              count,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: const Color(0xFF594139),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: const Color(0xFFF3F2FF),
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
