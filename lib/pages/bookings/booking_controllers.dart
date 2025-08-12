import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/booking_bloc.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';

class BookingControlsWidget extends StatefulWidget {
  final BookingModel booking;
  final bool isTracking;

  static final BookingTrackerService _trackerService = BookingTrackerService();

  const BookingControlsWidget({
    super.key,
    required this.booking,
    required this.isTracking,
  });

  @override
  State<BookingControlsWidget> createState() => _BookingControlsWidgetState();
}

class _BookingControlsWidgetState extends State<BookingControlsWidget> {
  bool isCancelBookingButtonBlocked = false;

  @override
  void initState() {
    super.initState();
    _initializeCancelButtonState();
  }

  void _initializeCancelButtonState() {
    final isCurrentlyTracking =
        BookingControlsWidget._trackerService.isTracking.value;
    setState(() {
      isCancelBookingButtonBlocked = isCurrentlyTracking;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingCancelSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.bookingCancelledSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BookingCancelFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is BookingCompleteSuccess) {
          setState(() => isCancelBookingButtonBlocked = false);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.bookingCompletedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BookingCompleteFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is BookingStartWorkingSuccess) {
          setState(() => isCancelBookingButtonBlocked = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.startedWorkingOnBookingSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BookingStartWorkingFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is BookingStopWorkingSuccess) {
          setState(() => isCancelBookingButtonBlocked = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.stopTrackingBookingSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BookingStopWorkingFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isCancelLoading = state is BookingCancelLoading;
        final isCompleteLoading = state is BookingCompleteLoading;
        final isStartWorkingLoading = state is BookingStartWorkingLoading;
        final isStopWorkingLoading = state is BookingStopWorkingLoading;

        return ValueListenableBuilder<bool>(
          valueListenable: BookingControlsWidget._trackerService.isTracking,
          builder: (context, serviceIsTracking, child) {
            final actualIsTracking = serviceIsTracking;
            final currentTrackingBookingId =
                BookingControlsWidget._trackerService.currentBookingId;
            final isThisBookingTracked =
                actualIsTracking &&
                currentTrackingBookingId == widget.booking.id;

            final shouldBlockCancel = actualIsTracking;

            return Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildButton(
                          onPressed: shouldBlockCancel || isCancelLoading
                              ? null
                              : () => _showCancelDialog(context),
                          label: AppLocalizations.of(context)!.cancelBooking,
                          color: shouldBlockCancel
                              ? Colors.grey
                              : Colors.red.shade50,
                          textColor: shouldBlockCancel
                              ? Colors.grey.shade700
                              : Colors.red.shade700,
                          borderColor: shouldBlockCancel
                              ? Colors.grey.shade200
                              : Colors.red.shade200,
                          isLoading: isCancelLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildButton(
                          onPressed:
                              (isStartWorkingLoading ||
                                  isStopWorkingLoading ||
                                  isCancelLoading ||
                                  isCompleteLoading ||
                                  (actualIsTracking &&
                                      BookingControlsWidget
                                              ._trackerService
                                              .currentBookingId !=
                                          widget.booking.id))
                              ? null
                              : isThisBookingTracked
                              ? () => _showStopTrackingDialog(context)
                              : () => _showStartTrackingDialog(context),
                          label: isThisBookingTracked
                              ? AppLocalizations.of(context)!.stopTracking
                              : AppLocalizations.of(context)!.startTracking,
                          color: isThisBookingTracked
                              ? Colors.orange.shade50
                              : Colors.blue.shade50,
                          textColor: isThisBookingTracked
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                          borderColor: isThisBookingTracked
                              ? Colors.orange.shade200
                              : Colors.blue.shade200,
                          isLoading:
                              isStartWorkingLoading || isStopWorkingLoading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isCompleteLoading
                          ? null
                          : () => _showCompleteWorkDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isCompleteLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)!.completeWork,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String label,
    required Color color,
    required Color textColor,
    required Color borderColor,
    bool isLoading = false,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: onPressed == null ? Colors.grey.shade100 : color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: onPressed == null ? Colors.grey.shade300 : borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: onPressed == null
                          ? Colors.grey.shade500
                          : textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final trackerService = BookingControlsWidget._trackerService;
    if (trackerService.isTracking.value) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.cancelBooking),
            content: Text(
              'Cannot cancel this booking while tracking is active. Please stop tracking first, then you can cancel the booking.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.cancelBooking),
          content: Text(
            AppLocalizations.of(context)!.areYouSureYouWantToCancelThisBooking,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<BookingBloc>().add(
                  CancelBooking(
                    bookingId: widget.booking.id,
                    agentUid: widget.booking.agent?.uid ?? '',
                    agentName: widget.booking.agent?.name ?? '',
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
        );
      },
    );
  }

  void _showStartTrackingDialog(BuildContext context) {
    final trackerService = BookingControlsWidget._trackerService;
    if (trackerService.isTracking.value &&
        trackerService.currentBookingId != null &&
        trackerService.currentBookingId != widget.booking.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Another booking is already being tracked. Please complete or stop the current tracking before starting a new one.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.startTracking),
          content: Text(
            AppLocalizations.of(
              context,
            )!.areYouSureYouWantToStartTrackingThisBooking,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final uid = LocalStore.getUID();
                if (uid != null) {
                  context.read<BookingBloc>().add(
                    StartWorkingOnBooking(
                      context: context,
                      bookingId: widget.booking.id,
                      uid: uid,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
        );
      },
    );
  }

  void _showStopTrackingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.stopTracking),
          content: Text(
            AppLocalizations.of(
              context,
            )!.areYouSureYouWantToStopTrackingThisBooking,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<BookingBloc>().add(
                  StopWorkingOnBooking(bookingId: widget.booking.id),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
        );
      },
    );
  }

  void _showCompleteWorkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.completeWork),
          content: Text(
            AppLocalizations.of(
              context,
            )!.areYouSureYouWantToCompleteThisBooking,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<BookingBloc>().add(
                  CompleteBooking(bookingId: widget.booking.id),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
        );
      },
    );
  }
}
