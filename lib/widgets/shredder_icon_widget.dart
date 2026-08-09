import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum ShredderState { idle, feeding, shredding }

class ShredderIconWidget extends StatelessWidget {
  final double size;
  final ShredderState state;
  final Color? mainColor;
  final Color? slotColor;
  final Color? binColor;

  const ShredderIconWidget({
    super.key,
    this.size = 32.0,
    this.state = ShredderState.idle,
    this.mainColor,
    this.slotColor,
    this.binColor,
  });

  String get _assetPath {
    switch (state) {
      case ShredderState.feeding:
        return 'assets/brand/paper_shredder_feeding.svg';
      case ShredderState.shredding:
        return 'assets/brand/paper_shredder_shredding.svg';
      case ShredderState.idle:
        return 'assets/brand/paper_shredder_idle.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
