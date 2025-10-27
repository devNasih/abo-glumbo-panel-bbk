part of 'admin_bloc.dart';

sealed class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object> get props => [];
}

class AssignAgentEvent extends AdminEvent {
  final BookingModel booking;
  final UserModel user;

  const AssignAgentEvent({required this.booking, required this.user});

  @override
  List<Object> get props => [booking, user];
}

class RejectOrderEvent extends AdminEvent {
  final BookingModel booking;

  const RejectOrderEvent({required this.booking});

  @override
  List<Object> get props => [booking];
}
