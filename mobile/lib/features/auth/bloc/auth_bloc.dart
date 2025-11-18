import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:teekoob/core/models/user_model.dart';
import 'package:teekoob/features/auth/services/auth_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class GoogleLoginRequested extends AuthEvent {
  const GoogleLoginRequested();
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  final String? phoneNumber;
  final String language;
  final String themePreference;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
    this.phoneNumber,
    this.language = 'en',
    this.themePreference = 'light',
  });

  @override
  List<Object?> get props => [
    email, password, displayName, phoneNumber, language, themePreference
  ];
}

class SendRegistrationCodeRequested extends AuthEvent {
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String language;
  final String themePreference;

  const SendRegistrationCodeRequested({
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.language = 'en',
    this.themePreference = 'light',
  });

  @override
  List<Object?> get props => [
    email, displayName, phoneNumber, language, themePreference
  ];
}

class VerifyRegistrationCodeRequested extends AuthEvent {
  final String email;
  final String code;

  const VerifyRegistrationCodeRequested({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

class CompleteRegistrationRequested extends AuthEvent {
  final String email;
  final String code;
  final String password;
  final String confirmPassword;

  const CompleteRegistrationRequested({
    required this.email,
    required this.code,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [email, code, password, confirmPassword];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class VerifyResetCodeRequested extends AuthEvent {
  final String email;
  final String code;

  const VerifyResetCodeRequested({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

class ResetPasswordRequested extends AuthEvent {
  final String email;
  final String code;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordRequested({
    required this.email,
    required this.code,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [email, code, newPassword, confirmPassword];
}

class ChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class UpdateProfileRequested extends AuthEvent {
  final String? displayName;
  final String? phoneNumber;
  final String? language;
  final String? themePreference;
  final String? avatarUrl;

  const UpdateProfileRequested({
    this.displayName,
    this.phoneNumber,
    this.language,
    this.themePreference,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [
    displayName, phoneNumber, language, themePreference, avatarUrl
  ];
}

class DeleteAccountRequested extends AuthEvent {
  final String password;

  const DeleteAccountRequested({required this.password});

  @override
  List<Object?> get props => [password];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final String? code;

  const AuthError(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class AuthSuccess extends AuthState {
  final String message;
  final User? user;

  const AuthSuccess(this.message, {this.user});

  @override
  List<Object?> get props => [message, user];
}

class ForgotPasswordSuccess extends AuthState {
  final String email;

  const ForgotPasswordSuccess(this.email);

  @override
  List<Object?> get props => [email];
}

class RegistrationCodeSent extends AuthState {
  final String email;

  const RegistrationCodeSent(this.email);

  @override
  List<Object?> get props => [email];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(const AuthInitial()) {
    
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<SendRegistrationCodeRequested>(_onSendRegistrationCodeRequested);
    on<VerifyRegistrationCodeRequested>(_onVerifyRegistrationCodeRequested);
    on<CompleteRegistrationRequested>(_onCompleteRegistrationRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<VerifyResetCodeRequested>(_onVerifyResetCodeRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      // Add timeout to prevent infinite loading
      final result = await Future.any([
        _checkAuthStatusInternal(),
        Future.delayed(const Duration(seconds: 15), () => 'timeout'),
      ]);
      
      if (result == 'timeout') {
        emit(const Unauthenticated());
        return;
      }
      
      if (result is bool) {
        if (result) {
          final user = await _authService.getCurrentUser();
          if (user != null) {
            emit(Authenticated(user));
          } else {
            emit(const Unauthenticated());
          }
        } else {
          emit(const Unauthenticated());
        }
      }
    } catch (e) {
      // On error, proceed to login screen instead of staying stuck
      emit(const Unauthenticated());
    }
  }

  Future<bool> _checkAuthStatusInternal() async {
    try {
      final isAuthenticated = await _authService.isAuthenticated();
      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      final user = await _authService.login(
        email: event.email,
        password: event.password,
      );
      
      emit(AuthSuccess('Login successful!', user: user));
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Login failed: $e'));
    }
  }

  Future<void> _onGoogleLoginRequested(
    GoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      final user = await _authService.loginWithGoogle();

      emit(AuthSuccess('Login successful!', user: user));
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Google login failed: $e'));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      final user = await _authService.register(
        email: event.email,
        displayName: event.displayName,
        password: event.password,
        confirmPassword: event.password, // For now, use same password
        phoneNumber: event.phoneNumber,
        preferredLanguage: event.language,
        themePreference: event.themePreference,
      );
      
      emit(AuthSuccess('Registration successful!', user: user));
      emit(Authenticated(user));
    } catch (e) {
      // Check if it's the "already exists" error
      final errorString = e.toString();
      String displayMessage;
      if (errorString.contains('already exists') || errorString.contains('This email already exists')) {
        displayMessage = 'This email already exists';
      } else {
        displayMessage = 'Registration failed: ${errorString.replaceAll('Exception: ', '')}';
      }
      emit(AuthError(displayMessage));
    }
  }

  Future<void> _onSendRegistrationCodeRequested(
    SendRegistrationCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      await _authService.sendRegistrationCode(
        email: event.email,
        displayName: event.displayName,
        phoneNumber: event.phoneNumber,
        preferredLanguage: event.language,
        themePreference: event.themePreference,
      );
      
      emit(RegistrationCodeSent(event.email));
    } catch (e) {
      final errorString = e.toString();
      String displayMessage;
      if (errorString.contains('already exists') || errorString.contains('This email already exists')) {
        displayMessage = 'This email already exists';
      } else {
        displayMessage = 'Failed to send verification code: ${errorString.replaceAll('Exception: ', '')}';
      }
      emit(AuthError(displayMessage));
    }
  }

  Future<void> _onVerifyRegistrationCodeRequested(
    VerifyRegistrationCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      await _authService.verifyRegistrationCode(
        email: event.email,
        code: event.code,
      );
      
      emit(const AuthSuccess('Verification code is valid!'));
    } catch (e) {
      emit(AuthError('Code verification failed: $e'));
    }
  }

  Future<void> _onCompleteRegistrationRequested(
    CompleteRegistrationRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      final result = await _authService.completeRegistration(
        email: event.email,
        code: event.code,
        password: event.password,
        confirmPassword: event.confirmPassword,
      );
      
      if (result != null && result['user'] != null && result['token'] != null) {
        final user = User.fromJson(result['user']);
        // Token is already stored in completeRegistration method
        emit(Authenticated(user));
        emit(AuthSuccess('Registration completed successfully! You are now logged in.', user: user));
      } else {
        emit(const AuthSuccess('Registration completed successfully!'));
      }
    } catch (e) {
      final errorString = e.toString();
      String displayMessage;
      if (errorString.contains('Invalid or expired')) {
        displayMessage = 'Invalid or expired verification code';
      } else {
        displayMessage = 'Registration failed: ${errorString.replaceAll('Exception: ', '')}';
      }
      emit(AuthError(displayMessage));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      await _authService.logout();
      
      emit(const AuthSuccess('Logout successful!'));
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError('Logout failed: $e'));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 AuthBloc - _onForgotPasswordRequested called with email: ${event.email}');
    try {
      print('🔵 AuthBloc - Emitting AuthLoading');
      emit(const AuthLoading());
      
      print('🔵 AuthBloc - Calling forgotPassword service');
      await _authService.forgotPassword(event.email);
      print('🔵 AuthBloc - forgotPassword service completed successfully');
      
      // Emit success with email for navigation
      // Note: Backend returns 200 even if email fails to send
      // The code is still generated and saved in database
      print('🔵 AuthBloc - Emitting ForgotPasswordSuccess with email: ${event.email}');
      emit(ForgotPasswordSuccess(event.email));
      print('🔵 AuthBloc - ForgotPasswordSuccess emitted');
    } catch (e) {
      print('🔴 AuthBloc - Error caught: $e');
      // Check if it's a network error or actual failure
      final errorMessage = e.toString();
      if (errorMessage.contains('SocketException') || 
          errorMessage.contains('TimeoutException') ||
          errorMessage.contains('Failed host lookup')) {
        // Network error - still allow navigation since code might be generated
        print('🔵 AuthBloc - Network error detected, emitting ForgotPasswordSuccess anyway');
        emit(ForgotPasswordSuccess(event.email));
      } else {
        // Check if it's the "not registered" error
        final errorString = errorMessage;
        String displayMessage;
        if (errorString.contains('not registered') || errorString.contains('This email is not registered')) {
          displayMessage = 'This email is not registered';
        } else {
          displayMessage = 'Failed to send password reset email: ${errorString.replaceAll('Exception: ', '')}';
        }
        print('🔴 AuthBloc - Emitting AuthError: $displayMessage');
        emit(AuthError(displayMessage));
      }
    }
  }

  Future<void> _onVerifyResetCodeRequested(
    VerifyResetCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      await _authService.verifyResetCode(
        email: event.email,
        code: event.code,
      );
      
      emit(const AuthSuccess('Verification code is valid!'));
    } catch (e) {
      emit(AuthError('Code verification failed: $e'));
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      final result = await _authService.resetPassword(
        email: event.email,
        code: event.code,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );
      
      // Auto-login after successful password reset
      if (result != null && result['user'] != null && result['token'] != null) {
        final user = User.fromJson(result['user']);
        final token = result['token'] as String;
        
        // Store token and user email
        await _authService.storeAuthToken(token, user.email);
        
        emit(Authenticated(user));
        emit(AuthSuccess('Password reset successful! You are now logged in.', user: user));
      } else {
        emit(const AuthSuccess('Password reset successful!'));
      }
    } catch (e) {
      emit(AuthError('Password reset failed: $e'));
    }
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      await _authService.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
        confirmPassword: event.newPassword, // For now, use same password
      );
      
      emit(const AuthSuccess('Password changed successfully!'));
    } catch (e) {
      emit(AuthError('Password change failed: $e'));
    }
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      // Split displayName into firstName and lastName if provided
      String? firstName;
      String? lastName;
      
      if (event.displayName != null && event.displayName!.isNotEmpty) {
        final nameParts = event.displayName!.trim().split(' ').where((part) => part.isNotEmpty).toList();
        firstName = nameParts.isNotEmpty ? nameParts.first : null;
        lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;
      }
      
      final updatedUser = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        profilePicture: event.avatarUrl,
        preferredLanguage: event.language,
        phoneNumber: event.phoneNumber,
        dateOfBirth: null,
        country: null,
        city: null,
        bio: null,
      );
      
      emit(AuthSuccess('Profile updated successfully!', user: updatedUser));
      emit(Authenticated(updatedUser));
    } catch (e) {
      emit(AuthError('Profile update failed: $e'));
    }
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      await _authService.deleteAccount(event.password);
      
      emit(const AuthSuccess('Account deleted successfully!'));
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError('Account deletion failed: $e'));
    }
  }

  // Helper methods
  bool get isAuthenticated => state is Authenticated;
  User? get currentUser {
    if (state is Authenticated) {
      return (state as Authenticated).user;
    }
    return null;
  }

  // Validate email format
  bool validateEmail(String email) {
    // More robust email validation
    // Must have: local part @ domain part with at least one dot and TLD
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    
    // Basic checks first
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return false;
    }
    
    // Check that @ appears only once
    final atCount = email.split('@').length - 1;
    if (atCount != 1) {
      return false;
    }
    
    final parts = email.split('@');
    if (parts.length != 2) {
      return false;
    }
    
    final localPart = parts[0];
    final domainPart = parts[1];
    
    // Local part must not be empty and should not start/end with special chars
    if (localPart.isEmpty || 
        localPart.startsWith('.') || 
        localPart.endsWith('.') ||
        localPart.contains('..')) {
      return false;
    }
    
    // Domain part must have at least one dot and TLD
    if (domainPart.isEmpty || !domainPart.contains('.')) {
      return false;
    }
    
    // Domain must not start/end with dot or hyphen
    if (domainPart.startsWith('.') || 
        domainPart.endsWith('.') ||
        domainPart.startsWith('-') ||
        domainPart.endsWith('-')) {
      return false;
    }
    
    // Final regex check
    return emailRegex.hasMatch(email);
  }

  // Validate password strength
  bool validatePasswordStrength(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }
}
