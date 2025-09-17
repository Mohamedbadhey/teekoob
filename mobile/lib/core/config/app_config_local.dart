// Local Development Configuration
// Use this for local development with Railway backend

class AppConfigLocal {
  // Base URL for API endpoints - Railway Production
  static const String baseUrl = 'https://teekoob-production.up.railway.app/api/v1';
  static const String apiVersion = 'v1';
  
  // Base URL for media files (images, audio, etc.)
  static const String mediaBaseUrl = 'https://teekoob-production.up.railway.app';
  
  // App Information
  static const String appName = 'Teekoob';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Development Settings
  static const bool isDevelopment = true;
  static const bool enableDebugLogs = true;
  
  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  
  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Download Configuration
  static const int maxConcurrentDownloads = 3;
  static const Duration downloadTimeout = Duration(minutes: 30);
  
  // Audio Configuration
  static const List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const double defaultPlaybackSpeed = 1.0;
  
  // Reader Configuration
  static const List<double> fontSizes = [12, 14, 16, 18, 20, 22, 24, 26, 28];
  static const double defaultFontSize = 16.0;
  static const List<double> lineHeights = [1.0, 1.2, 1.4, 1.6, 1.8, 2.0];
  static const double defaultLineHeight = 1.4;
  
  // Theme Configuration
  static const List<String> availableThemes = ['light', 'dark', 'sepia', 'night'];
  static const String defaultTheme = 'light';
  
  // Language Configuration
  static const List<String> supportedLanguages = ['en', 'so'];
  static const String defaultLanguage = 'en';
}
