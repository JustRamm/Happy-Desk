import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

class DeskStretchesModal extends StatefulWidget {
  const DeskStretchesModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DeskStretchesModal(),
    );
  }

  @override
  State<DeskStretchesModal> createState() => _DeskStretchesModalState();
}

class _StretchItem {
  final String title;
  final String category;
  final String instructions;
  final String duration;
  final IconData icon;

  const _StretchItem({
    required this.title,
    required this.category,
    required this.instructions,
    required this.duration,
    required this.icon,
  });
}

class _DeskStretchesModalState extends State<DeskStretchesModal> {
  final List<_StretchItem> _stretches = const [
    _StretchItem(
      title: 'Shoulder Drop & Chest Opener',
      category: 'Upper Body Relief',
      instructions:
          'Roll your shoulders back and down. Clasp hands behind your back, gently lift your chest, and hold for 30 seconds to reverse desk slouching.',
      duration: '30 Seconds',
      icon: Icons.accessibility_new_rounded,
    ),
    _StretchItem(
      title: 'Neck & Upper Trap Release',
      category: 'Neck & Head Tension',
      instructions:
          'Lower your right ear toward your right shoulder. Gently place your right hand on your head for light resistance. Hold for 15s, then switch sides.',
      duration: '30 Seconds',
      icon: Icons.self_improvement_rounded,
    ),
    _StretchItem(
      title: 'Wrist & Forearm De-Compressor',
      category: 'Keyboard Relief',
      instructions:
          'Extend your arm forward with palm facing up. Use your opposite hand to gently pull fingers back toward your wrist. Hold 15s per arm.',
      duration: '30 Seconds',
      icon: Icons.fitness_center_rounded,
    ),
  ];

  int _currentIndex = 0;
  Timer? _timer;
  int _secondsLeft = 30;
  bool _isRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    SoundService.playStretchStepSound();
    setState(() {
      _isRunning = true;
      _secondsLeft = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
        SoundService.playStretchStepSound();
        setState(() {
          _secondsLeft = 0;
          _isRunning = false;
        });
      }
    });
  }

  void _nextStretch() {
    _timer?.cancel();
    SoundService.playStretchStepSound();
    if (_currentIndex < _stretches.length - 1) {
      setState(() {
        _currentIndex++;
        _secondsLeft = 30;
        _isRunning = false;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevStretch() {
    _timer?.cancel();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _secondsLeft = 30;
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stretch = _stretches[_currentIndex];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.accessibility_rounded,
                          size: 16, color: Color(0xFFAB3500)),
                      const SizedBox(width: 6),
                      Text(
                        'Desk Stretches',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFAB3500),
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

            // Step Indicator
            Row(
              children: List.generate(_stretches.length, (index) {
                final isActive = index == _currentIndex;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                        right: index == _stretches.length - 1 ? 0 : 8),
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFAB3500)
                          : const Color(0xFFFFDBD0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Main Stretch Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4E7FE)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFAB3500).withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Icon badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F2FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      stretch.icon,
                      size: 36,
                      color: const Color(0xFF95416C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    stretch.category,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8D7168),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stretch.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF171B2B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    stretch.instructions,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF594139),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Timer Badge & Start
                  GestureDetector(
                    onTap: _startTimer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isRunning
                            ? const Color(0xFFEBF7F5)
                            : const Color(0xFFFAF8FF),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _isRunning
                              ? const Color(0xFF00AE88)
                              : const Color(0xFFDEE1F8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isRunning
                                ? Icons.timer_outlined
                                : Icons.play_arrow_rounded,
                            size: 20,
                            color: _isRunning
                                ? const Color(0xFF006C53)
                                : const Color(0xFFAB3500),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isRunning
                                ? 'Timer: ${_secondsLeft}s'
                                : 'Start 30s Timer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _isRunning
                                  ? const Color(0xFF006C53)
                                  : const Color(0xFFAB3500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Controls
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevStretch,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: Color(0xFF8D7168)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF594139),
                        ),
                      ),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _nextStretch,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xFFAB3500),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      _currentIndex == _stretches.length - 1
                          ? 'Finish Stretches'
                          : 'Next Stretch',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
