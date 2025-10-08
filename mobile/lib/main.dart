import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/config/app_router.dart';
import 'package:teekoob/core/config/app_theme.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/services/language_service.dart';
import 'package:teekoob/core/services/theme_service.dart';
import 'package:flutter/foundation.dart';

// Firebase notification service
import 'package:teekoob/core/services/firebase_notification_service.dart';
import 'package:teekoob/core/services/fallback_notification_service.dart';
import 'package:teekoob/core/services/notification_service_interface.dart';

import 'package:teekoob/features/auth/services/auth_service.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';
import 'package:teekoob/features/books/services/books_service.dart';
import 'package:teekoob/features/books/bloc/books_bloc.dart';
import 'package:teekoob/features/library/services/library_service.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';
import 'package:teekoob/features/player/services/audio_player_service.dart';
import 'package:teekoob/features/player/bloc/audio_player_bloc.dart';
import 'package:teekoob/features/reader/services/reader_service.dart';
import 'package:teekoob/features/reader/bloc/reader_bloc.dart';
import 'package:teekoob/features/settings/services/settings_service.dart';
import 'package:teekoob/features/settings/bloc/settings_bloc.dart';
import 'package:teekoob/features/subscription/services/subscription_service.dart';
import 'package:teekoob/features/subscription/bloc/subscription_bloc.dart';
import 'package:teekoob/core/bloc/notification_bloc.dart';
import 'package:teekoob/features/podcasts/services/podcasts_service.dart';
import 'package:teekoob/features/podcasts/bloc/podcasts_bloc.dart';

void main() async {
  print('🚀 ===== APP STARTUP =====');
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('🚀 WidgetsFlutterBinding initialized');
    
    // Initialize Localization
    print('🚀 Initializing Localization...');
    await LocalizationService.initialize();
    print('🚀 ✅ Localization initialized');
    
    print('🚀 Starting TeekoobApp...');
    runApp(TeekoobApp());
    
    // Initialize Firebase notification service in background (non-blocking)
    print('🚀 Initializing Firebase Notification Service in background...');
    _initializeFirebaseInBackground();
    
    print('🚀 ===== APP STARTUP COMPLETE =====');
  } catch (e) {
    print('🚀 ❌ Critical startup error: $e');
    print('🚀 Starting app anyway...');
    runApp(TeekoobApp());
  }
}

/// Initialize Firebase in background without blocking app startup
void _initializeFirebaseInBackground() async {
  try {
    await FirebaseNotificationService().initialize();
    print('🚀 ✅ Firebase Notification Service initialized successfully');
  } catch (e) {
    print('🚀 ❌ Firebase initialization failed, app will continue without notifications: $e');
  }
}

/// Create notification service with fallback
NotificationServiceInterface _createNotificationService() {
  try {
    return FirebaseNotificationService();
  } catch (e) {
    print('🚀 ⚠️ Using fallback notification service due to Firebase error: $e');
    return FallbackNotificationService();
  }
}

class TeekoobApp extends StatelessWidget {
  const TeekoobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthService>(
              create: (context) => AuthService(),
            ),
            RepositoryProvider<BooksService>(
              create: (context) => BooksService(),
            ),
            RepositoryProvider<LibraryService>(
              create: (context) => LibraryService(),
            ),
            RepositoryProvider<AudioPlayerService>(
              create: (context) => AudioPlayerService(),
            ),
            RepositoryProvider<ReaderService>(
              create: (context) => ReaderService(),
            ),
            RepositoryProvider<SettingsService>(
              create: (context) => SettingsService(),
            ),
            RepositoryProvider<SubscriptionService>(
              create: (context) => SubscriptionService(),
            ),
            RepositoryProvider<NotificationServiceInterface>(
              create: (context) => _createNotificationService(),
            ),
            RepositoryProvider<PodcastsService>(
              create: (context) => PodcastsService(),
            ),
          ],
                child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>(
                create: (context) => AuthBloc(
                  authService: context.read<AuthService>(),
                ),
              ),
              BlocProvider<BooksBloc>(
                create: (context) => BooksBloc(
                  booksService: context.read<BooksService>(),
                ),
              ),
              BlocProvider<LibraryBloc>(
                create: (context) => LibraryBloc(
                  libraryService: context.read<LibraryService>(),
                ),
              ),
              BlocProvider<AudioPlayerBloc>(
                create: (context) => AudioPlayerBloc(
                  audioPlayerService: context.read<AudioPlayerService>(),
                ),
              ),
              BlocProvider<ReaderBloc>(
                create: (context) => ReaderBloc(
                  readerService: context.read<ReaderService>(),
                ),
              ),
              BlocProvider<SettingsBloc>(
                create: (context) => SettingsBloc(
                  settingsService: context.read<SettingsService>(),
                ),
              ),
              BlocProvider<SubscriptionBloc>(
                create: (context) => SubscriptionBloc(
                  subscriptionService: context.read<SubscriptionService>(),
                ),
              ),
              BlocProvider<NotificationBloc>(
                create: (context) => NotificationBloc(
                  notificationService: context.read<NotificationServiceInterface>(),
                ),
              ),
              BlocProvider<PodcastsBloc>(
                create: (context) => PodcastsBloc(
                  podcastsService: context.read<PodcastsService>(),
                ),
              ),
            ],
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState is Authenticated) {
              // Load user's theme preference when authenticated
              final userTheme = authState.user.preferences['theme'] ?? 'system';
              final themeService = context.read<ThemeService>();
              themeService.setThemeFromString(userTheme);
            }
          },
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => ThemeService()),
              ChangeNotifierProvider(create: (context) => LanguageService()),
            ],
            child: Consumer<LanguageService>(
              builder: (context, languageService, child) {
                return Consumer<ThemeService>(
                  builder: (context, themeService, child) {
                    print('🎨 Main: Consumer rebuild - current theme: ${themeService.currentTheme}, language: ${languageService.currentLanguageCode}');
                    return MaterialApp.router(
                      title: 'Teekoob',
                      theme: AppTheme.lightTheme,
                      darkTheme: AppTheme.darkTheme,
                      themeMode: themeService.currentTheme,
                      routerConfig: AppRouter.router,
                      localizationsDelegates: LocalizationService.localizationsDelegates,
                      supportedLocales: LocalizationService.supportedLocales,
                      locale: languageService.currentLocale,
                      debugShowCheckedModeBanner: false,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
