import '../models/otp_config.dart';
import 'optica2_api.dart';

/// Cached OTP provider from admin SMS Gateway (Firebase vs MSG91).
abstract final class OtpConfigService {
  static OtpConfig? _cached;

  static void invalidate() => _cached = null;

  static OtpConfig? get cached => _cached;

  /// Loads `/api/otp/config`. Returns null when the API cannot be reached.
  static Future<OtpConfig?> ensureLoaded({Optica2Api? api, bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached;

    final client = api ?? Optica2Api();
    final ownsClient = api == null;
    try {
      final loaded = await client.fetchOtpConfig();
      _cached = loaded;
      return loaded;
    } catch (_) {
      return _cached;
    } finally {
      if (ownsClient) client.close();
    }
  }
}
