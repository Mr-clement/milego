import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Rayons, espacements et thèmes Material 3 personnalisés de Milego.
class AppRadius {
  AppRadius._();
  static const double card = 24;
  static const double hero = 28;
  static const double chip = 16;
  static const double button = 16;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(
        brightness: Brightness.light,
        bg: AppColors.lightBg,
        surface: AppColors.lightSurface,
        surfaceAlt: AppColors.lightSurfaceAlt,
        textPrimary: AppColors.lightTextPrimary,
        textMuted: AppColors.lightTextMuted,
        border: AppColors.lightBorder,
      );

  static ThemeData dark() => _base(
        brightness: Brightness.dark,
        bg: AppColors.darkBg,
        surface: AppColors.darkSurface,
        surfaceAlt: AppColors.darkSurfaceAlt,
        textPrimary: AppColors.darkTextPrimary,
        textMuted: AppColors.darkTextMuted,
        border: AppColors.darkBorder,
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surfaceAlt,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      surface: surface,
    );

    final textTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(bodyColor: textPrimary, displayColor: textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      dividerColor: border,
      // Style commun des champs texte (était dupliqué dans ~6 écrans).
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: BorderSide(color: border),
        ),
      ),
      extensions: [
        MilegoColors(
          bg: bg,
          surface: surface,
          surfaceAlt: surfaceAlt,
          textPrimary: textPrimary,
          textMuted: textMuted,
          border: border,
        ),
      ],
    );
  }
}

/// Couleurs sémantiques accessibles via `context.milego`.
@immutable
class MilegoColors extends ThemeExtension<MilegoColors> {
  const MilegoColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textMuted,
    required this.border,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textMuted;
  final Color border;

  @override
  MilegoColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textMuted,
    Color? border,
  }) =>
      MilegoColors(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        textPrimary: textPrimary ?? this.textPrimary,
        textMuted: textMuted ?? this.textMuted,
        border: border ?? this.border,
      );

  @override
  MilegoColors lerp(MilegoColors? other, double t) {
    if (other == null) return this;
    return MilegoColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

extension MilegoColorsX on BuildContext {
  MilegoColors get milego => Theme.of(this).extension<MilegoColors>()!;
}
