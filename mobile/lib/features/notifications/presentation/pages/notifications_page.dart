import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/models/notification_model.dart';
import 'package:teekoob/features/notifications/services/notifications_service.dart';
import 'package:teekoob/core/services/localization_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsService _notificationsService = NotificationsService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;
  int _unreadCount = 0;
  int _currentPage = 1;
  final int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _notifications.clear();
      });
    }

    setState(() {
      _isLoading = refresh && _notifications.isEmpty;
    });

    try {
      final result = await _notificationsService.getNotifications(
        page: _currentPage,
        limit: _limit,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _notifications = result['notifications'] as List<NotificationModel>;
          } else {
            _notifications.addAll(result['notifications'] as List<NotificationModel>);
          }
          _unreadCount = result['unreadCount'] as int;
          _hasMore = (_currentPage * _limit) < (result['pagination']['total'] as int);
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load notifications: $e';
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _currentPage++;
    });

    await _loadNotifications();
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await _notificationsService.markAsRead(notification.id);
      setState(() {
        notification = NotificationModel(
          id: notification.id,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          isRead: true,
          actionUrl: notification.actionUrl,
          createdAt: notification.createdAt,
          readAt: DateTime.now(),
        );
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification;
        }
        if (_unreadCount > 0) {
          _unreadCount--;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as read: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationsService.markAllAsRead();
      setState(() {
        _notifications = _notifications.map((n) {
          if (!n.isRead) {
            return NotificationModel(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              isRead: true,
              actionUrl: n.actionUrl,
              createdAt: n.createdAt,
              readAt: DateTime.now(),
            );
          }
          return n;
        }).toList();
        _unreadCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark all as read: $e')),
      );
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await _notificationsService.deleteNotification(notification.id);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
        if (!notification.isRead && _unreadCount > 0) {
          _unreadCount--;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark All Read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(refresh: true),
        child: _isLoading && _notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadNotifications(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo is ScrollEndNotification &&
                              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                              _hasMore &&
                              !_isLoading) {
                            _loadMore();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount: _notifications.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _notifications.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final notification = _notifications[index];
                            return Dismissible(
                            key: Key(notification.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _deleteNotification(notification);
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                _markAsRead(notification);
                                if (notification.actionUrl != null) {
                                  // Handle action URL if needed
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: notification.isRead
                                      ? Theme.of(context).colorScheme.surface
                                      : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                  border: Border(
                                    left: BorderSide(
                                      color: notification.isRead
                                          ? Colors.transparent
                                          : Theme.of(context).colorScheme.primary,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      notification.type == 'admin_message'
                                          ? Icons.message
                                          : Icons.notifications,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notification.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: notification.isRead
                                                  ? FontWeight.normal
                                                  : FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notification.message,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _formatDate(notification.createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          },
                        ),
                      ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

