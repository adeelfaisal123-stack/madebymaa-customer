import 'package:shared_preferences/shared_preferences.dart';

import 'models/customer_auth.dart';

/// Persisted customer session after phone OTP login.
abstract final class CustomerSessionPrefs {
  static const _loggedInKey = 'customer_session_logged_in';
  static const _idKey = 'customer_session_id';
  static const _nameKey = 'customer_session_name';
  static const _phoneKey = 'customer_session_phone';
  static const _emailKey = 'customer_session_email';

  static Future<CustomerAuth?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_loggedInKey) != true) return null;

      final id = prefs.getInt(_idKey);
      final name = prefs.getString(_nameKey);
      final phone = prefs.getString(_phoneKey);
      if (id == null || name == null || phone == null) return null;

      final email = prefs.getString(_emailKey);

      return CustomerAuth(
        id: id,
        name: name,
        phone: phone,
        email: email != null && email.trim().isNotEmpty ? email.trim() : null,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasSession() async {
    final session = await load();
    return session != null;
  }

  static Future<void> save(CustomerAuth customer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setInt(_idKey, customer.id);
    await prefs.setString(_nameKey, customer.name);
    await prefs.setString(_phoneKey, customer.phone);
    if (customer.email != null && customer.email!.trim().isNotEmpty) {
      await prefs.setString(_emailKey, customer.email!.trim());
    } else {
      await prefs.remove(_emailKey);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_idKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_emailKey);
  }
}
