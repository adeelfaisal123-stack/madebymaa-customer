import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../customer_location_prefs.dart';
import '../customer_session_prefs.dart';
import '../onboarding_prefs.dart';
import '../screens/home_screen.dart';
import '../screens/intro_onboarding_screen.dart';
import '../screens/location_picker_screen.dart';

/// App flow: splash → intro (first run) → location → home. Login is optional (Profile tab).
abstract final class AppNavigation {
  static Future<Widget> postSplashDestination() async {
    var hasLocation = false;
    var onboardingDone = false;

    try {
      hasLocation = await CustomerLocationPrefs.hasSavedLocation();
      final prefs = await SharedPreferences.getInstance();
      onboardingDone = prefs.getBool(OnboardingPrefs.completedKey) ?? false;
    } catch (_) {
      hasLocation = false;
      onboardingDone = false;
    }

    if (!onboardingDone) return const IntroOnboardingScreen();
    if (!hasLocation) return const LocationPickerScreen();
    return const HomeScreen();
  }

  /// After intro finishes or is skipped.
  static Future<void> afterIntroCompleted(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(OnboardingPrefs.completedKey, true);
    } catch (e, st) {
      debugPrint('Could not save onboarding state: $e\n$st');
    }

    if (!context.mounted) return;
    await _replaceWithNextGate(context);
  }

  /// After phone OTP login or registration succeeds.
  static Future<void> afterLoginCompleted(BuildContext context) async {
    if (!context.mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }

    await _replaceWithNextGate(context);
  }

  /// After delivery location is confirmed on the map screen.
  static Future<void> afterLocationSaved(BuildContext context) async {
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: child,
          );
        },
      ),
    );
  }

  static Future<void> afterLogout(BuildContext context) async {
    await CustomerSessionPrefs.clear();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: child,
          );
        },
      ),
      (_) => false,
    );
  }

  static Future<void> _replaceWithNextGate(BuildContext context) async {
    var hasLocation = false;

    try {
      hasLocation = await CustomerLocationPrefs.hasSavedLocation();
    } catch (_) {
      hasLocation = false;
    }

    if (!context.mounted) return;

    final next = hasLocation
        ? const HomeScreen()
        : const LocationPickerScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: child,
          );
        },
      ),
    );
  }
}
