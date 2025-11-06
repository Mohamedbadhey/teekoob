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

void main() async {
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Localization
    await LocalizationService.initialize();
    
    // CRITICAL: Initialize AudioService BEFORE runApp() to prevent old AudioPlayerService
    // from initializing it first. The old service is created when RepositoryProviders
    // are built, which happens synchronously during runApp().
    print('[AUDIO DEBUG] ========== STARTING EARLY AUDIO INITIALIZATION ==========');
    final audioHandlerCompleter = Completer<AudioHandler>();
    final globalService = GlobalAudioPlayerService();
    globalService.setAudioHandlerCompleter(audioHandlerCompleter);
    
    // Mark that we're initializing IMMEDIATELY (before any delay)
    // This prevents the old AudioPlayerService from trying to initialize
    print('[AUDIO DEBUG] Step 1: Marking as initializing...');
    GlobalAudioPlayerService.markInitializing();
    print('[AUDIO DEBUG] Step 2: Flag set, checking: ${GlobalAudioPlayerService.isInitializingAudioService}');
    
    // Initialize AudioService synchronously before runApp()
    // We need FlutterEngine to be ready, so we wait a bit after ensureInitialized
    try {
      print('[AUDIO DEBUG] Step 3: Waiting for FlutterEngine...');
      // Small delay to ensure FlutterEngine is ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('[AUDIO DEBUG] 🚀 Step 4: Initializing AudioService BEFORE runApp() to prevent conflicts...');
      await globalService.initializeAudioHandler();
      
      // Check both instance and static handler
      final audioHandler = globalService.audioHandler ?? GlobalAudioPlayerService.getGlobalHandler();
      print('[AUDIO DEBUG] Step 5: Initialization complete, handler: ${audioHandler != null}');
      print('[AUDIO DEBUG] Instance handler: ${globalService.audioHandler != null}');
      print('[AUDIO DEBUG] Static handler: ${GlobalAudioPlayerService.getGlobalHandler() != null}');
      if (audioHandler != null && !audioHandlerCompleter.isCompleted) {
        audioHandlerCompleter.complete(audioHandler);
        print('[AUDIO DEBUG] ✅ AudioService initialized successfully BEFORE runApp()!');
        print('[AUDIO DEBUG] ✅ Handler stored globally: ${GlobalAudioPlayerService.getGlobalHandler() != null}');
        print('[AUDIO DEBUG] ========== EARLY AUDIO INITIALIZATION SUCCESS ==========');
      } else {
        print('[AUDIO DEBUG] ⚠️ AudioService initialization - handler is null');
        print('[AUDIO DEBUG] ⚠️ Will retry after runApp() when FlutterEngine is ready');
        print('[AUDIO DEBUG] ========== EARLY AUDIO INITIALIZATION DEFERRED ==========');
      }
    } catch (e, stackTrace) {
      print('[AUDIO DEBUG] ❌ AudioService initialization failed: $e');
      print('[AUDIO DEBUG] Stack trace: $stackTrace');
      print('[AUDIO DEBUG] ========== EARLY AUDIO INITIALIZATION ERROR ==========');
      if (!audioHandlerCompleter.isCompleted) {
        audioHandlerCompleter.completeError(e);
      }
    }
    
    // Now run the app - AudioService is already initialized
    print('[AUDIO DEBUG] Step 6: Calling runApp()...');
    runApp(TeekoobApp());
    
    // Initialize Firebase notification service in background (non-blocking)
    _initializeFirebaseInBackground();
    
  } catch (e, stackTrace) {
    print('[AUDIO DEBUG] ❌ CRITICAL ERROR in main(): $e');
    print('[AUDIO DEBUG] Stack trace: $stackTrace');
    // Still run the app even if initialization fails
    runApp(TeekoobApp());
  }
}

/// Initialize Firebase in background without blocking app startup
void _initializeFirebaseInBackground() async {
  try {
    // Skip Firebase initialization on web platform
    if (kIsWeb) {
      return;
    }
    
    await FirebaseNotificationService().initialize();
  } catch (e) {
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
    
    // Initialize global audio service
    _initializeGlobalAudioService();
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

  Future<void> _initializeGlobalAudioService() async {
    try {
      // This is called AFTER runApp(), so FlutterEngine is definitely ready
      // If early initialization failed, retry here
      print('[AUDIO DEBUG] _initializeGlobalAudioService() called - FlutterEngine is ready');
      
      // Check if AudioService was already initialized
      final existingHandler = GlobalAudioPlayerService.getGlobalHandler();
      if (GlobalAudioPlayerService.isAudioServiceInitialized && existingHandler != null) {
        print('[AUDIO DEBUG] ✅ AudioService already initialized, handler exists');
        print('[AUDIO DEBUG] ✅ Handler type: ${existingHandler.runtimeType}');
        print('[AUDIO DEBUG] ✅ Using existing handler for background controls');
        // Make sure the instance also has the handler
        final service = GlobalAudioPlayerService();
        if (service.audioHandler == null) {
          print('[AUDIO DEBUG] Setting instance handler from global handler');
          // Directly set the handler - don't call initializeAudioHandler() as it will fail
          service.setAudioHandler(existingHandler);
          print('[AUDIO DEBUG] ✅ Instance handler set from global handler');
        } else {
          print('[AUDIO DEBUG] Instance handler already exists');
        }
        // Also call initialize() to set up audio player
        await GlobalAudioPlayerService().initialize();
        return;
      }
      
      // Wait a bit to ensure everything is ready
      await Future.delayed(const Duration(milliseconds: 300));
      
      print('[AUDIO DEBUG] Retrying AudioService initialization after runApp()...');
      await GlobalAudioPlayerService().initializeAudioHandler();
      
      final handler = GlobalAudioPlayerService.getGlobalHandler();
      if (handler != null) {
        print('[AUDIO DEBUG] ✅ AudioService initialized successfully after runApp()!');
        print('[AUDIO DEBUG] ✅ Handler stored: ${handler != null}');
      } else {
        print('[AUDIO DEBUG] ⚠️ AudioService initialization still failed after runApp()');
        print('[AUDIO DEBUG] ⚠️ Background controls will not be available');
      }
      
      // Also call initialize() to set up audio player
      await GlobalAudioPlayerService().initialize();
    } catch (e, stackTrace) {
      print('[AUDIO DEBUG] ⚠️ _initializeGlobalAudioService() error: $e');
      print('[AUDIO DEBUG] Stack trace: $stackTrace');
    }
  }

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
