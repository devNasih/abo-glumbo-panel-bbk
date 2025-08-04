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
