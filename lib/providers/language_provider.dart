import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('en', 'US');
  Map<String, String> _localizedStrings = {};
  bool _isLoading = false;

  Locale get currentLocale => _currentLocale;
  bool get isKurdish => _currentLocale.languageCode == 'ku';
  bool get isLoading => _isLoading;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('languageCode') ?? 'en';
      final countryCode = prefs.getString('countryCode') ?? 'US';

      print("Loading saved language: $languageCode, $countryCode");
      await loadLanguage(Locale(languageCode, countryCode));
    } catch (e) {
      print("Error loading saved language: $e");
      await loadLanguage(const Locale('en', 'US'));
    }
  }

  // UPDATED: lib/providers/language_provider.dart (loadLanguage method)
  Future<void> loadLanguage(Locale locale) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners(); // Notify listeners that loading started

    try {
      print("Attempting to load language: ${locale.languageCode}");

      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final languageAssetPath = 'assets/languages/${locale.languageCode}.json';

      if (!manifestMap.containsKey(languageAssetPath)) {
        print("Language file not found: $languageAssetPath");
        throw Exception("Language file not found");
      }

      String jsonString = await rootBundle.loadString(languageAssetPath);
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      _currentLocale = locale;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', locale.languageCode);
      await prefs.setString('countryCode', locale.countryCode ?? 'US');

      print("Language loaded successfully: ${locale.languageCode}");
      print("Available keys: ${_localizedStrings.keys.length}");
    } catch (e) {
      print("Error loading language file: $e");
      if (locale.languageCode != 'en') {
        print("Falling back to English");
        await loadLanguage(const Locale('en', 'US'));
      }
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that loading completed
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}
