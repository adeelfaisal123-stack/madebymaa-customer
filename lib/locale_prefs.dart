import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saved app UI language (English or Telugu).
abstract final class LocalePrefs {
  static const languageCodeKey = 'customer_app_language_code';

  static const supportedLocales = [
    Locale('en'),
    Locale('te'),
  ];

  static Future<Locale> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(languageCodeKey);
      if (code == 'te') return const Locale('te');
      return const Locale('en');
    } catch (_) {
      return const Locale('en');
    }
  }

  static Future<void> save(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageCodeKey, locale.languageCode);
  }
}
