import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PageIndicatorDots extends StatelessWidget {
  final int count;
  final int currentIndex;

  const PageIndicatorDots({
    super.key,
    this.count = 3,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 26 : 8,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryRust : AppTheme.progressTrack,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
