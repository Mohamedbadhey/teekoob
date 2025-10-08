import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';
import 'package:teekoob/core/services/localization_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textSlide;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _textSlide = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimations() async {
    // Start logo animation
    await _logoController.forward();
    
    // Start text animation
    await _textController.forward();
    
    // Start fade animation
    await _fadeController.forward();
    
    // Small delay for splash feel
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Check auth status and route with timeout
    final authBloc = context.read<AuthBloc>();
    
    // Add a timeout to prevent infinite loading
    try {
      await Future.any([
        Future.microtask(() async {
          authBloc.add(const CheckAuthStatus());
        }),
        Future.delayed(const Duration(seconds: 20), () {
          print('⏰ Splash screen timeout - forcing navigation to login');
          if (mounted) {
            context.go('/login');
          }
        }),
      ]);
    } catch (e) {
      print('❌ Splash screen error: $e');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go('/home');
          } else if (state is Unauthenticated || state is AuthInitial) {
            context.go('/login');
          } else if (state is AuthError) {
            print('❌ Auth error in splash: ${state.message}');
            // On auth error, proceed to login screen
            context.go('/login');
          }
          // Note: AuthLoading state is handled by the loading indicator
        },
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoSection(),
                const SizedBox(height: 40),
                _buildAppNameSection(),
                const SizedBox(height: 20),
                _buildAppDescriptionSection(),
                const SizedBox(height: 60),
                _buildLoadingIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Transform.rotate(
            angle: _logoRotation.value * 0.1,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/logo.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.book,
                        size: 75,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppNameSection() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _textSlide.value),
          child: Text(
            LocalizationService.getAppName,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppDescriptionSection() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            LocalizationService.getAppDescription,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Loading...',
                  somaliText: 'Soo dejinaya...',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
