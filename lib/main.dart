// hi
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/l10n.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
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
        key: ValueKey(_localeProvider.language),
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
            child: _RotatePhoneGate(child: child!),
          );
        },
        home: HomeScreen(key: ValueKey(_localeProvider.language)),
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

/// On phones held upright, covers the game with a "turn your phone sideways"
/// message. Browsers ignore orientation locks, so this is the web fallback.
/// The game stays mounted underneath, so no progress is lost.
class _RotatePhoneGate extends StatefulWidget {
  final Widget child;

  const _RotatePhoneGate({required this.child});

  @override
  State<_RotatePhoneGate> createState() => _RotatePhoneGateState();
}

class _RotatePhoneGateState extends State<_RotatePhoneGate> {
  // Lets players with rotation lock on (or browsers that don't rotate) get in.
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isPhonePortrait =
        !_dismissed && size.height > size.width && size.shortestSide < 600;
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        widget.child,
        if (isPhonePortrait)
          Positioned.fill(
            child: Material(
              color: colors.surface,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.screen_rotation,
                            size: 96, color: colors.primary),
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context).rotatePhone,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 32),
                        TextButton(
                          onPressed: () => setState(() => _dismissed = true),
                          child: Text(AppLocalizations.of(context).playAnyway),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
