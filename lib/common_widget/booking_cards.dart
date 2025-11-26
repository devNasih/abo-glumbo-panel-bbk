import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/address.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/booking_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/warranty_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/booking_info.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookingCards extends StatelessWidget {
  final BookingModel booking;
  final bool isAdmin;
  final VoidCallback? onAssign;
  final bool isWarranty;

  BookingCards({
    super.key,
    required this.booking,
    this.isAdmin = false,
    this.onAssign,
    this.isWarranty = false,
  });

  Color _getStatusColor() {
    final bool bookingCancelled = isWarranty
        ? (booking.warranty?.rejectedTechnicians?.any(
                (worker) => worker.uid == LocalStore.getUID(),
              ) ??
              false)
        : booking.cancelledWorkers.any(
            (worker) => worker.uid == LocalStore.getUID(),
          );

    if (bookingCancelled) {
      return Colors.red;
    }
    if (isWarranty) {
      switch (booking.warranty!.warrantyStatusCode) {
        case "X":
        case "E":
          return Colors.red;
        case "R":
          return Colors.blue;
        case "S":
          return Colors.orange;
        case "C":
          return Colors.green;
        default:
          return Colors.blue;
      }
    } else {
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
  }

  final TextEditingController reasonController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
                builder: (context) => BookingInfo(
                  booking: booking,
                  isAdmin: isAdmin,
                  isWarranty: isWarranty,
                ),
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
                  if ((!isAdmin &&
                          booking.bookingStatusCode == 'P' &&
                          !booking.cancelledWorkers.any(
                            (worker) => worker.uid == LocalStore.getUID(),
                          )) ||
                      (!isAdmin &&
                          isWarranty &&
                          booking.warranty!.warrantyStatusCode == 'R' &&
                          !(booking.warranty!.rejectedTechnicians?.any(
                                (tech) => tech.uid == LocalStore.getUID(),
                              ) ??
                              false))) ...[
                    IconButton(
                      onPressed: () {
                        _showAcceptConfirmationDialog(
                          context,
                          booking,
                          isWarranty,
                        );
                      },
                      icon: Icon(Icons.check_circle, color: Colors.green),
                    ),

                    IconButton(
                      onPressed: () {
                        showRejectBookingDialog(context, booking, isWarranty);
                      },
                      icon: Icon(Icons.cancel, color: Colors.red),
                    ),
                  ],
                  if ((isAdmin &&
                          !isWarranty &&
                          onAssign != null &&
                          booking.bookingStatusCode == 'P') ||
                      (isAdmin &&
                          isWarranty &&
                          booking.warranty!.warrantyStatusCode == 'R'))
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
                          "${AppLocalizations.of(context)!.rejectedAt}: ${LocalizationHelper().formatDateLocalized(booking.rejectedAt!.toDate(), context)}",
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

  void _showAcceptConfirmationDialog(
    BuildContext context,
    BookingModel booking,
    bool isWarranty,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.start,
          title: Text(
            isWarranty
                ? AppLocalizations.of(context)!.acceptWarrantyRepair
                : AppLocalizations.of(context)!.acceptBooking,
          ),
          content: Text(
            AppLocalizations.of(context)!.areYouSureYouWantToAcceptThisBooking,
          ),
          actions: [
            eButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              text: AppLocalizations.of(context)!.cancel,
              context: context,
              textColor: Colors.white,
              backgroundColor: Colors.grey,
            ),
            eButton(
              onPressed: isWarranty
                  ? () {
                      AppFirestore.bookingsCollectionRef
                          .doc(booking.id)
                          .update({
                            'warranty.warrantyStatusCode': 'S',
                            'warranty.acceptedAt': FieldValue.serverTimestamp(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) =>
                              Home(newIndex: 2, selectedFilter: "S"),
                        ),
                        (route) => false,
                      );
                    }
                  : () {
                      AppFirestore.bookingsCollectionRef
                          .doc(booking.id)
                          .update({
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
              text: AppLocalizations.of(context)!.accept,
              context: context,
              textColor: Colors.white,
              backgroundColor: Colors.green,
            ),
          ],
        );
      },
    );
  }

  void showRejectBookingDialog(
    BuildContext context,
    BookingModel booking,
    bool isWarranty,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.start,
          title: Text(AppLocalizations.of(context)!.rejectBooking),
          content: isWarranty
              ? Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.areYouSureYouWantToRejectThisBooking,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          )!.reasonforrejection,
                          hintText: AppLocalizations.of(
                            context,
                          )!.enterReasonForReject,
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(
                              context,
                            )!.pleaseProvideARejectionReason;
                          }
                          if (value.trim().length < 10) {
                            return AppLocalizations.of(
                              context,
                            )!.reasonMustBeAtLeast10Characters;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                )
              : Text(
                  AppLocalizations.of(
                    context,
                  )!.areYouSureYouWantToRejectThisBooking,
                ),
          actions: [
            eButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              text: AppLocalizations.of(context)!.cancel,
              context: context,
              textColor: Colors.black,
              backgroundColor: Colors.grey.shade100,
            ),
            eButton(
              onPressed: isWarranty
                  ? () async {
                      if (formKey.currentState!.validate()) {
                        final technicianDoc = await AppFirestore
                            .usersCollectionRef
                            .doc(booking.warranty?.assignedTechnicianId ?? '')
                            .get();

                        final tech = UserModel.fromDocumentSnapshot(
                          technicianDoc,
                        );

                        if (context.mounted) {
                          context.read<WarrantyBloc>().add(
                            CancelWarranty(
                              bookingId: booking.id,
                              technicianName: tech.name ?? "",
                              technicianPhone: tech.phone ?? "",
                              technicianUid:
                                  booking.warranty?.assignedTechnicianId ?? '',
                              rejectionReason: reasonController.text.trim(),
                            ),
                          );

                          Navigator.of(context).pop();
                        }
                      }
                    }
                  : () {
                      context.read<BookingBloc>().add(
                        CancelBooking(
                          bookingId: booking.id,
                          agentUid: booking.agent?.uid ?? '',
                          agentName: booking.agent?.name ?? '',
                        ),
                      );
                      Navigator.of(context).pop();
                    },
              text: AppLocalizations.of(context)!.reject,
              context: context,
              textColor: Colors.white,
              backgroundColor: Colors.red,
            ),
          ],
        );
      },
    );
  }
}
