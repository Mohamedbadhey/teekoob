import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/presentation/widgets/app_logo.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';

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
  
  String _selectedLanguage = 'en';
  String _selectedTheme = 'light';
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      // Step 1: Send verification code with email and name
      context.read<AuthBloc>().add(SendRegistrationCodeRequested(
        email: _emailController.text.trim(),
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
            if (state.user != null) {
              // Registration completed and user logged in
              context.go('/home');
            }
          } else if (state is RegistrationCodeSent) {
            // Navigate to verification code page
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                final email = _emailController.text.trim();
                final displayName = _displayNameController.text.trim();
                final phoneNumber = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
                final language = _selectedLanguage;
                final themePreference = _selectedTheme;
                
                context.go('/verify-registration-code?email=${Uri.encodeComponent(email)}&displayName=${Uri.encodeComponent(displayName)}&phoneNumber=${phoneNumber != null ? Uri.encodeComponent(phoneNumber) : ''}&language=${Uri.encodeComponent(language)}&themePreference=${Uri.encodeComponent(themePreference)}');
              }
            });
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: Stack(
          children: [
            // Background Image
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.35, // Cover upper 35% of screen
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/people.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.9),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20), // Space for background image
                      
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          LocalizationService.getLocalizedText(
                            englishText: 'Create Account',
                            somaliText: 'Samee Akoon',
                          ),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          LocalizationService.getLocalizedText(
                            englishText: 'Join Bookdoon and start your reading journey',
                            somaliText: 'Ku biir Bookdoon oo bilaabo safarkaaga akhrinta',
                          ),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
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
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.95),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
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
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.95),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
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
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.95),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Language Selection
                      DropdownButtonFormField<String>(
                        value: _selectedLanguage,
                        decoration: InputDecoration(
                          labelText: LocalizationService.getLanguageText,
                          prefixIcon: const Icon(Icons.language),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.95),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
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
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.95),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
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
          ],
        ),
      ),
    );
  }
}