import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_providers.dart';
import '../domain/app_settings.dart';

Future<bool> authenticatePrivateAccess(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings, {
  String confirmLabel = '確認',
}) async {
  if (settings.privateLockMethod != PrivateLockMethod.pin) {
    final authenticated = await ref
        .read(privateAccessAuthenticatorProvider)
        .authenticateWithDevice();
    if (authenticated) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    if (settings.privateLockMethod == PrivateLockMethod.deviceCredential) {
      _showSnackBar(context, '端末認証できませんでした');
      return false;
    }
  }

  if (!context.mounted) {
    return false;
  }

  if (!settings.hasPrivatePin) {
    return _showCreatePinDialog(context, ref, settings);
  }

  return _showPinConfirmationDialog(
    context,
    settings,
    confirmLabel: confirmLabel,
  );
}

Future<bool> _showPinConfirmationDialog(
  BuildContext context,
  AppSettings settings, {
  required String confirmLabel,
}) async {
  final controller = TextEditingController();
  final pin = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('PIN確認'),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'PIN'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  controller.dispose();

  if (pin == null) {
    return false;
  }

  final matched = pin == settings.privatePin;
  if (!matched && context.mounted) {
    _showSnackBar(context, 'PINが違います');
  }

  return matched;
}

Future<bool> _showCreatePinDialog(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings,
) async {
  final controller = TextEditingController();
  final pin = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('プライベートPINを設定'),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 8,
        decoration: const InputDecoration(
          labelText: '4〜8桁のPIN',
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('設定'),
        ),
      ],
    ),
  );
  controller.dispose();

  if (pin == null) {
    return false;
  }

  if (pin.length < 4 || pin.length > 8) {
    if (context.mounted) {
      _showSnackBar(context, 'PINは4〜8桁で設定してください');
    }
    return false;
  }

  await ref.read(updateSettingsUseCaseProvider).call(
        settings.copyWith(privatePin: pin),
      );
  return true;
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
