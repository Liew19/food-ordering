import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const String _prefsKey = 'language_code';

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Locale get locale => _locale;

  // Load saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      if (!kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final savedLanguage = prefs.getString(_prefsKey);

        if (savedLanguage != null) {
          _locale = Locale(savedLanguage);
          notifyListeners();
        }
      }
    } catch (e) {
      // Handle errors gracefully, especially for web platform
      debugPrint('Error loading language preferences: $e');
    }
  }

  // Change the language
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;

    try {
      if (!kIsWeb) {
        // Save to SharedPreferences (only for non-web platforms)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, locale.languageCode);
      }
    } catch (e) {
      debugPrint('Error saving language preferences: $e');
    }

    notifyListeners();
  }

  // Check if current language is English
  bool get isEnglish => _locale.languageCode == 'en';

  // Check if current language is Chinese
  bool get isChinese => _locale.languageCode == 'zh';
}
