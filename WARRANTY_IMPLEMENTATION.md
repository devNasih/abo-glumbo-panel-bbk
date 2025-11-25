# Warranty Page Implementation Summary

## Overview

This document outlines the implementation of the warranty repair functionality with admin/technician role distinction using `workerData.isAdmin`.

## Files Created/Modified

### 1. **warranty_page.dart** ✅ COMPLETE

- **Location**: `lib/pages/bookings/warranty_page.dart`
- **Features Implemented**:
  - Filter chips for warranty statuses: Pending (P), Started (S), Completed (C), Rejected (X)
  - Search bar to search by Booking ID, Customer Name, and Technician Name
  - Tab-based filtering with proper stream handling
  - Support for both admin and technician views
  - Uses `BookingCards` widget for consistent UI
  - Loading, empty, and error states with animations

### 2. **warranty_controllers.dart** ✅ COMPLETE

- **Location**: `lib/pages/bookings/warranty_controllers.dart`
- **Features Implemented**:
  - Warranty-specific control buttons
  - Start/Stop tracking functionality (same as bookings)
  - Cancel button (technician reject - adds to rejectedTechnicians, sets assignedTechnicianId to null)
  - Complete Warranty button (free service - no payment required)
  - Conditional rendering based on warranty status (buttons only show when status = 'S')
  - Integration with BookingBloc for state management

### 3. **app_services.dart** ✅ COMPLETE

- **Location**: `lib/services/app_services.dart`
- **Method Added**: `getWarrantiesStream()`
- **Features**:
  - Filters bookings where `warranty != null`, `paymentCompleted = true`, `bookingStatusCode = 'C'`
  - Admin sees all warranties
  - Technician sees only warranties where `warranty.assignedTechnicianId` matches their UID
  - Filters by warranty status code (P, S, C, X)
  - Ordered by `createdAt` descending

### 4. **booking_event.dart** ✅ COMPLETE

- **Location**: `lib/pages/bookings/bloc/booking_event.dart`
- **Events Added**:
  - `CancelWarranty` - Technician cancels/rejects warranty
  - `CompleteWarranty` - Complete warranty repair (free)
  - `StartWorkingOnWarranty` - Start tracking warranty repair
  - `AcceptWarranty` - Technician accepts warranty assignment
  - `RejectWarranty` - Technician rejects warranty assignment

## What Still Needs to Be Done

### 1. **booking_bloc.dart** ⚠️ REQUIRED

You need to add event handlers in the booking_bloc.dart file for the new warranty events:

```dart
// In booking_bloc.dart, add these handlers:

on<AcceptWarranty>(_onAcceptWarranty);
on<RejectWarranty>(_onRejectWarranty);
on<CancelWarranty>(_onCancelWarranty);
on<CompleteWarranty>(_onCompleteWarranty);
on<StartWorkingOnWarranty>(_onStartWorkingOnWarranty);

// Handler implementations:

Future<void> _onAcceptWarranty(
  AcceptWarranty event,
  Emitter<BookingState> emit,
) async {
  try {
    emit(BookingAcceptLoading());

    await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
      'warranty.warrantyStatusCode': 'S',
      'warranty.acceptedOn': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    emit(BookingAcceptSuccess());
  } catch (e) {
    emit(BookingAcceptFailure(e.toString()));
  }
}

Future<void> _onRejectWarranty(
  RejectWarranty event,
  Emitter<BookingState> emit,
) async {
  try {
    emit(BookingRejectLoading());

    final bookingDoc = await AppFirestore.bookingsCollectionRef
        .doc(event.bookingId)
        .get();

    final booking = BookingModel.fromDocumentSnapshot(bookingDoc);
    final rejectedTechs = booking.warranty?.rejectedTechnicians ?? [];

    rejectedTechs.add(RejectedTechnicianModel(
      uid: event.technicianUid,
      name: event.technicianName,
      rejectedOn: DateTime.now(),
    ));

    await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
      'warranty.assignedTechnicianId': null,
      'warranty.rejectedTechnicians': rejectedTechs.map((e) => e.toJson()).toList(),
      'warranty.rejectedOn': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    emit(BookingRejectSuccess());
  } catch (e) {
    emit(BookingRejectFailure(e.toString()));
  }
}

Future<void> _onCancelWarranty(
  CancelWarranty event,
  Emitter<BookingState> emit,
) async {
  try {
    emit(BookingCancelLoading());

    final bookingDoc = await AppFirestore.bookingsCollectionRef
        .doc(event.bookingId)
        .get();

    final booking = BookingModel.fromDocumentSnapshot(bookingDoc);
    final rejectedTechs = booking.warranty?.rejectedTechnicians ?? [];

    rejectedTechs.add(RejectedTechnicianModel(
      uid: event.technicianUid,
      name: event.technicianName,
      rejectedOn: DateTime.now(),
    ));

    await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
      'warranty.assignedTechnicianId': null,
      'warranty.rejectedTechnicians': rejectedTechs.map((e) => e.toJson()).toList(),
      'updatedAt': Timestamp.now(),
    });

    emit(BookingCancelSuccess());
  } catch (e) {
    emit(BookingCancelFailure(e.toString()));
  }
}

Future<void> _onCompleteWarranty(
  CompleteWarranty event,
  Emitter<BookingState> emit,
) async {
  try {
    emit(BookingCompleteLoading());

    await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
      'warranty.warrantyStatusCode': 'C',
      'warranty.completedOn': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    emit(BookingCompleteSuccess());
  } catch (e) {
    emit(BookingCompleteFailure(e.toString()));
  }
}

Future<void> _onStartWorkingOnWarranty(
  StartWorkingOnWarranty event,
  Emitter<BookingState> emit,
) async {
  // Same implementation as StartWorkingOnBooking
  // Just use the same tracking service
  return _onStartWorkingOnBooking(
    StartWorkingOnBooking(
      bookingId: event.bookingId,
      uid: event.uid,
      context: event.context,
    ),
    emit,
  );
}
```

### 2. **booking_info.dart** ⚠️ REQUIRED

Update `booking_info.dart` to:

- Detect if the booking is a warranty repair (check `booking.warranty != null`)
- Show warranty-specific UI elements
- Use `WarrantyControlsWidget` instead of `BookingControlsWidget` when it's a warranty
- Display warranty status and information
- Show accept/reject buttons for technicians when warranty status is 'P' (Pending)
- Show admin reject button when `workerData.isAdmin == true`

Example changes needed:

```dart
// In booking_info.dart, check if it's a warranty:
final isWarranty = widget.booking.warranty != null;
final warrantyStatus = widget.booking.warranty?.warrantyStatusCode;

// Show appropriate controls:
if (isWarranty) {
  if (warrantyStatus == 'P' && !widget.workerData.isAdmin) {
    // Show Accept/Reject buttons for technician
    _buildWarrantyAcceptRejectButtons();
  } else if (warrantyStatus == 'S') {
    // Show tracking and complete buttons
    WarrantyControlsWidget(
      booking: widget.booking,
      isTracking: widget.booking.isStartTracking ?? false,
      isAdmin: widget.workerData.isAdmin ?? false,
    );
  }

  // Admin can reject at any time
  if (widget.workerData.isAdmin ?? false) {
    _buildAdminRejectWarrantyButton();
  }
}
```

### 3. **booking_cards.dart** ⚠️ OPTIONAL

Consider adding a visual indicator for warranty repairs:

- Add a warranty badge/chip to the card
- Different color scheme for warranty cards
- Show warranty status prominently

### 4. **Admin Home / Worker Home** ⚠️ REQUIRED

Add navigation to the warranty page:

- Add a "Warranty Repairs" tab or menu item
- Pass `workerData` to the `WarrantyPage` widget

Example:

```dart
// In admin_home.dart or worker_home.dart:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => WarrantyPage(
      workerData: currentUserData,
    ),
  ),
);
```

### 5. **Admin Assign Technician** ⚠️ REQUIRED

Update the technician assignment logic to:

- Check if it's a warranty repair
- Prevent assigning to technicians in `rejectedTechnicians` list
- Update `warranty.assignedTechnicianId` instead of `agent.uid`

### 6. **Firebase Functions** ⚠️ REQUIRED (Backend)

You'll need to add Cloud Functions for:

- Sending notifications when warranty is assigned
- Sending notifications when warranty is accepted/rejected
- Sending notifications when warranty is completed
- Updating warranty status based on actions

## Warranty Status Flow

1. **Pending (P)**: Warranty created, waiting for technician assignment
2. **Started (S)**: Technician accepted, can start tracking and complete
3. **Completed (C)**: Warranty repair completed (free service)
4. **Rejected (X)**: Admin rejected the warranty claim

## Technician Actions by Status

| Status | Technician Can                                  | Admin Can      |
| ------ | ----------------------------------------------- | -------------- |
| P      | Accept, Reject                                  | Assign, Reject |
| S      | Start Tracking, Stop Tracking, Cancel, Complete | Reject         |
| C      | View only                                       | View only      |
| X      | View only                                       | View only      |

## Key Differences from Regular Bookings

1. **No Payment Required**: Warranty repairs are free
2. **Rejection Tracking**: Tracks which technicians rejected the warranty
3. **Cannot Reassign**: Once a technician rejects, they cannot be assigned again
4. **Status-Based Controls**: Buttons only appear when warranty status allows

## Testing Checklist

- [ ] Admin can view all warranties
- [ ] Technician can view only assigned warranties
- [ ] Filter chips work correctly
- [ ] Search functionality works
- [ ] Technician can accept warranty (status changes to 'S')
- [ ] Technician can reject warranty (added to rejectedTechnicians, assignedTechnicianId = null)
- [ ] Technician can start/stop tracking
- [ ] Technician can complete warranty (free, status changes to 'C')
- [ ] Technician can cancel warranty (same as reject)
- [ ] Admin can reject warranty (status changes to 'X')
- [ ] Admin cannot assign to rejected technicians
- [ ] Notifications are sent for all actions

## Next Steps

1. Implement the booking_bloc handlers (highest priority)
2. Update booking_info.dart to show warranty controls
3. Add navigation from home pages
4. Implement admin assignment logic
5. Add Firebase Functions for notifications
6. Test all workflows thoroughly
