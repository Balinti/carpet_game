import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../onboarding_strings.dart';
import 'onboarding_ui.dart';

/// "Check your email" screen. Nothing happens automatically: the user taps
/// "I confirmed" to re-check, or "resend". Status is shown inline.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.onCheck,
    required this.onResend,
    this.onUseDifferentEmail,
  });

  final String email;

  /// Re-checks verification; returns true when verified (the caller then
  /// moves on). Returning false shows "not verified yet".
  final Future<bool> Function() onCheck;
  final Future<void> Function() onResend;
  final VoidCallback? onUseDifferentEmail;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

enum _Status { none, notYet, resent, error }

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _checking = false;
  bool _resending = false;
  _Status _status = _Status.none;
  String _errorCode = 'unknown';

  Future<void> _run(Future<void> Function() body, bool check) async {
    if (_checking || _resending) return;
    setState(() {
      if (check) {
        _checking = true;
      } else {
        _resending = true;
      }
      _status = _Status.none;
    });
    try {
      await body();
    } on AuthException catch (e) {
      _status = _Status.error;
      _errorCode = e.code;
    } catch (_) {
      _status = _Status.error;
      _errorCode = 'unknown';
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
          _resending = false;
        });
      }
    }
  }

  Future<void> _check() => _run(() async {
        final ok = await widget.onCheck();
        if (!ok) _status = _Status.notYet;
      }, true);

  Future<void> _resend() => _run(() async {
        await widget.onResend();
        _status = _Status.resent;
      }, false);

  @override
  Widget build(BuildContext context) {
    final s = OnboardingStrings.of(context);
    final st = onboardingStyle;
    final busy = _checking || _resending;
    return OnboardingBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: OnboardingPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mark_email_unread_outlined,
                          size: 40, color: st.boardFrame),
                      const SizedBox(width: 12),
                      Expanded(child: OnboardingTitle(s.verifyTitle)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.verifyBody(widget.email),
                    style:
                        TextStyle(color: st.onTray, fontSize: 17, height: 1.3),
                  ),
                  if (_status == _Status.notYet)
                    InlineMessage(s.notVerifiedYet),
                  if (_status == _Status.resent)
                    InlineMessage(s.resent, isError: false),
                  if (_status == _Status.error)
                    InlineMessage(s.authError(_errorCode)),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 240),
                        child: BigButton(
                          key: const ValueKey('verify_confirmed'),
                          label: s.iConfirmed,
                          icon: Icons.check_rounded,
                          busy: _checking,
                          onPressed: busy ? null : _check,
                        ),
                      ),
                      BigButton(
                        key: const ValueKey('verify_resend'),
                        label: s.resend,
                        icon: Icons.refresh_rounded,
                        primary: false,
                        busy: _resending,
                        onPressed: busy ? null : _resend,
                      ),
                    ],
                  ),
                  if (widget.onUseDifferentEmail != null) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        key: const ValueKey('verify_different_email'),
                        onPressed: busy ? null : widget.onUseDifferentEmail,
                        style: TextButton.styleFrom(
                          foregroundColor: look.muted,
                          minimumSize: const Size(48, 48),
                        ),
                        child: Text(s.differentEmail,
                            style: const TextStyle(
                                fontSize: 15,
                                decoration: TextDecoration.underline)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
