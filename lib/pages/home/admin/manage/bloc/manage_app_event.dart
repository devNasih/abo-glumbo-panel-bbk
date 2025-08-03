part of 'manage_app_bloc.dart';

sealed class ManageAppEvent extends Equatable {
  const ManageAppEvent();

  @override
  List<Object> get props => [];
}

class ClearTipWalletEvent extends ManageAppEvent {
  final String agentId;
  const ClearTipWalletEvent(this.agentId);

  @override
  List<Object> get props => [agentId];
}

class ApproveRejectAgentEvent extends ManageAppEvent {
  final String agentId;
  final bool isApproved;
  const ApproveRejectAgentEvent(this.agentId, this.isApproved);

  @override
  List<Object> get props => [agentId, isApproved];
}
