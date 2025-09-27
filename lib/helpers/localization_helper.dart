import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livework_view/providers/language_provider.dart';

String translate(BuildContext context, String key) {
  try {
    // FIX: Use listen: false when we don't need to rebuild
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    return languageProvider.translate(key);
  } catch (e) {
    // Fallback if there's an error with translation
    print('Translation error for key "$key": $e');
    return key; // Return the key as fallback
  }
}
