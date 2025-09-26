import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String username;
  final String? firstName;
  
  final String? lastName;
  final String? profilePicture;
  final String preferredLanguage;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? country;
  final String? city;
  final String subscriptionPlan;
  final DateTime? subscriptionExpiry;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> preferences;
  final List<String> favoriteGenres;
  final int totalBooksRead;
  
  final int totalReadingTime;
  final double averageRating;
  final List<String> readingGoals;
  final bool isActive;
  final String? bio;

  const User({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePicture,
    required this.preferredLanguage,
    this.phoneNumber,
    this.dateOfBirth,
    this.country,
    this.city,
    required this.subscriptionPlan,
    this.subscriptionExpiry,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    required this.preferences,
    required this.favoriteGenres,
    required this.totalBooksRead,
    required this.totalReadingTime,
    required this.averageRating,
    required this.readingGoals,
    required this.isActive,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final String id = (json['id'] ?? json['userId']) as String;
    final String email = json['email'] as String;

    final String username = (json['username']
          ?? json['displayName']
          ?? (email.contains('@') ? email.split('@')[0] : email)) as String;

    final String? profilePicture = (json['profilePicture'] ?? json['avatarUrl']) as String?;

    final String preferredLanguage = (json['preferredLanguage'] ?? json['languagePreference'] ?? 'en') as String;

    final String subscriptionPlan = (json['subscriptionPlan'] ?? 'free') as String;

    final bool isEmailVerified = (json['isEmailVerified'] ?? json['isVerified'] ?? false) as bool;

    final DateTime createdAt = (() {
      final v = json['createdAt'];
      if (v is String) return DateTime.parse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.now();
    })();

    final DateTime updatedAt = (() {
      final v = json['updatedAt'];
      if (v is String) return DateTime.parse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return createdAt;
    })();

    final DateTime? lastLoginAt = (() {
      final v = json['lastLoginAt'];
      if (v is String) return DateTime.parse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return null;
    })();

    return User(
      id: id,
      email: email,
      username: username,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profilePicture: profilePicture,
      preferredLanguage: preferredLanguage,
      phoneNumber: json['phoneNumber'] as String?,
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth'] as String) : null,
      country: json['country'] as String?,
      city: json['city'] as String?,
      subscriptionPlan: subscriptionPlan,
      subscriptionExpiry: json['subscriptionExpiry'] != null ? DateTime.parse(json['subscriptionExpiry'] as String) : null,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
      preferences: Map<String, dynamic>.from(json['preferences'] as Map? ?? {}),
      favoriteGenres: List<String>.from(json['favoriteGenres'] as List? ?? []),
      totalBooksRead: json['totalBooksRead'] as int? ?? 0,
      totalReadingTime: json['totalReadingTime'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      readingGoals: List<String>.from(json['readingGoals'] as List? ?? []),
      isActive: json['isActive'] as bool? ?? true,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'profilePicture': profilePicture,
      'preferredLanguage': preferredLanguage,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'country': country,
      'city': city,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'preferences': preferences,
      'favoriteGenres': favoriteGenres,
      'totalBooksRead': totalBooksRead,
      'totalReadingTime': totalReadingTime,
      'averageRating': averageRating,
      'readingGoals': readingGoals,
      'isActive': isActive,
      'bio': bio,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? profilePicture,
    String? preferredLanguage,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? country,
    String? city,
    String? subscriptionPlan,
    DateTime? subscriptionExpiry,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    List<String>? favoriteGenres,
    int? totalBooksRead,
    int? totalReadingTime,
    double? averageRating,
    List<String>? readingGoals,
    bool? isActive,
    String? bio,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePicture: profilePicture ?? this.profilePicture,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      country: country ?? this.country,
      city: city ?? this.city,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      totalBooksRead: totalBooksRead ?? this.totalBooksRead,
      totalReadingTime: totalReadingTime ?? this.totalReadingTime,
      averageRating: averageRating ?? this.averageRating,
      readingGoals: readingGoals ?? this.readingGoals,
      isActive: isActive ?? this.isActive,
      bio: bio ?? this.bio,
    );
  }

  // Computed properties
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return username;
  }

  String get displayName => fullName.isNotEmpty ? fullName : username;
  
  bool get hasSubscription => subscriptionPlan != 'free' && 
      (subscriptionExpiry == null || subscriptionExpiry!.isAfter(DateTime.now()));
  
  bool get isPremium => hasSubscription && subscriptionPlan == 'premium';
  
  String get subscriptionStatus {
    if (!hasSubscription) return 'expired';
    if (subscriptionExpiry != null) {
      final daysLeft = subscriptionExpiry!.difference(DateTime.now()).inDays;
      if (daysLeft <= 7) return 'expiring_soon';
      if (daysLeft <= 30) return 'active';
      return 'active';
    }
    return 'active';
  }

  @override
  List<Object?> get props => [
    id, email, username, firstName, lastName, profilePicture, preferredLanguage,
    phoneNumber, dateOfBirth, country, city, subscriptionPlan, subscriptionExpiry,
    isEmailVerified, isPhoneVerified, createdAt, updatedAt, lastLoginAt,
    preferences, favoriteGenres, totalBooksRead, totalReadingTime, averageRating,
    readingGoals, isActive, bio
  ];
}
