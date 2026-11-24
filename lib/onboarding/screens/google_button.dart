import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../onboarding_strings.dart';
import 'onboarding_ui.dart';

/// Big white "Continue with Google" button + "or use email" divider.
/// Shows its own inline error code via [onError].
class GoogleSignInBlock extends StatefulWidget {
  final Future<void> Function() onGoogle;
  final void Function(String code) onError;
  final bool disabled;

  const GoogleSignInBlock({
    super.key,
    required this.onGoogle,
    required this.onError,
    this.disabled = false,
  });

  @override
  State<GoogleSignInBlock> createState() => _GoogleSignInBlockState();
}

class _GoogleSignInBlockState extends State<GoogleSignInBlock> {
  bool _busy = false;

  Future<void> _tap() async {
    if (_busy || widget.disabled) return;
    setState(() => _busy = true);
    try {
      await widget.onGoogle();
    } on AuthException catch (e) {
      // Closing the Google window is not an error worth showing.
      if (e.code != 'popup-closed-by-user' &&
          e.code != 'cancelled-popup-request' &&
          e.code != 'web-context-canceled') {
        widget.onError(e.code);
      }
    } catch (_) {
      widget.onError('unknown');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = OnboardingStrings.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 240),
            child: ElevatedButton(
              key: const ValueKey('google_sign_in'),
              onPressed: _busy || widget.disabled ? null : _tap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1F1F1F),
                elevation: look.brightness == Brightness.light ? 0 : 2,
                side: look.brightness == Brightness.light
                    ? BorderSide(color: look.border, width: 1.5)
                    : null,
                minimumSize: const Size(240, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        look.radius > 26 ? 26 : look.radius)),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('G',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4285F4))),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(s.continueWithGoogle,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(child: Divider(color: look.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(s.orUseEmail,
                  style: TextStyle(color: look.muted, fontSize: 14)),
            ),
            Expanded(child: Divider(color: look.border)),
          ]),
        ),
      ],
    );
  }
}
