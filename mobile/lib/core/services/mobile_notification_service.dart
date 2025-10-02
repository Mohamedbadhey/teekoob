import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:teekoob/core/services/notification_service_interface.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/books/services/books_service.dart';
import 'package:teekoob/core/services/localization_service.dart';

class MobileNotificationService implements NotificationServiceInterface {
  static final MobileNotificationService _instance = MobileNotificationService._internal();
  factory MobileNotificationService() => _instance;
  MobileNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final BooksService _booksService = BooksService();
  final Random _random = Random();

  bool _isInitialized = false;
  Timer? _notificationTimer;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Android initialization settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
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

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      print('🔔 Mobile Notification Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Mobile Notification Service: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (kIsWeb) {
        print('🔔 Web platform - skipping notification permissions');
        return;
      }

      // Request permissions for mobile platforms
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
      print('🔔 Notification permissions requested');
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped with payload: ${response.payload}');
    if (response.payload != null) {
      try {
        final bookId = response.payload!;
        if (bookId.isNotEmpty) {
          print('Navigating to book detail for ID: $bookId');
          // TODO: Implement navigation to book detail page using GoRouter
        }
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      if (kIsWeb) return false;
      
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      return true; // Assume enabled if we can get pending notifications
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }

  Future<List<dynamic>> getPendingNotifications() async {
    try {
      if (kIsWeb) return [];
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
      return [];
    }
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

  // Firebase Cloud Messaging methods (not supported - use local notifications)
  String? getFCMToken() {
    print('🔔 FCM not supported - using local notifications instead');
    return null;
  }

  Future<void> enableRandomBookNotifications() async {
    print('🔔 Random book notifications enabled via local notifications');
    _startRandomBookNotifications();
  }

  Future<void> disableRandomBookNotifications() async {
    print('🔔 Random book notifications disabled');
    _stopRandomBookNotifications();
  }

  Future<void> sendTestNotification() async {
    print('🔔 Sending test notification via local notifications');
    await _sendRandomBookNotification();
  }

  void _startRandomBookNotifications() {
    _stopRandomBookNotifications(); // Stop any existing timer
    
    // Send notification every 10 minutes
    _notificationTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _sendRandomBookNotification();
    });
    
    print('🔔 Random book notifications started (every 10 minutes)');
  }

  void _stopRandomBookNotifications() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    print('🔔 Random book notifications stopped');
  }

  Future<void> _sendRandomBookNotification() async {
    try {
      // Get random books from service
      final books = await _booksService.getBooks();
      if (books.isEmpty) return;

      final randomBook = books[_random.nextInt(books.length)];
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'random_book_channel',
        'Random Book Notifications',
        channelDescription: 'Notifications for random book recommendations',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      final title = _createBookNotificationTitle(randomBook);
      final body = _createBookNotificationBody(randomBook);
      
      await _notifications.show(
        randomBook.id.hashCode,
        title,
        body,
        platformChannelSpecifics,
        payload: randomBook.id.toString(),
      );
      
      print('🔔 Random book notification sent: ${randomBook.title}');
    } catch (e) {
      print('❌ Error sending random book notification: $e');
    }
  }

  Future<void> scheduleBookReminder({required Book book, required DateTime scheduledTime, String? customMessage}) async {
    try {
      if (kIsWeb) return;
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'book_reminder_channel',
        'Book Reminders',
        channelDescription: 'Notifications for book reading reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      final title = customMessage ?? _createBookNotificationTitle(book);
      final body = customMessage ?? _createBookNotificationBody(book);
      
      await _notifications.zonedSchedule(
        book.id.hashCode,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.getLocation('UTC')),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: book.id.toString(),
      );
      
      print('🔔 Book reminder scheduled for ${book.title} at $scheduledTime');
    } catch (e) {
      print('❌ Error scheduling book reminder: $e');
    }
  }

  Future<void> scheduleDailyReadingReminder({required Book book, required TimeOfDay time}) async {
    try {
      if (kIsWeb) return;
      
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      await scheduleBookReminder(
        book: book,
        scheduledTime: scheduledDate,
        customMessage: 'Time for your daily reading! 📚',
      );
      
      print('🔔 Daily reading reminder scheduled for ${book.title} at ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      print('❌ Error scheduling daily reading reminder: $e');
    }
  }

  Future<void> scheduleNewBookNotification({required Book book, required DateTime releaseTime}) async {
    try {
      if (kIsWeb) return;
      
      await scheduleBookReminder(
        book: book,
        scheduledTime: releaseTime,
        customMessage: 'New book released! 🎉',
      );
      
      print('🔔 New book notification scheduled for ${book.title} at $releaseTime');
    } catch (e) {
      print('❌ Error scheduling new book notification: $e');
    }
  }

  Future<void> showInstantBookReminder({required Book book, String? customMessage}) async {
    try {
      if (kIsWeb) return;
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'instant_reminder_channel',
        'Instant Reminders',
        channelDescription: 'Instant book reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      final title = customMessage ?? _createBookNotificationTitle(book);
      final body = customMessage ?? _createBookNotificationBody(book);
      
      await _notifications.show(
        book.id.hashCode,
        title,
        body,
        platformChannelSpecifics,
        payload: book.id.toString(),
      );
      
      print('🔔 Instant book reminder sent: ${book.title}');
    } catch (e) {
      print('❌ Error sending instant book reminder: $e');
    }
  }

  Future<void> scheduleReadingProgressReminder({required Book book, required Duration interval}) async {
    try {
      if (kIsWeb) return;
      
      final scheduledTime = DateTime.now().add(interval);
      
      await scheduleBookReminder(
        book: book,
        scheduledTime: scheduledTime,
        customMessage: 'Continue reading ${book.title}! 📖',
      );
      
      print('🔔 Reading progress reminder scheduled for ${book.title} in ${interval.inHours} hours');
    } catch (e) {
      print('❌ Error scheduling reading progress reminder: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      if (kIsWeb) return;
      await _notifications.cancel(id);
      print('🔔 Notification cancelled: $id');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      if (kIsWeb) return;
      await _notifications.cancelAll();
      print('🔔 All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
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
}
