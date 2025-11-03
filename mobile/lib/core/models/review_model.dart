import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String userId;
  final String itemId;
  final String itemType; // 'book' or 'podcast'
  final double rating;
  final String? comment;
  final bool isApproved;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // User info for display
  final String? userName;
  final String? userFirstName;
  final String? userLastName;
  final String? userProfilePicture;
  final String? userAvatarUrl;

  Review({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.itemType,
    required this.rating,
    this.comment,
    required this.isApproved,
    required this.isEdited,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userFirstName,
    this.userLastName,
    this.userProfilePicture,
    this.userAvatarUrl,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      itemId: json['item_id'] as String? ?? json['itemId'] as String? ?? '',
      itemType: json['item_type'] as String? ?? json['itemType'] as String? ?? 'book',
      rating: (() {
        final value = json['rating'];
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      })(),
      comment: json['comment'] as String?,
      isApproved: (() {
        final value = json['is_approved'] ?? json['isApproved'];
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) return value == '1' || value.toLowerCase() == 'true';
        return true;
      })(),
      isEdited: (() {
        final value = json['is_edited'] ?? json['isEdited'];
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) return value == '1' || value.toLowerCase() == 'true';
        return false;
      })(),
      createdAt: json['created_at'] != null
          ? (json['created_at'] is DateTime
              ? json['created_at']
              : DateTime.parse(json['created_at'].toString()))
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] is DateTime
              ? json['updated_at']
              : DateTime.parse(json['updated_at'].toString()))
          : DateTime.now(),
      userName: json['user_name'] as String? ?? json['userName'] as String?,
      userFirstName: json['user_first_name'] as String? ?? json['userFirstName'] as String?,
      userLastName: json['user_last_name'] as String? ?? json['userLastName'] as String?,
      userProfilePicture: json['user_profile_picture'] as String? ?? json['userProfilePicture'] as String? ?? json['user_avatar_url'] as String? ?? json['userAvatarUrl'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String? ?? json['userAvatarUrl'] as String? ?? json['user_profile_picture'] as String? ?? json['userProfilePicture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'item_id': itemId,
      'item_type': itemType,
      'rating': rating,
      'comment': comment,
      'is_approved': isApproved,
      'is_edited': isEdited,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Computed properties
  String get displayUserName {
    if (userFirstName != null && userLastName != null) {
      return '$userFirstName $userLastName';
    } else if (userFirstName != null) {
      return userFirstName!;
    } else if (userLastName != null) {
      return userLastName!;
    } else if (userName != null) {
      return userName!;
    }
    return 'Anonymous';
  }

  String? get displayAvatarUrl => userAvatarUrl ?? userProfilePicture;

  @override
  List<Object?> get props => [
    id, userId, itemId, itemType, rating, comment, isApproved, 
    isEdited, createdAt, updatedAt, userName, userFirstName, 
    userLastName, userProfilePicture, userAvatarUrl
  ];
}

