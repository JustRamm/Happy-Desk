import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// A continuous character animation widget that cycles through Mochi SVG poses.
///
/// ANR-safe design for budget Android (Infinix/Helio/Unisoc):
/// - SVGs are pre-cached via [SvgAssetLoader] before animation starts
/// - Frame switching (slow timer) is separated from bob animation (60fps)
/// - [RepaintBoundary] prevents SVG layer from invalidating bob transforms
/// - Cross-fade blending is only enabled for large sizes (≥180px) where
///   the effect is visible; small sizes skip the second [SvgPicture] entirely
class MochiAnimatedVideoWidget extends StatefulWidget {
  final double size;
  final bool showVideoBadge;
  final Duration cycleDuration;
  final bool showCircleBackground;

  const MochiAnimatedVideoWidget({
    super.key,
    this.size = 240,
    this.showVideoBadge = true,
    this.cycleDuration = const Duration(milliseconds: 6500),
    this.showCircleBackground = true,
  });

  @override
  State<MochiAnimatedVideoWidget> createState() =>
      _MochiAnimatedVideoWidgetState();
}

class _MochiAnimatedVideoWidgetState extends State<MochiAnimatedVideoWidget>
    with TickerProviderStateMixin {
  // SVG Frame sequence (EXCLUDING mochi_thinking.svg per user directive)
  static const List<Map<String, String>> _frames = [
    {'path': 'assets/mochi/mochi_relaxed.svg', 'label': ''},
    {'path': 'assets/mochi/mochi_cheering.svg', 'label': ''},
  ];

  late AnimationController _timelineController;
  late AnimationController _bobController;

  // Pre-cached SVG picture info (avoids per-frame re-decode)
  final List<SvgAssetLoader> _loaders = [];

  @override
  void initState() {
    super.initState();

    // 1. Timeline controller — drives frame index switching only
    _timelineController = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    )..repeat();

    // 2. Bob controller — separate 60fps sinusoidal float animation
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 3. Pre-cache all SVG assets after first frame so UI thread is free
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheSvgs());
  }

  Future<void> _precacheSvgs() async {
    for (final frame in _frames) {
      _loaders.add(SvgAssetLoader(frame['path']!));
      // Warm the SVG decode cache — runs after first frame, off the hot path
      await svg.cache.putIfAbsent(
        SvgAssetLoader(frame['path']!).cacheKey(null),
        () => SvgAssetLoader(frame['path']!).loadBytes(null),
      );
    }
  }

  @override
  void dispose() {
    _timelineController.dispose();
    _bobController.dispose();
    super.dispose();
  }

  // Whether the size is large enough to show cross-fade (expensive)
  bool get _useCrossFade => widget.size >= 180;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Bob animation wraps the SVG layer ────────────────────────────────
        AnimatedBuilder(
          animation: _bobController,
          builder: (context, child) {
            final double bobY =
                math.sin(_bobController.value * math.pi * 2) * 4.0;
            return Transform.translate(offset: Offset(0, bobY), child: child);
          },
          child: RepaintBoundary(
            // SVG container is isolated — bob Transform doesn't force SVG repaint
            child: AnimatedBuilder(
              animation: _timelineController,
              builder: (context, _) {
                final double timeline = _timelineController.value;
                final double frameProgress = timeline * _frames.length;
                final int currentIndex = frameProgress.floor() % _frames.length;
                final int nextIndex = (currentIndex + 1) % _frames.length;
                final double localT = frameProgress - frameProgress.floor();

                double blend = 0.0;
                double squishX = 1.0;
                double squishY = 1.0;
                double tiltAngle = 0.0;

                // Only compute cross-fade physics if size warrants it
                if (_useCrossFade && localT >= 0.65) {
                  final double t = (localT - 0.65) / 0.35;
                  blend = Curves.easeInOut.transform(t);
                  final double squishFactor = math.sin(t * math.pi) * 0.10;
                  squishX = 1.0 + squishFactor;
                  squishY = 1.0 - squishFactor;
                  tiltAngle =
                      math.sin(t * math.pi) *
                      (currentIndex % 2 == 0 ? 0.05 : -0.05);
                }

                final currentFrame = _frames[currentIndex];
                final nextFrame = _frames[nextIndex];

                final svgContent = Transform.rotate(
                  angle: tiltAngle,
                  child: Transform.scale(
                    scaleX: squishX,
                    scaleY: squishY,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Current frame SVG
                        SvgPicture.asset(
                          currentFrame['path']!,
                          width: widget.size,
                          height: widget.size,
                          fit: BoxFit.contain,
                        ),

                        // Cross-fade next frame — only on large sizes
                        if (_useCrossFade && blend > 0.0)
                          Opacity(
                            opacity: blend.clamp(0.0, 1.0),
                            child: SvgPicture.asset(
                              nextFrame['path']!,
                              width: widget.size,
                              height: widget.size,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),
                );

                if (!widget.showCircleBackground) {
                  return SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: svgContent,
                  );
                }

                return Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFFF0EB),
                        Color(0xFFFFE6DD),
                        Color(0xFFFAF9F8),
                      ],
                      stops: [0.5, 0.85, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC84B1A).withValues(alpha: 0.16),
                        blurRadius: 28,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: const Color(0xFFF472B6).withValues(alpha: 0.10),
                        blurRadius: 36,
                        spreadRadius: 4,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    child: svgContent,
                  ),
                );
              },
            ),
          ),
        ),

        if (widget.showVideoBadge) ...[
          const SizedBox(height: 16),

          // Video Playback Label Pill
          AnimatedBuilder(
            animation: _timelineController,
            builder: (context, child) {
              final double timeline = _timelineController.value;
              final int activeIndex =
                  (timeline * _frames.length).floor() % _frames.length;
              final frame = _frames[activeIndex];

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Container(
                  key: ValueKey<String>(frame['label']!),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD8CC),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC84B1A).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        frame['label']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC84B1A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
