import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:teekoob/core/models/book_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('🔔 NotificationService: Initialized successfully');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // Handle navigation to book details or reading page
    // This can be extended to navigate to specific book pages
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return false;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      // For iOS, we'll assume permissions are granted if we can initialize
      // The actual permission check happens during requestPermissions()
      return true;
    }
    return false;
  }

  /// Schedule a book reminder notification
  Future<void> scheduleBookReminder({
    required Book book,
    required DateTime scheduledTime,
    String? customMessage,
  }) async {
    try {
      await initialize();
      
      final bool hasPermission = await requestPermissions();
      if (!hasPermission) {
        debugPrint('🔔 NotificationService: Permission not granted');
        return;
      }

      final int notificationId = book.id.hashCode;
      final String title = '📚 Book Reminder';
      final String body = customMessage ?? 
          'Time to read "${book.displayTitle}" by ${book.displayAuthors}';
      
      final String category = book.displayCategories.isNotEmpty 
          ? book.displayCategories 
          : 'General';

      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'book_reminders',
        'Book Reading Reminders',
        channelDescription: 'Notifications for book reading reminders',
        importance: Importance.max, // Changed to max for better visibility
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.recommendation,
        showWhen: true, // Show timestamp
        when: null, // Will be set automatically
        enableVibration: true, // Enable vibration
        playSound: true, // Play notification sound
        autoCancel: false, // Don't auto-dismiss when tapped
        ongoing: false, // Not ongoing notification
        visibility: NotificationVisibility.public, // Show on lock screen
        fullScreenIntent: false, // Don't show as full screen
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        payload: 'book_${book.id}',
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('🔔 NotificationService: Scheduled reminder for "${book.displayTitle}" at $scheduledTime');
    } catch (e) {
      debugPrint('🔔 NotificationService: Error scheduling notification: $e');
    }
  }

  /// Schedule multiple book reminders (e.g., daily reading reminders)
  Future<void> scheduleDailyReadingReminder({
    required Book book,
    required TimeOfDay time,
  }) async {
    try {
      await initialize();
      
      final bool hasPermission = await requestPermissions();
      if (!hasPermission) {
        debugPrint('🔔 NotificationService: Permission not granted');
        return;
      }

      final int notificationId = book.id.hashCode;
      final String title = '📖 Daily Reading Time';
      final String body = 'Continue reading "${book.displayTitle}" by ${book.displayAuthors}';

      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'daily_reading',
        'Daily Reading Reminders',
        channelDescription: 'Daily notifications for reading time',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.recommendation,
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule daily notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        _nextInstanceOfTime(time),
        notificationDetails,
        payload: 'daily_reading_${book.id}',
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('🔔 NotificationService: Scheduled daily reading reminder for "${book.displayTitle}" at ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('🔔 NotificationService: Error scheduling daily reminder: $e');
    }
  }

  /// Schedule a new book release notification
  Future<void> scheduleNewBookNotification({
    required Book book,
    required DateTime releaseTime,
  }) async {
    try {
      await initialize();
      
      final bool hasPermission = await requestPermissions();
      if (!hasPermission) {
        debugPrint('🔔 NotificationService: Permission not granted');
        return;
      }

      final int notificationId = 'new_book_${book.id}'.hashCode;
      final String title = '🆕 New Book Available!';
      final String body = 'Check out "${book.displayTitle}" by ${book.displayAuthors} - ${book.displayCategories}';

      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'new_releases',
        'New Book Releases',
        channelDescription: 'Notifications for new book releases',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.recommendation,
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(releaseTime, tz.local),
        notificationDetails,
        payload: 'new_book_${book.id}',
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('🔔 NotificationService: Scheduled new book notification for "${book.displayTitle}"');
    } catch (e) {
      debugPrint('🔔 NotificationService: Error scheduling new book notification: $e');
    }
  }

  /// Show immediate notification (for testing or instant reminders)
  Future<void> showInstantBookReminder({
    required Book book,
    String? customMessage,
  }) async {
    try {
      await initialize();
      
      final bool hasPermission = await requestPermissions();
      if (!hasPermission) {
        debugPrint('🔔 NotificationService: Permission not granted');
        return;
      }

      final int notificationId = book.id.hashCode;
      final String title = '📚 Book Reminder';
      final String body = customMessage ?? 
          'Don\'t forget to read "${book.displayTitle}" by ${book.displayAuthors}';

      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'instant_reminders',
        'Instant Book Reminders',
        channelDescription: 'Instant notifications for book reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.recommendation,
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: 'instant_book_${book.id}',
      );

      debugPrint('🔔 NotificationService: Showed instant reminder for "${book.displayTitle}"');
    } catch (e) {
      debugPrint('🔔 NotificationService: Error showing instant reminder: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      debugPrint('🔔 NotificationService: Cancelled notification $notificationId');
    } catch (e) {
      debugPrint('🔔 NotificationService: Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('🔔 NotificationService: Cancelled all notifications');
    } catch (e) {
      debugPrint('🔔 NotificationService: Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('🔔 NotificationService: Error getting pending notifications: $e');
      return [];
    }
  }


  /// Schedule hourly random book notifications
  Future<void> scheduleHourlyRandomBookNotifications() async {
    try {
      await initialize();
      
      final bool hasPermission = await requestPermissions();
      if (!hasPermission) {
        debugPrint('🔔 NotificationService: Permission not granted for hourly notifications');
        return;
      }

      // Cancel any existing hourly notifications
      await cancelNotification(888888);

      // Schedule hourly notifications starting from the next hour
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime nextHour = tz.TZDateTime(tz.local, now.year, now.month, now.day, now.hour + 1, 0);

      const int notificationId = 888888; // Special ID for hourly notifications
      const String title = '📚 Discover a New Book!';
      const String body = 'Check out this amazing book recommendation from Teekoob!';

      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'hourly_recommendations',
        'Hourly Book Recommendations',
        channelDescription: 'Hourly notifications with random book recommendations',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.recommendation,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        autoCancel: false,
        visibility: NotificationVisibility.public,
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the hourly notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        nextHour,
        notificationDetails,
        payload: 'hourly_recommendation',
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('🔔 NotificationService: Scheduled hourly random book notifications starting at $nextHour');
    } catch (e) {
      debugPrint('🔔 NotificationService: Error scheduling hourly notifications: $e');
    }
  }

  /// Helper method to get next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Schedule reading progress reminder
  Future<void> scheduleReadingProgressReminder({
    required Book book,
    required Duration interval,
  }) async {
    try {
      await initialize();
      
      final bool hasPermission = await requestPermissions();
      if (!hasPermission) {
        debugPrint('🔔 NotificationService: Permission not granted');
        return;
      }

      final int notificationId = 'progress_${book.id}'.hashCode;
      final String title = '📖 Reading Progress';
      final String body = 'How\'s your progress with "${book.displayTitle}"?';

      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'reading_progress',
        'Reading Progress Reminders',
        channelDescription: 'Reminders to check reading progress',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.recommendation,
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule recurring notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(interval),
        notificationDetails,
        payload: 'progress_${book.id}',
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('🔔 NotificationService: Scheduled reading progress reminder for "${book.displayTitle}"');
    } catch (e) {
      debugPrint('🔔 NotificationService: Error scheduling reading progress reminder: $e');
    }
  }
}

