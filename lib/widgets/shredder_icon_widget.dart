import 'package:flutter/material.dart';

class ShredderIconWidget extends StatelessWidget {
  final double size;
  final Color mainColor;
  final Color slotColor;
  final Color binColor;

  const ShredderIconWidget({
    super.key,
    this.size = 24.0,
    this.mainColor = const Color(0xFFC84B1A),
    this.slotColor = const Color(0xFF4A1500),
    this.binColor = const Color(0xFFFAF8FF),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShredderPainter(
          mainColor: mainColor,
          slotColor: slotColor,
          binColor: binColor,
        ),
      ),
    );
  }
}

class _ShredderPainter extends CustomPainter {
  final Color mainColor;
  final Color slotColor;
  final Color binColor;

  _ShredderPainter({
    required this.mainColor,
    required this.slotColor,
    required this.binColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Shredder Top Housing
    final topPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.fill;

    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, height * 0.15, width, height * 0.35),
      Radius.circular(size.width * 0.12),
    );
    canvas.drawRRect(topRect, topPaint);

    // Intake Feed Slot
    final slotPaint = Paint()
      ..color = slotColor
      ..style = PaintingStyle.fill;
    final slotRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.15, height * 0.20, width * 0.70, height * 0.08),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(slotRect, slotPaint);

    // Status LED Light
    final ledPaint = Paint()
      ..color = const Color(0xFF00AE88)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width * 0.82, height * 0.28), width * 0.04, ledPaint);

    // Paper Collection Bin (Translucent)
    final binPaint = Paint()
      ..color = mainColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final binBorderPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06;

    final binRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.08, height * 0.48, width * 0.84, height * 0.46),
      Radius.circular(size.width * 0.10),
    );
    canvas.drawRRect(binRect, binPaint);
    canvas.drawRRect(binRect, binBorderPaint);

    // Vertical Shredded Strips inside Bin
    final stripPaint = Paint()
      ..color = mainColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04;

    for (int i = 1; i <= 4; i++) {
      final x = width * (0.18 + i * 0.13);
      canvas.drawLine(
        Offset(x, height * 0.54),
        Offset(x, height * 0.84),
        stripPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShredderPainter oldDelegate) {
    return oldDelegate.mainColor != mainColor ||
        oldDelegate.slotColor != slotColor ||
        oldDelegate.binColor != binColor;
  }
}
