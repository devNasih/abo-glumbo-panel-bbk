# Warranty Rejection Fix

## Issue

When a technician rejects a warranty booking:

1. The rejection is recorded in Firebase (`rejectedTechnicians` array)
2. The `assignedTechnicianId` is cleared
3. **Problem**: The warranty disappears from the technician's warranty list

The technician could not see the rejected warranty anymore, even though they should be able to see it in their "Requested" tab (marked as rejected).

---

## Root Cause

The `getWarrantiesStream` method for technicians was querying only warranties where:

```dart
.where('warranty.assignedTechnicianId', isEqualTo: workerId)
```

When a technician rejects a warranty:

- `assignedTechnicianId` is set to `null` (for reassignment)
- The warranty no longer matches the query
- It disappears from the technician's view

---

## Solution

Modified `getWarrantiesStream` in `lib/services/app_services.dart` to:

### Before:

```dart
// Technician sees only their assigned warranties
return AppFirestore.bookingsCollectionRef
    .where('bookingStatusCode', isEqualTo: 'C')
    .where('paymentCompleted', isEqualTo: true)
    .where('warranty.assignedTechnicianId', isEqualTo: workerId)  // ❌ Too restrictive
    .orderBy('createdAt', descending: true)
    .snapshots()
```

### After:

```dart
// Technician sees warranties they're assigned to OR have rejected
return AppFirestore.bookingsCollectionRef
    .where('bookingStatusCode', isEqualTo: 'C')
    .where('paymentCompleted', isEqualTo: true)
    // ✅ Removed assignedTechnicianId filter
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromDocumentSnapshot(doc))
          .where((booking) {
            if (booking.warranty == null) return false;

            // Check if technician is assigned
            bool isAssigned = booking.warranty!.assignedTechnicianId == workerId;

            // Check if technician has rejected this warranty
            bool hasRejected = booking.warranty!.rejectedTechnicians
                    ?.any((tech) => tech.uid == workerId) ?? false;

            // Include if assigned OR rejected
            if (!isAssigned && !hasRejected) return false;

            // Filter by warranty status if specified
            if (warrantyStatusCode != null) {
              return booking.warranty!.warrantyStatusCode == warrantyStatusCode;
            }
            return true;
          })
          .toList();
    });
```

---

## How It Works Now

### Warranty Rejection Flow:

1. **Technician Rejects Warranty**:

   - `CancelWarranty` event is triggered
   - Technician is added to `warranty.rejectedTechnicians` array
   - `warranty.assignedTechnicianId` is set to `null`
   - Warranty status remains 'R' (Requested) for reassignment

2. **Warranty Stream Fetches**:

   - Fetches ALL completed warranties with payment
   - Filters client-side to include warranties where:
     - Technician is assigned (`assignedTechnicianId == workerId`) **OR**
     - Technician has rejected (`rejectedTechnicians` contains `workerId`)

3. **Display**:
   - Rejected warranties appear in the "Requested" tab
   - They are visually marked with **red color** (already implemented in `booking_cards.dart`)
   - Technician can see them but cannot accept them again

---

## Visual Indication

The `BookingCards` widget already handles visual distinction:

```dart
Color _getStatusColor() {
  final bool bookingCancelled = isWarranty
      ? (booking.warranty?.rejectedTechnicians?.any(
              (worker) => worker.uid == LocalStore.getUID(),
            ) ?? false)
      : booking.cancelledWorkers.any(
          (worker) => worker.uid == LocalStore.getUID(),
        );

  if (bookingCancelled) {
    return Colors.red;  // ✅ Rejected warranties show in red
  }
  // ... other status colors
}
```

---

## Expected Behavior

### For Technician Who Rejected:

**"Requested" Tab**:

- ✅ Shows the rejected warranty
- ✅ Marked with red color
- ✅ Cannot accept it again (already in rejectedTechnicians)

**Other Tabs**:

- Warranty won't appear in "Accepted", "Completed", etc. (correct)

### For Admin:

**"Requested" Tab**:

- ✅ Shows all requested warranties
- ✅ Can see which technicians rejected it
- ✅ Can reassign to a different technician

### For Other Technicians:

**"Requested" Tab**:

- ✅ Shows the warranty (if they haven't rejected it)
- ✅ Can accept it

---

## Performance Consideration

**Note**: The technician stream now fetches ALL warranties (not filtered by `assignedTechnicianId` in the query). This means:

- **Firestore reads**: Slightly more data is fetched
- **Client-side filtering**: Applied to show only relevant warranties
- **Impact**: Minimal for most use cases (completed warranties are typically not huge in number)

If performance becomes an issue with many warranties, we could optimize by:

1. Adding a `rejectedTechnicianIds` array field (denormalized)
2. Using array-contains query for rejected warranties
3. Combining two streams (assigned + rejected)

For now, the current solution is simple and effective.

---

## Testing Checklist

### Technician Rejects Warranty:

- [ ] Reject a warranty as a technician
- [ ] Verify it appears in "Requested" tab with red color
- [ ] Verify it shows "Rejected by you" or similar indication
- [ ] Verify you cannot accept it again
- [ ] Verify admin can see it and reassign

### Admin Reassigns:

- [ ] Admin assigns rejected warranty to different technician
- [ ] Verify original technician still sees it as rejected
- [ ] Verify new technician sees it as requested (blue color)
- [ ] Verify new technician can accept it

### Multiple Rejections:

- [ ] Technician A rejects warranty
- [ ] Admin assigns to Technician B
- [ ] Technician B rejects warranty
- [ ] Verify both technicians see it as rejected
- [ ] Verify admin can see both rejections in timeline

---

## Files Modified

1. `lib/services/app_services.dart` - Updated `getWarrantiesStream` method

---

## Summary

The issue was that the warranty stream for technicians was too restrictive, only showing assigned warranties. Now it includes both assigned and rejected warranties, allowing technicians to see their rejection history while preventing them from accepting the same warranty again.

The visual distinction (red color) was already implemented, so no UI changes were needed. The fix is purely in the data fetching logic.
