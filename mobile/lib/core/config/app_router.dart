import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/features/auth/presentation/pages/login_page.dart';
import 'package:teekoob/features/auth/presentation/pages/register_page.dart';
import 'package:teekoob/features/auth/presentation/pages/splash_page.dart';
import 'package:teekoob/features/auth/presentation/pages/verify_reset_code_page.dart';
import 'package:teekoob/features/auth/presentation/pages/reset_password_page.dart';
import 'package:teekoob/core/presentation/app_scaffold.dart';
import 'package:teekoob/features/books/presentation/pages/books_page.dart';
import 'package:teekoob/features/books/presentation/pages/book_detail_page.dart';
import 'package:teekoob/features/books/presentation/pages/book_read_page.dart';
import 'package:teekoob/features/books/presentation/pages/all_books_page.dart';
import 'package:teekoob/features/library/presentation/pages/library_page.dart';
import 'package:teekoob/features/player/presentation/pages/audio_player_page.dart';
import 'package:teekoob/features/reader/presentation/pages/reader_page.dart';
import 'package:teekoob/features/settings/presentation/pages/settings_page.dart';
import 'package:teekoob/features/subscription/presentation/pages/subscription_page.dart';
import 'package:teekoob/features/books/presentation/pages/book_audio_player_page.dart';
import 'package:teekoob/features/podcasts/presentation/pages/podcast_detail_page.dart';
import 'package:teekoob/features/podcasts/presentation/pages/podcast_episode_page.dart';
import 'package:teekoob/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:teekoob/features/notifications/presentation/pages/notifications_page.dart';
import 'package:teekoob/features/auth/services/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyResetCode = '/verify-reset-code';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String books = '/books';
  static const String bookDetail = 'books/:id';
  static const String bookRead = 'books/:id/read';
  static const String library = '/library';
  static const String reader = 'reader/:id';
  static const String audioPlayer = '/player/:id';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  static const String podcastDetail = '/podcast/:id';
  static const String podcastEpisode = '/podcast/:podcastId/episode/:episodeId';
  
  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      // Splash Screen
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: verifyResetCode,
        name: 'verifyResetCode',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyResetCodePage(email: email);
        },
      ),
      GoRoute(
        path: resetPassword,
        name: 'resetPassword',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final code = state.uri.queryParameters['code'] ?? '';
          return ResetPasswordPage(email: email, code: code);
        },
      ),
      
      // Edit Profile Route (Protected)
      GoRoute(
        path: '/edit-profile',
        name: 'editProfile',
        builder: (context, state) => const EditProfilePage(),
      ),
      
      // Notifications Route (Protected)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      
      // Main App Routes (Protected) - All handled by AppScaffold
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const AppScaffold(),
      ),
      GoRoute(
        path: '/home/books',
        name: 'books',
        builder: (context, state) => const AppScaffold(),
      ),
      GoRoute(
        path: '/home/library',
        name: 'library',
        builder: (context, state) => const AppScaffold(),
      ),
      GoRoute(
        path: '/home/settings',
        name: 'settings',
        builder: (context, state) => const AppScaffold(),
      ),
      
      // Nested routes that don't show bottom navigation
      GoRoute(
        path: '/home/books/:id/read',
        name: 'bookRead',
        builder: (context, state) => const BookReadPage(),
      ),
      GoRoute(
        path: '/home/reader/:id',
        name: 'reader',
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return ReaderPage(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/home/player/:id',
        name: 'audioPlayer',
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return AudioPlayerPage(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/home/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionPage(),
      ),
      
      // Book Detail Page (Outside of AppScaffold to remove bottom navigation)
      GoRoute(
        path: '/book/:id',
        name: 'bookDetail',
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return BookDetailPage(bookId: bookId);
        },
      ),
      
      // Book Audio Player Page (Outside of AppScaffold to remove bottom navigation)
      GoRoute(
        path: '/book/:id/audio-player',
        name: 'bookAudioPlayer',
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return BookAudioPlayerPage(bookId: bookId);
        },
      ),
      
      // All Books Page (Outside of AppScaffold to remove bottom navigation)
      GoRoute(
        path: '/all-books/:category/:title',
        name: 'allBooks',
        builder: (context, state) {
          final category = state.pathParameters['category']!;
          final title = state.pathParameters['title']!;
          return AllBooksPage(category: category, title: title);
        },
      ),
      
      // Podcast Detail Page (Outside of AppScaffold to remove bottom navigation)
      GoRoute(
        path: '/podcast/:id',
        name: 'podcastDetail',
        builder: (context, state) {
          final podcastId = state.pathParameters['id']!;
          return PodcastDetailPage(podcastId: podcastId);
        },
      ),
      
      // Podcast Episode Page (Outside of AppScaffold to remove bottom navigation)
      GoRoute(
        path: '/podcast/:podcastId/episode/:episodeId',
        name: 'podcastEpisode',
        builder: (context, state) {
          final podcastId = state.pathParameters['podcastId']!;
          final episodeId = state.pathParameters['episodeId']!;
          return PodcastEpisodePage(
            podcastId: podcastId,
            episodeId: episodeId,
          );
        },
      ),
    ],
    
    // Redirect logic for authentication
    redirect: (context, state) async {
      final authService = AuthService();
      final isAuthenticated = await authService.isAuthenticated();
      
      // Public routes that don't require authentication
      final publicRoutes = ['/', '/login', '/register'];
      final isPublicRoute = publicRoutes.contains(state.uri.path);
      
      // If not authenticated and trying to access protected route, redirect to login
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }
      
      // If authenticated and on login/register, redirect to home
      if (isAuthenticated && (state.uri.path == '/login' || state.uri.path == '/register')) {
        return '/home';
      }
      
      return null; // Allow navigation
    },
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  // Navigation helper methods
  static void goToHome(BuildContext context) => context.go(home);
  static void goToLogin(BuildContext context) => context.go(login);
  static void goToRegister(BuildContext context) => context.go(register);
  static void goToBooks(BuildContext context) => context.go('$home/books');
  static void goToBookDetail(BuildContext context, String bookId) => 
      context.go('/book/$bookId');
  static void goToLibrary(BuildContext context) => context.go('$home/library');
  static void goToReader(BuildContext context, String bookId) => 
      context.go('$home/reader/$bookId');
  static void goToAudioPlayer(BuildContext context, String bookId) => 
      context.go('$home/player/$bookId');
  static void goToSettings(BuildContext context) => context.go('$home/settings');
  static void goToSubscription(BuildContext context) => context.go('$home/subscription');
  static void goToPodcastDetail(BuildContext context, String podcastId) => 
      context.go('/podcast/$podcastId');
  static void goToPodcastEpisode(BuildContext context, String podcastId, String episodeId) => 
      context.go('/podcast/$podcastId/episode/$episodeId');
  
  // Pop navigation
  static void goBack(BuildContext context) => context.pop();
  
  // Consistent back navigation that respects navigation stack
  static void handleBackNavigation(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(home);
    }
  }
  
  // Handle Android back button with consistent behavior
  static Future<bool> handleAndroidBackButton(BuildContext context) async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return false; // Prevent default back button behavior
    } else {
      context.go(home);
      return false; // Prevent default back button behavior
    }
  }
  
  // Show exit confirmation dialog
  static Future<void> showExitConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you ready to close the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Exit',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // User confirmed exit - close the app
      SystemNavigator.pop();
    }
  }
  
  // Replace current route
  static void replaceWithHome(BuildContext context) => context.go(home);
  static void replaceWithLogin(BuildContext context) => context.go(login);
}
