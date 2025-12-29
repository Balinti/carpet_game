import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Provider for managing the current locale/language.
class LocaleProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;
  TextDirection get textDirection => _language.textDirection;
  bool get isRtl => _language.isRtl;

  void setLanguage(AppLanguage language) {
    if (_language != language) {
      _language = language;
      notifyListeners();
    }
  }
}
