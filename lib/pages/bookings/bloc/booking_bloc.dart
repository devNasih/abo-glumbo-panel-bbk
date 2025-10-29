import 'dart:io';

import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/main.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingTrackerService tracker;
  BookingBloc(this.tracker) : super(BookingInitial()) {
    on<CancelBooking>(_cancelBookingWorker);
    on<CompleteBooking>(_completeBookingWorker);
    on<StartWorkingOnBooking>(_startBookingWorker);
    on<StopWorkingOnBooking>(_stopWorkingOnBookingWorker);
  }

  Future<void> _cancelBookingWorker(
    CancelBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingCancelLoading());
    try {
      bool isSuccess = await AppServices.cancelBooking(
        event.bookingId,
        agentUid: event.agentUid,
        agentName: event.agentName,
      );
      if (isSuccess) {
        emit(BookingCancelSuccess());
      } else {
        emit(BookingCancelFailure(error: "Failed to cancel booking"));
      }
    } catch (e) {
      emit(BookingCancelFailure(error: e.toString()));
    }
  }

  Future<void> _completeBookingWorker(
    CompleteBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingCompleteLoading());
    try {
      // Step 1: Upload image to Firebase Storage
      String imageUrl = await _uploadImageToStorage(
        event.selectedImage,
        event.bookingId,
      );

      // Step 2: Prepare service items data
      List<Map<String, dynamic>> serviceItemsData = event.serviceItems
          .map((item) => item.toMap())
          .toList();

      // Step 3: Save booking completion data to Firestore
      await _saveBookingCompletionData(
        bookingId: event.bookingId,
        imageUrl: imageUrl,
        serviceCost: event.serviceCost,
        serviceItems: serviceItemsData,
        paymentMethod: event.selectedPaymentMethod.toLowerCase() == 'card'
            ? 'C'
            : 'O',
        totalCost: event.totalCost,
        mode: event.mode,
      );

      // Step 4: Update booking status using existing service
      bool isSuccess = await AppServices.completeBooking(event.bookingId);

      if (isSuccess) {
        emit(BookingCompleteSuccess());
      } else {
        emit(BookingCompleteFailure(error: "Failed to update booking status"));
      }
    } catch (e) {
      emit(BookingCompleteFailure(error: e.toString()));
    }
  }

  // Upload image to Firebase Storage and return download URL
  Future<String> _uploadImageToStorage(File imageFile, String bookingId) async {
    try {
      // Create a unique filename using timestamp and booking ID
      String fileName =
          'booking_completion_${bookingId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload the file
      final uploadTask = AppFireStorage.servicesStorageRef
          .child(fileName)
          .putFile(imageFile);

      // Wait for upload to complete and get download URL
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Save booking completion data to Firestore
  Future<void> _saveBookingCompletionData({
    required String bookingId,
    required String imageUrl,
    required double serviceCost,
    required List<Map<String, dynamic>> serviceItems,
    required String paymentMethod,
    required double totalCost,
    required int mode,
  }) async {
    try {
      // Update the existing booking document with completion details
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'completionData': {
              'imageUrl': imageUrl,
              'serviceCost': serviceCost,
              'serviceItems': serviceItems,
              'paymentMethod': paymentMethod,
              'totalCost': totalCost,
              'mode': mode,
            },
            'completedAt': FieldValue.serverTimestamp(),
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to save booking completion data: $e');
    }
  }

  Future<void> _startBookingWorker(
    StartWorkingOnBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingStartWorkingLoading());
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
            backgroundFetchHeadlessTask(HeadlessTask(taskId, false));
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

      emit(BookingStartWorkingSuccess());
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('PlatformException') &&
          errorMessage.contains('1')) {
        final localizations = AppLocalizations.of(event.context);
        errorMessage =
            localizations?.locationPermissionErrorIOS ??
            'Location permission error on iOS. Please enable location access in Settings.';
      }

      emit(BookingStartWorkingFailure(error: errorMessage));
    }
  }

  Future<void> _stopWorkingOnBookingWorker(
    StopWorkingOnBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingStopWorkingLoading());
    try {
      await tracker.stopTracking();
      emit(BookingStopWorkingSuccess());
    } catch (e) {
      emit(BookingStopWorkingFailure(error: e.toString()));
    }
  }
}
