import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speedotrack/locale/lang/en.dart';
import 'package:speedotrack/locale/lang/fr.dart';

class TranslationService extends Translations {
  static Locale? get locale => Get.deviceLocale;
  static const fallbackLocale = Locale('en', 'US');
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': en_US,
        'fr_FR': fr_FR,
      };

  // ==========================================
  // TRACCAR API BACKEND TRANSLATION INTEGRATION
  // ==========================================

  /// Traccar `/api/session` ya `/api/users` response se user language sync karne ke liye helper
  static void syncWithTraccarUser(Map<String, dynamic> userJson) {
    if (userJson.containsKey('attributes') && userJson['attributes'] is Map) {
      final attrs = userJson['attributes'] as Map<String, dynamic>;
      final lang = attrs['userLanguage'] ?? userJson['lang'];
      if (lang != null && lang.toString().isNotEmpty) {
        changeLocaleByCode(lang.toString());
        return;
      }
    }
    
    if (userJson.containsKey('lang') && userJson['lang'] != null) {
      changeLocaleByCode(userJson['lang'].toString());
    }
  }

  /// Traccar server configuration (`/api/server`) se default language parse karna
  static Locale getTraccarServerLocale(Map<String, dynamic> serverJson) {
    if (serverJson.containsKey('attributes') && serverJson['attributes'] is Map) {
      final attrs = serverJson['attributes'] as Map<String, dynamic>;
      if (attrs.containsKey('language')) {
        return _parseLocale(attrs['language'].toString());
      }
    }
    return fallbackLocale;
  }

  /// App locale ko Traccar backend setting ke mutabiq switch karta hai
  static void changeLocaleByCode(String langCode) {
    final newLocale = _parseLocale(langCode);
    Get.updateLocale(newLocale);
  }

  static Locale _parseLocale(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'fr':
      case 'fr_fr':
      case 'french':
        return const Locale('fr', 'FR');
      case 'en':
      case 'en_us':
      case 'english':
      default:
        return const Locale('en', 'US');
    }
  }
}
