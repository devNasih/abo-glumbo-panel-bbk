import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/booking_bloc.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';

class BookingControlsWidget extends StatelessWidget {
  final BookingModel booking;
  final bool isTracking;

  // Static reference to ensure we're using the same service instance
  static final BookingTrackerService _trackerService = BookingTrackerService();

  const BookingControlsWidget({
    super.key,
    required this.booking,
    required this.isTracking,
  });

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

        // Use ValueListenableBuilder to get real-time tracking state from the service
        return ValueListenableBuilder<bool>(
          valueListenable: _trackerService.isTracking,
          builder: (context, serviceIsTracking, child) {
            // Use service state as the primary source of truth
            // Only fall back to Firestore state if service is not tracking but Firestore shows active
            final actualIsTracking = serviceIsTracking;

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
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildButton(
                          onPressed: isCancelLoading
                              ? null
                              : () => _showCancelDialog(context),
                          label: AppLocalizations.of(context)!.cancelBooking,
                          color: Colors.red.shade50,
                          textColor: Colors.red.shade700,
                          borderColor: Colors.red.shade200,
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
                                  isCompleteLoading)
                              ? null
                              : actualIsTracking
                              ? () => _showStopTrackingDialog(context)
                              : () => _showStartTrackingDialog(context),
                          label: actualIsTracking
                              ? AppLocalizations.of(context)!.stopTracking
                              : AppLocalizations.of(context)!.startTracking,
                          color: actualIsTracking
                              ? Colors.orange.shade50
                              : Colors.blue.shade50,
                          textColor: actualIsTracking
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                          borderColor: actualIsTracking
                              ? Colors.orange.shade200
                              : Colors.blue.shade200,
                          isLoading:
                              isStartWorkingLoading || isStopWorkingLoading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Complete button
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
                  CancelBooking(bookingId: booking.id),
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
                      bookingId: booking.id,
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
                  StopWorkingOnBooking(bookingId: booking.id),
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
                  CompleteBooking(bookingId: booking.id),
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
