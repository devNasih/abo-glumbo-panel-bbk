# Admin Warranty Button Fix

## Issue

In admin view, warranty cards were showing accept/reject buttons instead of the "Assign" button.

This was incorrect because:

- Admins should assign warranties to technicians
- Admins should not accept/reject warranties themselves
- The "Assign" button was being hidden by the accept/reject buttons

---

## Root Cause

The accept/reject button condition for warranties was:

```dart
if (isWarranty &&
    booking.warranty!.warrantyStatusCode == 'R' &&
    !hasRejected) {
  // Show accept/reject buttons
}
```

This condition was missing the `!isAdmin` check, so it showed the buttons for both admins and technicians.

---

## Solution

Added `!isAdmin` to the warranty accept/reject button condition:

### Before:

```dart
if ((!isAdmin && booking.bookingStatusCode == 'P' && !cancelled) ||
    (isWarranty && booking.warranty!.warrantyStatusCode == 'R' && !hasRejected)) {
  // Show accept/reject buttons
}
```

### After:

```dart
if ((!isAdmin && booking.bookingStatusCode == 'P' && !cancelled) ||
    (!isAdmin && isWarranty && booking.warranty!.warrantyStatusCode == 'R' && !hasRejected)) {
  // Show accept/reject buttons ONLY for technicians
}
```

---

## Expected Behavior

### Admin View - Warranty Cards:

**"Requested" Tab (R)**:

- ✅ Shows "Assign" button
- ❌ Does NOT show accept/reject buttons

**"Accepted" Tab (S)**:

- ✅ Shows assigned technician info
- ❌ No action buttons (technician is working on it)

**"Completed" Tab (C)**:

- ✅ Shows completion info
- ❌ No action buttons

**"Rejected" Tab (X)**:

- ✅ Shows admin-rejected warranties
- ❌ No action buttons

### Technician View - Warranty Cards:

**"Requested" Tab (R)**:

- ✅ Shows accept/reject buttons (if not rejected by them)
- ❌ Does NOT show "Assign" button

**"Rejected" Tab (X)**:

- ✅ Shows warranties they rejected
- ❌ No accept/reject buttons

---

## Complete Button Logic

### Accept/Reject Buttons (Technicians Only):

```dart
if ((!isAdmin && booking.bookingStatusCode == 'P' && !cancelled) ||
    (!isAdmin && isWarranty && booking.warranty!.warrantyStatusCode == 'R' && !hasRejected)) {
  // Show accept/reject IconButtons
}
```

### Assign Button (Admin Only):

```dart
if ((isAdmin && !isWarranty && onAssign != null && booking.bookingStatusCode == 'P') ||
    (isAdmin && isWarranty && booking.warranty!.warrantyStatusCode == 'R')) {
  // Show Assign OutlinedButton
}
```

---

## Files Modified

**File**: `lib/common_widget/booking_cards.dart`

**Lines**: 140-168

**Change**: Added `!isAdmin` condition to warranty accept/reject button logic

---

## Testing Checklist

### Admin View:

- [ ] Open warranty "Requested" tab as admin
- [ ] Verify "Assign" button appears
- [ ] Verify NO accept/reject buttons appear ✅
- [ ] Click "Assign" and verify assignment sheet opens
- [ ] Assign to a technician and verify it works

### Technician View:

- [ ] Open warranty "Requested" tab as technician
- [ ] Verify accept/reject buttons appear
- [ ] Verify NO "Assign" button appears
- [ ] Accept a warranty and verify it moves to "Accepted" tab

### Normal Bookings (Admin):

- [ ] Open normal booking "Pending" tab as admin
- [ ] Verify "Assign" button appears
- [ ] Verify NO accept/reject buttons appear

### Normal Bookings (Technician):

- [ ] Open normal booking "Pending" tab as technician
- [ ] Verify accept/reject buttons appear
- [ ] Verify NO "Assign" button appears

---

## Summary

The fix ensures proper role-based button visibility:

1. ✅ **Admins** see "Assign" button for pending/requested bookings and warranties
2. ✅ **Technicians** see accept/reject buttons for pending/requested bookings and warranties
3. ✅ No overlap or confusion between admin and technician actions
4. ✅ Consistent behavior across normal bookings and warranty bookings

This completes the warranty card UI, making it properly role-aware.
