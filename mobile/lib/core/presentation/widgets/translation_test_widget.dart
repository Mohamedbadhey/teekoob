import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/services/language_service.dart';

class TranslationTestWidget extends StatelessWidget {
  const TranslationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(LocalizationService.getSettingsText),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Language: ${languageService.currentLanguageCode}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                
                // Test various translations
                _buildTranslationTest(
                  context,
                  'App Name',
                  LocalizationService.getAppName,
                ),
                _buildTranslationTest(
                  context,
                  'Welcome Message',
                  LocalizationService.getWelcomeMessage,
                ),
                _buildTranslationTest(
                  context,
                  'Login Text',
                  LocalizationService.getLoginText,
                ),
                _buildTranslationTest(
                  context,
                  'Home Text',
                  LocalizationService.getHomeText,
                ),
                _buildTranslationTest(
                  context,
                  'Books Text',
                  LocalizationService.getBooksText,
                ),
                _buildTranslationTest(
                  context,
                  'Library Text',
                  LocalizationService.getLibraryText,
                ),
                _buildTranslationTest(
                  context,
                  'Settings Text',
                  LocalizationService.getSettingsText,
                ),
                
                const SizedBox(height: 30),
                
                // Language switching buttons
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => languageService.changeLanguage('en'),
                      child: const Text('Switch to English'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => languageService.changeLanguage('so'),
                      child: const Text('Switch to Somali'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTranslationTest(BuildContext context, String label, String translation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              translation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
