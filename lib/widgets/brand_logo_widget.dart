import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandLogoWidget extends StatelessWidget {
  final double height;
  final double? width;
  final BoxFit fit;

  const BrandLogoWidget({
    super.key,
    this.height = 48.0,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/U&ME.svg',
      height: height,
      width: width,
      fit: fit,
    );
  }
}
