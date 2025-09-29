import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class CustomWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const CustomWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support English and Somali
    return ['en', 'so'].contains(locale.languageCode);
  }

  @override
  Future<WidgetsLocalizations> load(Locale locale) async {
    // For both English and Somali, use English WidgetsLocalizations
    // This prevents localization errors
    return GlobalWidgetsLocalizations.delegate.load(const Locale('en', 'US'));
  }

  @override
  bool shouldReload(CustomWidgetsLocalizationsDelegate old) => false;
}
