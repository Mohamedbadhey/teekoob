import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/presentation/widgets/app_logo.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';
import 'package:teekoob/features/auth/presentation/widgets/password_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ));
    }
  }

  void _handleForgotPassword() {
    _showForgotPasswordDialog();
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.getLocalizedText(
          englishText: 'Forgot Password',
          somaliText: 'Furaha La Illaaway',
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(LocalizationService.getLocalizedText(
              englishText: 'Enter your email address to receive a verification code.',
              somaliText: 'Geli iimaylkaaga si aad u hesho lambarka xaqiijinta.',
            )),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: LocalizationService.getEmailLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocalizationService.getCancelText),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty && context.read<AuthBloc>().validateEmail(email)) {
                context.read<AuthBloc>().add(
                  ForgotPasswordRequested(email: email),
                );
                Navigator.of(context).pop();
                // Navigate to verify code page
                context.go('/verify-reset-code?email=${Uri.encodeComponent(email)}');
              }
            },
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Send Code',
              somaliText: 'Dir Lambarka',
            )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return Stack(
              children: [
                // Background Image
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.4, // Cover upper 40% of screen
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
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20), // Space for background image
                            
                            // Welcome Text
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
                                  englishText: 'Welcome Back!',
                                  somaliText: 'Ku Soo Dhowow!',
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
                                  englishText: 'Sign in to continue reading',
                                  somaliText: 'Gal si aad u sii akhrin',
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
                            
                            const SizedBox(height: 48),
                        
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              enabled: !isLoading,
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
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                    width: 1.5,
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
                            
                            // Password Field
                            PasswordField(
                              controller: _passwordController,
                              labelText: LocalizationService.getPasswordLabel,
                              hintText: LocalizationService.getLocalizedText(
                                englishText: 'Enter your password',
                                somaliText: 'Geli furahaaga',
                              ),
                              enabled: !isLoading,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return LocalizationService.getLocalizedText(
                                    englishText: 'Password is required',
                                    somaliText: 'Furaha waa loo baahan yahay',
                                  );
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Remember Me & Forgot Password
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: isLoading ? null : (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                      ),
                                      Flexible(
                                        child: Text(LocalizationService.getLocalizedText(
                                          englishText: 'Remember me',
                                          somaliText: 'I xasuus',
                                        )),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: isLoading ? null : _handleForgotPassword,
                                  child: Text(LocalizationService.getLocalizedText(
                                    englishText: 'Forgot Password?',
                                    somaliText: 'Furaha La Illaaway?',
                                  )),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Login Button
                            ElevatedButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      LocalizationService.getLoginText,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Social Login - Google
                            OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      context.read<AuthBloc>().add(const GoogleLoginRequested());
                                    },
                              icon: SizedBox(
                                width: 20,
                                height: 20,
                                child: Image.asset(
                                  'assets/icons/google.png',
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.g_translate, size: 20);
                                  },
                                ),
                              ),
                              label: Text(
                                LocalizationService.getLocalizedText(
                                  englishText: 'Sign in with Google',
                                  somaliText: 'Geli Google',
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Divider
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    LocalizationService.getLocalizedText(
                                      englishText: 'OR',
                                      somaliText: 'AMA',
                                    ),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  LocalizationService.getLocalizedText(
                                    englishText: "Don't have an account?",
                                    somaliText: 'Ma haysataa akoon?',
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                TextButton(
                                  onPressed: isLoading ? null : () => context.go('/register'),
                                  child: Text(
                                    LocalizationService.getRegisterText,
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
                // Modal barrier to prevent touches during authentication
                if (isLoading)
                  AbsorbPointer(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                LocalizationService.getLocalizedText(
                                  englishText: 'Signing in...',
                                  somaliText: 'Waa la galiyaa...',
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                LocalizationService.getLocalizedText(
                                  englishText: 'Please wait and do not touch the screen',
                                  somaliText: 'Fadlan sug oo ha taabin shaashadda',
                                ),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}