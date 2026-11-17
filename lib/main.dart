// hi
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/l10n.dart';
import 'screens/home_screen.dart';
import 'widgets/visual_style.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_gate.dart';
import 'fullscreen_stub.dart'
    if (dart.library.js_interop) 'fullscreen_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        theme: VisualStyle.current.isClassic
            ? ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF6750A4),
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
              )
            : _styledTheme(Brightness.light),
        darkTheme: VisualStyle.current.isClassic
            ? ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF6750A4),
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              )
            : _styledTheme(Brightness.dark),
        // Modern styles carry their own light/dark look.
        themeMode: VisualStyle.current.isClassic
            ? ThemeMode.system
            : (VisualStyle.current.id == 3 ? ThemeMode.light : ThemeMode.dark),
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
            child: Listener(
              // First touch anywhere: go full screen (browsers only allow
              // it after a tap).
              onPointerUp: (_) => requestFullscreen(),
              child: _RotatePhoneGate(child: child!),
            ),
          );
        },
        home: AppGate(key: ValueKey(_localeProvider.language)),
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

/// The game is played in landscape only. Phone browsers can't be forced to
/// rotate (and iPhones with rotation lock never do), so when the screen is
/// portrait we turn the whole app 90° ourselves: the player just holds the
/// phone sideways.
class _RotatePhoneGate extends StatelessWidget {
  final Widget child;

  const _RotatePhoneGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.height <= mq.size.width) return child;
    final p = mq.padding;
    return RotatedBox(
      quarterTurns: 1,
      child: MediaQuery(
        data: mq.copyWith(
          size: Size(mq.size.height, mq.size.width),
          // Clockwise turn: old left edge becomes the top, and so on.
          padding: EdgeInsets.fromLTRB(p.bottom, p.left, p.top, p.right),
          viewPadding: EdgeInsets.zero,
        ),
        child: child,
      ),
    );
  }
}

/// App-wide theme for the modern looks (app bar, info bar and tray follow it).
ThemeData _styledTheme(Brightness brightness) {
  final st = VisualStyle.current;
  final scheme = ColorScheme.fromSeed(
    seedColor: st.boardFrame,
    brightness: brightness,
  ).copyWith(
    surface: st.trayBackground,
    surfaceContainerHighest: st.trayCard,
    surfaceContainerLow: st.trayBackground,
    surfaceContainerHigh: st.trayBackground,
    inversePrimary: st.boardBackground.first,
    onSurface: st.onTray,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: st.trayBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: st.boardBackground.first,
      foregroundColor: st.onTray,
    ),
  );
}
