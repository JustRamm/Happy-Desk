import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stress_lesson_modal.dart';

class DailyStressBusterCard extends StatelessWidget {
  const DailyStressBusterCard({super.key});

  static const List<StressLessonData> _lessons = [
    StressLessonData(
      title: 'The 5-4-3-2-1 Grounding Method',
      category: 'Acute Stress & Anxiety',
      summary:
          'When work pressure builds up suddenly, use sensory awareness to bring your mind back to the present moment.',
      steps: [
        'Acknowledge 5 things you can see around your desk or room.',
        'Acknowledge 4 things you can physically touch (e.g. keyboard, desk, clothing).',
        'Acknowledge 3 distinct sounds you hear in your environment.',
        'Acknowledge 2 scents you can smell.',
        'Acknowledge 1 taste in your mouth or take a slow sip of water.',
      ],
      keyTakeaway:
          'Grounding interrupts the anxiety loop in your brain and resets your nervous system in less than two minutes.',
    ),
    StressLessonData(
      title: 'Reframing Deadline Anxiety',
      category: 'High Workload',
      summary:
          'Transform overwhelming to-do lists into calm, single-pointed execution through priority reframing.',
      steps: [
        'Pause and write down every task swirling in your head.',
        'Circle the single task that produces 80% of today\'s impact.',
        'Decline or defer non-urgent requests for the next 60 minutes.',
        'Commit to working on that single task for just 15 uninterrupted minutes.',
      ],
      keyTakeaway:
          'Focusing on one small action destroys feeling overwhelmed far faster than attempting to manage everything at once.',
    ),
    StressLessonData(
      title: 'Setting Healthy App Boundaries',
      category: 'Digital Communication',
      summary:
          'Prevent constant Slack and email interruptions from draining your mental energy throughout the day.',
      steps: [
        'Turn off non-urgent pop-up notifications during focus hours.',
        'Set your status to Focus Mode with your expected response time.',
        'Check messages in batch windows (e.g. top of the hour) rather than reacting instantly.',
      ],
      keyTakeaway:
          'Protecting your attention is a professional skill that improves work quality while lowering chronic stress.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Pick first featured lesson
    final featured = _lessons[0];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E7FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF95416C).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded,
                        size: 14, color: Color(0xFF95416C)),
                    const SizedBox(width: 6),
                    Text(
                      'DAILY STRESS SKILL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF95416C),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '3 Min Read',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8D7168),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            featured.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF171B2B),
            ),
          ),
          const SizedBox(height: 8),

          // Summary
          Text(
            featured.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF594139),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // Action Link
          GestureDetector(
            onTap: () => StressLessonModal.show(context, featured),
            child: Row(
              children: [
                Text(
                  'Learn Strategy & Steps',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFAB3500),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: Color(0xFFAB3500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
