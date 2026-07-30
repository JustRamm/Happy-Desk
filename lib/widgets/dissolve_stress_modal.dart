import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';
import 'shredder_icon_widget.dart';

class DissolveStressModal extends StatefulWidget {
  final String? initialText;
  final bool autoTrigger;

  const DissolveStressModal({
    super.key,
    this.initialText,
    this.autoTrigger = false,
  });

  static Future<void> show(BuildContext context, {String? initialText, bool autoTrigger = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DissolveStressModal(initialText: initialText, autoTrigger: autoTrigger),
      ),
    );
  }

  @override
  State<DissolveStressModal> createState() => _DissolveStressModalState();
}

class _DissolveStressModalState extends State<DissolveStressModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late AnimationController _shredController;
  bool _isShredding = false;
  bool _isShredded = false;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialText ?? '';
    _shredController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addListener(() {
        if (_shredController.value > 0.1 && _shredController.value < 0.9) {
          if ((_shredController.value * 25).floor() % 2 == 0) {
            SystemSound.play(SystemSoundType.click);
            HapticFeedback.lightImpact();
          }
        }
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isShredding = false;
            _isShredded = true;
          });
        }
      });

    if (widget.autoTrigger && _textController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerShred();
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _shredController.dispose();
    super.dispose();
  }

  void _triggerShred() {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _isShredding = true;
    });
    SoundService.playShredSound();
    _shredController.forward(from: 0.0);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Bar
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
                      const ShredderIconWidget(
                        size: 18,
                        mainColor: Color(0xFFAB3500),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Paper Shredder Stress Vent',
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
            const SizedBox(height: 12),

            if (!_isShredded) ...[
              Text(
                'Shred & Dissolve Your Stress Note',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171B2B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Type out what is causing you workplace tension. Your words will be pulled directly into the paper shredder and cut into fine paper strips.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF594139),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),

              // Interactive Paper Shredder Stage
              SizedBox(
                height: 240,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Top Input Paper Sheet pulling downwards
                    if (_isShredding)
                      Positioned(
                        top: 10 + (_shredController.value * 90),
                        child: Opacity(
                          opacity: (1.0 - _shredController.value).clamp(0.0, 1.0),
                          child: Container(
                            width: 260,
                            height: 100,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE4E7FE)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              _textController.text,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                color: const Color(0xFF594139),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 280,
                          height: 130,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE4E7FE)),
                          ),
                          child: TextField(
                            controller: _textController,
                            maxLines: 4,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 14,
                              color: const Color(0xFF171B2B),
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Write your workplace stress note here...',
                              hintStyle: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                color: const Color(0xFF8D7168),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),

                    // Paper Shredder Device Slot Header
                    Positioned(
                      top: 105,
                      child: Container(
                        width: 300,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFAB3500),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33AB3500),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 14.0),
                              child: Icon(Icons.shield_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            Container(
                              width: 180,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3D1200),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 14.0),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF64FBCE),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Shredded Strips Falling Output Box
                    if (_isShredding)
                      Positioned(
                        top: 145,
                        child: SizedBox(
                          width: 280,
                          height: 90,
                          child: AnimatedBuilder(
                            animation: _shredController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _ShredderStripsPainter(
                                  progress: _shredController.value,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isShredding ? null : _triggerShred,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAB3500),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ShredderIconWidget(
                        size: 20,
                        mainColor: Colors.white,
                        slotColor: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isShredding ? 'Shredding Note...' : 'Shred & Dissolve Stress',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Shredded Completion Screen
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEBF7F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: ShredderIconWidget(
                          size: 44,
                          mainColor: Color(0xFF006C53),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Stress Note Shredded & Dissolved',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF171B2B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your stress thoughts have been completely cut into paper strips and dissolved. Take a slow, relaxing deep breath.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF594139),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006C53),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Return to NGL Jar',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ShredderStripsPainter extends CustomPainter {
  final double progress;

  _ShredderStripsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(123);
    final stripCount = 14;

    for (int i = 0; i < stripCount; i++) {
      final x = (size.width / (stripCount + 1)) * (i + 1);
      final delay = (i % 4) * 0.15;
      final adjustedProgress = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);

      final yTop = adjustedProgress * (size.height * 0.4);
      final stripLength = 20.0 + (rand.nextDouble() * 25.0);

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFFAB3500),
          const Color(0xFFFF99C8),
          rand.nextDouble(),
        )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      if (adjustedProgress > 0) {
        canvas.drawLine(
          Offset(x + math.sin(progress * 10 + i) * 2, yTop),
          Offset(x + math.sin(progress * 10 + i) * 2, yTop + stripLength),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShredderStripsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
