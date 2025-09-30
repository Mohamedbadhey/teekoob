import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/books/services/books_service.dart';
import 'package:teekoob/core/services/localization_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final BooksService _booksService = BooksService();
  final Random _random = Random();

  bool _isInitialized = false;
  Timer? _notificationTimer;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

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

    _isInitialized = true;
    print('🔔 NotificationService initialized');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

        return result ?? false;
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Start sending random book notifications every 10 minutes
  Future<void> startRandomBookNotifications() async {
    try {
      // Cancel any existing timer
      _notificationTimer?.cancel();

      // Schedule the first notification immediately (for testing)
      await _scheduleRandomBookNotification();

      // Schedule recurring notifications every 10 minutes
      _notificationTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
        _scheduleRandomBookNotification();
      });

      print('🔔 Random book notifications started - every 10 minutes');
    } catch (e) {
      print('❌ Error starting random book notifications: $e');
    }
  }

  /// Stop random book notifications
  Future<void> stopRandomBookNotifications() async {
    try {
      _notificationTimer?.cancel();
      print('🔔 Random book notifications stopped');
    } catch (e) {
      print('❌ Error stopping random book notifications: $e');
    }
  }

  /// Schedule a random book notification
  Future<void> _scheduleRandomBookNotification() async {
    try {
      // Get random book from database
      final randomBook = await _getRandomBook();
      if (randomBook == null) {
        print('❌ No books available for notification');
        return;
      }

      // Create notification content
      final notificationContent = _createBookNotificationContent(randomBook);

      // Schedule notification
      await _notifications.show(
        _random.nextInt(1000000), // Random notification ID
        notificationContent['title'],
        notificationContent['body'],
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'random_books',
            'Random Book Recommendations',
            channelDescription: 'Notifications about random book recommendations',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'book_${randomBook.id}',
      );

      print('🔔 Random book notification sent: ${randomBook.title}');
    } catch (e) {
      print('❌ Error scheduling random book notification: $e');
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

  /// Create notification content for a book
  Map<String, String> _createBookNotificationContent(Book book) {
    final isSomali = LocalizationService.currentLanguage == 'so';
    
    if (isSomali) {
      return {
        'title': '📚 Buug Xiiso Leh!',
        'body': '${book.titleSomali ?? book.title}\n\n${book.descriptionSomali ?? book.description ?? 'Buug xiiso leh oo ka mid ah kuwa bogga hore!'}',
      };
    } else {
      return {
        'title': '📚 Featured Book Alert!',
        'body': '${book.title}\n\n${book.description ?? 'Discover this amazing book from our homepage collections!'}',
      };
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null && payload.startsWith('book_')) {
        final bookId = payload.substring(5);
        print('🔔 Notification tapped for book: $bookId');
        
        // Navigate to book detail page
        // This would need to be implemented with proper navigation
        // For now, just log the action
      }
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  /// Send immediate test notification
  Future<void> sendTestNotification() async {
    try {
      final randomBook = await _getRandomBook();
      if (randomBook != null) {
        await _scheduleRandomBookNotification();
        print('🔔 Test notification sent');
      }
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  /// Get pending notifications (placeholder implementation)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      // This would typically return scheduled notifications
      // For now, return empty list since we're using WorkManager
      return [];
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  /// Schedule a book reminder (placeholder implementation)
  Future<void> scheduleBookReminder({
    required Book book,
    required DateTime scheduledTime,
    String? customMessage,
  }) async {
    try {
      // This would schedule a specific book reminder
      print('📅 Book reminder scheduled for: ${book.title} at $scheduledTime');
    } catch (e) {
      print('❌ Error scheduling book reminder: $e');
    }
  }

  /// Schedule daily reading reminder (placeholder implementation)
  Future<void> scheduleDailyReadingReminder({
    required Book book,
    required TimeOfDay time,
  }) async {
    try {
      // Convert TimeOfDay to DateTime for today
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      
      print('📅 Daily reading reminder scheduled for: ${book.title} at $scheduledTime');
    } catch (e) {
      print('❌ Error scheduling daily reading reminder: $e');
    }
  }

  /// Schedule new book notification (placeholder implementation)
  Future<void> scheduleNewBookNotification({
    required Book book,
    required DateTime releaseTime,
  }) async {
    try {
      print('📚 New book notification scheduled for: ${book.title}');
    } catch (e) {
      print('❌ Error scheduling new book notification: $e');
    }
  }

  /// Show instant book reminder (placeholder implementation)
  Future<void> showInstantBookReminder({
    required Book book,
    String? customMessage,
  }) async {
    try {
      print('🔔 Instant book reminder shown for: ${book.title}');
    } catch (e) {
      print('❌ Error showing instant book reminder: $e');
    }
  }

  /// Schedule reading progress reminder (placeholder implementation)
  Future<void> scheduleReadingProgressReminder({
    required Book book,
    required Duration interval,
  }) async {
    try {
      print('📊 Reading progress reminder scheduled for: ${book.title}');
    } catch (e) {
      print('❌ Error scheduling reading progress reminder: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      print('❌ Notification cancelled: $notificationId');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('❌ All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? false;
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }
}