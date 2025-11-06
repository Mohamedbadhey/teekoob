// Stub implementation for web platform
import 'package:flutter/material.dart';
import 'package:teekoob/core/services/notification_service_interface.dart';
import 'package:teekoob/core/models/book_model.dart';

class FirebaseNotificationService implements NotificationServiceInterface {
  @override
  Future<void> initialize() async {
  }

  @override
  Future<String?> getToken() async {
    return null;
  }

  @override
  Future<void> requestPermission() async {
  }

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMessage => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => const Stream.empty();

  @override
  Future<void> subscribeToTopic(String topic) async {
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
  }

  @override
  Future<void> deleteToken() async {
  }

  @override
  Future<void> dispose() async {
  }

  @override
  Future<List<dynamic>> getPendingNotifications() async {
    return [];
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    return false;
  }

  @override
  Future<void> cancelAllNotifications() async {
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
  }

  @override
  Future<void> disableRandomBookNotifications() async {
  }

  @override
  Future<void> enableRandomBookNotifications() async {
  }

  @override
  String? getFCMToken() {
    return null;
  }

  @override
  Future<bool> requestPermissions() async {
    return false;
  }

  @override
  Future<void> scheduleBookReminder({required Book book, required DateTime scheduledTime, String? customMessage}) async {
  }

  @override
  Future<void> scheduleDailyReadingReminder({required Book book, required TimeOfDay time}) async {
  }

  @override
  Future<void> scheduleNewBookNotification({required Book book, required DateTime releaseTime}) async {
  }

  @override
  Future<void> scheduleReadingProgressReminder({required Book book, required Duration interval}) async {
  }

  @override
  Future<void> sendTestNotification() async {
  }

  @override
  Future<void> showInstantBookReminder({required Book book, String? customMessage}) async {
  }
}
