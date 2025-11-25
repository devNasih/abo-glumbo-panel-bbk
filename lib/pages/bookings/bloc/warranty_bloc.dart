import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/models/warranty.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'warranty_event.dart';
part 'warranty_state.dart';

class WarrantyBloc extends Bloc<WarrantyEvent, WarrantyState> {
  final BookingTrackerService tracker;

  WarrantyBloc(this.tracker) : super(WarrantyInitial()) {
    on<AcceptWarranty>(_onAcceptWarranty);
    on<AssignWarrantyTechnician>(_onAssignWarrantyTechnician);
    on<RejectWarranty>(_onRejectWarranty);
    on<CancelWarranty>(_onCancelWarranty);
    on<CompleteWarranty>(_onCompleteWarranty);
    on<StartWorkingOnWarranty>(_onStartWorkingOnWarranty);
    on<StopWorkingOnWarranty>(_onStopWorkingOnWarranty);
  }

  Future<void> _onAcceptWarranty(
    AcceptWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    try {
      emit(WarrantyAcceptLoading());

      await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
        'warranty.warrantyStatusCode': 'S',
        'warranty.acceptedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      emit(WarrantyAcceptSuccess());
    } catch (e) {
      emit(WarrantyAcceptFailure(e.toString()));
    }
  }

  Future<void> _onRejectWarranty(
    RejectWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    try {
      emit(WarrantyRejectLoading());

      await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
        'warranty.assignedTechnicianId': null,
        'warranty.warrantyStatusCode': 'X',
        'warranty.rejectedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      emit(WarrantyRejectSuccess());
    } catch (e) {
      emit(WarrantyRejectFailure(e.toString()));
    }
  }

  Future<void> _onCancelWarranty(
    CancelWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    try {
      emit(WarrantyCancelLoading());

      final bookingDoc = await AppFirestore.bookingsCollectionRef
          .doc(event.bookingId)
          .get();

      final booking = BookingModel.fromDocumentSnapshot(bookingDoc);
      final rejectedTechs = booking.warranty?.rejectedTechnicians ?? [];

      rejectedTechs.add(
        RejectedTechnicianModel(
          uid: event.technicianUid,
          name: event.technicianName,
          reason: event.rejectionReason,
          rejectedAt: DateTime.now(),
        ),
      );

      await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
        'warranty.assignedTechnicianId': null,
        'warranty.warrantyStatusCode': 'R',
        'warranty.rejectedTechnicians': rejectedTechs
            .map((e) => e.toJson())
            .toList(),
        'updatedAt': Timestamp.now(),
      });

      emit(WarrantyCancelSuccess());
    } catch (e) {
      emit(WarrantyCancelFailure(error: e.toString()));
    }
  }

  Future<void> _onCompleteWarranty(
    CompleteWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    try {
      emit(WarrantyCompleteLoading());

      await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
        'warranty.warrantyStatusCode': 'C',
        'warranty.availability': Timestamp.now(),
        'warranty.completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      emit(WarrantyCompleteSuccess());
    } catch (e) {
      emit(WarrantyCompleteFailure(error: e.toString()));
    }
  }

  Future<void> _onStartWorkingOnWarranty(
    StartWorkingOnWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    emit(WarrantyStartWorkingLoading());
    try {
      await tracker.startWorking(
        context: event.context,
        bookingId: event.bookingId,
        uid: event.uid,
      );

      // Configure background fetch with error handling
      try {
        await BackgroundFetch.configure(
          BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            startOnBoot: true,
            enableHeadless: true,
          ),
          (String taskId) async {
            // Background fetch callback
            BackgroundFetch.finish(taskId);
          },
          (String taskId) {
            BackgroundFetch.finish(taskId);
          },
        );
      } catch (backgroundFetchError) {
        if (kDebugMode) {
          print('Background fetch configuration failed: $backgroundFetchError');
        }
      }

      emit(WarrantyStartWorkingSuccess());
    } catch (e) {
      emit(WarrantyStartWorkingFailure(error: e.toString()));
    }
  }

  Future<void> _onAssignWarrantyTechnician(
    AssignWarrantyTechnician event,
    Emitter<WarrantyState> emit,
  ) async {
    try {
      emit(WarrantyAssignLoading());

      await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
        'warranty.assignedTechnicianId': event.technician.uid,
        'warranty.warrantyStatusCode': 'S',
        'warranty.acceptedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      emit(WarrantyAssignSuccess());
    } catch (e) {
      emit(WarrantyAssignFailure(error: e.toString()));
    }
  }

  Future<void> _onStopWorkingOnWarranty(
    StopWorkingOnWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    emit(WarrantyStopWorkingLoading());
    try {
      await tracker.stopTracking();
      emit(WarrantyStopWorkingSuccess());
    } catch (e) {
      emit(WarrantyStopWorkingFailure(error: e.toString()));
    }
  }
}
