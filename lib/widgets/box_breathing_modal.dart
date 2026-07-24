import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

class BoxBreathingModal extends StatefulWidget {
  const BoxBreathingModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BoxBreathingModal(),
    );
  }

  @override
  State<BoxBreathingModal> createState() => _BoxBreathingModalState();
}

class _BoxBreathingModalState extends State<BoxBreathingModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _countdownTimer;

  int _secondsRemaining = 60;
  int _currentCycle = 1;
  final int _totalCycles = 4;
  String _phaseLabel = 'Inhale';
  String _phaseSubtext = 'Breathe in slowly through your nose';

  @override
  void initState() {
    super.initState();
    // Total cycle duration is 16s (4s inhale, 4s hold, 4s exhale, 4s hold)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..addListener(_updatePhase);

    _controller.repeat();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
          _currentCycle = ((60 - _secondsRemaining) ~/ 16) + 1;
          if (_currentCycle > _totalCycles) {
            _currentCycle = _totalCycles;
          }
        });
      } else {
        timer.cancel();
        _controller.stop();
        setState(() {
          _secondsRemaining = 0;
          _phaseLabel = 'Complete';
          _phaseSubtext = 'Great job releasing workplace tension';
        });
      }
    });
  }

  void _updatePhase() {
    final value = _controller.value;
    String newLabel;
    String newSubtext;

    if (value < 0.25) {
      newLabel = 'Inhale';
      newSubtext = 'Breathe in slowly through your nose';
    } else if (value < 0.50) {
      newLabel = 'Hold';
      newSubtext = 'Hold your breath gently';
    } else if (value < 0.75) {
      newLabel = 'Exhale';
      newSubtext = 'Release your breath smoothly through your mouth';
    } else {
      newLabel = 'Hold';
      newSubtext = 'Rest before the next breath';
    }

    if (newLabel != _phaseLabel && _secondsRemaining > 0) {
      if (newLabel == 'Inhale') {
        SoundService.playInhaleSound();
      } else if (newLabel == 'Exhale') {
        SoundService.playExhaleSound();
      }
      setState(() {
        _phaseLabel = newLabel;
        _phaseSubtext = newSubtext;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _controller.dispose();
    super.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle & Close Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF7F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.spa_rounded,
                          size: 16, color: Color(0xFF006C53)),
                      const SizedBox(width: 6),
                      Text(
                        '60s Breathing Reset',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF006C53),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF594139)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cycle & Time Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cycle $_currentCycle of $_totalCycles',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF594139),
                  ),
                ),
                Text(
                  '${_secondsRemaining}s remaining',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFAB3500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (60 - _secondsRemaining) / 60,
                backgroundColor: const Color(0xFFFFDBD0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFAB3500)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 36),

            // Animated Breathing Visualizer Ring
            SizedBox(
              height: 220,
              width: 220,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPainterWidget(
                    progress: _controller.value,
                    phase: _phaseLabel,
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Phase Text
            Text(
              _phaseLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _phaseSubtext,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF594139),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Primary Action Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAB3500),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _secondsRemaining == 0 ? 'Done & Refreshed' : 'End Session Early',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class CustomPainterWidget extends StatelessWidget {
  final double progress;
  final String phase;

  const CustomPainterWidget({
    super.key,
    required this.progress,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BreathingCirclePainter(progress: progress, phase: phase),
    );
  }
}

class _BreathingCirclePainter extends CustomPainter {
  final double progress;
  final String phase;

  _BreathingCirclePainter({required this.progress, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 10;
    final minRadius = maxRadius * 0.45;

    double scale;
    if (progress < 0.25) {
      // Inhale: grow from min to max
      scale = minRadius + (maxRadius - minRadius) * (progress / 0.25);
    } else if (progress < 0.50) {
      // Hold: stay at max
      scale = maxRadius;
    } else if (progress < 0.75) {
      // Exhale: shrink from max to min
      scale = maxRadius - (maxRadius - minRadius) * ((progress - 0.50) / 0.25);
    } else {
      // Hold: stay at min
      scale = minRadius;
    }

    // Outer glow ring
    final glowPaint = Paint()
      ..color = const Color(0xFF00AE88).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, scale + 14, glowPaint);

    // Secondary pulse ring
    final midPaint = Paint()
      ..color = const Color(0xFFFF99C8).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, scale + 6, midPaint);

    // Primary Core Circle
    final corePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFAB3500), Color(0xFFFF6B35)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: scale))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, scale, corePaint);

    // Inner subtle center indicator
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, scale * 0.3, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _BreathingCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.phase != phase;
  }
}
