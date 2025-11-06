import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:teekoob/core/services/notification_service_interface.dart';
import 'package:teekoob/core/models/book_model.dart';

// Firebase messaging is temporarily disabled for Android builds
// TODO: Re-enable when Firebase messaging API is updated

class FirebaseNotificationService implements NotificationServiceInterface {
  @override
  Future<void> initialize() async {
  }

  @override
  Future<String?> getToken() async {
    return null;
  }

  @override
  Stream<String> get onTokenRefresh {
    return const Stream.empty();
  }

  @override
  Stream<Map<String, dynamic>> get onMessage {
    return const Stream.empty();
  }

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp {
    return const Stream.empty();
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    // No-op
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    // No-op
  }

  @override
  Future<void> sendNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // No-op
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    return false;
  }

  @override
  Future<bool> requestPermissions() async {
    return false;
  }

  @override
  Future<List<dynamic>> getPendingNotifications() async {
    return [];
  }

  @override
  String? getFCMToken() {
    return null;
  }

  @override
  Future<void> enableRandomBookNotifications() async {
    // No-op
  }

  @override
  Future<void> disableRandomBookNotifications() async {
    // No-op
  }

  @override
  Future<void> sendTestNotification() async {
    // No-op
  }

  @override
  Future<void> scheduleBookReminder({
    required Book book,
    required DateTime scheduledTime,
    String? customMessage,
  }) async {
    // No-op
  }

  @override
  Future<void> showInstantBookReminder({
    required Book book,
    String? customMessage,
  }) async {
    // No-op
  }

  @override
  Future<void> scheduleNewBookNotification({
    required Book book,
    required DateTime releaseTime,
  }) async {
    // No-op
  }

  @override
  Future<void> scheduleDailyReadingReminder({
    required Book book,
    required TimeOfDay time,
  }) async {
    // No-op
  }

  @override
  Future<void> scheduleReadingProgressReminder({
    required Book book,
    required Duration interval,
  }) async {
    // No-op
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
    // No-op
  }

  @override
  Future<void> cancelAllNotifications() async {
    // No-op
  }
}