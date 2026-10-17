/// OTP provider from `GET /api/otp/config` (admin SMS Gateway setting).
class OtpConfig {
  const OtpConfig({
    required this.provider,
    required this.configured,
  });

  final String provider;
  final bool configured;

  bool get isFirebase => provider == 'firebase';

  bool get isMsg91 => provider == 'msg91';

  factory OtpConfig.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> map;
    final otp = json['otp'];
    if (otp is Map) {
      map = Map<String, dynamic>.from(otp);
    } else if (json.containsKey('provider')) {
      map = json;
    } else {
      return const OtpConfig(provider: 'firebase', configured: true);
    }

    final rawProvider = (map['provider'] as String?)?.trim().toLowerCase();
    final provider = rawProvider == 'msg91' ? 'msg91' : 'firebase';

    return OtpConfig(
      provider: provider,
      configured: _readBool(map['configured'], defaultValue: provider == 'firebase'),
    );
  }

  static bool _readBool(dynamic value, {required bool defaultValue}) {
    if (value == true || value == 1) return true;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return defaultValue;
  }
}
