import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/config/app_router.dart';
import 'package:teekoob/core/config/app_theme.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/services/storage_service.dart';

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
import 'package:teekoob/core/bloc/theme_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Localization
  await LocalizationService.initialize();
  
  // Initialize Storage Service
  final storageService = StorageService();
  await storageService.initialize();
  
  runApp(TeekoobApp(storageService: storageService));
}

class TeekoobApp extends StatelessWidget {
  final StorageService storageService;
  
  const TeekoobApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<StorageService>(
              create: (context) => storageService,
            ),
            RepositoryProvider<AuthService>(
              create: (context) => AuthService(
                storageService: context.read<StorageService>(),
              ),
            ),
            RepositoryProvider<BooksService>(
              create: (context) => BooksService(
                storageService: context.read<StorageService>(),
              ),
            ),
            RepositoryProvider<LibraryService>(
              create: (context) => LibraryService(
                storageService: context.read<StorageService>(),
              ),
            ),
            RepositoryProvider<AudioPlayerService>(
              create: (context) => AudioPlayerService(),
            ),
            RepositoryProvider<ReaderService>(
              create: (context) => ReaderService(
                storageService: context.read<StorageService>(),
              ),
            ),
            RepositoryProvider<SettingsService>(
              create: (context) => SettingsService(
                storageService: context.read<StorageService>(),
              ),
            ),
            RepositoryProvider<SubscriptionService>(
              create: (context) => SubscriptionService(
                storageService: context.read<StorageService>(),
              ),
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
              BlocProvider<ThemeBloc>(
                create: (context) => ThemeBloc()..add(LoadTheme()),
              ),
            ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            ThemeMode themeMode = ThemeMode.system;
            
            if (themeState is ThemeLoaded) {
              themeMode = themeState.themeMode;
            }
            
            return MaterialApp.router(
              title: 'Teekoob',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              routerConfig: AppRouter.router,
              localizationsDelegates: LocalizationService.localizationsDelegates,
              supportedLocales: LocalizationService.supportedLocales,
              locale: LocalizationService.locale,
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}
