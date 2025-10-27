import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class LocalizationHelper {
  String localizedBookingStatus(
    String bookingStatus, {
    required BuildContext context,
  }) {
    switch (bookingStatus.toLowerCase()) {
      case 'to do':
        return AppLocalizations.of(context)!.pending;
      case 'accepted':
        return AppLocalizations.of(context)!.accepted;
      case 'rejected':
        return AppLocalizations.of(context)!.rejected;
      case 'completed':
        return AppLocalizations.of(context)!.completed;
      case 'cancelled':
        return AppLocalizations.of(context)!.cancelled;
      default:
        return 'unknown';
    }
  }

  String formatDateLocalized(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    String formatted;
    if (locale == 'ar') {
      // Use Arabic date format and convert numbers
      formatted = intl.DateFormat('EEEE، d MMMM y - h:mm a', 'ar').format(date);
      // Convert Western digits to Arabic-Indic digits
      formatted = formatted.replaceAllMapped(RegExp(r'[0-9]'), (match) {
        const arabicNumbers = [
          '٠',
          '١',
          '٢',
          '٣',
          '٤',
          '٥',
          '٦',
          '٧',
          '٨',
          '٩',
        ];
        return arabicNumbers[int.parse(match.group(0)!)];
      });
    } else {
      formatted = intl.DateFormat('EEE, MMM d, y - h:mm a').format(date);
    }
    return formatted;
  }

  getLocalizedBookingStatus(String status, BuildContext context) {
    switch (status) {
      case 'P':
        return AppLocalizations.of(context)!.pending;
      case 'A':
        return AppLocalizations.of(context)!.accepted;
      case 'R':
        return AppLocalizations.of(context)!.rejected;
      case 'C':
        return AppLocalizations.of(context)!.completed;
      case 'X':
        return AppLocalizations.of(context)!.cancelled;
      default:
        return status;
    }
  }
}
