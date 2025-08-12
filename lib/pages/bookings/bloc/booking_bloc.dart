import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/main.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingTrackerService tracker;
  BookingBloc(this.tracker) : super(BookingInitial()) {
    on<CancelBooking>(_cancelBookingWorker);
    on<CompleteBooking>(_completeBookingWorker);
    on<StartWorkingOnBooking>(_startBookingWorker);
    on<StopWorkingOnBooking>(_stopWorkingOnBookingWorker);
  }
  Future<void> _cancelBookingWorker(
    CancelBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingCancelLoading());
    try {
      emit(BookingCancelLoading());
      try {
        bool isSuccess = await AppServices.cancelBooking(
          event.bookingId,
          agentUid: event.agentUid,
          agentName: event.agentName,
        );
        if (isSuccess) {
          emit(BookingCancelSuccess());
        } else {
          emit(BookingCancelFailure(error: "Failed to cancel booking"));
        }
      } catch (e) {
        emit(BookingCancelFailure(error: e.toString()));
      }
    } catch (e) {
      emit(BookingCancelFailure(error: e.toString()));
    }
  }

  Future<void> _completeBookingWorker(
    CompleteBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingCompleteLoading());
    try {
      bool isSuccess = await AppServices.completeBooking(event.bookingId);
      if (isSuccess) {
        emit(BookingCompleteSuccess());
      } else {
        emit(BookingCompleteFailure(error: "Failed to complete booking"));
      }
    } catch (e) {
      emit(BookingCompleteFailure(error: e.toString()));
    }
  }

  Future<void> _startBookingWorker(
    StartWorkingOnBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingStartWorkingLoading());
    try {
      await tracker.startWorking(
        context: event.context,
        bookingId: event.bookingId,
        uid: event.uid,
      );

      // Configure background fetch with error handling
      try {
        await BackgroundFetch.configure(
          BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            startOnBoot: true,
            enableHeadless: true,
          ),
          (String taskId) async {
            backgroundFetchHeadlessTask(HeadlessTask(taskId, false));
          },
          (String taskId) {
            BackgroundFetch.finish(taskId);
          },
        );
      } catch (backgroundFetchError) {
        // Background fetch failed, but continue with foreground tracking
        print('Background fetch configuration failed: $backgroundFetchError');
      }

      emit(BookingStartWorkingSuccess());
    } catch (e) {
      // Provide specific error messages for common iOS issues
      String errorMessage = e.toString();
      if (errorMessage.contains('PlatformException') &&
          errorMessage.contains('1')) {
        final localizations = AppLocalizations.of(event.context);
        errorMessage =
            localizations?.locationPermissionErrorIOS ??
            'Location permission error on iOS. Please enable location access in Settings.';
      } else if (errorMessage.contains('Location permission')) {
        // Keep existing permission error messages
      } else if (errorMessage.contains('Location services disabled')) {
        // Keep existing service error messages
      }

      emit(BookingStartWorkingFailure(error: errorMessage));
    }
  }

  Future<void> _stopWorkingOnBookingWorker(
    StopWorkingOnBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingStopWorkingLoading());
    try {
      await tracker.stopTracking();
      emit(BookingStopWorkingSuccess());
    } catch (e) {
      emit(BookingStopWorkingFailure(error: e.toString()));
    }
  }
}
