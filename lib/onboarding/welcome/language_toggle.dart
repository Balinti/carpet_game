import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart' show LocaleProviderScope;
import 'onboarding_look.dart';

bool _defaultApplied = false;

/// Hebrew is the app's default language (`?lang=en` / `?lang=es` override).
///
/// Call once from the first onboarding screen's `initState`. Returns true
/// when it scheduled a language switch: the app then rebuilds from the top
/// in the new language, so the caller should wait instead of starting work.
/// Does nothing when there is no [LocaleProviderScope] (tests, debug app).
bool applyDefaultLanguageOnce(BuildContext context) {
  if (_defaultApplied) return false;
  _defaultApplied = true;
  final scope = context.getInheritedWidgetOfExactType<LocaleProviderScope>();
  if (scope == null) return false;
  final code = Uri.base.queryParameters['lang'];
  final want = code == null ? AppLanguage.hebrew : AppLanguage.fromCode(code);
  if (scope.provider.language == want) return false;
  WidgetsBinding.instance
      .addPostFrameCallback((_) => scope.provider.setLanguage(want));
  return true;
}

/// Small "עב | EN" switch for the welcome screens.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final l = OnboardingLook.current;
    final current = AppLocalizations.of(context).language;
    final scope = context.getInheritedWidgetOfExactType<LocaleProviderScope>();
    Widget option(AppLanguage lang, String label) {
      final on = current == lang;
      return Semantics(
        button: true,
        selected: on,
        child: InkWell(
          key: ValueKey('lang_${lang.code}'),
          borderRadius: BorderRadius.circular(20),
          onTap: on ? null : () => scope?.provider.setLanguage(lang),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: on ? l.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: on ? l.onAccent : l.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: l.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: l.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          // Always "עב" first, whatever the reading direction.
          textDirection: TextDirection.rtl,
          children: [
            option(AppLanguage.hebrew, 'עב'),
            option(AppLanguage.english, 'EN'),
          ],
        ),
      ),
    );
  }
}
