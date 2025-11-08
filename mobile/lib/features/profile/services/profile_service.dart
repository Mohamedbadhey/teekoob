import 'dart:io';
import 'package:teekoob/core/services/network_service.dart';
import 'package:teekoob/core/config/app_config.dart';
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
        final rawAvatarUrl = response.data['avatarUrl'] as String? 
            ?? (response.data['user'] != null 
                ? (response.data['user'] as Map<String, dynamic>)['avatarUrl'] as String?
                : null);
        
        if (rawAvatarUrl == null) {
          throw Exception('Avatar URL not found in response');
        }
        
        // Convert relative URL to absolute URL if needed
        final avatarUrl = _buildFullImageUrl(rawAvatarUrl);
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

  // Helper method to build full image URL from relative or absolute URL
  static String _buildFullImageUrl(String url) {
    if (url.isEmpty) return url;
    
    // If URL already starts with http/https, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // If URL starts with /, it's a relative path - prepend media base URL
    if (url.startsWith('/')) {
      // Remove trailing slash from mediaBaseUrl if present, then add the path
      final baseUrl = AppConfig.mediaBaseUrl.endsWith('/') 
          ? AppConfig.mediaBaseUrl.substring(0, AppConfig.mediaBaseUrl.length - 1)
          : AppConfig.mediaBaseUrl;
      return '$baseUrl$url';
    }
    
    // Otherwise, assume it's a relative path and prepend media base URL
    final baseUrl = AppConfig.mediaBaseUrl.endsWith('/') 
        ? AppConfig.mediaBaseUrl 
        : '${AppConfig.mediaBaseUrl}/';
    return '$baseUrl$url';
  }
}

