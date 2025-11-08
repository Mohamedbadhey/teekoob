import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';
import 'package:teekoob/features/auth/presentation/widgets/password_field.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      context.read<AuthBloc>().add(
        ResetPasswordRequested(
          email: widget.email,
          code: widget.code,
          newPassword: _newPasswordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.getLocalizedText(
          englishText: 'Reset Password',
          somaliText: 'Dib U Deji Furaha',
        )),
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            // Navigate to login page after successful reset
            Future.delayed(const Duration(seconds: 1), () {
              context.go('/login');
            });
          } else if (state is AuthError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Icon
                  Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    LocalizationService.getLocalizedText(
                      englishText: 'Create New Password',
                      somaliText: 'Abuur Furaha Cusub',
                    ),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    LocalizationService.getLocalizedText(
                      englishText: 'Please enter your new password. Make sure it\'s at least 6 characters long.',
                      somaliText: 'Fadlan geli furahaaga cusub. Hubi in uu ugu yaraan 6 xaraf uu ka kooban yahay.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // New password field
                  PasswordField(
                    controller: _newPasswordController,
                    labelText: LocalizationService.getLocalizedText(
                      englishText: 'New Password',
                      somaliText: 'Furaha Cusub',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.getLocalizedText(
                          englishText: 'Password is required',
                          somaliText: 'Furaha waa loo baahan yahay',
                        );
                      }
                      if (value.length < 6) {
                        return LocalizationService.getLocalizedText(
                          englishText: 'Password must be at least 6 characters',
                          somaliText: 'Furaha waa in uu ugu yaraan 6 xaraf uu ka kooban yahay',
                        );
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Confirm password field
                  PasswordField(
                    controller: _confirmPasswordController,
                    labelText: LocalizationService.getLocalizedText(
                      englishText: 'Confirm New Password',
                      somaliText: 'Xaqiiji Furaha Cusub',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.getLocalizedText(
                          englishText: 'Please confirm your password',
                          somaliText: 'Fadlan xaqiiji furahaaga',
                        );
                      }
                      if (value != _newPasswordController.text) {
                        return LocalizationService.getLocalizedText(
                          englishText: 'Passwords do not match',
                          somaliText: 'Furahaydu ma isku mid yihiin',
                        );
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Reset password button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            LocalizationService.getLocalizedText(
                              englishText: 'Reset Password',
                              somaliText: 'Dib U Deji Furaha',
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Back to login
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      LocalizationService.getLocalizedText(
                        englishText: 'Back to Login',
                        somaliText: 'Ku Noqo Login',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

