import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Locale-aware typography: Exo 2 for English, Noto Sans Telugu for Telugu script.
abstract final class AppFonts {
  static bool isTelugu(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'te';

  static TextStyle style(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
    if (isTelugu(context)) {
      return GoogleFonts.notoSansTelugu(textStyle: base);
    }
    return GoogleFonts.exo2(textStyle: base);
  }

  static TextTheme textTheme(BuildContext context) =>
      textThemeFor(Localizations.localeOf(context));

  static TextTheme textThemeFor(Locale locale) {
    if (locale.languageCode == 'te') {
      return GoogleFonts.notoSansTeluguTextTheme();
    }
    return GoogleFonts.exo2TextTheme();
  }
}
