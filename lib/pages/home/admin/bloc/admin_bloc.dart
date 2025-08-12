import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc() : super(AdminInitial()) {
    on<AssignAgentEvent>(_assignAgent);
    on<RejectOrderEvent>(_rejectOrder);
  }

  Future<void> _assignAgent(
    AssignAgentEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AssigningAgent());

    try {
      await AppFirestore.bookingsCollectionRef.doc(event.booking.id).update({
        'agent': event.user.toJson(),
        'bookingStatusCode': 'A',
        'cancelledBy': FieldValue.delete(),
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      emit(AgentAssigned(true, assignedAgent: event.user));
    } catch (e) {
      emit(AgentAssignmentError(e.toString()));
    }
  }

  Future<void> _rejectOrder(
    RejectOrderEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(RejectingOrder());

    try {
      await AppFirestore.bookingsCollectionRef.doc(event.booking.id).update({
        'bookingStatusCode': 'R',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      emit(OrderRejected(true));
    } catch (e) {
      emit(OrderRejectionError(e.toString()));
    }
  }
}
