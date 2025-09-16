import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class User extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String email;
  
  @HiveField(2)
  final String username;
  
  @HiveField(3)
  final String? firstName;
  
  @HiveField(4)
  final String? lastName;
  
  @HiveField(5)
  final String? profilePicture;
  
  @HiveField(6)
  final String preferredLanguage;
  
  @HiveField(7)
  final String? phoneNumber;
  
  @HiveField(8)
  final DateTime? dateOfBirth;
  
  @HiveField(9)
  final String? country;
  
  @HiveField(10)
  final String? city;
  
  @HiveField(11)
  final String subscriptionPlan;
  
  @HiveField(12)
  final DateTime? subscriptionExpiry;
  
  @HiveField(13)
  final bool isEmailVerified;
  
  @HiveField(14)
  final bool isPhoneVerified;
  
  @HiveField(15)
  final DateTime createdAt;
  
  @HiveField(16)
  final DateTime updatedAt;
  
  @HiveField(17)
  final DateTime? lastLoginAt;
  
  @HiveField(18)
  final Map<String, dynamic> preferences;
  
  @HiveField(19)
  final List<String> favoriteGenres;
  
  @HiveField(20)
  final int totalBooksRead;
  
  @HiveField(21)
  final int totalReadingTime;
  
  @HiveField(22)
  final double averageRating;
  
  @HiveField(23)
  final List<String> readingGoals;
  
  @HiveField(24)
  final bool isActive;
  
  @HiveField(25)
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

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

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
