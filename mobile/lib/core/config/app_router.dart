import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/features/auth/presentation/pages/login_page.dart';
import 'package:teekoob/features/auth/presentation/pages/register_page.dart';
import 'package:teekoob/features/auth/presentation/pages/splash_page.dart';
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

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String books = '/books';
  static const String bookDetail = 'books/:id';
  static const String bookRead = 'books/:id/read';
  static const String library = '/library';
  static const String reader = 'reader/:id';
  static const String audioPlayer = '/player/:id';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  
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
    ],
    
    // Redirect logic for authentication
    redirect: (context, state) {
      // Add authentication logic here
      // For now, always allow access
      return null;
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
  
  // Replace current route
  static void replaceWithHome(BuildContext context) => context.go(home);
  static void replaceWithLogin(BuildContext context) => context.go(login);
}
