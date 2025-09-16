import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';
import 'package:teekoob/features/auth/presentation/widgets/password_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _selectedLanguage = 'en';
  String _selectedTheme = 'light';
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      context.read<AuthBloc>().add(RegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        language: _selectedLanguage,
        themePreference: _selectedTheme,
      ));
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.getLocalizedText(
            englishText: 'Please agree to the terms and conditions',
            somaliText: 'Fadlan ku raalli noqo shuruudaha iyo qaab-dhismeedka',
          )),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.getRegisterText),
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            if (state.user != null) {
              context.go('/home');
            }
          } else if (state is AuthError) {
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
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    LocalizationService.getLocalizedText(
                      englishText: 'Create Account',
                      somaliText: 'Samee Akoon',
                    ),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    LocalizationService.getLocalizedText(
                      englishText: 'Join Teekoob and start your reading journey',
                      somaliText: 'Ku biir Teekoob oo bilaabo safarkaaga akhrinta',
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Display Name Field
                  TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.getFullNameLabel,
                      hintText: LocalizationService.getLocalizedText(
                        englishText: 'Enter your full name',
                        somaliText: 'Geli magacaaga buuxa',
                      ),
                      prefixIcon: const Icon(Icons.person_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.getLocalizedText(
                          englishText: 'Full name is required',
                          somaliText: 'Magaca buuxa waa loo baahan yahay',
                        );
                      }
                      if (value.trim().length < 2) {
                        return LocalizationService.getLocalizedText(
                          englishText: 'Name must be at least 2 characters',
                          somaliText: 'Magaca waa inuu ahaadaa ugu yaraan 2 xaraf',
                        );
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.getEmailLabel,
                      hintText: LocalizationService.getLocalizedText(
                        englishText: 'Enter your email',
                        somaliText: 'Geli iimaylkaaga',
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.getLocalizedText(
                          englishText: 'Email is required',
                          somaliText: 'Iimaylka waa loo baahan yahay',
                        );
                      }
                      if (!context.read<AuthBloc>().validateEmail(value)) {
                        return LocalizationService.getLocalizedText(
                          englishText: 'Please enter a valid email',
                          somaliText: 'Fadlan geli iimayl sax ah',
                        );
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Phone Field (Optional)
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.getLocalizedText(
                        englishText: 'Phone Number (Optional)',
                        somaliText: 'Lambarka Telefoonka (Ikhtiyaari)',
                      ),
                      hintText: LocalizationService.getLocalizedText(
                        englishText: 'Enter your phone number',
                        somaliText: 'Geli lambarka telefoonkaaga',
                      ),
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password Field
                  PasswordField(
                    controller: _passwordController,
                    labelText: LocalizationService.getPasswordLabel,
                    hintText: LocalizationService.getLocalizedText(
                      englishText: 'Create a strong password',
                      somaliText: 'Samee furah xooggan',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.getLocalizedText(
                          englishText: 'Password is required',
                          somaliText: 'Furaha waa loo baahan yahay',
                        );
                      }
                      if (!context.read<AuthBloc>().validatePasswordStrength(value)) {
                        return LocalizationService.getLocalizedText(
                          englishText: 'Password must be at least 8 characters with uppercase, number, and special character',
                          somaliText: 'Furaha waa inuu ahaadaa ugu yaraan 8 xaraf oo ku jira xaraf weyn, tiro, iyo xaraf gaar ah',
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
                  
                  const SizedBox(height: 24),
                  
                  // Language Selection
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: InputDecoration(
                      labelText: LocalizationService.getLanguageText,
                      prefixIcon: const Icon(Icons.language),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(LocalizationService.getLocalizedText(
                          englishText: 'English',
                          somaliText: 'Ingiriisi',
                        )),
                      ),
                      DropdownMenuItem(
                        value: 'so',
                        child: Text(LocalizationService.getLocalizedText(
                          englishText: 'Somali',
                          somaliText: 'Soomaali',
                        )),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Theme Selection
                  DropdownButtonFormField<String>(
                    value: _selectedTheme,
                    decoration: InputDecoration(
                      labelText: LocalizationService.getThemeText,
                      prefixIcon: const Icon(Icons.palette),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'light',
                        child: Text(LocalizationService.getLocalizedText(
                          englishText: 'Light',
                          somaliText: 'Iftiin',
                        )),
                      ),
                      DropdownMenuItem(
                        value: 'dark',
                        child: Text(LocalizationService.getLocalizedText(
                          englishText: 'Dark',
                          somaliText: 'Madow',
                        )),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTheme = value!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Terms and Conditions
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: LocalizationService.getLocalizedText(
                                  englishText: 'I agree to the ',
                                  somaliText: 'Waxaan ku raalli noqey ',
                                ),
                              ),
                              TextSpan(
                                text: LocalizationService.getLocalizedText(
                                  englishText: 'Terms & Conditions',
                                  somaliText: 'Shuruudaha & Qaab-dhismeedka',
                                ),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Register Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is AuthLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                LocalizationService.getRegisterText,
                                style: const TextStyle(fontSize: 16),
                              ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        LocalizationService.getLocalizedText(
                          englishText: 'Already have an account?',
                          somaliText: 'Horey u haysataa akoon?',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          LocalizationService.getLoginText,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
