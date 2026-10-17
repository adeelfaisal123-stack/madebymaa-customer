import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../customer_session_prefs.dart';
import '../firebase_bootstrap.dart';
import 'customer_orders_store.dart';
import 'optica2_api.dart';

/// FCM setup and device-token sync for customer order updates.
abstract final class CustomerPushService {
  static const _channelId = 'customer_orders';
  static const _channelName = 'Order updates';
  static const _channelDescription = 'Order status and delivery updates';

  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _backgroundPluginReady = false;
  static bool _tokenRefreshBound = false;
  static Future<void>? _initFuture;

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    WidgetsFlutterBinding.ensureInitialized();
    await ensureFirebaseInitialized();
    await _ensureLocalNotificationsPlugin();

    // FCM shows notification payloads in the tray when backgrounded/terminated.
    // Present locally for data-only messages (and as fallback if system display fails).
    if (message.notification == null) {
      await _presentNotification(message);
    }
  }

  static Future<void> ensureReady() {
    return _initFuture ??= initialize();
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    await ensureFirebaseInitialized();
    await _ensureLocalNotificationsPlugin();
    await _requestNotificationPermission();

    if (!kIsWeb) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    _initialized = true;

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      await _handlePayload(initial.data);
    }
  }

  static Future<void> _ensureLocalNotificationsPlugin() async {
    if (_backgroundPluginReady) return;

    if (!kIsWeb) {
      const android = AndroidInitializationSettings('@drawable/ic_notification');
      const initSettings = InitializationSettings(android: android);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _backgroundPluginReady = true;
  }

  static Future<void> _requestNotificationPermission() async {
    if (kIsWeb) return;

    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    if (kDebugMode && granted == false) {
      debugPrint('Customer notifications permission denied by user.');
    }
  }

  static Future<bool> notificationsEnabled() async {
    if (kIsWeb) return false;

    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? false;
  }

  static Future<String?> getToken() async {
    await ensureReady();
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Customer FCM getToken failed: $e');
      }
      return null;
    }
  }

  static Future<bool> registerDevice({
    required Optica2Api api,
    required int customerId,
    required String phoneE164,
  }) async {
    await ensureReady();
    await _requestNotificationPermission();

    final token = await getToken();
    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        debugPrint('Customer FCM registerDevice: no token');
      }
      return false;
    }

    final ok = await api.registerDeviceToken(
      customerId: customerId,
      phoneE164: phoneE164,
      fcmToken: token,
    );

    if (!_tokenRefreshBound) {
      _tokenRefreshBound = true;
      _messaging.onTokenRefresh.listen((newToken) async {
        final session = await CustomerSessionPrefs.load();
        if (session == null) return;
        await api.registerDeviceToken(
          customerId: session.id,
          phoneE164: session.phone,
          fcmToken: newToken,
        );
      });
    }

    return ok;
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    await _presentNotification(message);
    await _handlePayload(message.data);
  }

  static void _onMessageOpened(RemoteMessage message) {
    unawaited(_handlePayload(message.data));
  }

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map<String, dynamic>) {
        unawaited(_handlePayload(data));
      }
    } catch (_) {}
  }

  static Future<void> _presentNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final data = message.data;
    final notification = message.notification;
    final title = _stringFrom(data['title']) ?? notification?.title;
    final body = _stringFrom(data['body']) ?? notification?.body;
    if (title == null && body == null) return;

    final orderId = int.tryParse(data['order_id']?.toString() ?? '');
    final notificationId = orderId ?? message.hashCode;

    await _localNotifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.status,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  static String? _stringFrom(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static Future<void> _handlePayload(Map<String, dynamic> data) async {
    final type = data['type']?.toString();
    if (type != 'order_status_updated') return;

    await CustomerOrdersStore.instance.refresh();
  }
}
