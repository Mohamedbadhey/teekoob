import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';

class VerifyRegistrationCodePage extends StatefulWidget {
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String language;
  final String themePreference;

  const VerifyRegistrationCodePage({
    super.key,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    required this.language,
    required this.themePreference,
  });

  @override
  State<VerifyRegistrationCodePage> createState() => _VerifyRegistrationCodePageState();
}

class _VerifyRegistrationCodePageState extends State<VerifyRegistrationCodePage> {
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCooldownTimer() {
    _resendCooldownSeconds = 60; // 60 seconds cooldown
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldownSeconds > 0) {
        setState(() {
          _resendCooldownSeconds--;
        });
      } else {
        timer.cancel();
        _cooldownTimer = null;
      }
    });
  }

  void _resendCode() {
    if (_isResending || _resendCooldownSeconds > 0) return;

    setState(() {
      _isResending = true;
    });

    // Clear existing code fields
    for (var controller in _codeControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();

    context.read<AuthBloc>().add(
      SendRegistrationCodeRequested(
        email: widget.email,
        displayName: widget.displayName,
        phoneNumber: widget.phoneNumber,
        language: widget.language,
        themePreference: widget.themePreference,
      ),
    );
  }

  void _handleCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Check if all fields are filled
    if (_codeControllers.every((controller) => controller.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  void _verifyCode() {
    final code = _codeControllers.map((c) => c.text).join();
    
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.getLocalizedText(
            englishText: 'Please enter the complete 6-digit code',
            somaliText: 'Fadlan geli lambarka 6-digit oo dhan',
          )),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    context.read<AuthBloc>().add(
      VerifyRegistrationCodeRequested(
        email: widget.email,
        code: code,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.getLocalizedText(
          englishText: 'Verify Email',
          somaliText: 'Xaqiiji Iimaylka',
        )),
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            setState(() => _isLoading = false);
            // Navigate to complete registration page
            final code = _codeControllers.map((c) => c.text).join();
            final params = {
              'email': widget.email,
              'code': code,
              'displayName': widget.displayName,
              'phoneNumber': widget.phoneNumber ?? '',
              'language': widget.language,
              'themePreference': widget.themePreference,
            };
            final queryString = params.entries
                .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
                .join('&');
            context.go('/complete-registration?$queryString');
          } else if (state is RegistrationCodeSent) {
            // Handle resend code success
            setState(() {
              _isResending = false;
            });
            _startCooldownTimer();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocalizationService.getLocalizedText(
                  englishText: 'Verification code resent to your email',
                  somaliText: 'Lambarka xaqiijinta ayaa dib loo diray iimaylkaaga',
                )),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (state is AuthError) {
            final wasResending = _isResending;
            setState(() {
              _isLoading = false;
              _isResending = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            // Clear code fields on error (only if not resending, since resend already clears them)
            if (!wasResending) {
              for (var controller in _codeControllers) {
                controller.clear();
              }
              _focusNodes[0].requestFocus();
            }
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Icon
                Icon(
                  Icons.email_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  LocalizationService.getLocalizedText(
                    englishText: 'Enter Verification Code',
                    somaliText: 'Geli Lambarka Xaqiijinta',
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
                    englishText: 'We sent a 6-digit verification code to',
                    somaliText: 'Waxaan u dirnay lambar xaqiijin 6-digit ah',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Email
                Text(
                  widget.email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Code input fields
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate responsive width based on available space
                    final screenWidth = MediaQuery.of(context).size.width;
                    final padding = 48.0; // Total horizontal padding (24 * 2)
                    final spacing = 8.0 * 5; // Space between 6 boxes (5 gaps)
                    final availableWidth = screenWidth - padding - spacing;
                    final boxWidth = (availableWidth / 6).clamp(48.0, 60.0);
                    final boxHeight = boxWidth * 1.2;
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: boxWidth,
                          height: boxHeight,
                          child: TextField(
                            controller: _codeControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: boxWidth * 0.6,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.symmetric(
                                vertical: boxHeight * 0.3,
                                horizontal: 0,
                              ),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                            onChanged: (value) => _handleCodeChanged(index, value),
                          ),
                        );
                      }),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Verify button
                ElevatedButton(
                  onPressed: (_isLoading || _isResending) ? null : _verifyCode,
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
                            englishText: 'Verify Code',
                            somaliText: 'Xaqiiji Lambarka',
                          ),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Resend code button
                Center(
                  child: _resendCooldownSeconds > 0
                      ? Text(
                          LocalizationService.getLocalizedText(
                            englishText: 'Resend code in $_resendCooldownSeconds seconds',
                            somaliText: 'Dib u dir lambarka $_resendCooldownSeconds ilbiriqsi gudahood',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: (_isLoading || _isResending) ? null : _resendCode,
                          icon: _isResending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(
                            LocalizationService.getLocalizedText(
                              englishText: 'Resend Code',
                              somaliText: 'Dib U Dir Lambarka',
                            ),
                          ),
                        ),
                ),
                
                const SizedBox(height: 24),
                
                // Back to register
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(
                    LocalizationService.getLocalizedText(
                      englishText: 'Back to Register',
                      somaliText: 'Ku Noqo Diiwaan Geli',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

