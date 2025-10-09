// Stub implementation for web platform
import 'package:flutter/material.dart';
import 'package:teekoob/core/services/notification_service_interface.dart';
import 'package:teekoob/core/models/book_model.dart';

class FirebaseNotificationService implements NotificationServiceInterface {
  @override
  Future<void> initialize() async {
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Future<String?> getToken() async {
    print('🔔 Firebase Messaging disabled on web platform');
    return null;
  }

  @override
  Future<void> requestPermission() async {
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMessage => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => const Stream.empty();

  @override
  Future<void> subscribeToTopic(String topic) async {
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Future<void> deleteToken() async {
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Future<void> dispose() async {
    print('🔔 Firebase Messaging disabled on web platform');
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
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Future<void> disableRandomBookNotifications() async {
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Future<void> enableRandomBookNotifications() async {
    print('🔔 Firebase Messaging disabled on web platform');
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
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Future<void> scheduleDailyReadingReminder({required Book book, required TimeOfDay time}) async {
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Future<void> scheduleNewBookNotification({required Book book, required DateTime releaseTime}) async {
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Future<void> scheduleReadingProgressReminder({required Book book, required Duration interval}) async {
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Future<void> sendTestNotification() async {
    print('🔔 Firebase Messaging disabled on web platform');
  }

  @override
  Future<void> showInstantBookReminder({required Book book, String? customMessage}) async {
    print('🔔 Firebase Messaging disabled on web platform');
  }
}
