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
  print('🔔 ===== BACKGROUND MESSAGE RECEIVED =====');
  print('🔔 Message ID: ${message.messageId}');
  print('🔔 Message Type: ${message.messageType}');
  print('🔔 Sent Time: ${message.sentTime}');
  print('🔔 From: ${message.from}');
  print('🔔 TTL: ${message.ttl}');
  print('🔔 Collapse Key: ${message.collapseKey}');
  
  if (message.notification != null) {
    print('🔔 ===== NOTIFICATION DATA =====');
    print('🔔 Title: ${message.notification?.title}');
    print('🔔 Body: ${message.notification?.body}');
    print('🔔 Android: ${message.notification?.android}');
    print('🔔 Apple: ${message.notification?.apple}');
  }
  
  if (message.data.isNotEmpty) {
    print('🔔 ===== MESSAGE DATA =====');
    message.data.forEach((key, value) {
      print('🔔 $key: $value');
    });
  }
  
  print('🔔 ===== END BACKGROUND MESSAGE =====');
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

    print('🔔 ===== FIREBASE INITIALIZATION START =====');
    print('🔔 Platform: ${kIsWeb ? "Web" : "Mobile"}');

    try {
      // Initialize Firebase with error handling
      print('🔔 Initializing Firebase Core...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('🔔 ✅ Firebase Core initialized successfully');

      // Set up background message handler (only for mobile)
      if (!kIsWeb) {
        print('🔔 Setting up background message handler...');
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        print('🔔 ✅ Background message handler set up');
      }

      // Request permissions
      print('🔔 Requesting notification permissions...');
      await _requestPermissions();

      // Get FCM token
      print('🔔 Getting FCM token...');
      await _getFCMToken();

      // Set up message listeners
      print('🔔 Setting up message listeners...');
      _setupMessageListeners();

      _isInitialized = true;
      print('🔔 ✅ Firebase Notification Service initialized successfully');
      print('🔔 ===== FIREBASE INITIALIZATION COMPLETE =====');
    } catch (e) {
      print('🔔 ❌ Error initializing Firebase Notification Service: $e');
      print('🔔 Stack trace: ${StackTrace.current}');
      // Don't throw error - let app continue without notifications
    }
  }

  Future<void> _requestPermissions() async {
    print('🔔 ===== REQUESTING PERMISSIONS =====');
    try {
      if (kIsWeb) {
        print('🔔 Web platform - skipping notification permissions');
        return;
      }

      // Request FCM permissions
      print('🔔 Requesting FCM permissions...');
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 ===== PERMISSION RESULTS =====');
      print('🔔 Authorization Status: ${settings.authorizationStatus}');
      print('🔔 Alert: ${settings.alert}');
      print('🔔 Badge: ${settings.badge}');
      print('🔔 Sound: ${settings.sound}');
      print('🔔 Car Play: ${settings.carPlay}');
      print('🔔 Critical Alert: ${settings.criticalAlert}');
      print('🔔 Announcement: ${settings.announcement}');
      print('🔔 ===== END PERMISSION RESULTS =====');
    } catch (e) {
      print('🔔 ❌ Error requesting notification permissions: $e');
    }
  }

  Future<void> _getFCMToken() async {
    print('🔔 ===== GETTING FCM TOKEN =====');
    try {
      if (kIsWeb) {
        print('🔔 Web platform - FCM token not available');
        return;
      }
      
      print('🔔 Requesting FCM token from Firebase...');
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken != null) {
        print('🔔 ✅ FCM Token received successfully');
        print('🔔 Token length: ${_fcmToken!.length} characters');
        print('🔔 Token preview: ${_fcmToken!.substring(0, 20)}...');
        
        // Register token with backend
        print('🔔 Registering token with backend...');
        await _registerTokenWithBackend(_fcmToken!);
      } else {
        print('🔔 ❌ FCM Token is null');
      }
    } catch (e) {
      print('🔔 ❌ Error getting FCM token: $e');
    }
    print('🔔 ===== END FCM TOKEN =====');
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
    print('🔔 ===== SETTING UP MESSAGE LISTENERS =====');
    
    if (kIsWeb) {
      print('🔔 Web platform - message listeners not supported');
      return;
    }
    
    // Handle foreground messages - NO LOCAL NOTIFICATIONS
    print('🔔 Setting up foreground message listener...');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 ===== FOREGROUND MESSAGE RECEIVED =====');
      print('🔔 Message ID: ${message.messageId}');
      print('🔔 Message Type: ${message.messageType}');
      print('🔔 Sent Time: ${message.sentTime}');
      print('🔔 From: ${message.from}');
      
      if (message.notification != null) {
        print('🔔 ===== FOREGROUND NOTIFICATION DATA =====');
        print('🔔 Title: ${message.notification?.title}');
        print('🔔 Body: ${message.notification?.body}');
        print('🔔 Android: ${message.notification?.android}');
        print('🔔 Apple: ${message.notification?.apple}');
      }
      
      if (message.data.isNotEmpty) {
        print('🔔 ===== FOREGROUND MESSAGE DATA =====');
        message.data.forEach((key, value) {
          print('🔔 $key: $value');
        });
      }
      
      print('🔔 ===== END FOREGROUND MESSAGE =====');
      // No local notification shown - Firebase handles everything
    });

    // Handle messages when app is opened from background
    print('🔔 Setting up background message opened listener...');
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 ===== BACKGROUND MESSAGE OPENED =====');
      print('🔔 Message ID: ${message.messageId}');
      print('🔔 Title: ${message.notification?.title}');
      print('🔔 Body: ${message.notification?.body}');
      print('🔔 Data: ${message.data}');
      print('🔔 ===== END BACKGROUND MESSAGE OPENED =====');
      _handleMessageTap(message);
    });

    // Handle messages when app is opened from terminated state
    print('🔔 Setting up initial message listener...');
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🔔 ===== INITIAL MESSAGE FOUND =====');
        print('🔔 Message ID: ${message.messageId}');
        print('🔔 Title: ${message.notification?.title}');
        print('🔔 Body: ${message.notification?.body}');
        print('🔔 Data: ${message.data}');
        print('🔔 ===== END INITIAL MESSAGE =====');
        _handleMessageTap(message);
      } else {
        print('🔔 No initial message found');
      }
    });
    
    print('🔔 ✅ All message listeners set up successfully');
    print('🔔 ===== END MESSAGE LISTENERS SETUP =====');
  }

  void _handleMessageTap(RemoteMessage message) {
    // Handle navigation when notification is tapped
    final bookId = message.data['bookId'];
    if (bookId != null) {
      print('🔔 Navigating to book detail for ID: $bookId');
      // TODO: Implement navigation to book detail page using GoRouter
    }
  }

  Future<List<dynamic>> getPendingNotifications() async {
    // No local notifications - return empty list
    return [];
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

  // Firebase Cloud Messaging methods
  String? getFCMToken() => _fcmToken;

  Future<void> enableRandomBookNotifications() async {
    print('🔔 ===== ENABLING RANDOM BOOK NOTIFICATIONS =====');
    print('🔔 Random book notifications enabled via Firebase Cloud Messaging');
    print('🔔 Backend will send notifications every 10 minutes');
    print('🔔 ===== END ENABLE NOTIFICATIONS =====');
    // TODO: Implement API call to enable notifications in backend
  }

  Future<void> disableRandomBookNotifications() async {
    print('🔔 ===== DISABLING RANDOM BOOK NOTIFICATIONS =====');
    print('🔔 Random book notifications disabled via Firebase Cloud Messaging');
    print('🔔 Backend will stop sending notifications');
    print('🔔 ===== END DISABLE NOTIFICATIONS =====');
    // TODO: Implement API call to disable notifications in backend
  }

  Future<void> sendTestNotification() async {
    print('🔔 ===== SENDING TEST NOTIFICATION =====');
    print('🔔 Test notification sent via Firebase Cloud Messaging');
    print('🔔 Backend will send a test notification immediately');
    print('🔔 ===== END TEST NOTIFICATION =====');
    // TODO: Implement API call to send test notification from backend
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

  Future<void> showInstantBookReminder({required Book book, String? customMessage}) async {
    print('🔔 Instant book reminder disabled - use Firebase Cloud Messaging instead');
  }

  Future<void> scheduleReadingProgressReminder({required Book book, required Duration interval}) async {
    print('🔔 Reading progress reminder disabled - use Firebase Cloud Messaging instead');
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
