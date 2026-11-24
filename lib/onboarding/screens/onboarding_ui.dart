import 'package:flutter/material.dart';

import '../../widgets/visual_style.dart';
import '../welcome/onboarding_look.dart';
import '../welcome/tile_art.dart';

export '../welcome/onboarding_look.dart';

/// Look of the onboarding screens for the chosen design model
/// ([OnboardingLook.current], `?welcome=N`).
OnboardingLook get look => OnboardingLook.current;

/// The onboarding look in [VisualStyle] terms (kept for older call sites):
/// boardFrame = accent, onTray = text, trayCard = surface.
VisualStyle get onboardingStyle {
  final l = look;
  return VisualStyle(
    id: VisualStyle.soft3d.id,
    name: 'Onboarding',
    palette: VisualStyle.soft3d.palette,
    boardBackground: l.background,
    trayBackground: l.background.last,
    trayCard: l.surface,
    boardFrame: l.accent,
    emptySlot: l.surface,
    emptySlotBorder: l.border,
    onTray: l.text,
  );
}

/// Error text color for the current look.
Color get kOnboardingError => look.error;

/// Full-screen background with safe-area padding, in the current look.
class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = look;
    final colors = l.background.length > 1
        ? l.background
        : [...l.background, ...l.background];
    return Theme(
      data: l.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: l.background.last,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (l.model == WelcomeModel.playful)
                const Positioned.fill(child: TileConfetti()),
              if (l.model == WelcomeModel.calm) ...[
                _blob(const Alignment(-1.25, -1.2), const Color(0xFFFFD9B8)),
                _blob(const Alignment(1.3, 1.25), const Color(0xFFBFE6DF)),
              ],
              SafeArea(
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: l.text),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Soft round color patch in a corner (calm model).
  static Widget _blob(Alignment a, Color c) => Positioned.fill(
        child: IgnorePointer(
          child: Align(
            alignment: a,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [c.withValues(alpha: 0.75), c.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Card that holds a form or a question (models 1 and 2). Model 3 has no
/// card: the content sits right on the white page.
class OnboardingPanel extends StatelessWidget {
  const OnboardingPanel({super.key, required this.child, this.compact = false});
  final Widget child;

  /// Less inner padding (short landscape screens).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = look;
    if (!l.panel) return child;
    final pad = compact ? 14.0 : 20.0;
    final playful = l.model == WelcomeModel.playful;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: playful ? l.surface.withValues(alpha: 0.82) : l.surface,
        borderRadius: BorderRadius.circular(playful ? 24 : 26),
        border: Border.all(
          color: playful ? const Color(0x33FFFFFF) : l.border,
          width: playful ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: playful
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF22303F).withValues(alpha: 0.08),
            blurRadius: playful ? 18 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Big, finger-size button. [primary] = filled accent, else outlined.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final l = look;
    final fg = primary ? l.onAccent : l.text;
    final child = busy
        ? SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 3, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 24),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: l.model == WelcomeModel.minimal ? 0.2 : 0,
                  ),
                ),
              ),
            ],
          );
    final radius = BorderRadius.circular(l.radius);
    final shape = RoundedRectangleBorder(borderRadius: radius);
    const minSize = Size(120, 56);
    const padding = EdgeInsets.symmetric(horizontal: 22, vertical: 10);
    final enabled = onPressed != null && !busy;
    if (primary) {
      final button = FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: l.accent,
          foregroundColor: fg,
          disabledBackgroundColor: l.accent.withValues(alpha: 0.5),
          disabledForegroundColor: fg.withValues(alpha: 0.8),
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          elevation: l.chunky || l.model == WelcomeModel.minimal ? 0 : 2,
          shadowColor: l.accent.withValues(alpha: 0.4),
        ),
        child: child,
      );
      if (!l.chunky) return button;
      // Toy-like button: a darker edge under it, like a game piece.
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: Color.lerp(l.accent, Colors.black, enabled ? 0.45 : 0.6),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: button,
        ),
      );
    }
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: l.model == WelcomeModel.calm
            ? Colors.white.withValues(alpha: 0.7)
            : null,
        minimumSize: minSize,
        padding: padding,
        shape: shape,
        side: BorderSide(
          color: l.model == WelcomeModel.minimal
              ? l.text
              : l.text.withValues(alpha: 0.35),
          width: l.model == WelcomeModel.minimal ? 1.5 : 2,
        ),
      ),
      child: child,
    );
  }
}

/// Small underlined text link ("I already have an account").
class OnboardingLink extends StatelessWidget {
  const OnboardingLink(
      {super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: look.model == WelcomeModel.calm
              ? look.accent
              : look.text.withValues(alpha: 0.85),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
        child: Text(label, textAlign: TextAlign.center),
      );
}

/// Round back arrow (flips in Hebrew).
class OnboardingBackButton extends StatelessWidget {
  const OnboardingBackButton(
      {super.key, required this.onPressed, this.tooltip});
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final l = look;
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: tooltip,
        iconSize: 26,
        color: l.text,
        style: IconButton.styleFrom(
          backgroundColor: l.model == WelcomeModel.minimal
              ? Colors.transparent
              : l.surface.withValues(alpha: 0.9),
          side: l.model == WelcomeModel.minimal
              ? BorderSide(color: l.border)
              : null,
        ),
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: onPressed,
      ),
    );
  }
}

/// Text field styled for the current look.
class OnboardingField extends StatelessWidget {
  const OnboardingField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.keyboardType,
    this.obscure = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final l = look;
    final InputBorder Function(Color c, [double w]) border = l.underlineFields
        ? (c, [w = 1.5]) =>
            UnderlineInputBorder(borderSide: BorderSide(color: c, width: w))
        : (c, [w = 1.5]) => OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c, width: w),
            );
    final fill = switch (l.model) {
      WelcomeModel.calm => const Color(0xFFF5F7F8),
      WelcomeModel.playful => const Color(0xFF14172B).withValues(alpha: 0.7),
      WelcomeModel.minimal => Colors.transparent,
    };
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscure,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      autofillHints: autofillHints,
      autocorrect: false,
      enableSuggestions: !obscure,
      style: TextStyle(color: l.text, fontSize: 18),
      cursorColor: l.accent,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: !l.underlineFields,
        fillColor: fill,
        labelStyle: TextStyle(color: l.muted),
        floatingLabelStyle: TextStyle(color: l.text),
        errorStyle: TextStyle(color: l.error, fontSize: 13),
        contentPadding: l.underlineFields
            ? const EdgeInsets.symmetric(horizontal: 2, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: border(
            l.underlineFields ? l.border : l.text.withValues(alpha: 0.18)),
        focusedBorder: border(l.accent, 2),
        errorBorder: border(l.error),
        focusedErrorBorder: border(l.error, 2),
      ),
    );
  }
}

/// Inline status line (never a pop-up).
class InlineMessage extends StatelessWidget {
  const InlineMessage(this.text, {super.key, this.isError = true});
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? look.error : look.success;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class OnboardingTitle extends StatelessWidget {
  const OnboardingTitle(this.text, {super.key, this.size});
  final String text;
  final double? size;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: look.text,
          fontSize: size ?? look.titleSize * 0.92,
          fontWeight: look.model == WelcomeModel.minimal
              ? FontWeight.w700
              : FontWeight.w800,
          height: 1.15,
          letterSpacing: look.model == WelcomeModel.minimal ? -0.4 : 0,
        ),
      );
}
