import 'package:shared_preferences/shared_preferences.dart';

abstract final class DishSwipeHintPrefs {
  static const _dismissedKey = 'customer_dish_swipe_hint_dismissed';

  static Future<bool> isDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_dismissedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dismissedKey, true);
    } catch (_) {}
  }

  /// Clears the one-time dismiss flag (e.g. for testing).
  static Future<void> clearDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dismissedKey);
    } catch (_) {}
  }
}
