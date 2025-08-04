part of 'booking_bloc.dart';

sealed class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object> get props => [];
}

final class BookingInitial extends BookingState {}

final class BookingCancelLoading extends BookingState {}

final class BookingCancelSuccess extends BookingState {}

final class BookingCancelFailure extends BookingState {
  final String error;

  const BookingCancelFailure({required this.error});

  @override
  List<Object> get props => [error];
}

final class BookingCompleteLoading extends BookingState {}

final class BookingCompleteSuccess extends BookingState {}

final class BookingCompleteFailure extends BookingState {
  final String error;
  const BookingCompleteFailure({required this.error});
  @override
  List<Object> get props => [error];
}
