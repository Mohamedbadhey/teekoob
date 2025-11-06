import 'package:teekoob/core/services/network_service.dart';

class SettingsService {
  final NetworkService _networkService;

  SettingsService() : _networkService = NetworkService() {
    _networkService.initialize();
  }

  // Load all settings for a user
  Future<Map<String, dynamic>> loadSettings(String userId) async {
    // Note: No local storage - return default settings
    return _getDefaultSettings();
  }

  // Update language setting
  Future<void> updateLanguage(String userId, String language) async {
    try {
      // Note: No local storage - settings not saved locally

      // Sync with server if online
      try {
        await _networkService.put('/user/settings', data: {
          'userId': userId,
          'language': language,
        });
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to update language: $e');
    }
  }

  // Update theme setting
  Future<void> updateTheme(String userId, String theme) async {
    try {
      // Note: No local storage - settings not saved locally

      // Sync with server if online
      try {
        await _networkService.put('/user/settings', data: {
          'userId': userId,
          'theme': theme,
        });
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to update theme: $e');
    }
  }

  // Update notification settings
  Future<void> updateNotifications(String userId, Map<String, bool> notificationSettings) async {
    try {
      // Note: No local storage - settings not saved locally

      // Sync with server if online
      try {
        await _networkService.put('/user/settings', data: {
          'userId': userId,
          'notifications': notificationSettings,
        });
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to update notification settings: $e');
    }
  }

  // Update auto-download setting
  Future<void> updateAutoDownload(String userId, bool autoDownload) async {
    try {
      // Note: No local storage - settings not saved locally

      // Sync with server if online
      try {
        await _networkService.put('/user/settings', data: {
          'userId': userId,
          'autoDownload': autoDownload,
        });
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to update auto-download setting: $e');
    }
  }

  // Update font size setting
  Future<void> updateFontSize(String userId, double fontSize) async {
    try {
      // Note: No local storage - settings not saved locally

      // Sync with server if online
      try {
        await _networkService.put('/user/settings', data: {
          'userId': userId,
          'fontSize': fontSize,
        });
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to update font size: $e');
    }
  }

  // Update audio speed setting
  Future<void> updateAudioSpeed(String userId, double audioSpeed) async {
    try {
      // Note: No local storage - settings not saved locally

      // Sync with server if online
      try {
        await _networkService.put('/user/settings', data: {
          'userId': userId,
          'audioSpeed': audioSpeed,
        });
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to update audio speed: $e');
    }
  }

  // Update offline mode setting
  Future<void> updateOfflineMode(String userId, bool offlineMode) async {
    try {
      // Note: No local storage - settings not saved locally

      // Sync with server if online
      try {
        await _networkService.put('/user/settings', data: {
          'userId': userId,
          'offlineMode': offlineMode,
        });
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to update offline mode: $e');
    }
  }

  // Update audio quality setting
  Future<void> updateAudioQuality(String userId, String audioQuality) async {
    try {
      // Note: No local storage - settings not saved locally

      // Sync with server if online
      try {
        await _networkService.put('/user/settings', data: {
          'userId': userId,
          'audioQuality': audioQuality,
        });
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to update audio quality: $e');
    }
  }

  // Clear cache
  Future<void> clearCache(String userId) async {
    try {
      // Note: No local storage - cache not cleared locally

      // Sync with server if online
      try {
        await _networkService.put('/user/settings', data: {
          'userId': userId,
          'lastCacheClear': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  // Export settings
  Future<Map<String, dynamic>> exportSettings(String userId) async {
    try {
      // Note: No local storage - return default settings
      final settings = _getDefaultSettings();
      return {
        'userId': userId,
        'exportedAt': DateTime.now().toIso8601String(),
        'settings': settings,
      };
    } catch (e) {
      throw Exception('Failed to export settings: $e');
    }
  }

  // Import settings
  Future<void> importSettings(String userId, Map<String, dynamic> settingsData) async {
    try {
      if (settingsData['settings'] != null) {
        final settings = Map<String, dynamic>.from(settingsData['settings']);
        
        // Validate settings before importing
        _validateSettings(settings);
        
        // Import settings
        // Note: No local storage - settings not saved locally

        // Sync with server if online
        try {
          await _networkService.put('/user/settings', data: {
            'userId': userId,
            'settings': settings,
          });
        } catch (e) {
          // Continue offline if sync fails
        }
      }
    } catch (e) {
      throw Exception('Failed to import settings: $e');
    }
  }

  // Reset settings to defaults
  Future<void> resetSettings(String userId) async {
    try {
      final defaultSettings = _getDefaultSettings();
      // Note: No local storage - settings not saved locally

      // Sync with server if online
      try {
        await _networkService.put('/user/settings', data: {
          'userId': userId,
          'settings': defaultSettings,
        });
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to reset settings: $e');
    }
  }

  // Get default settings
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'language': 'en',
      'theme': 'system',
      'notifications': {
        'newReleases': true,
        'subscriptionRenewals': true,
        'personalizedRecommendations': true,
        'readingReminders': false,
        'achievements': true,
      },
      'autoDownload': false,
      'fontSize': 16.0,
      'fontFamily': 'Roboto',
      'lineHeight': 1.5,
      'readingTheme': 'light',
      'backgroundColor': '#FFFFFF',
      'textColor': '#000000',
      'margin': 16.0,
      'justifyText': true,
      'audioSpeed': 1.0,
      'offlineMode': false,
      'audioQuality': 'high',
      'lastCacheClear': null,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Validate settings before importing
  void _validateSettings(Map<String, dynamic> settings) {
    // Validate language
    if (settings['language'] != null && !['en', 'so'].contains(settings['language'])) {
      throw Exception('Invalid language setting');
    }

    // Validate theme
    if (settings['theme'] != null && !['light', 'dark', 'system'].contains(settings['theme'])) {
      throw Exception('Invalid theme setting');
    }

    // Validate font size
    if (settings['fontSize'] != null && (settings['fontSize'] < 8.0 || settings['fontSize'] > 32.0)) {
      throw Exception('Invalid font size setting');
    }

    // Validate audio speed
    if (settings['audioSpeed'] != null && (settings['audioSpeed'] < 0.5 || settings['audioSpeed'] > 2.0)) {
      throw Exception('Invalid audio speed setting');
    }

    // Validate audio quality
    if (settings['audioQuality'] != null && !['low', 'medium', 'high'].contains(settings['audioQuality'])) {
      throw Exception('Invalid audio quality setting');
    }
  }

  // Get specific setting value
  T? getSetting<T>(String userId, String key, {T? defaultValue}) {
    try {
      // Note: No local storage - return default settings
      final settings = _getDefaultSettings();
      final value = settings[key];
      
      if (value != null && value is T) {
        return value;
      }
      
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  // Set specific setting value
  Future<void> setSetting<T>(String userId, String key, T value) async {
    try {
      // Note: No local storage - return default settings
      final currentSettings = _getDefaultSettings();
      currentSettings[key] = value;
      currentSettings['updatedAt'] = DateTime.now().toIso8601String();
      
      // Note: No local storage - settings not saved locally

      // Sync with server if online
      try {
        await _networkService.put('/user/settings', data: {
          'userId': userId,
          'key': key,
          'value': value,
        });
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to set setting: $e');
    }
  }

  // Check if a setting exists
  bool hasSetting(String userId, String key) {
    try {
      // Note: No local storage - return default settings
      final settings = _getDefaultSettings();
      return settings.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  // Remove a setting
  Future<void> removeSetting(String userId, String key) async {
    try {
      // Note: No local storage - return default settings
      final currentSettings = _getDefaultSettings();
      currentSettings.remove(key);
      currentSettings['updatedAt'] = DateTime.now().toIso8601String();
      
      // Note: No local storage - settings not saved locally

      // Sync with server if online
      try {
        await _networkService.delete('/user/settings/$key');
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to remove setting: $e');
    }
  }

  // Get all settings keys
  List<String> getSettingsKeys(String userId) {
    try {
      // Note: No local storage - return default settings
      final settings = _getDefaultSettings();
      return settings.keys.toList();
    } catch (e) {
      return [];
    }
  }

  // Get settings count
  int getSettingsCount(String userId) {
    try {
      // Note: No local storage - return default settings
      final settings = _getDefaultSettings();
      return settings.length;
    } catch (e) {
      return 0;
    }
  }

  // Check if settings are synced with server
  Future<bool> areSettingsSynced(String userId) async {
    try {
      // Note: No local storage - return default settings
      final localSettings = _getDefaultSettings();
      final lastUpdated = localSettings['updatedAt'];
      
      if (lastUpdated == null) return false;

      // Try to get server settings to check sync status
      try {
        final response = await _networkService.get('/user/settings/$userId');
        if (response.statusCode == 200) {
          final serverSettings = response.data['settings'];
          final serverLastUpdated = serverSettings['updatedAt'];
          
          return lastUpdated == serverLastUpdated;
        }
      } catch (e) {
        // If we can't reach server, assume not synced
        return false;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Force sync settings with server
  Future<void> forceSyncSettings(String userId) async {
    try {
      // Note: No local storage - return default settings
      final localSettings = _getDefaultSettings();
      
      // Send all local settings to server
      await _networkService.put('/user/settings', data: {
        'userId': userId,
        'settings': localSettings,
        'forceSync': true,
      });
      
      // Update local timestamp
      localSettings['updatedAt'] = DateTime.now().toIso8601String();
      // Note: No local storage - settings not saved locally
      
    } catch (e) {
      throw Exception('Failed to force sync settings: $e');
    }
  }
}
