import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/books/services/books_service.dart';
import 'package:teekoob/core/services/localization_service.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final BooksService _booksService = BooksService();
  final Random _random = Random();

  bool _isInitialized = false;
  String? _fcmToken;

  /// Initialize Firebase and FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      
      // Initialize timezone data
      tz.initializeTimeZones();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize FCM
      await _initializeFCM();

      _isInitialized = true;
      print('🔥 Firebase NotificationService initialized');
    } catch (e) {
      print('❌ Error initializing Firebase: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM permission granted');
        
        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        print('🔥 FCM Token: $_fcmToken');
        
        // Register for background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Handle notification taps when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        
        // Handle notification tap when app is terminated
        RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
        
      } else {
        print('❌ FCM permission denied');
      }
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  /// Get FCM token for device registration
  Future<String?> getFCMToken() async {
    if (_fcmToken == null) {
      _fcmToken = await _firebaseMessaging.getToken();
    }
    return _fcmToken;
  }

  /// Subscribe to random book notifications topic
  Future<void> subscribeToRandomBookNotifications() async {
    try {
      await _firebaseMessaging.subscribeToTopic('random_books');
      print('🔥 Subscribed to random_books topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from random book notifications topic
  Future<void> unsubscribeFromRandomBookNotifications() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('random_books');
      print('🔥 Unsubscribed from random_books topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('🔥 Received foreground message: ${message.messageId}');
    
    // Show local notification for foreground messages
    _showLocalNotification(message);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('🔥 Notification tapped: ${message.messageId}');
    
    // Handle navigation based on notification data
    final data = message.data;
    if (data.containsKey('book_id')) {
      // Navigate to book detail page
      print('📚 Navigate to book: ${data['book_id']}');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _notifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'random_books',
          'Random Book Recommendations',
          channelDescription: 'Notifications about random book recommendations',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null) {
        print('🔔 Local notification tapped: $payload');
        // Handle navigation
      }
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  /// Send test notification (for testing purposes)
  Future<void> sendTestNotification() async {
    try {
      // This would typically be called from your backend
      // For now, we'll simulate a notification
      final randomBook = await _getRandomBook();
      if (randomBook != null) {
        await _notifications.show(
          _random.nextInt(1000000),
          '📚 Featured Book Alert!',
          '${randomBook.title}\n\n${randomBook.description ?? 'Discover this amazing book from our homepage collections!'}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'random_books',
              'Random Book Recommendations',
              channelDescription: 'Notifications about random book recommendations',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: 'book_${randomBook.id}',
        );
        print('🔔 Test notification sent');
      }
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  /// Get a random book from the homepage collections
  Future<Book?> _getRandomBook() async {
    try {
      // Get books from different homepage collections
      final List<Future<List<Book>>> futures = [
        _booksService.getFeaturedBooks(limit: 10),
        _booksService.getNewReleases(limit: 10),
        _booksService.getRecentBooks(limit: 10),
        _booksService.getFreeBooks(limit: 10),
        _booksService.getRandomBooks(limit: 10),
      ];

      // Wait for all collections to load
      final List<List<Book>> allCollections = await Future.wait(futures);
      
      // Combine all books into one list
      final List<Book> allBooks = [];
      for (final collection in allCollections) {
        allBooks.addAll(collection);
      }

      if (allBooks.isEmpty) {
        return null;
      }

      // Return a random book from all homepage collections
      return allBooks[_random.nextInt(allBooks.length)];
    } catch (e) {
      print('❌ Error getting random book from homepage collections: $e');
      return null;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔥 Background message received: ${message.messageId}');
}
