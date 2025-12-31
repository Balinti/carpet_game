import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/l10n.dart';
import 'screens/grid_selection_screen.dart';

void main() {
  runApp(const CarpetGameApp());
}

class CarpetGameApp extends StatefulWidget {
  const CarpetGameApp({super.key});

  @override
  State<CarpetGameApp> createState() => _CarpetGameAppState();
}

class _CarpetGameAppState extends State<CarpetGameApp> {
  final LocaleProvider _localeProvider = LocaleProvider();

  @override
  void initState() {
    super.initState();
    _localeProvider.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeProvider.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LocaleProviderScope(
      provider: _localeProvider,
      child: MaterialApp(
        title: 'Carpet Game',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        locale: _localeProvider.locale,
        supportedLocales: AppLanguage.values.map((l) => l.locale),
        localizationsDelegates: [
          AppLocalizationsDelegate(_localeProvider.language),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: _localeProvider.textDirection,
            child: child!,
          );
        },
        home: const GridSelectionScreen(),
      ),
    );
  }
}

/// InheritedWidget to provide LocaleProvider to descendants.
class LocaleProviderScope extends InheritedWidget {
  final LocaleProvider provider;

  const LocaleProviderScope({
    super.key,
    required this.provider,
    required super.child,
  });

  static LocaleProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleProviderScope>();
    return scope!.provider;
  }

  @override
  bool updateShouldNotify(LocaleProviderScope oldWidget) {
    // Always notify - the parent setState already triggered a rebuild,
    // and we need dependents to update with the new language
    return true;
  }
}
