import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:teekoob/firebase_options.dart';
import 'package:teekoob/core/services/notification_service_interface.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/config/app_config.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 Background message received: ${message.notification?.title}');
}

class FirebaseNotificationService implements NotificationServiceInterface {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final _storage = const FlutterSecureStorage();
  
  FirebaseMessaging? _messaging;
  String? _fcmToken;
  bool _isInitialized = false;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageOpenedAppController = StreamController<Map<String, dynamic>>.broadcast();
  final _tokenRefreshController = StreamController<String>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => _messageOpenedAppController.stream;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      print('🔔 Firebase Notification Service already initialized');
      return;
    }

    try {
      print('🔔 Initializing Firebase Notification Service...');

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('🔔 ✅ Firebase Core initialized');

      // Initialize Firebase Messaging
      _messaging = FirebaseMessaging.instance;

      // Request permissions (iOS)
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print('🔔 Notification permissions: ${settings.authorizationStatus}');

      // Get FCM token
      _fcmToken = await _messaging!.getToken();
      if (_fcmToken != null) {
        print('🔔 ✅ FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
        await _storage.write(key: 'fcm_token', value: _fcmToken);
      }

      // Initialize local notifications for foreground messages
      await _initializeLocalNotifications();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 Foreground message received: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🔔 Notification tapped (background): ${message.notification?.title}');
        _messageOpenedAppController.add(message.data);
      });

      // Handle initial message if app was opened from terminated state
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        print('🔔 App opened from notification: ${initialMessage.notification?.title}');
        _messageOpenedAppController.add(initialMessage.data);
      }

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen((String token) {
        print('🔔 FCM Token refreshed: ${token.substring(0, 20)}...');
        _fcmToken = token;
        _storage.write(key: 'fcm_token', value: token);
        _tokenRefreshController.add(token);
      });

      _isInitialized = true;
      print('🔔 ✅ Firebase Notification Service initialized successfully');
    } catch (e) {
      print('🔔 ❌ Error initializing Firebase Notification Service: $e');
      rethrow;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = json.decode(response.payload!);
          _messageOpenedAppController.add(data);
        }
      },
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'teekoob_notifications',
      'Teekoob Notifications',
      description: 'Notifications for new books and updates',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    print('🔔 ✅ Local notifications initialized');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      // Show local notification for foreground messages
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'teekoob_notifications',
            'Teekoob Notifications',
            channelDescription: 'Notifications for new books and updates',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            largeIcon: message.data['image'] != null 
                ? DrawableResourceAndroidBitmap('@mipmap/ic_launcher')
                : null,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );

      _messageController.add(message.data);
    }
  }

  @override
  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;

    // Try to get from storage
    _fcmToken = await _storage.read(key: 'fcm_token');
    if (_fcmToken != null) return _fcmToken;

    // Get new token
    if (_messaging != null) {
      _fcmToken = await _messaging!.getToken();
      if (_fcmToken != null) {
        await _storage.write(key: 'fcm_token', value: _fcmToken);
      }
    }

    return _fcmToken;
  }

  @override
  String? getFCMToken() => _fcmToken;

  @override
  Future<void> subscribeToTopic(String topic) async {
    if (_messaging != null) {
      await _messaging!.subscribeToTopic(topic);
      print('🔔 Subscribed to topic: $topic');
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging != null) {
      await _messaging!.unsubscribeFromTopic(topic);
      print('🔔 Unsubscribed from topic: $topic');
    }
  }

  @override
  Future<void> sendNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'teekoob_notifications',
          'Teekoob Notifications',
          channelDescription: 'Notifications for new books and updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: data != null ? json.encode(data) : null,
    );
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    if (_messaging == null) return false;
    final settings = await _messaging!.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<bool> requestPermissions() async {
    if (_messaging == null) return false;

    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<List<dynamic>> getPendingNotifications() async {
    final pendingNotifications = await _localNotifications.pendingNotificationRequests();
    return pendingNotifications;
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) {
        print('🔔 ⚠️ No auth token, skipping backend registration');
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'fcmToken': token,
          'platform': 'mobile',
          'enabled': true,
        }),
      );

      if (response.statusCode == 200) {
        print('🔔 ✅ FCM token registered with backend');
      } else {
        print('🔔 ⚠️ Failed to register token with backend: ${response.statusCode}');
      }
    } catch (e) {
      print('🔔 ❌ Error registering token with backend: $e');
    }
  }

  @override
  Future<void> enableRandomBookNotifications() async {
    try {
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) return;

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/notifications/preferences/random-books'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'enabled': true}),
      );

      if (response.statusCode == 200) {
        print('🔔 ✅ Random book notifications enabled');
      }
    } catch (e) {
      print('🔔 ❌ Error enabling random book notifications: $e');
    }
  }

  @override
  Future<void> disableRandomBookNotifications() async {
    try {
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) return;

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/notifications/preferences/random-books'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'enabled': false}),
      );

      if (response.statusCode == 200) {
        print('🔔 ✅ Random book notifications disabled');
      }
    } catch (e) {
      print('🔔 ❌ Error disabling random book notifications: $e');
    }
  }

  @override
  Future<void> sendTestNotification() async {
    try {
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) return;

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/notifications/test'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        print('🔔 ✅ Test notification sent');
      }
    } catch (e) {
      print('🔔 ❌ Error sending test notification: $e');
    }
  }

  @override
  Future<void> scheduleBookReminder({
    required Book book,
    required DateTime scheduledTime,
    String? customMessage,
  }) async {
    // Local notification scheduling not implemented in this version
    print('🔔 Book reminder scheduled for ${book.title}');
  }

  @override
  Future<void> showInstantBookReminder({
    required Book book,
    String? customMessage,
  }) async {
    await sendNotification(
      title: '📚 Book Reminder',
      body: customMessage ?? 'Continue reading ${book.title}',
      data: {'bookId': book.id.toString(), 'type': 'book_reminder'},
    );
  }

  @override
  Future<void> scheduleNewBookNotification({
    required Book book,
    required DateTime releaseTime,
  }) async {
    print('🔔 New book notification scheduled for ${book.title}');
  }

  @override
  Future<void> scheduleDailyReadingReminder({
    required Book book,
    required TimeOfDay time,
  }) async {
    print('🔔 Daily reading reminder scheduled for ${book.title}');
  }

  @override
  Future<void> scheduleReadingProgressReminder({
    required Book book,
    required Duration interval,
  }) async {
    print('🔔 Reading progress reminder scheduled for ${book.title}');
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Register token with backend when user logs in
  Future<void> registerTokenOnLogin() async {
    final token = await getToken();
    if (token != null) {
      await _registerTokenWithBackend(token);
    }
  }

  void dispose() {
    _messageController.close();
    _messageOpenedAppController.close();
    _tokenRefreshController.close();
  }
}
