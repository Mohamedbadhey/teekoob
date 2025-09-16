import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:teekoob/features/settings/services/settings_service.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  final String userId;

  const LoadSettings(this.userId);

  @override
  List<Object> get props => [userId];
}

class UpdateLanguage extends SettingsEvent {
  final String userId;
  final String language;

  const UpdateLanguage(this.userId, this.language);

  @override
  List<Object> get props => [userId, language];
}

class UpdateTheme extends SettingsEvent {
  final String userId;
  final String theme;

  const UpdateTheme(this.userId, this.theme);

  @override
  List<Object> get props => [userId, theme];
}

class UpdateNotifications extends SettingsEvent {
  final String userId;
  final Map<String, bool> notificationSettings;

  const UpdateNotifications(this.userId, this.notificationSettings);

  @override
  List<Object> get props => [userId, notificationSettings];
}

class UpdateAutoDownload extends SettingsEvent {
  final String userId;
  final bool autoDownload;

  const UpdateAutoDownload(this.userId, this.autoDownload);

  @override
  List<Object> get props => [userId, autoDownload];
}

class UpdateFontSize extends SettingsEvent {
  final String userId;
  final double fontSize;

  const UpdateFontSize(this.userId, this.fontSize);

  @override
  List<Object> get props => [userId, fontSize];
}

class UpdateAudioSpeed extends SettingsEvent {
  final String userId;
  final double audioSpeed;

  const UpdateAudioSpeed(this.userId, this.audioSpeed);

  @override
  List<Object> get props => [userId, audioSpeed];
}

class UpdateOfflineMode extends SettingsEvent {
  final String userId;
  final bool offlineMode;

  const UpdateOfflineMode(this.userId, this.offlineMode);

  @override
  List<Object> get props => [userId, offlineMode];
}

class UpdateAudioQuality extends SettingsEvent {
  final String userId;
  final String audioQuality;

  const UpdateAudioQuality(this.userId, this.audioQuality);

  @override
  List<Object> get props => [userId, audioQuality];
}

class ClearCache extends SettingsEvent {
  final String userId;

  const ClearCache(this.userId);

  @override
  List<Object> get props => [userId];
}

class ExportSettings extends SettingsEvent {
  final String userId;

  const ExportSettings(this.userId);

  @override
  List<Object> get props => [userId];
}

class ImportSettings extends SettingsEvent {
  final String userId;
  final Map<String, dynamic> settingsData;

  const ImportSettings(this.userId, this.settingsData);

  @override
  List<Object> get props => [userId, settingsData];
}

class ResetSettings extends SettingsEvent {
  final String userId;

  const ResetSettings(this.userId);

  @override
  List<Object> get props => [userId];
}

class SetSetting extends SettingsEvent {
  final String userId;
  final String key;
  final dynamic value;

  const SetSetting(this.userId, this.key, this.value);

  @override
  List<Object?> get props => [userId, key, value];
}

class RemoveSetting extends SettingsEvent {
  final String userId;
  final String key;

  const RemoveSetting(this.userId, this.key);

  @override
  List<Object> get props => [userId, key];
}

class ForceSyncSettings extends SettingsEvent {
  final String userId;

  const ForceSyncSettings(this.userId);

  @override
  List<Object> get props => [userId];
}

// States
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final Map<String, dynamic> settings;
  final bool isSynced;

  const SettingsLoaded({
    required this.settings,
    required this.isSynced,
  });

  @override
  List<Object?> get props => [settings, isSynced];

  SettingsLoaded copyWith({
    Map<String, dynamic>? settings,
    bool? isSynced,
  }) {
    return SettingsLoaded(
      settings: settings ?? this.settings,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class SettingsOperationSuccess extends SettingsState {
  final String message;
  final String operation;

  const SettingsOperationSuccess({
    required this.message,
    required this.operation,
  });

  @override
  List<Object> get props => [message, operation];
}

class SettingsExportReady extends SettingsState {
  final Map<String, dynamic> exportData;

  const SettingsExportReady(this.exportData);

  @override
  List<Object> get props => [exportData];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService _settingsService;

  SettingsBloc({required SettingsService settingsService})
      : _settingsService = settingsService,
        super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateLanguage>(_onUpdateLanguage);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateNotifications>(_onUpdateNotifications);
    on<UpdateAutoDownload>(_onUpdateAutoDownload);
    on<UpdateFontSize>(_onUpdateFontSize);
    on<UpdateAudioSpeed>(_onUpdateAudioSpeed);
    on<UpdateOfflineMode>(_onUpdateOfflineMode);
    on<UpdateAudioQuality>(_onUpdateAudioQuality);
    on<ClearCache>(_onClearCache);
    on<ExportSettings>(_onExportSettings);
    on<ImportSettings>(_onImportSettings);
    on<ResetSettings>(_onResetSettings);
    on<SetSetting>(_onSetSetting);
    on<RemoveSetting>(_onRemoveSetting);
    on<ForceSyncSettings>(_onForceSyncSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());

      final settings = await _settingsService.loadSettings(event.userId);
      final isSynced = await _settingsService.areSettingsSynced(event.userId);

      emit(SettingsLoaded(
        settings: settings,
        isSynced: isSynced,
      ));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  Future<void> _onUpdateLanguage(
    UpdateLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.updateLanguage(event.userId, event.language);

      emit(const SettingsOperationSuccess(
        message: 'Language updated successfully',
        operation: 'language',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to update language: $e'));
    }
  }

  Future<void> _onUpdateTheme(
    UpdateTheme event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.updateTheme(event.userId, event.theme);

      emit(const SettingsOperationSuccess(
        message: 'Theme updated successfully',
        operation: 'theme',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to update theme: $e'));
    }
  }

  Future<void> _onUpdateNotifications(
    UpdateNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.updateNotifications(event.userId, event.notificationSettings);

      emit(const SettingsOperationSuccess(
        message: 'Notification settings updated successfully',
        operation: 'notifications',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to update notification settings: $e'));
    }
  }

  Future<void> _onUpdateAutoDownload(
    UpdateAutoDownload event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.updateAutoDownload(event.userId, event.autoDownload);

      emit(const SettingsOperationSuccess(
        message: 'Auto-download setting updated successfully',
        operation: 'autoDownload',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to update auto-download setting: $e'));
    }
  }

  Future<void> _onUpdateFontSize(
    UpdateFontSize event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.updateFontSize(event.userId, event.fontSize);

      emit(const SettingsOperationSuccess(
        message: 'Font size updated successfully',
        operation: 'fontSize',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to update font size: $e'));
    }
  }

  Future<void> _onUpdateAudioSpeed(
    UpdateAudioSpeed event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.updateAudioSpeed(event.userId, event.audioSpeed);

      emit(const SettingsOperationSuccess(
        message: 'Audio speed updated successfully',
        operation: 'audioSpeed',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to update audio speed: $e'));
    }
  }

  Future<void> _onUpdateOfflineMode(
    UpdateOfflineMode event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.updateOfflineMode(event.userId, event.offlineMode);

      emit(const SettingsOperationSuccess(
        message: 'Offline mode updated successfully',
        operation: 'offlineMode',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to update offline mode: $e'));
    }
  }

  Future<void> _onUpdateAudioQuality(
    UpdateAudioQuality event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.updateAudioQuality(event.userId, event.audioQuality);

      emit(const SettingsOperationSuccess(
        message: 'Audio quality updated successfully',
        operation: 'audioQuality',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to update audio quality: $e'));
    }
  }

  Future<void> _onClearCache(
    ClearCache event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.clearCache(event.userId);

      emit(const SettingsOperationSuccess(
        message: 'Cache cleared successfully',
        operation: 'clearCache',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to clear cache: $e'));
    }
  }

  Future<void> _onExportSettings(
    ExportSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final exportData = await _settingsService.exportSettings(event.userId);

      emit(SettingsExportReady(exportData));
    } catch (e) {
      emit(SettingsError('Failed to export settings: $e'));
    }
  }

  Future<void> _onImportSettings(
    ImportSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.importSettings(event.userId, event.settingsData);

      emit(const SettingsOperationSuccess(
        message: 'Settings imported successfully',
        operation: 'import',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to import settings: $e'));
    }
  }

  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.resetSettings(event.userId);

      emit(const SettingsOperationSuccess(
        message: 'Settings reset to defaults successfully',
        operation: 'reset',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to reset settings: $e'));
    }
  }

  Future<void> _onSetSetting(
    SetSetting event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.setSetting(event.userId, event.key, event.value);

      emit(const SettingsOperationSuccess(
        message: 'Setting updated successfully',
        operation: 'setSetting',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to set setting: $e'));
    }
  }

  Future<void> _onRemoveSetting(
    RemoveSetting event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsService.removeSetting(event.userId, event.key);

      emit(const SettingsOperationSuccess(
        message: 'Setting removed successfully',
        operation: 'removeSetting',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to remove setting: $e'));
    }
  }

  Future<void> _onForceSyncSettings(
    ForceSyncSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());

      await _settingsService.forceSyncSettings(event.userId);

      emit(const SettingsOperationSuccess(
        message: 'Settings synced successfully',
        operation: 'forceSync',
      ));

      // Reload settings
      add(LoadSettings(event.userId));
    } catch (e) {
      emit(SettingsError('Failed to force sync settings: $e'));
    }
  }

  // Helper methods for UI
  String getLanguage(String userId) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      return currentState.settings['language'] ?? 'en';
    }
    return 'en';
  }

  String getTheme(String userId) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      return currentState.settings['theme'] ?? 'system';
    }
    return 'system';
  }

  bool getAutoDownload(String userId) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      return currentState.settings['autoDownload'] ?? false;
    }
    return false;
  }

  double getFontSize(String userId) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      return currentState.settings['fontSize'] ?? 16.0;
    }
    return 16.0;
  }

  double getAudioSpeed(String userId) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      return currentState.settings['audioSpeed'] ?? 1.0;
    }
    return 1.0;
  }

  bool getOfflineMode(String userId) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      return currentState.settings['offlineMode'] ?? false;
    }
    return false;
  }

  String getAudioQuality(String userId) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      return currentState.settings['audioQuality'] ?? 'high';
    }
    return 'high';
  }

  Map<String, bool> getNotificationSettings(String userId) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final notifications = currentState.settings['notifications'];
      if (notifications is Map<String, bool>) {
        return notifications;
      }
    }
    return {
      'newReleases': true,
      'subscriptionRenewals': true,
      'personalizedRecommendations': true,
      'readingReminders': false,
      'achievements': true,
    };
  }

  bool isSettingEnabled(String userId, String key) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      return currentState.settings[key] == true;
    }
    return false;
  }

  T? getSettingValue<T>(String userId, String key, {T? defaultValue}) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final value = currentState.settings[key];
      if (value is T) {
        return value;
      }
    }
    return defaultValue;
  }
}
