# Warranty Tab Filtering Fix

## Issue

When a technician rejected a warranty, it appeared in the **"Requested" tab** instead of the **"Rejected" tab**.

### Why This Happened

When a technician rejects a warranty:

1. They are added to `warranty.rejectedTechnicians` array
2. `warranty.assignedTechnicianId` is cleared
3. **Warranty status remains 'R' (Requested)** - so it can be reassigned by admin

The previous fix made rejected warranties visible, but they were showing in the wrong tab because the filtering was based solely on the warranty's actual status code ('R'), not on the technician's relationship to it.

---

## Solution

Updated the warranty filtering logic in `getWarrantiesStream` to handle tab filtering differently for technicians:

### Tab Filtering Logic for Technicians:

#### "Rejected" Tab (warrantyStatusCode == 'X'):

```dart
if (warrantyStatusCode == 'X') {
  // Show only warranties this technician has rejected
  return hasRejected;
}
```

- Shows warranties where the technician is in `rejectedTechnicians` array
- **Regardless of the actual warranty status** (could be 'R', 'S', etc.)

#### Other Tabs (Requested, Accepted, Completed):

```dart
else {
  // Show only if NOT rejected by this technician
  // AND the warranty status matches the tab
  return !hasRejected &&
         booking.warranty!.warrantyStatusCode == warrantyStatusCode;
}
```

- Excludes warranties the technician has rejected
- Shows only warranties matching the actual status code

---

## Expected Behavior

### Technician Who Rejected a Warranty:

**"Requested" Tab (R)**:

- ❌ Does NOT show the rejected warranty
- ✅ Shows only warranties they can accept

**"Rejected" Tab (X)**:

- ✅ Shows the warranty they rejected
- ✅ Marked with red color
- ✅ Cannot accept it again

**"Accepted" Tab (S)**:

- ✅ Shows warranties they accepted and are working on
- ❌ Does NOT show rejected warranties

**"Completed" Tab (C)**:

- ✅ Shows warranties they completed
- ❌ Does NOT show rejected warranties

### Admin View:

**"Requested" Tab (R)**:

- ✅ Shows ALL requested warranties (including those rejected by technicians)
- ✅ Can see which technicians rejected each warranty
- ✅ Can reassign to different technicians

**"Rejected" Tab (X)**:

- ✅ Shows warranties that were permanently rejected by admin
- ❌ Does NOT show warranties rejected by technicians (those stay in 'R' for reassignment)

---

## Code Changes

**File**: `lib/services/app_services.dart`

**Method**: `getWarrantiesStream`

**Change**: Added special handling for 'X' status code when filtering for technicians:

```dart
// Filter by warranty status if specified
if (warrantyStatusCode != null) {
  // Special handling for 'X' (Rejected) tab for technicians
  if (warrantyStatusCode == 'X') {
    // Show only warranties this technician has rejected
    return hasRejected;
  } else {
    // For other tabs, show only if NOT rejected by this technician
    // and the warranty status matches
    return !hasRejected &&
        booking.warranty!.warrantyStatusCode == warrantyStatusCode;
  }
}
```

---

## Workflow Example

### Scenario: Warranty Rejection and Reassignment

1. **Customer requests warranty repair**

   - Warranty status: 'R' (Requested)
   - Admin sees it in "Requested" tab

2. **Admin assigns to Technician A**

   - `assignedTechnicianId`: Technician A
   - Warranty status: 'S' (Accepted)
   - Technician A sees it in "Accepted" tab

3. **Technician A rejects the warranty**

   - Added to `rejectedTechnicians` array
   - `assignedTechnicianId`: null
   - Warranty status: 'R' (Requested) - back to requested for reassignment
   - **Technician A** sees it in "Rejected" tab ✅
   - **Admin** sees it in "Requested" tab ✅

4. **Admin assigns to Technician B**

   - `assignedTechnicianId`: Technician B
   - Warranty status: 'S' (Accepted)
   - **Technician A** still sees it in "Rejected" tab ✅
   - **Technician B** sees it in "Accepted" tab ✅

5. **Technician B completes the warranty**
   - Warranty status: 'C' (Completed)
   - **Technician A** sees it in "Rejected" tab ✅
   - **Technician B** sees it in "Completed" tab ✅

---

## Testing Checklist

### Technician Rejection:

- [ ] Reject a warranty as technician
- [ ] Verify it appears in YOUR "Rejected" tab
- [ ] Verify it does NOT appear in YOUR "Requested" tab
- [ ] Verify it appears with red color in "Rejected" tab

### Admin View:

- [ ] As admin, verify rejected warranty appears in "Requested" tab
- [ ] Verify you can see the technician in rejectedTechnicians list
- [ ] Verify you can reassign to another technician

### Reassignment:

- [ ] Admin reassigns rejected warranty to different technician
- [ ] Verify original technician still sees it in "Rejected" tab
- [ ] Verify new technician sees it in "Accepted" tab
- [ ] Verify new technician does NOT see it in "Rejected" tab

### Multiple Rejections:

- [ ] Technician A rejects warranty
- [ ] Admin reassigns to Technician B
- [ ] Technician B rejects warranty
- [ ] Verify Technician A sees it in "Rejected" tab
- [ ] Verify Technician B sees it in "Rejected" tab
- [ ] Verify admin sees it in "Requested" tab with both rejections

---

## Summary

The fix ensures that:

1. ✅ Rejected warranties appear in the technician's "Rejected" tab
2. ✅ Rejected warranties do NOT appear in other tabs for that technician
3. ✅ Admin can still see and reassign rejected warranties
4. ✅ Visual distinction (red color) is maintained
5. ✅ Technicians cannot accept warranties they previously rejected

The key insight is that for technicians, the "Rejected" tab shows **their personal rejections**, not the warranty's actual status. This allows the warranty to remain in 'R' status for admin reassignment while still appearing correctly in the technician's view.
