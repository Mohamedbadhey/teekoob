import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Removed - no local storage

// Events
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class LoadTheme extends ThemeEvent {}

class ChangeTheme extends ThemeEvent {
  final String theme;

  const ChangeTheme(this.theme);

  @override
  List<Object?> get props => [theme];
}

class LoadUserTheme extends ThemeEvent {
  final String themePreference;

  const LoadUserTheme(this.themePreference);

  @override
  List<Object?> get props => [themePreference];
}

// States
abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

class ThemeInitial extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final ThemeMode themeMode;
  final String themeString;

  const ThemeLoaded({
    required this.themeMode,
    required this.themeString,
  });

  @override
  List<Object?> get props => [themeMode, themeString];
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'app_theme';

  ThemeBloc() : super(const ThemeLoaded(themeMode: ThemeMode.system, themeString: 'system')) {
    on<LoadTheme>(_onLoadTheme);
    on<ChangeTheme>(_onChangeTheme);
    on<LoadUserTheme>(_onLoadUserTheme);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    try {
      // Note: No local storage - return default theme
      // final prefs = await SharedPreferences.getInstance();
      // Note: No local storage - return default theme
      final themeString = 'system';
      
      ThemeMode themeMode;
      switch (themeString) {
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          themeMode = ThemeMode.system;
          break;
      }

      emit(ThemeLoaded(
        themeMode: themeMode,
        themeString: themeString,
      ));
    } catch (e) {
      // Default to system theme if there's an error
      emit(const ThemeLoaded(
        themeMode: ThemeMode.system,
        themeString: 'system',
      ));
    }
  }

  Future<void> _onChangeTheme(ChangeTheme event, Emitter<ThemeState> emit) async {
    try {
      // Note: No local storage - return default theme
      // final prefs = await SharedPreferences.getInstance();
      // Note: No local storage - theme not saved locally
      // await prefs.setString(_themeKey, event.theme);

      ThemeMode themeMode;
      switch (event.theme) {
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          themeMode = ThemeMode.system;
          break;
      }

      emit(ThemeLoaded(
        themeMode: themeMode,
        themeString: event.theme,
      ));
    } catch (e) {
      // If there's an error, keep the current state
      if (state is ThemeLoaded) {
        emit(state);
      }
    }
  }

  Future<void> _onLoadUserTheme(LoadUserTheme event, Emitter<ThemeState> emit) async {
    try {
      final themeString = event.themePreference;
      
      ThemeMode themeMode;
      switch (themeString) {
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          themeMode = ThemeMode.system;
          break;
      }

      emit(ThemeLoaded(
        themeMode: themeMode,
        themeString: themeString,
      ));
    } catch (e) {
      // If there's an error, keep the current state
      if (state is ThemeLoaded) {
        emit(state);
      }
    }
  }
}
