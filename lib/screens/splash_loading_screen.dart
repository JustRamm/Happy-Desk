import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashLoadingScreen extends StatefulWidget {
  final VoidCallback? onLoadingComplete;

  const SplashLoadingScreen({
    super.key,
    this.onLoadingComplete,
  });

  @override
  State<SplashLoadingScreen> createState() => _SplashLoadingScreenState();
}

class _SplashLoadingScreenState extends State<SplashLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fluidShrinkAnimation;
  late Animation<double> _logoFillAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textScaleAnimation;
  late Animation<double> _textTrackingAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Slower 6.5 second duration for a luxurious, hypnotic fluid movement
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    );

    // Phase 1: Organic liquid fluid background collapses into center (0.0 -> 0.65)
    _fluidShrinkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeInOutCubic),
    );

    // Phase 2: Logo emerges & scales up at center (0.28 -> 0.68)
    _logoScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.68, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.48, curve: Curves.easeIn),
      ),
    );

    // Liquid fill level rising inside logo to reveal original full-color image (0.35 -> 0.78)
    _logoFillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.78, curve: Curves.easeInOutCubic),
      ),
    );

    // Phase 3: "Happy Desk" title spring pop & subtitle reveal (0.65 -> 0.92)
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.90, curve: Curves.easeOut),
      ),
    );

    _textScaleAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.92, curve: Curves.easeOutBack),
      ),
    );

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.40), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    _textTrackingAnimation = Tween<double>(begin: 5.0, end: -0.4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Comfortable 800ms hold on final screen before proceeding
        Future.delayed(const Duration(milliseconds: 800), () {
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
      backgroundColor: const Color(0xFFFAF9F8), // Warm soft white bg
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final shrinkProgress = _fluidShrinkAnimation.value;
          final fillProgress = _logoFillAnimation.value;
          final rawProgress = _controller.value;

          return Stack(
            children: [
              // 1. Organic Fluid Water Sinking Background Painter
              Positioned.fill(
                child: CustomPaint(
                  painter: _OrganicFluidWaterPainter(
                    progress: shrinkProgress,
                    rawProgress: rawProgress,
                    orangeColor: const Color(0xFFFF652F), // Vibrant Brand Orange
                    whiteColor: const Color(0xFFFAF9F8),
                  ),
                ),
              ),

              // 2. Upper-Middle Content (Doubled-size Liquid-Filled Logo + Title Reveal)
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Doubled size logo container (260px height) with original color liquid fill reveal
                          Transform.scale(
                            scale: _logoScaleAnimation.value.clamp(0.0, 1.3),
                            child: Opacity(
                              opacity: _logoOpacityAnimation.value.clamp(0.0, 1.0),
                              child: Container(
                                height: 260, // Doubled size for high-impact presence!
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF652F)
                                          .withValues(alpha: 0.20 * fillProgress),
                                      blurRadius: 40,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    // Faint translucent placeholder outline
                                    Opacity(
                                      opacity: 0.12,
                                      child: Image.asset(
                                        'assets/brand/logo_removedbg.png',
                                        height: 260,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.sentiment_very_satisfied_rounded,
                                            size: 160,
                                            color: Color(0xFFC84B1A),
                                          );
                                        },
                                      ),
                                    ),

                                    // Liquid fill reveal of the ORIGINAL MULTI-COLORED logo image!
                                    ClipRect(
                                      clipper: _LiquidFillClipper(fillProgress),
                                      child: Image.asset(
                                        'assets/brand/logo_removedbg.png',
                                        height: 260,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.sentiment_very_satisfied_rounded,
                                            size: 160,
                                            color: Color(0xFFC84B1A),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // "Happy Desk" App Name & Subtitle Reveal (Spring Pop + Lexend Typography)
                          SlideTransition(
                            position: _textSlideAnimation,
                            child: FadeTransition(
                              opacity: _textOpacityAnimation,
                              child: Transform.scale(
                                scale: _textScaleAnimation.value.clamp(0.0, 1.2),
                                child: Column(
                                  children: [
                                    Text(
                                      'Happy Desk',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.lexend(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                        color: const Color(0xFFC84B1A), // Crisp solid brand rust
                                        letterSpacing: _textTrackingAnimation.value,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'WORKPLACE JOY REINVENTED',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF594139),
                                        letterSpacing: 2.8,
                                      ),
                                    ),
                                  ],
                                ),
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
//  Custom Clipper for Liquid Fill Level (Revealing original colored image)
// ---------------------------------------------------------------------------
class _LiquidFillClipper extends CustomClipper<Rect> {
  final double progress; // 0.0 (empty) -> 1.0 (fully filled)

  _LiquidFillClipper(this.progress);

  @override
  Rect getClip(Size size) {
    final fillHeight = size.height * progress.clamp(0.0, 1.0);
    // Reveal from bottom to top
    return Rect.fromLTRB(0, size.height - fillHeight, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant _LiquidFillClipper oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ---------------------------------------------------------------------------
//  Custom Painter for Ultra-Smooth Organic Fluid Water Sinking Effect
// ---------------------------------------------------------------------------
class _OrganicFluidWaterPainter extends CustomPainter {
  final double progress; // 0.0 (full orange) -> 1.0 (sunk into center point)
  final double rawProgress; // Drives continuous smooth wave fluid phase
  final Color orangeColor;
  final Color whiteColor;

  _OrganicFluidWaterPainter({
    required this.progress,
    required this.rawProgress,
    required this.orangeColor,
    required this.whiteColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sink point positioned just slightly above center (42% down screen height)
    final center = Offset(size.width / 2, size.height * 0.42);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2 +
            120;

    // 1. Draw outer background (white increasing as orange liquid shrinks)
    final whitePaint = Paint()
      ..color = whiteColor
      ..isAntiAlias = true;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), whitePaint);

    if (progress >= 1.0) return;

    // 2. Base radius of orange liquid collapsing toward center logo
    final baseRadius = maxRadius * (1.0 - progress);

    if (baseRadius > 0.5) {
      final phase = rawProgress * math.pi * 6; // Smooth, silky wave phase

      // Build organic irregular fluid liquid path with high sampling density
      final fluidPath =
          _createOrganicFluidPath(center, baseRadius, maxRadius, phase);

      final orangePaint = Paint()
        ..color = orangeColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;

      canvas.drawPath(fluidPath, orangePaint);

      // 3. Draw inner liquid wave contour lines for fluid ripple depth
      if (progress > 0.04 && progress < 0.94) {
        final innerPath1 = _createOrganicFluidPath(
            center, baseRadius * 0.84, maxRadius, phase * 1.2);
        final innerPath2 = _createOrganicFluidPath(
            center, baseRadius * 0.64, maxRadius, -phase * 1.05);

        // Lighter orange shades matching the brand logo for subtle liquid wave ripples
        final strokePaint1 = Paint()
          ..color = const Color(0xFFFFB299).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..isAntiAlias = true;

        final strokePaint2 = Paint()
          ..color = const Color(0xFFFFD6C7).withValues(alpha: 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..isAntiAlias = true;

        canvas.drawPath(innerPath1, strokePaint1);
        canvas.drawPath(innerPath2, strokePaint2);
      }
    }
  }

  // Helper method to build dynamic irregular organic liquid wave boundary
  Path _createOrganicFluidPath(
      Offset center, double baseRadius, double maxRadius, double phase) {
    final path = Path();
    const int sampleCount = 90; // High 90-point resolution for ultra-smooth fluid curves
    final List<Offset> points = [];

    for (int i = 0; i < sampleCount; i++) {
      final double angle = (i / sampleCount) * 2 * math.pi;

      // Multi-frequency smooth sine/cosine wave distortion for realistic liquid fluid wobble
      final double wave1 = math.sin(angle * 3 + phase * 1.8) * (baseRadius * 0.14);
      final double wave2 = math.cos(angle * 4 - phase * 2.4) * (baseRadius * 0.08);
      final double wave3 = math.sin(angle * 2 + phase * 1.2) * (baseRadius * 0.06);

      final double r = (baseRadius + wave1 + wave2 + wave3).clamp(0.0, maxRadius * 1.6);
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);

      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);

      // Smooth quadratic Bezier curve interpolation around radial points
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
  bool shouldRepaint(covariant _OrganicFluidWaterPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rawProgress != rawProgress;
  }
}




