import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:teekoob/firebase_options.dart';
import 'package:teekoob/core/services/notification_service_interface.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/books/services/books_service.dart';
import 'package:teekoob/core/services/localization_service.dart';

// Background message handler - must be top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 Background message received: ${message.messageId}');
  print('🔔 Title: ${message.notification?.title}');
  print('🔔 Body: ${message.notification?.body}');
  print('🔔 Data: ${message.data}');
}

class FirebaseNotificationService implements NotificationServiceInterface {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final BooksService _booksService = BooksService();

  bool _isInitialized = false;
  String? _fcmToken;

  /// Initialize Firebase and FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permissions
      await _requestPermissions();

      // Get FCM token
      await _getFCMToken();

      // Set up message listeners
      _setupMessageListeners();

      _isInitialized = true;
      print('🔔 Firebase Notification Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase Notification Service: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (kIsWeb) {
        print('🔔 Web platform - skipping notification permissions');
        return;
      }

      // Request FCM permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 FCM Permission status: ${settings.authorizationStatus}');
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
    }
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('🔔 FCM Token: $_fcmToken');
      
      // Register token with backend
      if (_fcmToken != null) {
        await _registerTokenWithBackend(_fcmToken!);
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      // TODO: Implement API call to register FCM token with backend
      // This should call your backend's /notifications/register-token endpoint
      print('🔔 Registering FCM token with backend: $token');
    } catch (e) {
      print('❌ Error registering FCM token with backend: $e');
    }
  }

  void _setupMessageListeners() {
    // Handle foreground messages - NO LOCAL NOTIFICATIONS
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground message received: ${message.messageId}');
      print('🔔 Title: ${message.notification?.title}');
      print('🔔 Body: ${message.notification?.body}');
      // No local notification shown - Firebase handles everything
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Background message opened: ${message.messageId}');
      _handleMessageTap(message);
    });

    // Handle messages when app is opened from terminated state
    FirebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🔔 Initial message: ${message.messageId}');
        _handleMessageTap(message);
      }
    });
  }

  void _handleMessageTap(RemoteMessage message) {
    // Handle navigation when notification is tapped
    final bookId = message.data['bookId'];
    if (bookId != null) {
      print('🔔 Navigating to book detail for ID: $bookId');
      // TODO: Implement navigation to book detail page using GoRouter
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      if (kIsWeb) return false;
      
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    // No local notifications - return empty list
    return [];
  }

  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;
      
      await _requestPermissions();
      return true;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  // All local notification methods are disabled - Firebase handles everything
  Future<void> scheduleBookReminder({required Book book, required DateTime scheduledTime, String? customMessage}) async {
    print('🔔 Local notifications disabled - use Firebase Cloud Messaging instead');
  }

  Future<void> scheduleDailyReadingReminder({required Book book, required TimeOfDay time}) async {
    print('🔔 Local notifications disabled - use Firebase Cloud Messaging instead');
  }

  Future<void> scheduleNewBookNotification({required Book book, required DateTime releaseTime}) async {
    print('🔔 Local notifications disabled - use Firebase Cloud Messaging instead');
  }

  Future<void> cancelNotification(int id) async {
    print('🔔 Local notifications disabled - no notifications to cancel');
  }

  Future<void> cancelAllNotifications() async {
    print('🔔 Local notifications disabled - no notifications to cancel');
  }

  String _createBookNotificationTitle(Book book) {
    final isSomali = LocalizationService.currentLanguageCode == 'so';
    if (isSomali) {
      return '📚 Buug Xiiso Leh!';
    } else {
      return '📚 Featured Book Alert!';
    }
  }

  String _createBookNotificationBody(Book book) {
    final isSomali = LocalizationService.currentLanguageCode == 'so';
    final title = isSomali ? (book.titleSomali ?? book.title) : book.title;
    final description = isSomali ? (book.descriptionSomali ?? book.description ?? 'Buug xiiso leh!') : (book.description ?? 'Discover this amazing book!');
    
    return '$title\n\n$description';
  }

  // Getter for FCM token
  String? get fcmToken => _fcmToken;
}
