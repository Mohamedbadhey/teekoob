
import 'package:teekoob/core/models/user_model.dart';
import 'package:teekoob/core/services/network_service.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

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
      print('🚀 ===== GOOGLE SIGN-IN STARTED =====');
      
      // Debug information
      if (kIsWeb) {
        print('🌐 Web platform detected');
        print('🔑 Using client ID: ${AppConfig.googleWebClientId}');
        print('🌍 Current origin: ${Uri.base.origin}');
        print('🔧 Google Sign-In configured scopes: email, profile');
      }
      
      GoogleSignInAccount? googleUser;
      
      if (kIsWeb) {
        // For web, ensure fresh authentication by signing out first
        print('🔄 Signing out any existing session to ensure fresh authentication...');
        await _googleSignIn.signOut();
        
        // For web, skip silent sign-in and go directly to interactive
        print('🔄 Attempting interactive sign-in (web)...');
        print('⏰ Starting Google Sign-In process...');
        
        try {
          googleUser = await _googleSignIn.signIn().timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              print('⏰ Google sign-in timed out after 60 seconds');
              print('⏰ This might be due to popup communication issues');
              throw Exception('Google sign-in timed out. Please check if popup is blocked or try again.');
            },
          );
          
          print('✅ Interactive sign-in completed');
          print('👤 Google user account: ${googleUser?.email ?? 'null'}');
          print('🆔 Google user ID: ${googleUser?.id ?? 'null'}');
          print('📝 Google user display name: ${googleUser?.displayName ?? 'null'}');
          
        } catch (e) {
          print('❌ Interactive sign-in failed');
          print('❌ Error type: ${e.runtimeType}');
          print('❌ Error details: ${e.toString()}');
          if (e is Exception) {
            print('❌ Exception message: ${e.toString()}');
          }
          
          // Always rethrow errors to ensure user confirmation is required
          print('🔄 Interactive sign-in failed - user must confirm manually');
          rethrow;
        }
      } else {
        // For mobile, ensure fresh authentication by signing out first
        print('📱 Mobile platform - signing out and using regular sign-in');
        await _googleSignIn.signOut();
        googleUser = await _googleSignIn.signIn();
        print('✅ Mobile sign-in result: ${googleUser?.email ?? 'null'}');
      }
      
      if (googleUser == null) {
        print('❌ Google user is null - sign-in was cancelled');
        throw Exception('Google sign-in was cancelled by user');
      }

      print('🔐 Getting Google authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      print('🔑 ID Token: ${idToken != null ? "Present (${idToken.length} chars)" : "Missing"}');
      print('🔑 Access Token: ${accessToken != null ? "Present (${accessToken.length} chars)" : "Missing"}');
      
      if (accessToken != null) {
        print('🔑 Access Token (first 20 chars): ${accessToken.substring(0, 20)}...');
      }

      // For web, if ID token is missing, use access token to get user info
      if (idToken == null && accessToken != null && kIsWeb) {
        print('🔄 ID token missing, using access token to get user info...');
        print('🌐 Fetching user info from Google OAuth2 API...');
        
        // Get user info using access token
        final userInfoResponse = await _networkService.get(
          'https://www.googleapis.com/oauth2/v2/userinfo',
          options: Options(
            headers: {'Authorization': 'Bearer $accessToken'},
          ),
        );
        
        print('📡 Google OAuth2 API response status: ${userInfoResponse.statusCode}');
        
        if (userInfoResponse.statusCode == 200) {
          final userInfo = userInfoResponse.data;
          print('✅ User info obtained successfully');
          print('📧 Email: ${userInfo['email']}');
          print('👤 Name: ${userInfo['name']}');
          print('🆔 Google ID: ${userInfo['id']}');
          print('🖼️ Picture: ${userInfo['picture']}');
          
          print('🚀 Sending data to backend /auth/google-web...');
          // Send user info to backend for authentication
          final response = await _networkService.post('/auth/google-web', data: {
            'accessToken': accessToken,
            'userInfo': userInfo,
          });
          
          print('📡 Backend response status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            print('✅ Backend authentication successful!');
            final userData = response.data['user'] as Map<String, dynamic>;
            final token = response.data['token'] as String;
            
            print('👤 User data received:');
            print('   - ID: ${userData['id']}');
            print('   - Email: ${userData['email']}');
            print('   - Name: ${userData['firstName']} ${userData['lastName']}');
            print('   - Admin: ${userData['isAdmin']}');
            
            print('🔐 Setting authentication token...');
            _networkService.setAuthToken(token);
            await _secureStorage.write(key: _tokenKey, value: token);
            await _secureStorage.write(key: _userEmailKey, value: userData['email'] as String?);
            
            print('🎉 Google Sign-In completed successfully!');
            return User.fromJson(userData);
          } else {
            print('❌ Backend authentication failed');
            print('❌ Status: ${response.statusCode}');
            print('❌ Message: ${response.statusMessage}');
            print('❌ Response data: ${response.data}');
            throw Exception('Google login failed: ${response.statusMessage}');
          }
        } else {
          print('❌ Failed to get user info from Google');
          print('❌ Status: ${userInfoResponse.statusCode}');
          print('❌ Response: ${userInfoResponse.data}');
          throw Exception('Failed to get user info from Google');
        }
      }

      if (idToken == null) {
        print('❌ No ID token available - this should not happen with People API enabled');
        throw Exception('Failed to obtain Google ID token. This may be due to origin configuration issues.');
      }

      print('🔑 Using ID token for authentication...');
      print('🚀 Sending ID token to backend /auth/google...');
      
      // Send the ID token to backend to verify and exchange for app JWT
      final response = await _networkService.post('/auth/google', data: {
        'idToken': idToken,
      });
      
      print('📡 Backend response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Backend authentication successful!');
        final userData = response.data['user'] as Map<String, dynamic>;
        final token = response.data['token'] as String;
        
        print('👤 User data received:');
        print('   - ID: ${userData['id']}');
        print('   - Email: ${userData['email']}');
        print('   - Name: ${userData['firstName']} ${userData['lastName']}');
        print('   - Admin: ${userData['isAdmin']}');
        
        print('🔐 Setting authentication token...');
        _networkService.setAuthToken(token);
        await _secureStorage.write(key: _tokenKey, value: token);
        await _secureStorage.write(key: _userEmailKey, value: userData['email'] as String?);
        
        print('🎉 Google Sign-In completed successfully!');
        return User.fromJson(userData);
      } else {
        print('❌ Backend authentication failed');
        print('❌ Status: ${response.statusCode}');
        print('❌ Message: ${response.statusMessage}');
        print('❌ Response data: ${response.data}');
        throw Exception('Google login failed: ${response.statusMessage}');
      }
    } catch (e) {
      print('🚨 ===== GOOGLE SIGN-IN ERROR =====');
      print('🚨 Error caught: $e');
      print('🚨 Error type: ${e.runtimeType}');
      print('🚨 Full error details: ${e.toString()}');
      print('🚨 Stack trace: ${StackTrace.current}');
      
      if (e.toString().contains('unregistered_origin') ||
          e.toString().contains('origin is not allowed')) {
        print('🚨 Origin configuration error detected');
        print('🚨 Solution: Add your domain to Google Cloud Console authorized origins');
        throw Exception('Google OAuth configuration error: Please add your domain to Google Cloud Console authorized origins');
      }
      
      if (e.toString().contains('popup') || e.toString().contains('blocked')) {
        print('🚨 Popup blocking error detected');
        print('🚨 Solution: Allow popups for localhost:3000 in your browser');
        throw Exception('Popup blocked: Please allow popups for localhost:3000 in your browser');
      }
      
      if (e.toString().contains('timeout')) {
        print('🚨 Timeout error detected');
        print('🚨 Solution: Check internet connection and try again');
        throw Exception('Google sign-in timed out: Please check your internet connection and try again');
      }
      
      if (e.toString().contains('PERMISSION_DENIED')) {
        print('🚨 Permission denied error detected');
        print('🚨 Solution: Ensure People API is enabled in Google Cloud Console');
        throw Exception('Google API permission error: Please ensure People API is enabled in Google Cloud Console');
      }
      
      print('🚨 Unknown error, rethrowing...');
      print('🚨 ===== END ERROR =====');
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
