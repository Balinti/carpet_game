// Debug entry point to try the onboarding flow on its own (main.dart is
// untouched):
//
//   flutter run -d chrome -t lib/onboarding/debug_onboarding_main.dart
//   (add ?lang=he or ?lang=es to the URL for Hebrew / Spanish)
//
// Uses FakeAuthService with auto-verify, so "I confirmed" always succeeds.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import 'onboarding.dart';
import 'screens/onboarding_ui.dart';

void main() => runApp(const OnboardingDebugApp());

class OnboardingDebugApp extends StatefulWidget {
  const OnboardingDebugApp({super.key});

  @override
  State<OnboardingDebugApp> createState() => _OnboardingDebugAppState();
}

class _OnboardingDebugAppState extends State<OnboardingDebugApp> {
  final _auth = FakeAuthService(autoVerifyOnCheck: true);
  final _lang = AppLanguage.fromCode(Uri.base.queryParameters['lang'] ?? 'en');
  UserProfile? _profile;
  QuestionnaireResult? _result;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _lang.locale,
      supportedLocales: AppLanguage.values.map((l) => l.locale),
      localizationsDelegates: [
        AppLocalizationsDelegate(_lang),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _result == null
          ? OnboardingFlow(
              auth: _auth,
              onDone: (p, r) => setState(() {
                _profile = p;
                _result = r;
              }),
            )
          : OnboardingBackground(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_profile!.name} (${_profile!.age}, ${_profile!.ageGroup.name})',
                      style: const TextStyle(fontSize: 22),
                    ),
                    for (final e in _result!.scores.entries)
                      Text(
                        '${e.key.labelIn(_lang)}: ${e.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    Text(
                        'Primary: ${_result!.primaryBottleneck.labelIn(_lang)}',
                        style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
    );
  }
}
