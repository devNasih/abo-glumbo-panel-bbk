import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc() : super(BookingInitial()) {
    on<CancelBooking>(_cancelBookingWorker);
    on<CompleteBooking>(_completeBookingWorker);
  }
  Future<void> _cancelBookingWorker(
    CancelBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingCancelLoading());
    try {
      emit(BookingCancelLoading());
      try {
        bool isSuccess = await AppServices.cancelBooking(event.bookingId);
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
}
