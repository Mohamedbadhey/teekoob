import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  ThemeBloc() : super(ThemeInitial()) {
    on<LoadTheme>(_onLoadTheme);
    on<ChangeTheme>(_onChangeTheme);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey) ?? 'system';
      
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, event.theme);

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
}
