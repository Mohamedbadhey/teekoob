import 'package:teekoob/core/models/notification_model.dart';
import 'package:teekoob/core/services/network_service.dart';

class NotificationsService {
  final NetworkService _networkService = NetworkService();

  NotificationsService() {
    // Initialize the NetworkService instance
    _networkService.initialize();
  }

  /// Get user's notifications
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _networkService.get(
        '/messages',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (unreadOnly) 'unreadOnly': 'true',
        },
      );

      if (response.statusCode == 200) {
        final notifications = (response.data['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        return {
          'notifications': notifications,
          'pagination': response.data['pagination'],
          'unreadCount': response.data['unreadCount'] ?? 0,
        };
      } else {
        throw Exception('Failed to fetch notifications');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _networkService.get('/messages/unread-count');

      if (response.statusCode == 200) {
        return response.data['unreadCount'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _networkService.put('/messages/$notificationId/read');
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _networkService.put('/messages/read-all');
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _networkService.delete('/messages/$notificationId');
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }
}

