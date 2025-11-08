
import 'package:teekoob/core/models/user_model.dart';
import 'package:teekoob/core/services/network_service.dart';
import 'package:teekoob/core/services/firebase_notification_service.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class AuthService {
  final NetworkService _networkService;
  FirebaseNotificationService? _notificationService;

  AuthService() : _networkService = NetworkService() {
    _networkService.initialize();
  }

  /// Get notification service instance (lazy initialization)
  FirebaseNotificationService get _notificationServiceInstance {
    _notificationService ??= FirebaseNotificationService();
    return _notificationService!;
  }

  /// Register user for notifications after successful login
  Future<void> _registerUserForNotifications() async {
    try {
      // Register FCM token with backend
      await _notificationServiceInstance.registerTokenOnLogin();
      // Enable random book notifications by default
      await _notificationServiceInstance.enableRandomBookNotifications();
    } catch (e) {
      // Don't throw error - login should succeed even if notifications fail
      print('⚠️ Failed to register for notifications: $e');
    }
  }

  // Google Sign-In
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
    // Use web client ID for all platforms to avoid configuration issues
    clientId: AppConfig.googleWebClientId,
    // Enable account picker for better UX
    forceCodeForRefreshToken: true,
  );

  // Secure storage for JWT persistence
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'auth_user_email';

  // Login user
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _networkService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final userData = response.data['user'] as Map<String, dynamic>;
        final token = response.data['token'] as String;

        final user = User.fromJson(userData);

        await _secureStorage.write(key: _tokenKey, value: token);
        await _secureStorage.write(key: _userEmailKey, value: user.email);
        _networkService.setAuthToken(token);

        // Register user for notifications
        await _registerUserForNotifications();

        return user;
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Login with Google
  Future<User> loginWithGoogle() async {
    try {
      
      // Debug information
      if (kIsWeb) {
      }
      
      GoogleSignInAccount? googleUser;
      
      if (kIsWeb) {
        // For web, ensure fresh authentication by signing out first
        await _googleSignIn.signOut();
        
        // For web, skip silent sign-in and go directly to interactive
        
        try {
          googleUser = await _googleSignIn.signIn().timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception('Google sign-in timed out. Please check if popup is blocked or try again.');
            },
          );
          
          
        } catch (e) {
          if (e is Exception) {
          }
          
          // Always rethrow errors to ensure user confirmation is required
          rethrow;
        }
      } else {
        // For mobile platforms (Android/iOS)
        await _googleSignIn.signOut();
        
        try {
          googleUser = await _googleSignIn.signIn().timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception('Google sign-in timed out. Please try again.');
            },
          );
          
          
        } catch (e) {
          rethrow;
        }
      }
      
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      
      if (accessToken != null) {
      }

      // For web, if ID token is missing, use access token to get user info
      if (idToken == null && accessToken != null && kIsWeb) {
        
        // Get user info using access token
        final userInfoResponse = await _networkService.get(
          'https://www.googleapis.com/oauth2/v2/userinfo',
          options: Options(
            headers: {'Authorization': 'Bearer $accessToken'},
          ),
        );
        
        
        if (userInfoResponse.statusCode == 200) {
          final userInfo = userInfoResponse.data;
          
          // Send user info to backend for authentication
          final response = await _networkService.post('/auth/google-web', data: {
            'accessToken': accessToken,
            'userInfo': userInfo,
          });
          
          
          if (response.statusCode == 200) {
            final userData = response.data['user'] as Map<String, dynamic>;
            final token = response.data['token'] as String;
            
            
            _networkService.setAuthToken(token);
            await _secureStorage.write(key: _tokenKey, value: token);
            await _secureStorage.write(key: _userEmailKey, value: userData['email'] as String?);
            
            // Register user for notifications
            await _registerUserForNotifications();
            
            return User.fromJson(userData);
          } else {
            throw Exception('Google login failed: ${response.statusMessage}');
          }
        } else {
          throw Exception('Failed to get user info from Google');
        }
      }

      if (idToken == null) {
        throw Exception('Failed to obtain Google ID token. This may be due to origin configuration issues.');
      }

      
      // Send the ID token to backend to verify and exchange for app JWT
      final response = await _networkService.post('/auth/google', data: {
        'idToken': idToken,
      });
      

      if (response.statusCode == 200) {
        final userData = response.data['user'] as Map<String, dynamic>;
        final token = response.data['token'] as String;
        
        
        _networkService.setAuthToken(token);
        await _secureStorage.write(key: _tokenKey, value: token);
        await _secureStorage.write(key: _userEmailKey, value: userData['email'] as String?);
        
        // Register user for notifications
        await _registerUserForNotifications();
        
        return User.fromJson(userData);
      } else {
        throw Exception('Google login failed: ${response.statusMessage}');
      }
    } catch (e) {
      
      if (e.toString().contains('unregistered_origin') ||
          e.toString().contains('origin is not allowed')) {
        throw Exception('Google OAuth configuration error: Please add your domain to Google Cloud Console authorized origins');
      }
      
      if (e.toString().contains('popup') || e.toString().contains('blocked')) {
        throw Exception('Popup blocked: Please allow popups for localhost:3000 in your browser');
      }
      
      if (e.toString().contains('timeout')) {
        throw Exception('Google sign-in timed out: Please check your internet connection and try again');
      }
      
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Google API permission error: Please ensure People API is enabled in Google Cloud Console');
      }
      
      throw Exception('Google login failed: $e');
    }
  }

  // Register user
  Future<User> register({
    required String email,
    required String displayName,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
    String preferredLanguage = 'en',
    String themePreference = 'light',
  }) async {
    try {
      if (password != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      // Parse display name into firstName and lastName
      String firstName = displayName.trim();
      String lastName = '';
      
      if (displayName.contains(' ')) {
        final nameParts = displayName.trim().split(' ');
        firstName = nameParts.first;
        lastName = nameParts.skip(1).join(' ');
      }
      
      // Ensure lastName is not empty (backend requires both first and last name)
      if (lastName.isEmpty) {
        lastName = firstName; // Use firstName as lastName if only one name provided
      }

      final response = await _networkService.post('/auth/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'preferredLanguage': preferredLanguage,
        'themePreference': themePreference,
      });

      if (response.statusCode == 201) {
        final userData = response.data['user'] as Map<String, dynamic>;
        final token = response.data['token'] as String;

        final user = User.fromJson(userData);
        await _secureStorage.write(key: _tokenKey, value: token);
        await _secureStorage.write(key: _userEmailKey, value: user.email);
        _networkService.setAuthToken(token);
        
        // Register user for notifications
        await _registerUserForNotifications();
        
        return user;
      } else {
        throw Exception('Registration failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      // TODO: Backend doesn't have logout endpoint yet
      // await _networkService.post('/auth/logout');
    } catch (e) {
      // Continue with local logout even if server call fails
    } finally {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userEmailKey);
      _networkService.clearAuthToken();
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null) return false;
      _networkService.setAuthToken(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null) return null;
      
      // Check connectivity first
      if (!await _networkService.isConnected()) {
        return null;
      }
      
      // Set the token for API calls
      _networkService.setAuthToken(token);
      
      // Fetch user data from backend with timeout
      final response = await _networkService.get('/auth/me').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );
      
      if (response.statusCode == 200) {
        final userData = response.data['user'] as Map<String, dynamic>;
        return User.fromJson(userData);
      }
      return null;
    } on DioException catch (e) {
      // Handle 401 - token expired or invalid
      if (e.response?.statusCode == 401) {
        // Clear token and logout
        await _secureStorage.delete(key: _tokenKey);
        await _secureStorage.delete(key: _userEmailKey);
        _networkService.clearAuthToken();
        // Return null to indicate user needs to login
        return null;
      }
      return null;
    } catch (e) {
      // Return null instead of throwing to allow app to continue
      return null;
    }
  }

  // Refresh token
  Future<String> refreshToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null) throw Exception('No auth token available');
    return token;
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _networkService.post('/auth/forgot-password', data: {
        'email': email,
      });

      if (response.statusCode != 200) {
        throw Exception('Password reset request failed');
      }
    } catch (e) {
      throw Exception('Password reset request failed: $e');
    }
  }

  // Verify reset code
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _networkService.post('/auth/verify-reset-code', data: {
        'email': email,
        'code': code,
      });

      if (response.statusCode != 200) {
        throw Exception('Invalid or expired verification code');
      }
    } catch (e) {
      throw Exception('Code verification failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      if (newPassword != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      final response = await _networkService.post('/auth/reset-password', data: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      });

      if (response.statusCode != 200) {
        throw Exception('Password reset failed');
      }
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      if (newPassword != confirmPassword) {
        throw Exception('New passwords do not match');
      }

      final response = await _networkService.put('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.statusCode != 200) {
        throw Exception('Password change failed');
      }
    } catch (e) {
      throw Exception('Password change failed: $e');
    }
  }

  // Update profile
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? profilePicture,
    String? preferredLanguage,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? country,
    String? city,
    String? bio,
  }) async {
    try {
      final response = await _networkService.put('/users/profile', data: {
        'firstName': firstName,
        'lastName': lastName,
        'preferredLanguage': preferredLanguage,
      });

      if (response.statusCode == 200) {
        // Try to get user from response first
        if (response.data['user'] != null) {
        final userData = response.data['user'] as Map<String, dynamic>;
        return User.fromJson(userData);
        }
        // Otherwise fetch updated user data
        final userResponse = await _networkService.get('/users/profile');
        if (userResponse.statusCode == 200) {
          final userData = userResponse.data['user'] as Map<String, dynamic>;
          return User.fromJson(userData);
        } else {
          // If fetch fails, get current user from /auth/me
          final user = await getCurrentUser();
          if (user == null) {
            throw Exception('Failed to get updated user');
          }
          return user;
        }
      } else {
        throw Exception('Profile update failed');
      }
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  // Verify email
  Future<void> verifyEmail(String token) async {
    try {
      final response = await _networkService.post('/auth/verify-email', data: {
        'token': token,
      });

      if (response.statusCode == 200) {
        // Update user verification status
        // Note: No local storage - user verification status not updated locally
      } else {
        throw Exception('Email verification failed');
      }
    } catch (e) {
      throw Exception('Email verification failed: $e');
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      final response = await _networkService.post('/auth/resend-verification');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to resend verification email');
      }
    } catch (e) {
      throw Exception('Failed to resend verification email: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount(String password) async {
    try {
      final response = await _networkService.delete('/auth/account', data: {
        'password': password,
      });

      if (response.statusCode == 200) {
        await logout();
      } else {
        throw Exception('Account deletion failed');
      }
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }
  }

  // Get auth token
  String? getAuthToken() {
    return null;
  }

  // Check if token is expired
  bool isTokenExpired(String token) {
    try {
      // Simple check - in production, you'd decode JWT and check expiration
      return false; // Placeholder
    } catch (e) {
      return true;
    }
  }
}
