import 'package:flutter/material.dart';
import 'package:teekoob/core/services/localization_service.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  Locale _currentLocale = LocalizationService.defaultLocale;

  Locale get currentLocale => _currentLocale;
  
  String get currentLanguageCode => _currentLocale.languageCode;

  Future<void> changeLanguage(String languageCode) async {
    final newLocale = Locale(languageCode, languageCode == 'en' ? 'US' : 'SO');
    
    if (LocalizationService.supportedLocales.contains(newLocale)) {
      _currentLocale = newLocale;
      await LocalizationService.changeLocale(newLocale);
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    await LocalizationService.initialize();
    _currentLocale = LocalizationService.currentLocale;
    notifyListeners();
  }
}
