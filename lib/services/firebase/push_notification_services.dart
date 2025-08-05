import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_services.dart';

class PushNotificationService {
  // ─── Singleton Setup ─────
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // ─── Firebase Messaging ─────
  static late final FirebaseMessaging _messaging;
  static String? fcmToken;

  // ─── Local Notification Setup ─────
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final AndroidInitializationSettings _androidSettings =
  const AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings _initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  Map<String, dynamic>? _payloadData;

  // ─────────────────────────────────────────────────────────────────────────────

  /// Call this in your FirebaseService.init() after Firebase is initialized.
   Future<void> initialize(BuildContext context) async {
    _messaging = FirebaseMessaging.instance;

    await _requestPermissions();
    await _setupLocalNotificationChannel();
    await _setupFlutterLocalNotificationsPlugin();
    await _setForegroundPresentationOptions();

    await generateDeviceToken();

    _listenForegroundNotifications();
    _listenBackgroundAndTerminatedNotifications();
  }

  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
      provisional: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    } else {
    }
  }

  static Future<void> generateDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      fcmToken = token;
    } catch (e) {
    }
  }

  Future<void> _setupLocalNotificationChannel() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _setupFlutterLocalNotificationsPlugin() async {
    await _flutterLocalNotificationsPlugin.initialize(
      _initSettings,
      onDidReceiveNotificationResponse: _onNotificationClick,
    );
  }

  Future<void> _setForegroundPresentationOptions() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────

  void _listenForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _payloadData = message.data;

      if (message.notification != null) {
        _flutterLocalNotificationsPlugin.show(
          1,
          message.notification?.title,
          message.notification?.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  void _listenBackgroundAndTerminatedNotifications() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _payloadData = message.data;
      _handleNotificationTap();
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);
  }

  static Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
    await FirebaseService.firebase;
  }

  // ─────────────────────────────────────────────────────────────────────────────

  void _onNotificationClick(NotificationResponse response) {
    _handleNotificationTap();
  }

  void _handleNotificationTap() {
    if (_payloadData == null) return;

    _payloadData = null;
  }

  // ─────────────────────────────────────────────────────────────────────────────

  /// Expose FCM token getter
  String? get deviceToken => fcmToken;
}
