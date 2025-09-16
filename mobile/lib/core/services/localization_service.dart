import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _languageCodeKey = 'language_code';
  static const String _countryCodeKey = 'country_code';
  
  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('so', 'SO'), // Somali
  ];
  
  // Default locale
  static const Locale defaultLocale = Locale('en', 'US');
  
  // Current locale
  static Locale _currentLocale = defaultLocale;
  
  // Get current locale
  static Locale get currentLocale => _currentLocale;
  
  // Get locale for MaterialApp
  static Locale get locale => _currentLocale;
  
  // Get current language code
  static String get currentLanguageCode => _currentLocale.languageCode;
  
  // Get current language (alias for currentLanguageCode)
  static String get currentLanguage => _currentLocale.languageCode;
  
  // Get current country code
  static String get currentCountryCode => _currentLocale.countryCode ?? '';
  
  // Localization delegates
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  
  // Initialize localization service
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageCodeKey);
    final savedCountry = prefs.getString(_countryCodeKey);
    
    if (savedLanguage != null) {
      _currentLocale = Locale(savedLanguage, savedCountry);
    }
  }
  
  // Change locale
  static Future<void> changeLocale(Locale newLocale) async {
    if (!supportedLocales.contains(newLocale)) {
      throw ArgumentError('Unsupported locale: $newLocale');
    }
    
    _currentLocale = newLocale;
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, newLocale.languageCode);
    if (newLocale.countryCode != null) {
      await prefs.setString(_countryCodeKey, newLocale.countryCode!);
    }
  }
  
  // Get localized text
  static String getLocalizedText({
    required String englishText,
    required String somaliText,
  }) {
    switch (_currentLocale.languageCode) {
      case 'so':
        return somaliText;
      case 'en':
      default:
        return englishText;
    }
  }
  
  // Get localized app name
  static String get getAppName {
    return getLocalizedText(
      englishText: 'Teekoob',
      somaliText: 'Teekoob',
    );
  }
  
  // Get localized app description
  static String get getAppDescription {
    return getLocalizedText(
      englishText: 'Multilingual eBook & Audiobook Platform',
      somaliText: 'Platformka Kitaabka iyo Kitaabka Codka ee Luqado Badan',
    );
  }
  
  // Get localized welcome message
  static String get getWelcomeMessage {
    return getLocalizedText(
      englishText: 'Welcome to Teekoob',
      somaliText: 'Ku soo dhowow Teekoob',
    );
  }
  
  // Get localized login text
  static String get getLoginText {
    return getLocalizedText(
      englishText: 'Login',
      somaliText: 'Gal',
    );
  }
  
  // Get localized register text
  static String get getRegisterText {
    return getLocalizedText(
      englishText: 'Register',
      somaliText: 'Diiwaan Geli',
    );
  }
  
  // Get localized email label
  static String get getEmailLabel {
    return getLocalizedText(
      englishText: 'Email',
      somaliText: 'Iimaylka',
    );
  }
  
  // Get localized password label
  static String get getPasswordLabel {
    return getLocalizedText(
      englishText: 'Password',
      somaliText: 'Furaha',
    );
  }
  
  // Get localized full name label
  static String get getFullNameLabel {
    return getLocalizedText(
      englishText: 'Full Name',
      somaliText: 'Magaca Buuxa',
    );
  }
  
  // Get localized confirm password label
  static String get getConfirmPasswordLabel {
    return getLocalizedText(
      englishText: 'Confirm Password',
      somaliText: 'Xaqiiji Furaha',
    );
  }
  
  // Get localized home text
  static String get getHomeText {
    return getLocalizedText(
      englishText: 'Home',
      somaliText: 'Guriga',
    );
  }
  
  // Get localized books text
  static String get getBooksText {
    return getLocalizedText(
      englishText: 'Books',
      somaliText: 'Kutubta',
    );
  }
  
  // Get localized library text
  static String get getLibraryText {
    return getLocalizedText(
      englishText: 'Library',
      somaliText: 'Maktabadda',
    );
  }
  
  // Get localized settings text
  static String get getSettingsText {
    return getLocalizedText(
      englishText: 'Settings',
      somaliText: 'Dejinta',
    );
  }
  
  // Get localized profile text
  static String get getProfileText {
    return getLocalizedText(
      englishText: 'Profile',
      somaliText: 'Profileka',
    );
  }
  
  // Get localized search text
  static String get getSearchText {
    return getLocalizedText(
      englishText: 'Search',
      somaliText: 'Raadi',
    );
  }
  
  // Get localized search hint
  static String get getSearchHint {
    return getLocalizedText(
      englishText: 'Search books, authors...',
      somaliText: 'Raadi kutubta, qoraayaal...',
    );
  }
  
  // Get localized read text
  static String get getReadText {
    return getLocalizedText(
      englishText: 'Read',
      somaliText: 'Akhrin',
    );
  }
  
  // Get localized listen text
  static String get getListenText {
    return getLocalizedText(
      englishText: 'Listen',
      somaliText: 'Dhegayso',
    );
  }
  
  // Get localized download text
  static String get getDownloadText {
    return getLocalizedText(
      englishText: 'Download',
      somaliText: 'Soo deji',
    );
  }
  
  // Get localized favorite text
  static String get getFavoriteText {
    return getLocalizedText(
      englishText: 'Favorite',
      somaliText: 'Ku xiisatay',
    );
  }
  
  // Get localized share text
  static String get getShareText {
    return getLocalizedText(
      englishText: 'Share',
      somaliText: 'Wadaag',
    );
  }
  
  // Get localized language text
  static String get getLanguageText {
    return getLocalizedText(
      englishText: 'Language',
      somaliText: 'Luuqadda',
    );
  }
  
  // Get localized theme text
  static String get getThemeText {
    return getLocalizedText(
      englishText: 'Theme',
      somaliText: 'Mawduuca',
    );
  }
  
  // Get localized notifications text
  static String get getNotificationsText {
    return getLocalizedText(
      englishText: 'Notifications',
      somaliText: 'Ogeysiinta',
    );
  }
  
  // Get localized about text
  static String get getAboutText {
    return getLocalizedText(
      englishText: 'About',
      somaliText: 'Ku saabsan',
    );
  }
  
  // Get localized help text
  static String get getHelpText {
    return getLocalizedText(
      englishText: 'Help',
      somaliText: 'Caawimaad',
    );
  }
  
  // Get localized logout text
  static String get getLogoutText {
    return getLocalizedText(
      englishText: 'Logout',
      somaliText: 'Ka bax',
    );
  }
  
  // Get localized cancel text
  static String get getCancelText {
    return getLocalizedText(
      englishText: 'Cancel',
      somaliText: 'Jooji',
    );
  }
  
  // Get localized save text
  static String get getSaveText {
    return getLocalizedText(
      englishText: 'Save',
      somaliText: 'Kaydi',
    );
  }
  
  // Get localized edit text
  static String get getEditText {
    return getLocalizedText(
      englishText: 'Edit',
      somaliText: 'Tafsiir',
    );
  }
  
  // Get localized delete text
  static String get getDeleteText {
    return getLocalizedText(
      englishText: 'Delete',
      somaliText: 'Tir',
    );
  }
  
  // Get localized yes text
  static String get getYesText {
    return getLocalizedText(
      englishText: 'Yes',
      somaliText: 'Haa',
    );
  }
  
  // Get localized no text
  static String get getNoText {
    return getLocalizedText(
      englishText: 'No',
      somaliText: 'Maya',
    );
  }
  
  // Get localized ok text
  static String get getOkText {
    return getLocalizedText(
      englishText: 'OK',
      somaliText: 'Hagaag',
    );
  }
  
  // Get localized error text
  static String get getErrorText {
    return getLocalizedText(
      englishText: 'Error',
      somaliText: 'Khalad',
    );
  }
  
  // Get localized success text
  static String get getSuccessText {
    return getLocalizedText(
      englishText: 'Success',
      somaliText: 'Guul',
    );
  }
  
  // Get localized warning text
  static String get getWarningText {
    return getLocalizedText(
      englishText: 'Warning',
      somaliText: 'Digniin',
    );
  }
  
  // Get localized info text
  static String get getInfoText {
    return getLocalizedText(
      englishText: 'Information',
      somaliText: 'Macluumaad',
    );
  }
  
  // Get localized retry text
  static String get getRetryText {
    return getLocalizedText(
      englishText: 'Retry',
      somaliText: 'Isku day mar kale',
    );
  }
  
  // Get localized load more text
  static String get getLoadMoreText {
    return getLocalizedText(
      englishText: 'Load More',
      somaliText: 'Soo deji dheeraad',
    );
  }
  
  // Get localized apply text
  static String get getApplyText {
    return getLocalizedText(
      englishText: 'Apply',
      somaliText: 'Codsii',
    );
  }
  
  // Get localized clear text
  static String get getClearText {
    return getLocalizedText(
      englishText: 'Clear',
      somaliText: 'Tir',
    );
  }
}
