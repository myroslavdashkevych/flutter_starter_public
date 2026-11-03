import 'package:flutter/material.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';

/// Asks before the system request, which iOS shows only once. Returns whether
/// the user agreed, or null when [context] is gone and nothing was shown.
Future<bool?> showNotificationPermissionDialog(BuildContext context) async {
  if (!context.mounted) return null;
  final l10n = context.l10n;
  final allowed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.notificationPermissionTitle),
      content: Text(l10n.notificationPermissionBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.notificationPermissionNotNow),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.notificationPermissionAllow),
        ),
      ],
    ),
  );
  return allowed ?? false;
}
