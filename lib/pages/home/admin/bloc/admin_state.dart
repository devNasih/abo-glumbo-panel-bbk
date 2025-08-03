part of 'admin_bloc.dart';

sealed class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object> get props => [];
}

final class AdminInitial extends AdminState {}

// Loading states
final class AssigningAgent extends AdminState {}

final class RejectingOrder extends AdminState {}

// Success states
final class AgentAssigned extends AdminState {
  final bool isAssigned;
  const AgentAssigned(this.isAssigned);

  @override
  List<Object> get props => [isAssigned];
}

final class OrderRejected extends AdminState {
  final bool isRejected;
  const OrderRejected(this.isRejected);

  @override
  List<Object> get props => [isRejected];
}

// Error states
final class AgentAssignmentError extends AdminState {
  final String error;
  const AgentAssignmentError(this.error);

  @override
  List<Object> get props => [error];
}

final class OrderRejectionError extends AdminState {
  final String error;
  const OrderRejectionError(this.error);

  @override
  List<Object> get props => [error];
}
