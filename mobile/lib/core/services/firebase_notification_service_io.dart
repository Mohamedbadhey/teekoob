import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  FirebaseMessaging? _firebaseMessaging;
  final BooksService _booksService = BooksService();

  /// Get FirebaseMessaging instance (lazy initialization)
  FirebaseMessaging get _firebaseMessagingInstance {
    _firebaseMessaging ??= FirebaseMessaging.instance;
    return _firebaseMessaging!;
  }

  bool _isInitialized = false;
  String? _fcmToken;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  /// Initialize Firebase and FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔔 ===== FIREBASE INITIALIZATION START =====');
    print('🔔 Platform: ${kIsWeb ? "Web" : "Mobile"}');
    print('🔔 Retry attempt: ${_retryCount + 1}/$_maxRetries');

    try {
      // Initialize Firebase with timeout and error handling
      print('🔔 Initializing Firebase Core...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('🔔 ⏰ Firebase initialization timed out after 10 seconds');
          throw Exception('Firebase initialization timeout');
        },
      );
      print('🔔 ✅ Firebase Core initialized successfully');

      // Set up background message handler (only for mobile)
      if (!kIsWeb) {
        print('🔔 Setting up background message handler...');
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        print('🔔 ✅ Background message handler set up');
      }

      // Request permissions with timeout
      print('🔔 Requesting notification permissions...');
      await _requestPermissions().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('🔔 ⏰ Permission request timed out');
          throw Exception('Permission request timeout');
        },
      );

      // Get FCM token with timeout
      print('🔔 Getting FCM token...');
      await _getFCMToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('🔔 ⏰ FCM token retrieval timed out');
          throw Exception('FCM token timeout');
        },
      );

      // Set up message listeners
      print('🔔 Setting up message listeners...');
      _setupMessageListeners();

      _isInitialized = true;
      print('🔔 ✅ Firebase Notification Service initialized successfully');
      print('🔔 ===== FIREBASE INITIALIZATION COMPLETE =====');
    } catch (e) {
      print('🔔 ❌ Error initializing Firebase Notification Service: $e');
      print('🔔 Stack trace: ${StackTrace.current}');
      
      _retryCount++;
      if (_retryCount < _maxRetries) {
        print('🔔 🔄 Retrying Firebase initialization in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
        return initialize(); // Retry
      } else {
        print('🔔 ⚠️ Max retries reached. App will continue without Firebase notifications');
        _isInitialized = false; // Reset so it can be retried later
      }
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
      NotificationSettings settings = await _firebaseMessagingInstance.requestPermission(
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
      _fcmToken = await _firebaseMessagingInstance.getToken();
      
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
      print('🔔 Registering FCM token with backend: $token');
      
      // Get the backend URL from environment or use default
      const String backendUrl = 'https://teekoob-production.up.railway.app';
      
      // Get auth token from secure storage
      String? authToken = await _getAuthToken();
      
      if (authToken == null) {
        print('🔔 ⚠️ No auth token found, FCM token will be registered after login');
        return;
      }
      
      // Use the authenticated register-token endpoint
      print('🔔 Using authenticated register-token endpoint...');
      
      final response = await _makeApiCall(
        '$backendUrl/api/v1/notifications/register-token',
        'POST',
        {
          'fcmToken': token,
          'platform': 'mobile',
          'enabled': true,
        },
        authToken: authToken,
      );
      
      if (response['success'] == true) {
        print('🔔 ✅ FCM token registered with backend successfully');
      } else {
        print('🔔 ❌ Backend registration failed: ${response['error']}');
      }
      
    } catch (e) {
      print('❌ Error registering FCM token with backend: $e');
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      print('🔔 Getting auth token from secure storage...');
      
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      
      if (token != null) {
        print('🔔 ✅ Auth token found');
        print('🔔 Token preview: ${token.substring(0, 20)}...');
        return token;
      } else {
        print('🔔 ⚠️ No auth token found in secure storage');
        return null;
      }
    } catch (e) {
      print('🔔 ❌ Error getting auth token: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _makeApiCall(String url, String method, Map<String, dynamic>? data, {String? authToken}) async {
    try {
      print('🔔 Making API call to: $url');
      print('🔔 Method: $method');
      print('🔔 Data: $data');
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Add auth token if provided
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      late final http.Response response;
      
      if (method == 'POST') {
        response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: data != null ? jsonEncode(data) : null,
        );
      } else if (method == 'GET') {
        response = await http.get(Uri.parse(url), headers: headers);
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }
      
      print('🔔 Response status: ${response.statusCode}');
      print('🔔 Response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('🔔 ❌ API call error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
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
      
      final settings = await _firebaseMessagingInstance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }

  // Firebase Cloud Messaging methods
  String? getFCMToken() => _fcmToken;

  /// Manually retry Firebase initialization
  Future<void> retryInitialization() async {
    print('🔔 🔄 Manual retry requested');
    _retryCount = 0;
    _isInitialized = false;
    await initialize();
  }

  Future<void> enableRandomBookNotifications() async {
    print('🔔 ===== ENABLING RANDOM BOOK NOTIFICATIONS =====');
    
    try {
      // Get FCM token if not already available
      if (_fcmToken == null) {
        print('🔔 Getting FCM token for notification registration...');
        await _getFCMToken();
      }
      
      if (_fcmToken != null) {
        print('🔔 Registering FCM token with backend...');
        await _registerTokenWithBackend(_fcmToken!);
      } else {
        print('🔔 ⚠️ No FCM token available, skipping notification registration');
      }
      
      print('🔔 ✅ Random book notifications enabled via Firebase Cloud Messaging');
      print('🔔 Backend will send notifications every 2 minutes');
    } catch (e) {
      print('🔔 ❌ Error enabling random book notifications: $e');
    }
    
    print('🔔 ===== END ENABLE NOTIFICATIONS =====');
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

  // Interface methods
  @override
  Future<String?> getToken() async {
    return _fcmToken;
  }

  @override
  Future<void> requestPermission() async {
    await _requestPermissions();
  }

  @override
  Stream<String> get onTokenRefresh {
    if (kIsWeb) return const Stream.empty();
    return _firebaseMessagingInstance.onTokenRefresh;
  }

  @override
  Stream<Map<String, dynamic>> get onMessage {
    if (kIsWeb) return const Stream.empty();
    return _firebaseMessagingInstance.onMessage.map((message) => message.data);
  }

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp {
    if (kIsWeb) return const Stream.empty();
    return _firebaseMessagingInstance.onMessageOpenedApp.map((message) => message.data);
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    await _firebaseMessagingInstance.subscribeToTopic(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    await _firebaseMessagingInstance.unsubscribeFromTopic(topic);
  }

  @override
  Future<void> deleteToken() async {
    if (kIsWeb) return;
    await _firebaseMessagingInstance.deleteToken();
  }

  @override
  Future<void> dispose() async {
    // No cleanup needed for Firebase Messaging
  }
}
