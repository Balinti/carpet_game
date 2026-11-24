import 'package:flutter/material.dart';

/// The three design models for the start of the app (welcome, sign-up,
/// questionnaire). On the web pick one with `?welcome=1`, `?welcome=2` or
/// `?welcome=3` (default 1) so they can be compared side by side.
enum WelcomeModel {
  /// 1: calm, light, step-by-step cards with progress dots.
  calm,

  /// 2: playful, dark, big tile art from the game itself.
  playful,

  /// 3: minimal, white, one screen with one big start button.
  minimal,
}

/// Colors and shapes shared by every onboarding screen for one model.
class OnboardingLook {
  final WelcomeModel model;

  /// Page background (top-left to bottom-right gradient).
  final List<Color> background;

  /// Cards, panels and text-field fill.
  final Color surface;
  final Color text;
  final Color muted;

  /// Main button / highlight color and the text on it.
  final Color accent;
  final Color onAccent;
  final Color border;
  final Color error;
  final Color success;
  final Brightness brightness;

  /// Corner radius for buttons, fields and cards.
  final double radius;

  /// Chunky "toy" buttons with a darker bottom edge.
  final bool chunky;

  /// Flat underline text fields instead of filled boxes.
  final bool underlineFields;

  /// Forms sit on a card.
  final bool panel;
  final double titleSize;

  const OnboardingLook({
    required this.model,
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.border,
    required this.error,
    required this.success,
    required this.brightness,
    required this.radius,
    required this.chunky,
    required this.underlineFields,
    required this.panel,
    required this.titleSize,
  });

  static const calm = OnboardingLook(
    model: WelcomeModel.calm,
    background: [Color(0xFFF7F2EA), Color(0xFFEAF3F1)],
    surface: Colors.white,
    text: Color(0xFF22303F),
    muted: Color(0xFF5D6B79),
    accent: Color(0xFF2A8C82),
    onAccent: Colors.white,
    border: Color(0xFFD9E1E6),
    error: Color(0xFFC62828),
    success: Color(0xFF2E7D32),
    brightness: Brightness.light,
    radius: 20,
    chunky: false,
    underlineFields: false,
    panel: true,
    titleSize: 26,
  );

  static const playful = OnboardingLook(
    model: WelcomeModel.playful,
    background: [Color(0xFF1B1F3B), Color(0xFF2B1F4D), Color(0xFF14172B)],
    surface: Color(0xFF262B55),
    text: Colors.white,
    muted: Color(0xCCFFFFFF),
    accent: Color(0xFF1463FF),
    onAccent: Colors.white,
    border: Color(0x40FFFFFF),
    error: Color(0xFFFF8A80),
    success: Color(0xFF8CF5B0),
    brightness: Brightness.dark,
    radius: 18,
    chunky: true,
    underlineFields: false,
    panel: true,
    titleSize: 27,
  );

  static const minimal = OnboardingLook(
    model: WelcomeModel.minimal,
    background: [Colors.white, Colors.white],
    surface: Color(0xFFF3F4F6),
    text: Color(0xFF111111),
    muted: Color(0xFF6B6F76),
    accent: Color(0xFF111111),
    onAccent: Colors.white,
    border: Color(0xFFCFD3D8),
    error: Color(0xFFC62828),
    success: Color(0xFF2E7D32),
    brightness: Brightness.light,
    radius: 999,
    chunky: false,
    underlineFields: true,
    panel: false,
    titleSize: 30,
  );

  static OnboardingLook of(WelcomeModel m) => switch (m) {
        WelcomeModel.calm => calm,
        WelcomeModel.playful => playful,
        WelcomeModel.minimal => minimal,
      };

  /// For tests / screenshots: forces a model instead of the URL.
  static WelcomeModel? debugModel;

  static final WelcomeModel _urlModel = _fromUrl();

  static WelcomeModel _fromUrl() {
    final n = int.tryParse(Uri.base.queryParameters['welcome'] ?? '');
    if (n != null && n >= 1 && n <= WelcomeModel.values.length) {
      return WelcomeModel.values[n - 1];
    }
    return WelcomeModel.calm;
  }

  /// The model in use: [debugModel], else `?welcome=N`, else 1 (calm).
  static OnboardingLook get current => of(debugModel ?? _urlModel);

  /// Material theme matching this look, so default widgets fit in.
  ThemeData theme(ThemeData base) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: onAccent,
      surface: background.last,
      onSurface: text,
      error: error,
    );
    return base.copyWith(
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: background.last,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.3),
        selectionHandleColor: accent,
      ),
    );
  }
}
