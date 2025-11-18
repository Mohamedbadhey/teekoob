import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';
import 'package:teekoob/features/auth/presentation/widgets/password_field.dart';

class CompleteRegistrationPage extends StatefulWidget {
  final String email;
  final String code;
  final String displayName;
  final String? phoneNumber;
  final String language;
  final String themePreference;

  const CompleteRegistrationPage({
    super.key,
    required this.email,
    required this.code,
    required this.displayName,
    this.phoneNumber,
    required this.language,
    required this.themePreference,
  });

  @override
  State<CompleteRegistrationPage> createState() => _CompleteRegistrationPageState();
}

class _CompleteRegistrationPageState extends State<CompleteRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleCompleteRegistration() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      context.read<AuthBloc>().add(
        CompleteRegistrationRequested(
          email: widget.email,
          code: widget.code,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.getLocalizedText(
          englishText: 'Complete Registration',
          somaliText: 'Dhamaystir Diiwaan Geli',
        )),
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            setState(() => _isLoading = false);
            if (state.user != null) {
              // Registration completed and user logged in
              context.go('/home');
            }
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
                    Icons.lock_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    LocalizationService.getLocalizedText(
                      englishText: 'Create Password',
                      somaliText: 'Samee Furaha',
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
                      englishText: 'Create a secure password for your account',
                      somaliText: 'Samee furah ammaan ah akoonkaaga',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Password Field
                  PasswordField(
                    controller: _passwordController,
                    labelText: LocalizationService.getPasswordLabel,
                    hintText: LocalizationService.getLocalizedText(
                      englishText: 'Enter your password',
                      somaliText: 'Geli furahaaga',
                    ),
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
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
                          somaliText: 'Furaha waa inuu ahaadaa ugu yaraan 6 xaraf',
                        );
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Confirm Password Field
                  PasswordField(
                    controller: _confirmPasswordController,
                    labelText: LocalizationService.getConfirmPasswordLabel,
                    hintText: LocalizationService.getLocalizedText(
                      englishText: 'Confirm your password',
                      somaliText: 'Xaqiiji furahaaga',
                    ),
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.getLocalizedText(
                          englishText: 'Please confirm your password',
                          somaliText: 'Fadlan xaqiiji furahaaga',
                        );
                      }
                      if (value != _passwordController.text) {
                        return LocalizationService.getLocalizedText(
                          englishText: 'Passwords do not match',
                          somaliText: 'Furaha ma isku mid aha',
                        );
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Complete Registration Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleCompleteRegistration,
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
                              englishText: 'Complete Registration',
                              somaliText: 'Dhamaystir Diiwaan Geli',
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Back to verification
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      final params = {
                        'email': widget.email,
                        'displayName': widget.displayName,
                        'phoneNumber': widget.phoneNumber ?? '',
                        'language': widget.language,
                        'themePreference': widget.themePreference,
                      };
                      final queryString = params.entries
                          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
                          .join('&');
                      context.go('/verify-registration-code?$queryString');
                    },
                    child: Text(
                      LocalizationService.getLocalizedText(
                        englishText: 'Back to Verification',
                        somaliText: 'Ku Noqo Xaqiijinta',
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

