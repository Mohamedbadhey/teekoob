// Simple notification service that works on both web and mobile
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'dart:math';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/services/notification_service_interface.dart';
import 'package:teekoob/features/books/services/books_service.dart';
import 'package:teekoob/core/services/localization_service.dart';

class SimpleNotificationService implements NotificationServiceInterface {
  static final SimpleNotificationService _instance = SimpleNotificationService._internal();
  factory SimpleNotificationService() => _instance;
  SimpleNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final BooksService _booksService = BooksService();
  final Random _random = Random();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request permissions
      await _requestPermissions();
      
      _isInitialized = true;
      print('🔔 Simple Notification Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Simple Notification Service: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    print('🔔 Local notifications initialized');
  }

  Future<void> _requestPermissions() async {
    try {
      if (kIsWeb) {
        print('🔔 Web platform - skipping notification permissions');
        return;
      }

      // Request permissions for mobile platforms
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      await _localNotifications
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
        final data = response.payload!;
        final bookId = data;
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
      
      final pendingNotifications = await _localNotifications.pendingNotificationRequests();
      return true; // Assume enabled if we can get pending notifications
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      if (kIsWeb) return [];
      return await _localNotifications.pendingNotificationRequests();
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
      
      await _localNotifications.zonedSchedule(
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
      
      await _localNotifications.show(
        book.id.hashCode,
        title,
        body,
        platformChannelSpecifics,
        payload: book.id.toString(),
      );
      
      print('🔔 Instant book reminder shown for ${book.title}');
    } catch (e) {
      print('❌ Error showing instant book reminder: $e');
    }
  }

  Future<void> scheduleReadingProgressReminder({required Book book, required Duration interval}) async {
    try {
      if (kIsWeb) return;
      
      final scheduledTime = DateTime.now().add(interval);
      
      await scheduleBookReminder(
        book: book,
        scheduledTime: scheduledTime,
        customMessage: 'Check your reading progress! 📖',
      );
      
      print('🔔 Reading progress reminder scheduled for ${book.title} in ${interval.inMinutes} minutes');
    } catch (e) {
      print('❌ Error scheduling reading progress reminder: $e');
    }
  }

  Future<void> cancelNotification(int notificationId) async {
    try {
      await _localNotifications.cancel(notificationId);
      print('🔔 Notification $notificationId cancelled');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('🔔 All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  Future<void> enableRandomBookNotifications() async {
    try {
      print('🔔 Random book notifications enabled');
      // Start sending random book notifications every 10 minutes
      _startRandomBookNotifications();
    } catch (e) {
      print('❌ Error enabling random book notifications: $e');
    }
  }

  Future<void> disableRandomBookNotifications() async {
    try {
      print('🔔 Random book notifications disabled');
      // Stop sending random book notifications
      _stopRandomBookNotifications();
    } catch (e) {
      print('❌ Error disabling random book notifications: $e');
    }
  }

  Future<void> sendTestNotification() async {
    try {
      if (kIsWeb) return;
      
      final book = await _getRandomBook();
      if (book != null) {
        await showInstantBookReminder(
          book: book,
          customMessage: 'Test notification with random book! 📚',
        );
        print('🔔 Test notification sent with book: ${book.title}');
      } else {
        print('❌ No books available for test notification');
      }
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  String? getFCMToken() => null; // No FCM token for simple notifications

  Timer? _notificationTimer;

  void _startRandomBookNotifications() {
    _stopRandomBookNotifications(); // Stop any existing timer
    
    _notificationTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      try {
        final book = await _getRandomBook();
        if (book != null) {
          await showInstantBookReminder(book: book);
          print('🔔 Random book notification sent: ${book.title}');
        }
      } catch (e) {
        print('❌ Error sending random book notification: $e');
      }
    });
    
    print('🔔 Random book notifications started (every 10 minutes)');
  }

  void _stopRandomBookNotifications() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    print('🔔 Random book notifications stopped');
  }

  Future<Book?> _getRandomBook() async {
    try {
      // Get books from homepage collections (same as displayed on homepage)
      final List<Future<List<Book>>> futures = [
        _booksService.getFeaturedBooks(limit: 10),
        _booksService.getNewReleases(limit: 10),
        _booksService.getRecentBooks(limit: 10),
        _booksService.getFreeBooks(limit: 10),
        _booksService.getRandomBooks(limit: 10),
      ];

      final List<List<Book>> allCollections = await Future.wait(futures);
      
      // Combine all homepage books
      final List<Book> allHomepageBooks = [];
      for (final collection in allCollections) {
        allHomepageBooks.addAll(collection);
      }

      if (allHomepageBooks.isEmpty) {
        print('❌ No homepage books available for notifications');
        return null;
      }

      // Select a random book from homepage collections
      final randomBook = allHomepageBooks[_random.nextInt(allHomepageBooks.length)];
      print('🔔 Selected random book from homepage: ${randomBook.title}');
      
      return randomBook;
    } catch (e) {
      print('❌ Error getting random book from homepage collections: $e');
      return null;
    }
  }

  String _createBookNotificationTitle(Book book) {
    final isSomali = LocalizationService.currentLanguage == 'so';
    return isSomali ? '📚 Buug Xiiso Leh!' : '📚 Featured Book Alert!';
  }

  String _createBookNotificationBody(Book book) {
    final isSomali = LocalizationService.currentLanguage == 'so';
    final bookTitle = isSomali ? book.titleSomali ?? book.title : book.title;
    final description = isSomali ? book.descriptionSomali ?? book.description : book.description;
    final author = isSomali 
        ? (book.authorsSomali?.isNotEmpty == true ? book.authorsSomali![0] : 'Qoraaga')
        : (book.authors?.isNotEmpty == true ? book.authors![0] : 'Author');
    
    return '$bookTitle\n\n$author\n\n${description ?? (isSomali ? 'Buug xiiso leh oo ka mid ah kuwa bogga hore!' : 'Discover this amazing book from our homepage collections!')}';
  }

  Future<void> dispose() async {
    _stopRandomBookNotifications();
    print('🔔 Simple Notification Service disposed');
  }
}
