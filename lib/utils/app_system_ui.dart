import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen system UI — status and navigation bars hidden (swipe edge to peek).
abstract final class AppSystemUi {
  static const overlayLightBackground = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  static const overlayOnDark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );

  /// Hides the status bar (time/battery) and system navigation bar app-wide.
  static Future<void> apply() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(overlayLightBackground);
  }

  static double topInset(BuildContext context, [double extra = 0]) =>
      MediaQuery.viewPaddingOf(context).top + extra;

  static double bottomInset(BuildContext context, [double extra = 0]) =>
      MediaQuery.viewPaddingOf(context).bottom + extra;
}
