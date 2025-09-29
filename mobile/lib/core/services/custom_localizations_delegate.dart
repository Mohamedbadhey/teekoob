import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class CustomLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const CustomLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support English and Somali
    return ['en', 'so'].contains(locale.languageCode);
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // For both English and Somali, use English MaterialLocalizations
    // This prevents the "No MaterialLocalizations found" error
    return GlobalMaterialLocalizations.delegate.load(const Locale('en', 'US'));
  }

  @override
  bool shouldReload(CustomLocalizationsDelegate old) => false;
}
