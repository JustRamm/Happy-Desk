import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors from Design System
  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceDim = Color(0xFFD6D9EF);
  static const Color surfaceBright = Color(0xFFFAF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F2FF);
  static const Color surfaceContainer = Color(0xFFEBEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE4E7FE);
  static const Color surfaceContainerHighest = Color(0xFFDEE1F8);

  static const Color onSurface = Color(0xFF171B2B);
  static const Color onSurfaceVariant = Color(0xFF594139);

  // Primary Vivid Orange
  static const Color primary = Color(0xFFAB3500);
  static const Color primaryContainer = Color(0xFFFF6B35);
  static const Color onPrimaryContainer = Color(0xFF5F1900);
  static const Color primaryFixed = Color(0xFFFFDBD0);

  // Secondary Soft Pink
  static const Color secondary = Color(0xFF95416C);
  static const Color secondaryContainer = Color(0xFFFF99C8);
  static const Color onSecondaryContainer = Color(0xFF7B2C56);

  // Tertiary Bright Emerald Green
  static const Color tertiary = Color(0xFF006C53);
  static const Color tertiaryContainer = Color(0xFF00AE88);
  static const Color onTertiaryContainer = Color(0xFF00392B);

  // Outline & Neutral
  static const Color outline = Color(0xFF8D7168);
  static const Color outlineVariant = Color(0xFFE1BFB5);
  static const Color background = Color(0xFFFAF8FF);

  // Legacy compatibility mappings for existing screens
  static const Color primaryRust = Color(0xFFAB3500);
  static const Color primaryRustDark = Color(0xFF5F1900);
  static const Color primaryRustLight = Color(0xFFFFF0EB);
  static const Color titleDark = Color(0xFF171B2B);
  static const Color textSecondary = Color(0xFF594139);
  static const Color textMuted = Color(0xFF8D7168);
  static const Color brandTitleOrange = Color(0xFF832600);
  static const Color pinkBadgeBg = Color(0xFFFDF0F3);
  static const Color pinkIconBg = Color(0xFFFCE7F3);
  static const Color pinkIconColor = Color(0xFFEC4899);
  static const Color mintBadgeBg = Color(0xFFEBF7F5);
  static const Color mintIconBg = Color(0xFFD1FAE5);
  static const Color mintIconColor = Color(0xFF10B981);
  static const Color progressTrack = Color(0xFFFFDBD0);
  static const Color backgroundLight = Color(0xFFFAF8FF);

  // Shapes & Radii
  static const double radiusSm = 4.0;
  static const double radiusDefault = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusLarge = 32.0;
  static const double radiusFull = 9999.0;

  // Typography Styles
  static TextStyle headlineXl({Color color = onSurface}) => GoogleFonts.plusJakartaSans(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 48 / 40,
        letterSpacing: -0.8,
        color: color,
      );

  static TextStyle headlineLg({Color color = onSurface}) => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.32,
        color: color,
      );

  static TextStyle headlineLgMobile({Color color = onSurface}) => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        color: color,
      );

  static TextStyle headlineMd({Color color = onSurface}) => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        color: color,
      );

  static TextStyle bodyLg({Color color = onSurfaceVariant}) => GoogleFonts.beVietnamPro(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
        color: color,
      );

  static TextStyle bodyMd({Color color = onSurfaceVariant}) => GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: color,
      );

  static TextStyle labelMd({Color color = onSurface}) => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: color,
      );

  static TextStyle labelSm({Color color = onSurfaceVariant}) => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        color: color,
      );

  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.beVietnamProTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: background,
      ),
      textTheme: baseTextTheme,
    );
  }
}
