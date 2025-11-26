import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
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
          eButton(
            onPressed: () => Navigator.of(context).pop(false),
            text: AppLocalizations.of(context)?.cancel ?? 'Cancel',
            context: context,
            textColor: Colors.black,
            backgroundColor: Colors.white,
          ),
          eButton(
            onPressed: () => Navigator.of(context).pop(true),
            text: AppLocalizations.of(context)?.delete ?? 'Delete',
            context: context,
            textColor: Colors.white,
            backgroundColor: Colors.red,
          ),
        ],
      );
    },
  );
}
