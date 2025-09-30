// Common interface for notification services
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:teekoob/core/models/book_model.dart';

abstract class NotificationServiceInterface {
  Future<void> initialize();
  Future<bool> areNotificationsEnabled();
  Future<List<PendingNotificationRequest>> getPendingNotifications();
  Future<bool> requestPermissions();
  Future<void> scheduleBookReminder({required Book book, required DateTime scheduledTime, String? customMessage});
  Future<void> scheduleDailyReadingReminder({required Book book, required TimeOfDay time});
  Future<void> scheduleNewBookNotification({required Book book, required DateTime releaseTime});
  Future<void> showInstantBookReminder({required Book book, String? customMessage});
  Future<void> scheduleReadingProgressReminder({required Book book, required Duration interval});
  Future<void> cancelNotification(int notificationId);
  Future<void> cancelAllNotifications();
  Future<void> enableRandomBookNotifications();
  Future<void> disableRandomBookNotifications();
  Future<void> sendTestNotification();
  String? getFCMToken();
}
