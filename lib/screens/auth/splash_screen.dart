import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onLoadingComplete;

  const SplashScreen({super.key, this.onLoadingComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fluidFlowAnimation;
  late Animation<double> _logoFillAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Phase 1: Logo scales & fades in cleanly
    _logoScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutSine),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.30, curve: Curves.easeIn),
      ),
    );

    // Phase 2: Fluid wave flows from screen edges into the logo area
    _fluidFlowAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.85, curve: Curves.easeInOutSine),
    );

    // Phase 3: Liquid colors flow INTO and fill the logo SVG
    _logoFillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.85, curve: Curves.easeInOutSine),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            widget.onLoadingComplete?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8), // Warm soft background (no gradient behind logo)
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final flowProgress = _fluidFlowAnimation.value;
          final fillProgress = _logoFillAnimation.value;
          final rawProgress = _controller.value;

          return Stack(
            children: [
              // 1. Organic Fluid Wave flowing INTO the logo (stops at logo bounds, no shrinking to a point)
              Positioned.fill(
                child: CustomPaint(
                  painter: _OrganicFluidFlowPainter(
                    flowProgress: flowProgress,
                    rawProgress: rawProgress,
                    brandColor: const Color(0xFFFF652F), // Vibrant Brand Orange
                    whiteColor: const Color(0xFFFAF9F8),
                  ),
                ),
              ),

              // 2. Main Content Container (Clean logo without background gradient or shadow)
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo Container (No gradient or shadow in background)
                          Transform.scale(
                            scale: _logoScaleAnimation.value.clamp(0.0, 1.1),
                            child: Opacity(
                              opacity: _logoOpacityAnimation.value.clamp(0.0, 1.0),
                              child: SizedBox(
                                height: 300,
                                width: 300,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    // Faint outline placeholder
                                    Opacity(
                                      opacity: 0.12,
                                      child: SvgPicture.asset(
                                        'assets/brand/U&ME.svg',
                                        height: 300,
                                        fit: BoxFit.contain,
                                      ),
                                    ),

                                    // Colors flow into and fill the U&ME logo SVG
                                    ClipRect(
                                      clipper: _LiquidFillClipper(fillProgress),
                                      child: SvgPicture.asset(
                                        'assets/brand/U&ME.svg',
                                        height: 300,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Subtitle Tagline ("WORKPLACE JOY REINVENTED")
                          Opacity(
                            opacity: _logoOpacityAnimation.value.clamp(0.0, 1.0),
                            child: Text(
                              'WORKPLACE JOY REINVENTED',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF594139),
                                letterSpacing: 2.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Custom Clipper for Liquid Fill Level (Revealing logo colors as fluid enters)
// ---------------------------------------------------------------------------
class _LiquidFillClipper extends CustomClipper<Rect> {
  final double progress; // 0.0 (empty) -> 1.0 (fully filled)

  _LiquidFillClipper(this.progress);

  @override
  Rect getClip(Size size) {
    final fillHeight = size.height * progress.clamp(0.0, 1.0);
    return Rect.fromLTRB(0, size.height - fillHeight, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant _LiquidFillClipper oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ---------------------------------------------------------------------------
//  Custom Painter for Fluid Waves Flowing INTO the Logo (Stops at logo, does NOT shrink to a point)
// ---------------------------------------------------------------------------
class _OrganicFluidFlowPainter extends CustomPainter {
  final double flowProgress; // 0.0 (full screen) -> 1.0 (flows into logo bounds)
  final double rawProgress;
  final Color brandColor;
  final Color whiteColor;

  _OrganicFluidFlowPainter({
    required this.flowProgress,
    required this.rawProgress,
    required this.brandColor,
    required this.whiteColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.44);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2 + 100;
    // Target radius matches the logo container size so fluid flows INTO logo without shrinking to a point!
    const targetLogoRadius = 150.0;

    final whitePaint = Paint()
      ..color = whiteColor
      ..isAntiAlias = true;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), whitePaint);

    if (flowProgress >= 1.0) return; // Completely stops rendering once fluid flow into logo is complete!

    final fluidAlpha = (1.0 - flowProgress).clamp(0.0, 1.0);
    if (fluidAlpha <= 0.001) return;

    // Liquid flows down from max screen radius to target logo radius
    final currentRadius =
        maxRadius - (maxRadius - targetLogoRadius) * flowProgress;

    final phase = rawProgress * math.pi * 5;

    final fluidPath = _createOrganicFluidPath(
      center,
      currentRadius,
      maxRadius,
      phase,
    );

    final orangePaint = Paint()
      ..color = brandColor.withValues(alpha: fluidAlpha)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawPath(fluidPath, orangePaint);

    if (flowProgress < 0.90) {
      final innerPath = _createOrganicFluidPath(
        center,
        currentRadius * 0.85,
        maxRadius,
        phase * 1.3,
      );

      final strokePaint = Paint()
        ..color = const Color(0xFFFFB299)
            .withValues(alpha: (0.45 * (1.0 - flowProgress)).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..isAntiAlias = true;

      canvas.drawPath(innerPath, strokePaint);
    }
  }

  Path _createOrganicFluidPath(
    Offset center,
    double baseRadius,
    double maxRadius,
    double phase,
  ) {
    final path = Path();
    const int sampleCount = 80;
    final List<Offset> points = [];

    for (int i = 0; i < sampleCount; i++) {
      final double angle = (i / sampleCount) * 2 * math.pi;

      final double wave1 = math.sin(angle * 3 + phase * 1.6) * (baseRadius * 0.10);
      final double wave2 = math.cos(angle * 4 - phase * 2.0) * (baseRadius * 0.06);

      final double r = (baseRadius + wave1 + wave2).clamp(0.0, maxRadius * 1.5);
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);

      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length; i++) {
        final p1 = points[i];
        final p2 = points[(i + 1) % points.length];
        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
      }

      path.close();
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _OrganicFluidFlowPainter oldDelegate) {
    return oldDelegate.flowProgress != flowProgress ||
        oldDelegate.rawProgress != rawProgress;
  }
}
