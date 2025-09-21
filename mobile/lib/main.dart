import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/config/app_router.dart';
import 'package:teekoob/core/config/app_theme.dart';
import 'package:teekoob/core/services/localization_service.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Localization
  await LocalizationService.initialize();
  
  runApp(TeekoobApp());
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
