
import 'package:teekoob/core/models/user_model.dart';
import 'package:teekoob/core/services/network_service.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final NetworkService _networkService;

  AuthService() : _networkService = NetworkService() {
    _networkService.initialize();
  }

  // Google Sign-In
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
    // For Web, you MUST pass the Web client ID
    clientId: kIsWeb && AppConfig.googleWebClientId.isNotEmpty
        ? AppConfig.googleWebClientId
        : null,
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
      GoogleSignInAccount? googleUser;
      
      if (kIsWeb) {
        // For web, try silent sign-in first (recommended approach)
        googleUser = await _googleSignIn.signInSilently();
        
        // If silent sign-in fails, use interactive sign-in
        if (googleUser == null) {
          googleUser = await _googleSignIn.signIn();
        }
      } else {
        // For mobile, use regular sign-in
        googleUser = await _googleSignIn.signIn();
      }
      
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to obtain Google ID token');
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

        return User.fromJson(userData);
      } else {
        throw Exception('Google login failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Google login failed: $e');
    }
  }

  // Register user
  Future<User> register({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
    String? firstName,
    String? lastName,
    String preferredLanguage = 'en',
  }) async {
    try {
      if (password != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      final response = await _networkService.post('/auth/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'preferredLanguage': preferredLanguage == 'en' ? 'english' : 'somali',
      });

      if (response.statusCode == 201) {
        final userData = response.data['user'] as Map<String, dynamic>;
        final token = response.data['token'] as String;

        final user = User.fromJson(userData);
        await _secureStorage.write(key: _tokenKey, value: token);
        await _secureStorage.write(key: _userEmailKey, value: user.email);
        _networkService.setAuthToken(token);
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
      print('Server logout failed: $e');
    } finally {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userEmailKey);
      _networkService.clearAuthToken();
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null) return false;
    _networkService.setAuthToken(token);
    return true;
  }

  // Get current user
  User? getCurrentUser() {
    return null;
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

  // Reset password
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      if (newPassword != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      final response = await _networkService.post('/auth/reset-password', data: {
        'token': token,
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
      // Note: No local storage - cannot get current user
      throw Exception('No user logged in - no local storage');

      final response = await _networkService.put('/auth/profile', data: {
        'firstName': firstName,
        'lastName': lastName,
        'profilePicture': profilePicture,
        'preferredLanguage': preferredLanguage,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'country': country,
        'city': city,
        'bio': bio,
      });

      if (response.statusCode == 200) {
        // Note: No local storage - cannot get current user
        throw Exception('No user logged in - no local storage');
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
