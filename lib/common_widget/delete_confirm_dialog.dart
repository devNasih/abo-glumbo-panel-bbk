import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Future<bool?> showDeleteConfirmDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        actionsAlignment: MainAxisAlignment.start,

        title: Text(
          AppLocalizations.of(context)?.confirmDelete ?? 'Confirm Delete',
        ),
        content: Text(
          AppLocalizations.of(context)?.deleteItemConfirmation ??
              'Are you sure you want to delete this item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
        ],
      );
    },
  );
}
