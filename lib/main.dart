import 'dart:async' show unawaited;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/optica2_config.dart';
import 'customer_session_prefs.dart';
import 'firebase_bootstrap.dart';
import 'l10n/app_localizations.dart';
import 'locale_prefs.dart';
import 'screens/splash_screen.dart';
import 'services/customer_push_service.dart';
import 'services/google_maps_config_service.dart';
import 'services/optica2_api.dart';
import 'services/otp_config_service.dart';
import 'services/payment_config_service.dart';
import 'theme/app_colors.dart';
import 'utils/app_fonts.dart';
import 'utils/app_system_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      CustomerPushService.firebaseMessagingBackgroundHandler,
    );
  }
  await AppSystemUi.apply();
  await Optica2Config.initialize();
  try {
    await ensureFirebaseInitialized();
  } catch (e, st) {
    debugPrint('Firebase init in main() failed: $e\n$st');
  }
  try {
    await CustomerPushService.ensureReady();
  } catch (e, st) {
    debugPrint('Customer push init skipped: $e\n$st');
  }
  try {
    await GoogleMapsConfigService.ensureLoaded();
  } catch (e, st) {
    debugPrint('Maps config preload skipped: $e\n$st');
  }
  try {
    await OtpConfigService.ensureLoaded();
  } catch (e, st) {
    debugPrint('OTP config preload skipped: $e\n$st');
  }
  try {
    await PaymentConfigService.ensureLoaded();
  } catch (e, st) {
    debugPrint('Payment config preload skipped: $e\n$st');
  }
  final initialLocale = await LocalePrefs.load();
  runApp(CustomerApp(initialLocale: initialLocale));
  unawaited(_registerPushIfSignedIn());
}

Future<void> _registerPushIfSignedIn() async {
  final session = await CustomerSessionPrefs.load();
  if (session == null) return;
  try {
    await CustomerPushService.registerDevice(
      api: Optica2Api(),
      customerId: session.id,
      phoneE164: session.phone,
    );
  } catch (e, st) {
    debugPrint('Customer push registration skipped: $e\n$st');
  }
}

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key, required this.initialLocale});

  final Locale initialLocale;

  static CustomerAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<CustomerAppState>();

  @override
  State<CustomerApp> createState() => CustomerAppState();
}

class CustomerAppState extends State<CustomerApp> {
  late Locale _locale = widget.initialLocale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    setState(() => _locale = locale);
    LocalePrefs.save(locale);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPurple,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Made by Maa',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: LocalePrefs.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.cream,
        textTheme: AppFonts.textThemeFor(_locale),
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
