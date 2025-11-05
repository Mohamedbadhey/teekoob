class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? actionUrl;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.actionUrl,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'admin_message',
      isRead: (() {
        final value = json['is_read'] ?? json['isRead'];
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) return value == '1' || value.toLowerCase() == 'true';
        return false;
      })(),
      actionUrl: json['action_url'] as String? ?? json['actionUrl'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : json['readAt'] != null
              ? DateTime.parse(json['readAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'action_url': actionUrl,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }
}

