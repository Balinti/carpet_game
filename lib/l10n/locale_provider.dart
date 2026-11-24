import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Provider for managing the current locale/language.
class LocaleProvider extends ChangeNotifier {
  /// Hebrew by default; `?lang=en` (or es) in the URL overrides.
  AppLanguage _language = _initial();

  static AppLanguage _initial() {
    final code = Uri.base.queryParameters['lang'];
    return code == null ? AppLanguage.hebrew : AppLanguage.fromCode(code);
  }

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
