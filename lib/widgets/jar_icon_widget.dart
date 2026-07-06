import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class JarIconWidget extends StatelessWidget {
  final double size;
  final Color? mainColor;
  final Color? lidColor;
  final Color? liquidColor;

  const JarIconWidget({
    super.key,
    this.size = 24.0,
    this.mainColor,
    this.lidColor,
    this.liquidColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMain = mainColor ?? AppTheme.primaryRust;
    final effectiveLid = lidColor ?? AppTheme.primaryRust;
    final effectiveLiquid = liquidColor ?? const Color(0xFFFF8EA9);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _JarIconPainter(
          mainColor: effectiveMain,
          lidColor: effectiveLid,
          liquidColor: effectiveLiquid,
        ),
      ),
    );
  }
}

class _JarIconPainter extends CustomPainter {
  final Color mainColor;
  final Color lidColor;
  final Color liquidColor;

  _JarIconPainter({
    required this.mainColor,
    required this.lidColor,
    required this.liquidColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double scale = w / 24.0;

    // 1. Lid (Top Wooden / Rust Cap)
    final lidPaint = Paint()
      ..color = lidColor
      ..style = PaintingStyle.fill;
    final lidRRect = RRect.fromLTRBR(
      7.0 * scale,
      2.5 * scale,
      17.0 * scale,
      5.0 * scale,
      Radius.circular(1.2 * scale),
    );
    canvas.drawRRect(lidRRect, lidPaint);

    // 2. Neck Rim Bar
    final neckPaint = Paint()
      ..color = lidColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(8.0 * scale, 5.0 * scale, 16.0 * scale, 7.0 * scale),
      neckPaint,
    );

    // 3. Inner Liquid Fill (Bottom half fill with soft pink/peach wave)
    final liquidPath = Path();
    liquidPath.moveTo(7.0 * scale, 14.0 * scale);
    liquidPath.quadraticBezierTo(
      9.5 * scale, 13.0 * scale, 12.0 * scale, 14.0 * scale,
    );
    liquidPath.quadraticBezierTo(
      14.5 * scale, 15.0 * scale, 17.0 * scale, 14.0 * scale,
    );
    liquidPath.lineTo(17.0 * scale, 18.5 * scale);
    liquidPath.arcToPoint(
      Offset(14.5 * scale, 21.0 * scale),
      radius: Radius.circular(2.5 * scale),
    );
    liquidPath.lineTo(9.5 * scale, 21.0 * scale);
    liquidPath.arcToPoint(
      Offset(7.0 * scale, 18.5 * scale),
      radius: Radius.circular(2.5 * scale),
    );
    liquidPath.close();

    final liquidPaint = Paint()
      ..color = liquidColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(liquidPath, liquidPaint);

    // 4. Glass Jar Body Outer Contour
    final bodyPath = Path();
    bodyPath.moveTo(7.5 * scale, 7.0 * scale);
    bodyPath.lineTo(16.5 * scale, 7.0 * scale);
    bodyPath.arcToPoint(
      Offset(18.0 * scale, 8.5 * scale),
      radius: Radius.circular(1.5 * scale),
    );
    bodyPath.lineTo(18.0 * scale, 18.5 * scale);
    bodyPath.arcToPoint(
      Offset(14.5 * scale, 22.0 * scale),
      radius: Radius.circular(3.5 * scale),
    );
    bodyPath.lineTo(9.5 * scale, 22.0 * scale);
    bodyPath.arcToPoint(
      Offset(6.0 * scale, 18.5 * scale),
      radius: Radius.circular(3.5 * scale),
    );
    bodyPath.lineTo(6.0 * scale, 8.5 * scale);
    bodyPath.arcToPoint(
      Offset(7.5 * scale, 7.0 * scale),
      radius: Radius.circular(1.5 * scale),
    );
    bodyPath.close();

    final glassStrokePaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * scale
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyPath, glassStrokePaint);

    // 5. Heart floating inside jar
    final heartPath = Path();
    final double cx = 12.0 * scale;
    final double cy = 13.0 * scale;
    final double hs = scale * 0.9;
    heartPath.moveTo(cx, cy);
    heartPath.cubicTo(cx - 1.2 * hs, cy - 1.2 * hs, cx - 2.5 * hs, cy + 0.2 * hs, cx, cy + 2.2 * hs);
    heartPath.cubicTo(cx + 2.5 * hs, cy + 0.2 * hs, cx + 1.2 * hs, cy - 1.2 * hs, cx, cy);
    heartPath.close();

    final heartPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(heartPath, heartPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
