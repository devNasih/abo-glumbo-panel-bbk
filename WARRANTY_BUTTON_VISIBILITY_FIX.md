# Warranty Card Button Visibility Fix

## Issue

Accept and reject buttons were appearing on warranty cards in the "Rejected" tab, even for warranties that the technician had already rejected.

This was confusing because:

- The technician already rejected the warranty
- They shouldn't be able to accept or reject it again
- The buttons served no purpose on rejected warranties

---

## Root Cause

The button visibility condition in `booking_cards.dart` was:

```dart
if (isWarranty && booking.warranty!.warrantyStatusCode == 'R') {
  // Show accept/reject buttons
}
```

This showed buttons for ALL warranties with status 'R' (Requested), including:

- ✅ Warranties the technician can accept (correct)
- ❌ Warranties the technician has already rejected (incorrect)

---

## Solution

Updated the condition to exclude warranties that the current technician has rejected:

### Before:

```dart
if (isWarranty &&
    booking.warranty!.warrantyStatusCode == 'R') {
  // Show buttons
}
```

### After:

```dart
if (isWarranty &&
    booking.warranty!.warrantyStatusCode == 'R' &&
    !(booking.warranty!.rejectedTechnicians?.any(
      (tech) => tech.uid == LocalStore.getUID(),
    ) ?? false)) {
  // Show buttons only if NOT rejected by current technician
}
```

---

## Expected Behavior

### "Requested" Tab (R):

- ✅ Shows accept/reject buttons on warranties you can accept
- ❌ Does NOT show rejected warranties (they're in "Rejected" tab)

### "Rejected" Tab (X):

- ❌ Does NOT show accept/reject buttons
- ✅ Shows rejected warranties with red color
- ✅ Read-only view (cannot interact)

### "Accepted" Tab (S):

- ❌ Does NOT show accept/reject buttons
- ✅ Shows tracking controls instead

### "Completed" Tab (C):

- ❌ Does NOT show accept/reject buttons
- ✅ Shows completion data

---

## Complete Button Logic

### For Normal Bookings:

```dart
if (!isAdmin &&
    booking.bookingStatusCode == 'P' &&
    !booking.cancelledWorkers.any(
      (worker) => worker.uid == LocalStore.getUID()
    )) {
  // Show accept/reject buttons
}
```

- Shows buttons only for pending bookings
- Excludes bookings the technician has cancelled

### For Warranty Bookings:

```dart
if (isWarranty &&
    booking.warranty!.warrantyStatusCode == 'R' &&
    !(booking.warranty!.rejectedTechnicians?.any(
      (tech) => tech.uid == LocalStore.getUID()
    ) ?? false)) {
  // Show accept/reject buttons
}
```

- Shows buttons only for requested warranties
- Excludes warranties the technician has rejected

---

## Files Modified

**File**: `lib/common_widget/booking_cards.dart`

**Lines**: 140-164

**Change**: Added check for `rejectedTechnicians` array to exclude rejected warranties from showing buttons

---

## Testing Checklist

### Requested Tab:

- [ ] Open "Requested" tab
- [ ] Verify accept/reject buttons appear on warranties you can accept
- [ ] Verify no rejected warranties appear (they're in "Rejected" tab)

### Rejected Tab:

- [ ] Reject a warranty
- [ ] Open "Rejected" tab
- [ ] Verify the rejected warranty appears
- [ ] Verify NO accept/reject buttons appear ✅
- [ ] Verify warranty shows with red color

### Accepted Tab:

- [ ] Accept a warranty
- [ ] Open "Accepted" tab
- [ ] Verify NO accept/reject buttons appear
- [ ] Verify tracking controls appear instead

### Admin View:

- [ ] As admin, open "Requested" tab
- [ ] Verify "Assign" button appears (not accept/reject)
- [ ] Verify you can see which technicians rejected each warranty

---

## Summary

The fix ensures that:

1. ✅ Accept/reject buttons only appear on warranties the technician can actually accept
2. ✅ Rejected warranties do not show these buttons
3. ✅ Technicians cannot accidentally try to accept a warranty they already rejected
4. ✅ The UI is cleaner and less confusing

This completes the warranty card interaction logic, making it consistent with the tab filtering behavior.
