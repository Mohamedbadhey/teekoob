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

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;

  const ResetPasswordRequested({
    required this.token,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [token, newPassword];
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
    on<LogoutRequested>(_onLogoutRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
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
      emit(AuthError('Registration failed: $e'));
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
    try {
      emit(const AuthLoading());
      
      await _authService.forgotPassword(event.email);
      
      emit(const AuthSuccess('Password reset email sent!'));
    } catch (e) {
      emit(AuthError('Failed to send password reset email: $e'));
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      await _authService.resetPassword(
        token: event.token,
        newPassword: event.newPassword,
        confirmPassword: event.newPassword, // For now, use same password
      );
      
      emit(const AuthSuccess('Password reset successful!'));
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
      
      final updatedUser = await _authService.updateProfile(
        firstName: event.displayName, // Use displayName as firstName
        lastName: null,
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
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  // Validate password strength
  bool validatePasswordStrength(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }
}
