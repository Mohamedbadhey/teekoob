class AppConfig {
  // Base URL for API endpoints
  static const String baseUrl = 'https://teekoob-production.up.railway.app/api/v1';
  static const String apiVersion = 'v1';
  
  // Base URL for media files (images, audio, etc.)
  static const String mediaBaseUrl = 'https://teekoob-production.up.railway.app';
  
  // App Information
  static const String appName = 'Teekoob';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Google OAuth Configuration
  // Web client ID - for web platform
  static const String googleWebClientId = '4861039733-db4ode2aiqps85n3t116i4eabvjrnur7.apps.googleusercontent.com';
  
  // Android client ID - for Android platform
  static const String googleAndroidClientId = '4861039733-11kdgmdpdi7anir3bpl14orven45hlhq.apps.googleusercontent.com';
  
  // iOS client ID - for iOS platform  
  static const String googleIOSClientId = '4861039733-hmccm6ifr07kcbk2al0a22f85f57svf8.apps.googleusercontent.com';
  
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
  
  // Subscription Plans
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    'free': {
      'name': 'Free',
      'nameSomali': 'Bilaash',
      'price': 0.0,
      'currency': 'USD',
      'features': ['Access to free books', 'Basic features'],
      'featuresSomali': ['Helitaanka kutubta bilaashka ah', 'Astaamaha aasaasiga ah'],
    },
    'premium_monthly': {
      'name': 'Premium Monthly',
      'nameSomali': 'Premium Bilaha',
      'price': 9.99,
      'currency': 'USD',
      'features': [
        'Access to all books',
        'Audiobooks',
        'Offline downloads',
        'Priority support'
      ],
      'featuresSomali': [
        'Helitaanka dhammaan kutubta',
        'Kutubta codka',
        'Soo dejinta offline',
        'Taageerada mudan'
      ],
    },
    'premium_yearly': {
      'name': 'Premium Yearly',
      'nameSomali': 'Premium Sanadka',
      'price': 99.99,
      'currency': 'USD',
      'features': [
        'Access to all books',
        'Audiobooks',
        'Offline downloads',
        'Priority support',
        '2 months free'
      ],
      'featuresSomali': [
        'Helitaanka dhammaan kutubta',
        'Kutubta codka',
        'Soo dejinta offline',
        'Taageerada mudan',
        '2 bilood oo bilaash'
      ],
    },
    'lifetime': {
      'name': 'Lifetime',
      'nameSomali': 'Nololka oo dhammeystiran',
      'price': 299.99,
      'currency': 'USD',
      'features': [
        'Access to all books forever',
        'Audiobooks',
        'Offline downloads',
        'Priority support',
        'Future updates included'
      ],
      'featuresSomali': [
        'Helitaanka dhammaan kutubta weligeed',
        'Kutubta codka',
        'Soo dejinta offline',
        'Taageerada mudan',
        'Cusbooneysiinta mustaqbalka oo ku jira'
      ],
    },
  };
  
  // File Extensions
  static const List<String> supportedEbookFormats = ['epub', 'pdf'];
  static const List<String> supportedAudioFormats = ['mp3', 'm4a', 'aac'];
  
  // Error Messages
  static const Map<String, String> errorMessages = {
    'network_error': 'Network error. Please check your connection.',
    'network_error_somali': 'Khaladka shabakadda. Fadlan hubi xiriirkaaga.',
    'server_error': 'Server error. Please try again later.',
    'server_error_somali': 'Khaladka serverka. Fadlan isku day mar kale.',
    'unauthorized': 'Unauthorized. Please login again.',
    'unauthorized_somali': 'Oggolaansho la\'aan. Fadlan mar kale gal.',
    'forbidden': 'Access forbidden.',
    'forbidden_somali': 'Helitaanka waa la mamnuucay.',
    'not_found': 'Resource not found.',
    'not_found_somali': 'Hantida lama helin.',
    'validation_error': 'Validation error. Please check your input.',
    'validation_error_somali': 'Khaladka xaqiijinta. Fadlan hubi gelitaankaaga.',
    'unknown_error': 'An unknown error occurred.',
    'unknown_error_somali': 'Khalad aan la aqoon ayaa dhacay.',
  };
  
  // Success Messages
  static const Map<String, String> successMessages = {
    'login_success': 'Login successful!',
    'login_success_somali': 'Galitaanka waa guulaystay!',
    'register_success': 'Registration successful!',
    'register_success_somali': 'Diiwaangelinta waa guulaystay!',
    'logout_success': 'Logout successful!',
    'logout_success_somali': 'Ka bixitaanka waa guulaystay!',
    'book_added_library': 'Book added to library!',
    'book_added_library_somali': 'Kitaabka waa la daray maktabadda!',
    'book_removed_library': 'Book removed from library!',
    'book_removed_library_somali': 'Kitaabka waa la ka saaray maktabadda!',
    'download_started': 'Download started!',
    'download_started_somali': 'Soo dejinta waa la bilaabay!',
    'download_completed': 'Download completed!',
    'download_completed_somali': 'Soo dejinta waa la dhammeeyay!',
    'settings_saved': 'Settings saved!',
    'settings_saved_somali': 'Dejinta waa la kaydiyay!',
  };
  
  // Animation Durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration buttonPressDuration = Duration(milliseconds: 100);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 2.0;
  
  // Search Configuration
  static const int minSearchLength = 2;
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const int maxSearchResults = 50;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Rate Limiting
  static const int maxApiCallsPerMinute = 60;
  static const int maxDownloadAttempts = 3;
  
  // Security
  static const int passwordMinLength = 8;
  static const bool requireSpecialCharacters = true;
  static const bool requireNumbers = true;
  static const bool requireUppercase = true;
  
  // Analytics Events
  static const Map<String, String> analyticsEvents = {
    'app_opened': 'app_opened',
    'user_login': 'user_login',
    'user_register': 'user_register',
    'book_viewed': 'book_viewed',
    'book_read': 'book_read',
    'book_listened': 'book_listened',
    'book_downloaded': 'book_downloaded',
    'search_performed': 'search_performed',
    'subscription_purchased': 'subscription_purchased',
    'settings_changed': 'settings_changed',
  };
}
