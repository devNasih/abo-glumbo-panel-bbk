part of 'booking_bloc.dart';

sealed class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object> get props => [];
}

class CancelBooking extends BookingEvent {
  final String bookingId;

  const CancelBooking({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class CompleteBooking extends BookingEvent {
  final String bookingId;

  const CompleteBooking({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class StartWorkingOnBooking extends BookingEvent {
  final String bookingId;
  final String uid;
  final BuildContext context;

  const StartWorkingOnBooking({
    required this.bookingId,
    required this.uid,
    required this.context,
  });

  @override
  List<Object> get props => [bookingId, uid, context];
}

class StopWorkingOnBooking extends BookingEvent {
  final String bookingId;

  const StopWorkingOnBooking({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}
