// Common interface for Firebase notification services
import 'package:flutter/material.dart';
import 'package:teekoob/core/models/book_model.dart';

abstract class NotificationServiceInterface {
  Future<void> initialize();
  Future<bool> areNotificationsEnabled();
  Future<bool> requestPermissions();
  Future<List<dynamic>> getPendingNotifications();
  
  // Firebase Cloud Messaging methods
  String? getFCMToken();
  Future<void> enableRandomBookNotifications();
  Future<void> disableRandomBookNotifications();
  Future<void> sendTestNotification();
  
  // Local notification methods (disabled - Firebase handles everything)
  Future<void> scheduleBookReminder({required Book book, required DateTime scheduledTime, String? customMessage});
  Future<void> scheduleDailyReadingReminder({required Book book, required TimeOfDay time});
  Future<void> scheduleNewBookNotification({required Book book, required DateTime releaseTime});
  Future<void> showInstantBookReminder({required Book book, String? customMessage});
  Future<void> scheduleReadingProgressReminder({required Book book, required Duration interval});
  Future<void> cancelNotification(int notificationId);
  Future<void> cancelAllNotifications();
}
