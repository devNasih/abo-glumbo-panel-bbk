import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:flutter/material.dart';

class BookingInfo extends StatelessWidget {
  final BookingModel booking;
  const BookingInfo({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(AppLocalizations.of(context)!.bookingInfo),
      ),
    );
  }
}
