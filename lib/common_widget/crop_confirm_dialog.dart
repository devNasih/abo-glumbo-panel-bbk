import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Future<bool?> showCropConfirmDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title:
            Text(AppLocalizations.of(context)?.keepImage ?? 'Keep Image?'),
        content: Text(AppLocalizations.of(context)?.keepImageDescription ??
            'Do you want to keep the selected image without cropping?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)?.keep ?? 'Keep'),
          ),
        ],
      );
    },
  );
}