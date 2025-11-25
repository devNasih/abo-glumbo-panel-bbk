# Warranty Assignment Feature - Implementation Plan

## Objective

When admin clicks "Assign" on a warranty booking card, open the assign worker bottom sheet with simplified conflict checking that only checks if the technician has rejected this specific warranty.

## Current Status

- ✅ `isAdmin` parameter added to `AssignUserBottomSheet` constructor
- ✅ `isWarranty` parameter added to `BookingCards` and passed correctly
- ✅ Admin button visibility fixed - shows "Assign" instead of accept/reject
- ❌ Warranty-specific conflict checking not yet implemented

## What Needs to Be Done

### 1. Update warranty_page.dart

Add `isWarranty: true` parameter when calling `AssignUserBottomSheet`:

```dart
void _showAssignToUserBottomSheet(BookingModel booking) {
  final warrantyBloc = context.read<WarrantyBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return AssignUserBottomSheet(
        booking: booking,
        isWarranty: true,  // ← ADD THIS LINE
        onAssignAgent: ({required BookingModel booking, required UserModel user}) {
          warrantyBloc.add(
            AssignWarrantyTechnician(
              bookingId: booking.id,
              technician: user,
            ),
          );
        },
        onRejectOrder: (BookingModel booking) {
          warrantyBloc.add(
            CancelWarranty(
              bookingId: booking.id,
              technicianName: "",
              technicianUid: booking.warranty?.assignedTechnicianId ?? '',
            ),
          );
        },
      );
    },
  );
}
```

### 2. Update assign_worker.dart - \_preloadConflictData method

Modify the conflict checking logic to handle warranties differently:

**Location**: Around line 180 in `_preloadConflictData` method

**Change**: Replace the current conflict checking code with warranty-aware logic:

```dart
// Get the list of UIDs to check for conflicts
List<String> conflictUids = [];

if (widget.isWarranty) {
  // For warranties, only get rejected technician UIDs
    final currentBookingDoc = await AppFirestore.bookingsCollectionRef
          .doc(widget.booking.id)
                .get();

                  if (currentBookingDoc.exists) {
                      final data = currentBookingDoc.data() as Map<String, dynamic>?;
                          final warrantyData = data?['warranty'] as Map<String, dynamic>?;
                              final rejectedTechnicians = warrantyData?['rejectedTechnicians'] as List?;

                                  if (rejectedTechnicians != null) {
                                        for (var tech in rejectedTechnicians) {
                                                final uid = tech['uid'] as String?;
                                                        if (uid != null) {
                                                                  conflictUids.add(uid);
                                                                          }
                                                                                }
                                                                                    }
                                                                                      }
                                                                                      } else {
                                                                                        // For normal bookings, get cancelled worker UIDs
                                                                                          final currentBookingDoc = await AppFirestore.bookingsCollectionRef
                                                                                                .doc(widget.booking.id)
                                                                                                      .get();

                                                                                                        if (currentBookingDoc.exists) {
                                                                                                            final data = currentBookingDoc.data() as Map<String, dynamic>?;
                                                                                                                final uids = data?['cancelledWorkerUids'] as List?;
                                                                                                                    if (uids != null) {
                                                                                                                          conflictUids.addAll(uids.cast<String>());
                                                                                                                              }
                                                                                                                                }
                                                                                                                                }

                                                                                                                                // Batch check conflicts with the appropriate UIDs
                                                                                                                                final userIds = users.map((u) => u.uid).whereType<String>().toList();

                                                                                                                                await _conflictService.batchCheckConflicts(
                                                                                                                                  userIds: userIds,
                                                                                                                                    booking: widget.booking,
                                                                                                                                      cancelledWorkerUids: conflictUids,  // ← Use warranty-aware UIDs
                                                                                                                                      );
```

## Expected Behavior

### For Normal Bookings (isWarranty: false):

- Shows all conflict types:
  - Time conflicts with other bookings
  - Worker cancelled this booking
  - Worker cancelled other bookings
  - Local session conflicts

### For Warranty Bookings (isWarranty: true):

- Shows ONLY:
  - Worker rejected this specific warranty (shown as "Worker cancelled this booking")
- Does NOT check:
  - Time conflicts
  - Other booking cancellations
  - Local session conflicts

## Visual Indication

Technicians who have rejected the warranty will show:

- ❌ Red badge indicating "Cancelled this booking"
- Disabled state (cannot assign)
- Clear visual feedback that they rejected this warranty

## Testing

1. Create a warranty booking
2. As admin, click "Assign" button
3. Assign to Technician A
4. Technician A rejects the warranty
5. As admin, click "Assign" again
6. Verify Technician A shows as "Cancelled" with red badge
7. Verify other technicians show as available (no time conflict checks)
8. Assign to Technician B
9. Verify assignment works correctly

## Files to Modify

1. `lib/pages/bookings/warranty_page.dart` - Add `isWarranty: true` parameter
2. `lib/sheets/assign_worker.dart` - Update `_preloadConflictData` method

## Notes

- The `isWarranty` parameter is already added to the constructor
- The conflict service already handles "worker cancelled this booking" type
- We're reusing existing conflict checking infrastructure
- No new UI components needed - just different data filtering
