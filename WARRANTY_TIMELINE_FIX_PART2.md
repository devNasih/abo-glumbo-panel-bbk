# Warranty Timeline Fix - Part 2

## Issue Identified

Even though `warranty.acceptedAt` exists in Firebase, the timeline was not showing the warranty "Accepted" entry correctly.

### Root Cause

The timeline was showing **BOTH** normal booking events AND warranty events for warranty bookings. This caused:

1. The normal booking "Accepted" event (from `booking.acceptedAt`) was being displayed
2. The normal booking "Tracking Started" event was being displayed
3. The normal booking "Completed" event was being displayed
4. These were mixing with or hiding the warranty-specific events

For warranty bookings, we should ONLY show:

- **Original booking creation** (when the initial service was booked)
- **Warranty-specific events** (requested, accepted, completed)

We should NOT show the normal booking progress events (accepted, tracking, completed) for warranty bookings.

---

## Fixes Applied

### 1. Excluded Normal Booking Progress Events for Warranties ✅

**File**: `lib/pages/bookings/booking_info.dart`

Added `&& !isWarranty` condition to three timeline sections:

```dart
// Before (showing for ALL bookings):
if (widget.booking.acceptedAt != null) {
  // Add "Accepted" timeline item
}

// After (only for normal bookings):
if (widget.booking.acceptedAt != null && !isWarranty) {
  // Add "Accepted" timeline item
}
```

**Changes**:

- Line 1093: Added `&& !isWarranty` to "Accepted" event
- Line 1109: Added `&& !isWarranty` to "Tracking Started" event
- Line 1123: Added `&& !isWarranty` to "Completed" event

### 2. Added Debug Logging ✅

**File**: `lib/pages/bookings/booking_info.dart`

Added comprehensive debug logging at the start of timeline building:

```dart
if (isWarranty) {
  log('🔍 Building warranty timeline');
  log('Warranty object: ${widget.booking.warranty}');
  log('Warranty status: ${widget.booking.warranty?.warrantyStatusCode}');
  log('Warranty acceptedAt: ${widget.booking.warranty?.acceptedAt}');
  log('Warranty completedAt: ${widget.booking.warranty?.completedAt}');
  log('Warranty requestedOn: ${widget.booking.warranty?.requestedOn}');
}
```

### 3. Added toString to WarrantyModel ✅

**File**: `lib/models/warranty.dart`

Added a `toString()` method for better debug output:

```dart
@override
String toString() {
  return 'WarrantyModel(id: $id, status: $warrantyStatusCode, '
      'assignedTo: $assignedTechnicianId, '
      'requestedOn: $requestedOn, acceptedAt: $acceptedAt, '
      'completedAt: $completedAt, rejectedOn: $rejectedOn)';
}
```

---

## Expected Timeline Display

### For Normal Bookings (`isWarranty: false`):

1. ✅ Created
2. ✅ Accepted (from `booking.acceptedAt`)
3. ✅ Tracking Started (from `booking.trackingStartedAt`)
4. ✅ Completed (from `booking.completedAt`)
5. ✅ Worker cancellations (if any)

### For Warranty Bookings (`isWarranty: true`):

1. ✅ Created (original booking creation)
2. ✅ Warranty Repair Requested (from `warranty.requestedOn`)
3. ✅ Waiting for Service Provider (if not yet accepted)
4. ✅ Warranty Repair Accepted (from `warranty.acceptedAt`) ← **NOW VISIBLE**
5. ✅ Technician Cancelled (if rejected, admin only)
6. ✅ Warranty Repair Completed (from `warranty.completedAt`)

---

## Testing Steps

### 1. Check Debug Logs

When you open a warranty booking, check the console/logs for:

```
🔍 Building warranty timeline
WarrantyModel(id: xxx, status: S, assignedTo: yyy,
  requestedOn: 2025-11-25 ..., acceptedAt: 2025-11-25 ...,
  completedAt: null, rejectedOn: null)
```

**Verify**:

- ✅ `acceptedAt` is NOT null
- ✅ `acceptedAt` has a valid timestamp
- ✅ Status is 'S' (Started/Accepted)

### 2. Check Timeline Display

The timeline should now show:

```
✅ Created
   [timestamp from booking.createdAt]

✅ Warranty Repair Requested
   [timestamp from warranty.requestedOn]

✅ Warranty Repair Accepted    ← THIS SHOULD NOW BE VISIBLE
   [timestamp from warranty.acceptedAt]

   (If warranty is completed, this will show with green checkmark)
   (If warranty is in progress, this will show as current/active)
```

### 3. Verify No Duplicate Events

The timeline should NOT show:

- ❌ Normal "Accepted" event (from booking.acceptedAt)
- ❌ Normal "Tracking Started" event
- ❌ Normal "Completed" event (for the original service)

These are now filtered out for warranty bookings.

---

## Data Verification

If the timeline still doesn't show the "Accepted" entry, check Firebase:

### Required Fields in Firestore:

```json
{
  "id": "booking_id",
  "bookingStatusCode": "C",
  "paymentCompleted": true,
  "warranty": {
    "warrantyStatusCode": "S",  // Must be 'S' for accepted
    "requestedOn": Timestamp,
    "acceptedAt": Timestamp,     // ← Must exist
    "assignedTechnicianId": "tech_uid",
    // ... other fields
  }
}
```

### Common Issues:

1. **Field name mismatch**:

   - ✅ Should be `acceptedAt`
   - ❌ NOT `acceptedOn` (legacy name, but model has fallback)

2. **Field type**:

   - ✅ Should be Firestore `Timestamp`
   - ❌ NOT a string or number

3. **Field location**:

   - ✅ Should be `warranty.acceptedAt`
   - ❌ NOT `acceptedAt` at root level

4. **Status code**:
   - ✅ `warrantyStatusCode` should be 'S' (accepted) or 'C' (completed)
   - ❌ NOT 'R' (requested) - won't show accepted event if still in requested state

---

## Summary

The issue was that normal booking timeline events were being shown for warranty bookings, which was either hiding or conflicting with warranty-specific events.

By adding the `!isWarranty` condition to filter out normal booking progress events, the warranty timeline now correctly shows only warranty-specific events, including the "Warranty Repair Accepted" entry.

The debug logging will help verify that:

1. The warranty data is being parsed correctly from Firebase
2. The `acceptedAt` timestamp exists and has a valid value
3. The timeline building logic is receiving the correct data

---

## Files Modified (Part 2)

1. `lib/pages/bookings/booking_info.dart` - Filtered normal booking events, added debug logging
2. `lib/models/warranty.dart` - Added toString method for debugging
