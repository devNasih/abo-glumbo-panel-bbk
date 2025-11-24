import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/address.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/booking_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/booking_info.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookingCards extends StatelessWidget {
  final BookingModel booking;
  final bool isAdmin;
  final VoidCallback? onAssign;

  const BookingCards({
    super.key,
    required this.booking,
    this.isAdmin = false,
    this.onAssign,
  });

  Color _getStatusColor() {
    final bool bookingCancelled = booking.cancelledWorkers.any(
      (worker) => worker.uid == LocalStore.getUID(),
    );

    if (bookingCancelled) {
      return Colors.red;
    }

    switch (booking.bookingStatusCode) {
      case "X":
      case "R":
      case "XC":
        return Colors.red;
      case "C":
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final addresses = booking.customer.addresses;
    AddressModel? selectedAddress =
        addresses.where((a) => a.isSelected == true).isNotEmpty
        ? addresses.firstWhere((a) => a.isSelected == true)
        : null;

    final bool bookingCancelled = booking.cancelledWorkers.any(
      (worker) => worker.uid == LocalStore.getUID(),
    );

    return GestureDetector(
      onTap: bookingCancelled
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BookingInfo(booking: booking, isAdmin: isAdmin),
              ),
            ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            // Top section with service name and status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.localeName == 'en'
                          ? (booking.service.name ?? '')
                          : (booking.service.name_ar ?? ''),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isAdmin &&
                      booking.bookingStatusCode == 'P' &&
                      !booking.cancelledWorkers.any(
                        (worker) => worker.uid == LocalStore.getUID(),
                      )) ...[
                    IconButton(
                      onPressed: () {
                        showAcceptBookingDialog(context, booking);
                      },
                      icon: Icon(Icons.check_circle, color: Colors.green),
                    ),

                    IconButton(
                      onPressed: () {
                        showRejectBookingDialog(context, booking);
                      },
                      icon: Icon(Icons.cancel, color: Colors.red),
                    ),
                  ],
                  if (isAdmin &&
                      onAssign != null &&
                      booking.bookingStatusCode == 'P')
                    OutlinedButton(
                      onPressed: onAssign,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(60, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.assign ?? 'Assign',
                      ),
                    ),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Customer row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // (selectedAddress != null &&
                              //         selectedAddress.id.isNotEmpty)
                              //     ? (selectedAddress.fullName)
                              //     :
                              (booking.customer.name ?? ''),
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (booking.customer.location != null)
                              Text(
                                (selectedAddress != null &&
                                        selectedAddress.id.isNotEmpty)
                                    ? (selectedAddress.streetName ?? '')
                                    : (booking.customer.location?.name ?? ''),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Agent row (if exists)
                  if (isAdmin && booking.agent != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Icon(
                            Icons.support_agent,
                            size: 16,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            booking.agent?.name ?? '',
                            style: textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Date info
                  Column(
                    spacing: 2,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocalizationHelper().formatDateLocalized(
                                    booking.bookingDateTime.toDate(),
                                    context,
                                  ),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (booking.bookingStatusCode == 'P' &&
                          booking.cancelledWorkers.any(
                            (worker) => worker.uid != LocalStore.getUID(),
                          )) ...{
                        if (booking.createdAt != null)
                          Text(
                            "${AppLocalizations.of(context)!.bookedOn}: ${LocalizationHelper().formatDateLocalized(booking.createdAt!.toDate(), context)}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      } else if (booking.bookingStatusCode == 'A') ...{
                        if (booking.acceptedAt != null)
                          Text(
                            "${AppLocalizations.of(context)!.acceptedOn}: ${LocalizationHelper().formatDateLocalized(booking.acceptedAt!.toDate(), context)}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (isAdmin)
                          Text(
                            "${AppLocalizations.of(context)!.acceptedBy}: ${booking.agent?.name ?? ''}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      } else if (booking.bookingStatusCode == 'C') ...{
                        if (booking.completedAt != null)
                          Text(
                            "${AppLocalizations.of(context)!.completedOn}: ${LocalizationHelper().formatDateLocalized(booking.completedAt!.toDate(), context)}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (isAdmin)
                          Text(
                            "${AppLocalizations.of(context)!.completedBy}: ${booking.agent?.name ?? ''}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      } else if (booking.bookingStatusCode == 'XC') ...{
                        if (booking.cancelledAt != null)
                          Text(
                            "${AppLocalizations.of(context)!.cancelledOn}: ${LocalizationHelper().formatDateLocalized(booking.cancelledAt!.toDate(), context)}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          "${AppLocalizations.of(context)!.cancelledBy}: ${AppLocalizations.of(context)!.customer}",
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      } else if (booking.bookingStatusCode == 'XC') ...{
                        Text(
                          "${AppLocalizations.of(context)!.rejectedOn}: ${LocalizationHelper().formatDateLocalized(booking.cancelledWorkers.firstWhere((worker) => worker.uid == LocalStore.getUID()).cancelledAt.toDate(), context)}",
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isAdmin)
                          Text(
                            "${AppLocalizations.of(context)!.rejectedBy}: ${AppLocalizations.of(context)!.admin}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      } else if (booking.bookingStatusCode == 'R') ...{
                        Text(
                          "${AppLocalizations.of(context)!.rejectedOn}: ${LocalizationHelper().formatDateLocalized(booking.rejectedAt!.toDate(), context)}",
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        Text(
                          "${AppLocalizations.of(context)!.rejectedBy}: ${AppLocalizations.of(context)!.admin}",
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      } else if (!isAdmin &&
                          booking.cancelledWorkers.any(
                            (worker) => worker.uid == LocalStore.getUID(),
                          )) ...{
                        Text(
                          "${AppLocalizations.of(context)!.rejectedOn}: ${LocalizationHelper().formatDateLocalized(booking.cancelledWorkers.firstWhere((worker) => worker.uid == LocalStore.getUID()).cancelledAt.toDate(), context)}",
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      },
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showAcceptBookingDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.acceptBooking),
          content: Text(
            AppLocalizations.of(context)!.areYouSureYouWantToAcceptThisBooking,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                AppFirestore.bookingsCollectionRef.doc(booking.id).update({
                  'bookingStatusCode': 'A',
                  'acceptedAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        Home(newIndex: 1, selectedFilter: "A"),
                  ),
                  (route) => false,
                );
              },
              child: Text(AppLocalizations.of(context)!.accept),
            ),
          ],
        );
      },
    );
  }

  void showRejectBookingDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.rejectBooking),
          content: Text(
            AppLocalizations.of(context)!.areYouSureYouWantToRejectThisBooking,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<BookingBloc>().add(
                  CancelBooking(
                    bookingId: booking.id,
                    agentUid: booking.agent?.uid ?? '',
                    agentName: booking.agent?.name ?? '',
                  ),
                );
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.reject),
            ),
          ],
        );
      },
    );
  }
}
