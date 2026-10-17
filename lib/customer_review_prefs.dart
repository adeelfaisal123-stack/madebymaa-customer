import 'package:shared_preferences/shared_preferences.dart';

abstract final class CustomerReviewPrefs {
  static const _skippedPrefix = 'customer_review_skipped_';

  static Future<bool> isSkipped(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_skippedPrefix$orderId') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSkipped(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_skippedPrefix$orderId', true);
    } catch (_) {}
  }

  static Future<void> clearSkipped(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_skippedPrefix$orderId');
    } catch (_) {}
  }
}
