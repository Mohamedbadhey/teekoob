import 'package:flutter/material.dart';
import 'package:teekoob/core/services/notification_service_interface.dart';
import 'package:teekoob/core/models/book_model.dart';

/// Fallback notification service that provides basic functionality
/// when Firebase is not available or fails to initialize
class FallbackNotificationService implements NotificationServiceInterface {
  @override
  Future<void> initialize() async {
    print('🔔 Fallback notification service initialized (no Firebase)');
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    return false; // Always return false since we can't send notifications
  }

  @override
  Future<bool> requestPermissions() async {
    print('🔔 Fallback: Cannot request permissions without Firebase');
    return false;
  }

  @override
  Future<List<dynamic>> getPendingNotifications() async {
    return []; // No pending notifications without Firebase
  }

  @override
  String? getFCMToken() {
    return null; // No FCM token without Firebase
  }

  @override
  Future<void> enableRandomBookNotifications() async {
    print('🔔 Fallback: Random book notifications not available without Firebase');
  }

  @override
  Future<void> disableRandomBookNotifications() async {
    print('🔔 Fallback: Random book notifications not available without Firebase');
  }

  @override
  Future<void> sendTestNotification() async {
    print('🔔 Fallback: Test notifications not available without Firebase');
  }

  // Local notification methods (disabled)
  @override
  Future<void> scheduleBookReminder({
    required Book book,
    required DateTime scheduledTime,
    String? customMessage,
  }) async {
    print('🔔 Fallback: Local notifications disabled');
  }

  @override
  Future<void> scheduleDailyReadingReminder({
    required Book book,
    required TimeOfDay time,
  }) async {
    print('🔔 Fallback: Local notifications disabled');
  }

  @override
  Future<void> scheduleNewBookNotification({
    required Book book,
    required DateTime releaseTime,
  }) async {
    print('🔔 Fallback: Local notifications disabled');
  }

  @override
  Future<void> showInstantBookReminder({
    required Book book,
    String? customMessage,
  }) async {
    print('🔔 Fallback: Local notifications disabled');
  }

  @override
  Future<void> scheduleReadingProgressReminder({
    required Book book,
    required Duration interval,
  }) async {
    print('🔔 Fallback: Local notifications disabled');
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
    print('🔔 Fallback: Local notifications disabled');
  }

  @override
  Future<void> cancelAllNotifications() async {
    print('🔔 Fallback: Local notifications disabled');
  }
}
