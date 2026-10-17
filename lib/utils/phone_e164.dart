import 'package:intl_phone_field/phone_number.dart';

/// Normalizes [IntlPhoneField] input to E.164 (e.g. +923044406903).
///
/// Only strips a duplicated country code when the local part starts with the
/// same [PhoneNumber.countryCode] (e.g. +92 selected and user typed 923…).
String phoneToE164(PhoneNumber phone) {
  final cc = phone.countryCode.replaceAll(RegExp(r'\D'), '');
  var local = phone.number.replaceAll(RegExp(r'\D'), '');

  if (local.startsWith('0') && local.length >= 11) {
    local = local.substring(1);
  }

  if (cc.isNotEmpty &&
      local.startsWith(cc) &&
      local.length > cc.length + 8) {
    local = local.substring(cc.length);
  }

  return '+$cc$local';
}
