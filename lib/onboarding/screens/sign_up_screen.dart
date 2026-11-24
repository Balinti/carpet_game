import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../onboarding_strings.dart';
import 'google_button.dart';
import '../validators.dart';
import 'onboarding_ui.dart';

/// What the sign-up form collected.
class SignUpData {
  final String name;
  final String email;
  final String password;
  final int age;
  const SignUpData({
    required this.name,
    required this.email,
    required this.password,
    required this.age,
  });
}

/// Name, email, password and age. Errors are shown inline, never as pop-ups.
///
/// [onSubmit] does the actual work; if it throws [AuthException] the matching
/// localized message is shown above the button.
///
/// With [completeProfileEmail] set the screen only asks for name and age
/// (signed-in account without a profile on this device); [SignUpData.email]
/// is then that email and [SignUpData.password] is empty.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.onSubmit,
    this.onSignInInstead,
    this.onBack,
    this.onGoogle,
    this.initialName,
    this.completeProfileEmail,
  });

  final Future<void> Function(SignUpData data) onSubmit;
  final VoidCallback? onSignInInstead;

  /// Back to the welcome screen. When null, no back button.
  final VoidCallback? onBack;

  /// Shows "Continue with Google" above the form when set.
  final Future<void> Function()? onGoogle;
  final String? completeProfileEmail;

  /// Pre-fills the name field (e.g. the Google account name).
  final String? initialName;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _age = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) _name.text = widget.initialName!;
  }

  bool _busy = false;
  bool _submitted = false;
  String? _error;

  bool get _profileOnly => widget.completeProfileEmail != null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _age.dispose();
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
      await widget.onSubmit(SignUpData(
        name: _name.text.trim(),
        email: _profileOnly ? widget.completeProfileEmail! : _email.text.trim(),
        password: _profileOnly ? '' : _password.text,
        age: parseAge(_age.text)!,
      ));
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

    final nameField = OnboardingField(
      key: const ValueKey('signup_name'),
      controller: _name,
      label: s.name,
      validator: (x) => v(validateName(x)),
      autofillHints: const [AutofillHints.name],
    );
    final ageField = OnboardingField(
      key: const ValueKey('signup_age'),
      controller: _age,
      label: s.age,
      keyboardType: TextInputType.number,
      validator: (x) => v(validateAge(x)),
      textInputAction:
          _profileOnly ? TextInputAction.done : TextInputAction.next,
      onSubmitted: _profileOnly ? (_) => _submit() : null,
    );
    final emailField = OnboardingField(
      key: const ValueKey('signup_email'),
      controller: _email,
      label: s.email,
      keyboardType: TextInputType.emailAddress,
      validator: (x) => v(validateEmail(x)),
      autofillHints: const [AutofillHints.email],
    );
    final passwordField = OnboardingField(
      key: const ValueKey('signup_password'),
      controller: _password,
      label: s.password,
      obscure: true,
      validator: (x) => v(validatePassword(x)),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      autofillHints: const [AutofillHints.newPassword],
    );

    const gap = SizedBox(height: 10, width: 14);

    return OnboardingBackground(
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 560;
        final fields = _profileOnly
            ? (wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: nameField),
                      gap,
                      Expanded(flex: 2, child: ageField),
                    ],
                  )
                : Column(children: [nameField, gap, ageField]))
            : (wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Column(children: [nameField, gap, ageField])),
                      gap,
                      Expanded(
                          child: Column(
                              children: [emailField, gap, passwordField])),
                    ],
                  )
                : Column(children: [
                    nameField,
                    gap,
                    ageField,
                    gap,
                    emailField,
                    gap,
                    passwordField,
                  ]));

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
                                key: const ValueKey('signup_back'),
                                tooltip: s.back,
                                onPressed: _busy ? null : widget.onBack,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: OnboardingTitle(_profileOnly
                                  ? s.completeProfileTitle
                                  : s.signUpTitle),
                            ),
                            if (!_profileOnly && widget.onSignInInstead != null)
                              Flexible(
                                child: OnboardingLink(
                                  key: const ValueKey('signup_go_signin'),
                                  label: s.haveAccount,
                                  onPressed:
                                      _busy ? null : widget.onSignInInstead,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (!_profileOnly && widget.onGoogle != null)
                          GoogleSignInBlock(
                            onGoogle: widget.onGoogle!,
                            disabled: _busy,
                            onError: (c) => setState(() => _error = c),
                          ),
                        fields,
                        if (_error != null)
                          InlineMessage(s.authError(_error!))
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              s.kidHint,
                              style: TextStyle(
                                color: look.muted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 280),
                            child: BigButton(
                              key: const ValueKey('signup_submit'),
                              label: _profileOnly
                                  ? s.continueLabel
                                  : s.createAccount,
                              busy: _busy,
                              onPressed: _submit,
                            ),
                          ),
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
