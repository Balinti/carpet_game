import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../onboarding_strings.dart';
import 'google_button.dart';
import '../validators.dart';
import 'onboarding_ui.dart';

/// Email + password sign-in. Errors are shown inline.
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.onSubmit,
    this.onCreateAccount,
    this.onGoogle,
    this.initialErrorCode,
    this.onBack,
    this.onForgotPassword,
  });

  /// Back to the welcome screen. When null, no back button.
  final VoidCallback? onBack;

  /// Throws [AuthException] on failure.
  final Future<void> Function(String email, String password) onSubmit;
  final VoidCallback? onCreateAccount;

  /// Shows "Continue with Google" above the form when set.
  final Future<void> Function()? onGoogle;

  /// Auth error code to show when the screen opens (e.g. a failed resume).
  final String? initialErrorCode;

  /// "Forgot password": email a reset link. Throws [AuthException].
  final Future<void> Function(String email)? onForgotPassword;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _submitted = false;
  late String? _error = widget.initialErrorCode;
  String? _info;

  Future<void> _forgot() async {
    final s = OnboardingStrings.of(context);
    final email = _email.text.trim();
    setState(() {
      _error = null;
      _info = null;
    });
    if (validateEmail(email) != null) {
      setState(() => _info = null);
      setState(() => _error = 'need-email');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onForgotPassword!(email);
      if (mounted) setState(() => _info = s.resetSent(email));
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.code);
    } catch (_) {
      if (mounted) setState(() => _error = 'unknown');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(_email.text.trim(), _password.text);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.code);
    } catch (_) {
      if (mounted) setState(() => _error = 'unknown');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = OnboardingStrings.of(context);
    String? v(FieldError? e) => e == null ? null : s.fieldError(e);
    const gap = SizedBox(height: 10, width: 14);

    final emailField = OnboardingField(
      key: const ValueKey('signin_email'),
      controller: _email,
      label: s.email,
      keyboardType: TextInputType.emailAddress,
      validator: (x) => v(validateEmail(x)),
      autofillHints: const [AutofillHints.email],
    );
    final passwordField = OnboardingField(
      key: const ValueKey('signin_password'),
      controller: _password,
      label: s.password,
      obscure: true,
      // Don't enforce the sign-up length rule here: just require something.
      validator: (x) => (x == null || x.isEmpty)
          ? s.fieldError(FieldError.passwordTooShort)
          : null,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      autofillHints: const [AutofillHints.password],
    );

    return OnboardingBackground(
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 560;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: OnboardingPanel(
                compact: c.maxHeight < 500,
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (widget.onBack != null) ...[
                              OnboardingBackButton(
                                key: const ValueKey('signin_back'),
                                tooltip: s.back,
                                onPressed: _busy ? null : widget.onBack,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(child: OnboardingTitle(s.signInTitle)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (widget.onGoogle != null)
                          GoogleSignInBlock(
                            onGoogle: widget.onGoogle!,
                            disabled: _busy,
                            onError: (c) => setState(() => _error = c),
                          ),
                        wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: emailField),
                                  gap,
                                  Expanded(child: passwordField),
                                ],
                              )
                            : Column(
                                children: [emailField, gap, passwordField]),
                        if (widget.onForgotPassword != null)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: OnboardingLink(
                              key: const ValueKey('signin_forgot'),
                              label: s.forgotPassword,
                              onPressed: _busy ? null : _forgot,
                            ),
                          ),
                        if (_error != null)
                          InlineMessage(_error == 'need-email'
                              ? s.forgotNeedEmail
                              : s.authError(_error!)),
                        if (_info != null)
                          InlineMessage(_info!, isError: false),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 10,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 240),
                              child: BigButton(
                                key: const ValueKey('signin_submit'),
                                label: s.signIn,
                                busy: _busy,
                                onPressed: _submit,
                              ),
                            ),
                            if (widget.onCreateAccount != null)
                              BigButton(
                                key: const ValueKey('signin_go_signup'),
                                label: s.newAccount,
                                primary: false,
                                onPressed:
                                    _busy ? null : widget.onCreateAccount,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
