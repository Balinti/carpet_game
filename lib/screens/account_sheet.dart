import 'package:flutter/material.dart';

import '../onboarding/account_deletion.dart';
import '../onboarding/auth/auth_service.dart';
import '../onboarding/onboarding_strings.dart';
import '../onboarding/privacy_link.dart';

enum _AccountAction { deleteAccount, privacy }

/// Small bottom sheet: "Delete account" (red, with a confirm dialog) and
/// "Privacy policy". Calls [onDeleted] after the account is gone.
Future<void> showAccountSheet(
  BuildContext context, {
  required AccountDeletionService deletion,
  required VoidCallback onDeleted,
}) async {
  final s = OnboardingStrings.of(context);
  final action = await showModalBottomSheet<_AccountAction>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const ValueKey('account_privacy'),
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(s.privacyPolicy),
            onTap: () => Navigator.pop(ctx, _AccountAction.privacy),
          ),
          ListTile(
            key: const ValueKey('account_delete'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(s.deleteAccount,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pop(ctx, _AccountAction.deleteAccount),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  switch (action) {
    case _AccountAction.privacy:
      await openPrivacyPolicy();
    case _AccountAction.deleteAccount:
      await _confirmAndDelete(context, deletion, onDeleted);
    case null:
      break;
  }
}

Future<void> _confirmAndDelete(
  BuildContext context,
  AccountDeletionService deletion,
  VoidCallback onDeleted,
) async {
  final s = OnboardingStrings.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const ValueKey('delete_confirm_dialog'),
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
      title: Text(s.deleteConfirmTitle),
      content: Text(s.deleteConfirmBody),
      actions: [
        TextButton(
          key: const ValueKey('delete_cancel'),
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(s.cancel),
        ),
        FilledButton(
          key: const ValueKey('delete_confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(s.deleteForever),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(s.deleting)),
          ],
        ),
      ),
    ),
  );

  String? error;
  try {
    await deletion.deleteAccount(
      askPassword: () => _askPassword(navigator.context),
    );
  } on AuthException catch (e) {
    error = e.code;
  } catch (_) {
    error = 'unknown';
  }
  navigator.pop(); // progress dialog
  if (error == null) {
    onDeleted();
  } else {
    messenger?.showSnackBar(SnackBar(content: Text(s.deleteError(error))));
  }
}

Future<String?> _askPassword(BuildContext context) => showDialog<String>(
    context: context, builder: (_) => const _PasswordDialog());

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = OnboardingStrings.of(context);
    return AlertDialog(
      title: Text(s.reenterPasswordTitle),
      content: TextField(
        key: const ValueKey('reauth_password'),
        controller: _controller,
        obscureText: true,
        autofocus: true,
        autofillHints: const [AutofillHints.password],
        decoration: InputDecoration(labelText: s.password),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          key: const ValueKey('reauth_confirm'),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(s.confirm),
        ),
      ],
    );
  }
}
