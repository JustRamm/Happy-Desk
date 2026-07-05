import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PageIndicatorDots extends StatelessWidget {
  final int count;
  final int currentIndex;
  final ValueChanged<int>? onDotTapped;

  const PageIndicatorDots({
    super.key,
    this.count = 3,
    required this.currentIndex,
    this.onDotTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return GestureDetector(
          onTap: () => onDotTapped?.call(index),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              width: isActive ? 26 : 8,
              height: 7,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryRust : AppTheme.progressTrack,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }
}
