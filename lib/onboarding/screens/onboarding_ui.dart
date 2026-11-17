import 'package:flutter/material.dart';

import '../../widgets/visual_style.dart';

/// Look shared by the onboarding screens: the app's Soft 3D style (or the
/// current modern style), with Soft 3D as fallback for the classic look.
VisualStyle get onboardingStyle =>
    VisualStyle.current.isClassic ? VisualStyle.soft3d : VisualStyle.current;

const Color kOnboardingError = Color(0xFFFF8A80);

/// Full-screen gradient background with safe-area padding.
class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final st = onboardingStyle;
    return Scaffold(
      backgroundColor: st.trayBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: st.boardBackground,
          ),
        ),
        child: SafeArea(
          child: DefaultTextStyle.merge(
            style: TextStyle(color: st.onTray),
            child: child,
          ),
        ),
      ),
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
    final st = onboardingStyle;
    final fg = primary ? Colors.white : st.onTray;
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
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
    const minSize = Size(120, 56);
    const padding = EdgeInsets.symmetric(horizontal: 20, vertical: 10);
    if (primary) {
      return FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: st.boardFrame,
          foregroundColor: fg,
          disabledBackgroundColor: st.boardFrame.withOpacity(0.5),
          disabledForegroundColor: fg.withOpacity(0.8),
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          elevation: 4,
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        minimumSize: minSize,
        padding: padding,
        shape: shape,
        side: BorderSide(color: st.onTray.withOpacity(0.5), width: 2),
      ),
      child: child,
    );
  }
}

/// Text field styled for the dark onboarding background.
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
    final st = onboardingStyle;
    OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
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
      style: TextStyle(color: st.onTray, fontSize: 18),
      cursorColor: st.boardFrame,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: st.trayCard.withOpacity(0.85),
        labelStyle: TextStyle(color: st.onTray.withOpacity(0.75)),
        floatingLabelStyle: TextStyle(color: st.onTray),
        errorStyle: const TextStyle(color: kOnboardingError, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: border(st.onTray.withOpacity(0.25)),
        focusedBorder: border(st.boardFrame, 2),
        errorBorder: border(kOnboardingError),
        focusedErrorBorder: border(kOnboardingError, 2),
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
    final color = isError ? kOnboardingError : const Color(0xFF8CF5B0);
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
  const OnboardingTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: onboardingStyle.onTray,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      );
}
