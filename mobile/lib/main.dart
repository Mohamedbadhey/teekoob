import 'dart:async';
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
import 'package:teekoob/core/services/global_audio_player_service.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:teekoob/core/services/teekoob_audio_handler.dart';

// Global navigation key for accessing navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Prevent multiple calls to main()
  if (_mainCalled) {
    print('[AUDIO DEBUG] ⚠️ main() called multiple times, skipping...');
    return;
  }
  _mainCalled = true;
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Localization
    await LocalizationService.initialize();
    
    // AudioService will be initialized on-demand when user clicks play
    // This improves app startup time and only initializes when needed
    print('[AUDIO DEBUG] AudioService will be initialized on-demand when user clicks play');
    
    // DO NOT call markInitializing() here - it causes premature initialization
    // AudioService will only initialize when user actually plays audio
    
    // Now run the app
    print('[AUDIO DEBUG] Calling runApp()...');
    runApp(TeekoobApp());
    
    // Initialize Firebase notification service in background (non-blocking)
    _initializeFirebaseInBackground();
    
  } catch (e, stackTrace) {
    print('[AUDIO DEBUG] ❌ CRITICAL ERROR in main(): $e');
    print('[AUDIO DEBUG] Stack trace: $stackTrace');
    // Still run the app even if initialization fails
    if (!_mainCalled) {
    runApp(TeekoobApp());
    }
  }
}

// Static flag to prevent multiple main() calls
bool _mainCalled = false;

/// Initialize Firebase in background without blocking app startup
void _initializeFirebaseInBackground() async {
  try {
    // Skip Firebase initialization on web platform
    if (kIsWeb) {
      return;
    }
    
    final notificationService = FirebaseNotificationService();
    await notificationService.initialize();
    
    // Listen for notification taps (when app is in background/closed)
    notificationService.onMessageOpenedApp.listen((data) {
      print('🔔 📱 Notification tapped (background)! Data: $data');
      _handleNotificationTap(data);
    });
    
    // Listen for messages when app is in foreground
    notificationService.onMessage.listen((data) {
      print('🔔 📱 Message received (foreground)! Data: $data');
      // The local notification is already shown by the service
      // We can optionally handle tap on local notification here
    });
  } catch (e) {
    print('⚠️ Error initializing Firebase: $e');
  }
}

/// Handle notification tap and navigate to book
void _handleNotificationTap(Map<String, dynamic> data) {
  try {
    final bookId = data['bookId']?.toString();
    
    if (bookId != null && bookId.isNotEmpty) {
      print('🔔 📖 Navigating to book: $bookId');
      
      // Navigate using GoRouter
      AppRouter.router.go('/book/$bookId');
      print('🔔 ✅ Navigation successful!');
    } else {
      print('🔔 ⚠️ No bookId in notification data');
    }
  } catch (e) {
    print('🔔 ❌ Error handling notification tap: $e');
  }
}

/// Create notification service with fallback
NotificationServiceInterface _createNotificationService() {
  try {
    // Use stub implementation on web platform
    if (kIsWeb) {
      return FirebaseNotificationService(); // This will use the stub implementation
    }
    
    return FirebaseNotificationService();
  } catch (e) {
    return FallbackNotificationService();
  }
}

class TeekoobApp extends StatefulWidget {
  const TeekoobApp({super.key});

  @override
  State<TeekoobApp> createState() => _TeekoobAppState();
}

class _TeekoobAppState extends State<TeekoobApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Don't initialize audio service here - it will initialize on-demand when user clicks play
    // This improves app startup time and only initializes when needed
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app lifecycle changes for background audio
    final audioService = GlobalAudioPlayerService();
    audioService.handleAppLifecycleChange(state);
  }

  // Removed automatic initialization - audio service will initialize on-demand when user clicks play
  // This improves app startup time and only initializes when needed

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
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeService()),
            ChangeNotifierProvider(create: (context) => LanguageService()),
            ChangeNotifierProvider(create: (context) => GlobalAudioPlayerService()),
          ],
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              if (authState is Authenticated) {
                // Apply theme change after current frame to avoid setState during build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final userTheme = authState.user.preferences['theme'] ?? 'system';
                  final themeService = context.read<ThemeService>();
                  themeService.setThemeFromString(userTheme);
                });
              }
            },
            child: Consumer<LanguageService>(
              builder: (context, languageService, child) {
                return Consumer<ThemeService>(
                  builder: (context, themeService, child) {
                    return MaterialApp.router(
                      title: 'Bookdoon',
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
