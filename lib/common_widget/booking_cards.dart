import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:flutter/material.dart';

class BookingCards extends StatelessWidget {
  final BookingModel booking;
  const BookingCards({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () {
        // context.push(
        //   AppRoutes.bookingInfo,
        //   extra: {
        //     'booking': booking,
        //     'uid':
        //         uid ?? FirebaseAuth.instance.currentUser!.uid,
        //   },
        // );
      },
      leading: booking.bookingStatusCode == "X"
          ? const Icon(Icons.cancel_rounded, color: Colors.red)
          : booking.bookingStatusCode == "C"
          ? const Icon(Icons.check_circle_rounded, color: Colors.green)
          : null,
      title: Text(
        AppLocalizations.of(context)?.localeName == 'en'
            ? '${booking.service.name}'
            : '${booking.service.name_ar}',
        style: textTheme.labelLarge,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: textTheme.labelMedium,
              children: [
                const WidgetSpan(
                  // alignment: ui.PlaceholderAlignment.middle,
                  child: Icon(Icons.person, size: 15),
                ),
                TextSpan(
                  text: "${booking.customer.name} ・ ",
                  style: textTheme.labelMedium,
                ),
                if (booking.customer.location != null) ...[
                  const WidgetSpan(
                    // alignment: ui.PlaceholderAlignment.middle,
                    child: Icon(Icons.location_city, size: 15),
                  ),
                  TextSpan(text: " ${booking.customer.location?.name ?? ''}"),
                ],
                if (booking.agent != null) ...[
                  const TextSpan(text: " ・ "),
                  const WidgetSpan(
                    // alignment: ui.PlaceholderAlignment.middle,
                    child: Icon(Icons.assignment_ind_rounded, size: 15),
                  ),
                  TextSpan(text: " ${booking.agent?.name ?? ''}"),
                ],
              ],
            ),
          ),
          if (booking.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: RichText(
                text: TextSpan(
                  style: textTheme.labelSmall,
                  children: [
                    ...[
                      TextSpan(
                        text: "${AppLocalizations.of(context)?.scheduledFor}: ",
                        style: textTheme.labelMedium!.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: LocalizationHelper().formatDateLocalized(
                          booking.bookingDateTime.toDate(),
                          context,
                        ),
                        style: textTheme.labelMedium!.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    ...[
                      TextSpan(
                        text: '\n${AppLocalizations.of(context)?.bookedOn}: ',
                        style: textTheme.labelSmall,
                      ),
                      TextSpan(
                        text: LocalizationHelper().formatDateLocalized(
                          booking.createdAt!.toDate(),
                          context,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
