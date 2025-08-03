part of 'manage_app_bloc.dart';

sealed class ManageAppState extends Equatable {
  const ManageAppState();

  @override
  List<Object> get props => [];
}

final class ManageAppInitial extends ManageAppState {}

final class ClearingWallet extends ManageAppState {}

final class WalletCleared extends ManageAppState {}

final class WalletClearError extends ManageAppState {
  final String error;
  const WalletClearError(this.error);
  @override
  List<Object> get props => [error];
}

final class ApprovingAgent extends ManageAppState {}

final class AgentApproved extends ManageAppState {
  final bool isApproved;
  const AgentApproved(this.isApproved);
  @override
  List<Object> get props => [isApproved];
}

final class AgentApprovalError extends ManageAppState {
  final String error;
  const AgentApprovalError(this.error);

  @override
  List<Object> get props => [error];
}
