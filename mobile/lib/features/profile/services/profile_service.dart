import 'dart:io';
import 'package:teekoob/core/services/network_service.dart';
import 'package:dio/dio.dart';

class ProfileService {
  final NetworkService _networkService = NetworkService();

  ProfileService() {
    _networkService.initialize();
  }

  // Upload profile image
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Extract filename from path (works on both '/' and '\' separators)
      final filename = imageFile.path.split(RegExp(r'[/\\]')).last;
      
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: filename,
        ),
      });

      final response = await _networkService.put('/users/avatar', data: formData);

      if (response.statusCode == 200) {
        // Handle both avatarUrl and user.avatarUrl response formats
        final avatarUrl = response.data['avatarUrl'] as String? 
            ?? (response.data['user'] != null 
                ? (response.data['user'] as Map<String, dynamic>)['avatarUrl'] as String?
                : null);
        
        if (avatarUrl == null) {
          throw Exception('Avatar URL not found in response');
        }
        
        return avatarUrl;
      } else {
        throw Exception('Failed to upload avatar: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Avatar upload failed: $e');
    }
  }

  // Update profile
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? bio,
    String? profilePicture,
  }) async {
    try {
      // Split displayName into firstName and lastName if provided
      String? firstName;
      String? lastName;
      
      if (displayName != null && displayName.isNotEmpty) {
        final parts = displayName.trim().split(' ');
        firstName = parts[0];
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
      }

      // Update profile via auth service endpoint
      final response = await _networkService.put('/users/profile', data: {
        'firstName': firstName,
        'lastName': lastName,
      });

      if (response.statusCode != 200) {
        throw Exception('Profile update failed');
      }

      // If avatar was updated separately, it's already handled
      // The profile picture URL should already be set from the upload
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }
}

