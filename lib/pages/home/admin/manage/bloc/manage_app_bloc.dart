import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'manage_app_event.dart';
part 'manage_app_state.dart';

class ManageAppBloc extends Bloc<ManageAppEvent, ManageAppState> {
  ManageAppBloc() : super(ManageAppInitial()) {
    on<ClearTipWalletEvent>(_clearTipWallet);
    on<ApproveRejectAgentEvent>(_approveRejectAgent);
  }

  Future<void> _clearTipWallet(
    ClearTipWalletEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(ClearingWallet());
    try {
      await AppServices.clearTippingAmount(event.agentId);
      emit(WalletCleared());
    } catch (e) {
      emit(WalletClearError(e.toString()));
    }
  }

  Future<void> _approveRejectAgent(
    ApproveRejectAgentEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(ApprovingAgent());
    try {
      await AppServices.approveOrRejectAgent(event.agentId, event.isApproved);
      emit(AgentApproved(event.isApproved));
    } catch (e) {
      emit(AgentApprovalError(e.toString()));
    }
  }
}
