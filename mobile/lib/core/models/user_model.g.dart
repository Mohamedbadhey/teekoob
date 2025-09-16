// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      email: fields[1] as String,
      username: fields[2] as String,
      firstName: fields[3] as String?,
      lastName: fields[4] as String?,
      profilePicture: fields[5] as String?,
      preferredLanguage: fields[6] as String,
      phoneNumber: fields[7] as String?,
      dateOfBirth: fields[8] as DateTime?,
      country: fields[9] as String?,
      city: fields[10] as String?,
      subscriptionPlan: fields[11] as String,
      subscriptionExpiry: fields[12] as DateTime?,
      isEmailVerified: fields[13] as bool,
      isPhoneVerified: fields[14] as bool,
      createdAt: fields[15] as DateTime,
      updatedAt: fields[16] as DateTime,
      lastLoginAt: fields[17] as DateTime?,
      preferences: (fields[18] as Map).cast<String, dynamic>(),
      favoriteGenres: (fields[19] as List).cast<String>(),
      totalBooksRead: fields[20] as int,
      totalReadingTime: fields[21] as int,
      averageRating: fields[22] as double,
      readingGoals: (fields[23] as List).cast<String>(),
      isActive: fields[24] as bool,
      bio: fields[25] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.firstName)
      ..writeByte(4)
      ..write(obj.lastName)
      ..writeByte(5)
      ..write(obj.profilePicture)
      ..writeByte(6)
      ..write(obj.preferredLanguage)
      ..writeByte(7)
      ..write(obj.phoneNumber)
      ..writeByte(8)
      ..write(obj.dateOfBirth)
      ..writeByte(9)
      ..write(obj.country)
      ..writeByte(10)
      ..write(obj.city)
      ..writeByte(11)
      ..write(obj.subscriptionPlan)
      ..writeByte(12)
      ..write(obj.subscriptionExpiry)
      ..writeByte(13)
      ..write(obj.isEmailVerified)
      ..writeByte(14)
      ..write(obj.isPhoneVerified)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.lastLoginAt)
      ..writeByte(18)
      ..write(obj.preferences)
      ..writeByte(19)
      ..write(obj.favoriteGenres)
      ..writeByte(20)
      ..write(obj.totalBooksRead)
      ..writeByte(21)
      ..write(obj.totalReadingTime)
      ..writeByte(22)
      ..write(obj.averageRating)
      ..writeByte(23)
      ..write(obj.readingGoals)
      ..writeByte(24)
      ..write(obj.isActive)
      ..writeByte(25)
      ..write(obj.bio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profilePicture: json['profilePicture'] as String?,
      preferredLanguage: json['preferredLanguage'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.parse(json['dateOfBirth'] as String),
      country: json['country'] as String?,
      city: json['city'] as String?,
      subscriptionPlan: json['subscriptionPlan'] as String,
      subscriptionExpiry: json['subscriptionExpiry'] == null
          ? null
          : DateTime.parse(json['subscriptionExpiry'] as String),
      isEmailVerified: json['isEmailVerified'] as bool,
      isPhoneVerified: json['isPhoneVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastLoginAt: json['lastLoginAt'] == null
          ? null
          : DateTime.parse(json['lastLoginAt'] as String),
      preferences: json['preferences'] as Map<String, dynamic>,
      favoriteGenres: (json['favoriteGenres'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      totalBooksRead: (json['totalBooksRead'] as num).toInt(),
      totalReadingTime: (json['totalReadingTime'] as num).toInt(),
      averageRating: (json['averageRating'] as num).toDouble(),
      readingGoals: (json['readingGoals'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isActive: json['isActive'] as bool,
      bio: json['bio'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'username': instance.username,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'profilePicture': instance.profilePicture,
      'preferredLanguage': instance.preferredLanguage,
      'phoneNumber': instance.phoneNumber,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
      'country': instance.country,
      'city': instance.city,
      'subscriptionPlan': instance.subscriptionPlan,
      'subscriptionExpiry': instance.subscriptionExpiry?.toIso8601String(),
      'isEmailVerified': instance.isEmailVerified,
      'isPhoneVerified': instance.isPhoneVerified,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
      'preferences': instance.preferences,
      'favoriteGenres': instance.favoriteGenres,
      'totalBooksRead': instance.totalBooksRead,
      'totalReadingTime': instance.totalReadingTime,
      'averageRating': instance.averageRating,
      'readingGoals': instance.readingGoals,
      'isActive': instance.isActive,
      'bio': instance.bio,
    };
