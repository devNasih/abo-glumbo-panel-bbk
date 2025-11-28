# Warranty Notification Investigation & Debugging

## Summary

The warranty notification code **IS already implemented** for both scenarios:

1. ✅ Customer requests warranty repair (A → R)
2. ✅ Technician rejects warranty repair (rejectedTechnicians array grows)

However, notifications are **not being sent** to admins. To diagnose the issue, I've added comprehensive debug logging.

## Changes Made to `functions/index.js`

### 1. Added Debug Logging at Function Start (Line ~2166)

```javascript
// 🔍 DEBUG: Log warranty status change details
console.log(`[WARRANTY DEBUG] Booking ${bookingId}:`);
console.log(`  Before Status: ${beforeStatusCode || "null"}`);
console.log(`  After Status: ${afterStatusCode}`);
console.log(
  `  Before rejectedTechnicians: ${
    beforeWarranty?.rejectedTechnicians?.length || 0
  }`
);
console.log(
  `  After rejectedTechnicians: ${
    afterWarranty.rejectedTechnicians?.length || 0
  }`
);
```

**Purpose:** Track what warranty data the function is receiving

### 2. Added Status Detection Logging (Line ~2290)

```javascript
if (!status) {
  console.log(
    `[WARRANTY DEBUG] ⚠️ No status change detected for booking ${bookingId} - notifications will NOT be sent`
  );
  console.log(
    `[WARRANTY DEBUG] This could mean the warranty change doesn't match any known patterns`
  );
  return;
}

console.log(
  `[WARRANTY DEBUG] ✅ Status detected: ${status} for booking ${bookingId}`
);
```

**Purpose:** Identify if the warranty status change is being detected correctly

### 3. Added Admin Notification Logging (Line ~2490)

```javascript
console.log(`[WARRANTY DEBUG] Admin notification check for status: ${status}`);
console.log(`[WARRANTY DEBUG] Admin tokens found: ${adminTokens.length}`);

if (adminTokens.length > 0) {
  for (const { uid, token, lanCode } of adminTokens) {
    console.log(`[WARRANTY DEBUG] Sending notification to admin ${uid}`);
    // ... send notification ...
    console.log(`[WARRANTY DEBUG] ✅ Notification sent to admin ${uid}`);
  }
} else {
  console.log(
    `[WARRANTY DEBUG] ⚠️ No admin tokens available - admins won't be notified!`
  );
}
```

**Purpose:** Track if admin users are being found and notified

## How to Deploy & Test

### Step 1: Deploy the Updated Functions

```bash
cd d:\Brandbik\abo-glumbo-panel-bbk\functions
firebase deploy --only functions:notifyOnWarrantyRequestStatusChange
```

### Step 2: Trigger a Warranty Status Change

#### Option A: Customer Requests Repair (A → R)

1. Create a completed booking with warranty
2. Ensure `warranty.warrantyStatusCode = 'A'`
3. Update the booking:
   ```dart
   await FirebaseFirestore.instance
     .collection('bookings')
     .doc(bookingId)
     .update({
       'warranty.warrantyStatusCode': 'R',
       'warranty.requestedOn': FieldValue.serverTimestamp(),
     });
   ```

#### Option B: Technician Rejects Warranty

1. Have a warranty repair request (status 'R')
2. Technician rejects it:
   ```dart
   await FirebaseFirestore.instance
     .collection('bookings')
     .doc(bookingId)
     .update({
       'warranty.rejectedTechnicians': FieldValue.arrayUnion([
         {
           'uid': technicianId,
           'name': technicianName,
           'phone': technicianPhone,
           'reason': rejectionReason,
           'rejectedAt': FieldValue.serverTimestamp(),
         }
       ]),
     });
   ```

### Step 3: Check the Logs

#### Via Firebase Console:

1. Go to Firebase Console → Functions
2. Click on `notifyOnWarrantyRequestStatusChange`
3. Click "Logs" tab
4. Look for `[WARRANTY DEBUG]` messages

#### Via Command Line:

```bash
firebase functions:log --only notifyOnWarrantyRequestStatusChange
```

## Expected Log Output

### If Everything Works:

```
[WARRANTY DEBUG] Booking abc123:
  Before Status: A
  After Status: R
  Before rejectedTechnicians: 0
  After rejectedTechnicians: 0
[WARRANTY DEBUG] ✅ Status detected: repair_requested for booking abc123
[WARRANTY DEBUG] Admin notification check for status: repair_requested
[WARRANTY DEBUG] Admin tokens found: 2
[WARRANTY DEBUG] Sending notification to admin admin-uid-1
[WARRANTY DEBUG] ✅ Notification sent to admin admin-uid-1
[WARRANTY DEBUG] Sending notification to admin admin-uid-2
[WARRANTY DEBUG] ✅ Notification sent to admin admin-uid-2
```

### If Status Not Detected:

```
[WARRANTY DEBUG] Booking abc123:
  Before Status: A
  After Status: A  ← PROBLEM: Status didn't change!
  Before rejectedTechnicians: 0
  After rejectedTechnicians: 0
[WARRANTY DEBUG] ⚠️ No status change detected for booking abc123 - notifications will NOT be sent
```

### If No Admin Tokens:

```
[WARRANTY DEBUG] Booking abc123:
  Before Status: A
  After Status: R
  Before rejectedTechnicians: 0
  After rejectedTechnicians: 0
[WARRANTY DEBUG] ✅ Status detected: repair_requested for booking abc123
[WARRANTY DEBUG] Admin notification check for status: repair_requested
[WARRANTY DEBUG] Admin tokens found: 0  ← PROBLEM: No admins found!
[WARRANTY DEBUG] ⚠️ No admin tokens available - admins won't be notified!
```

## Possible Root Causes

Based on the logs, you'll be able to identify the issue:

### 1. Function Not Triggering

- **Log:** No `[WARRANTY DEBUG]` messages at all
- **Cause:** Function not deployed or not listening to correct path
- **Fix:** Deploy the function

### 2. Status Not Changing

- **Log:** "Before Status" and "After Status" are the same
- **Cause:** App code not updating `warrantyStatusCode` correctly
- **Fix:** Update your Dart code to properly change the status

### 3. No Admin Users

- **Log:** "Admin tokens found: 0"
- **Cause:** No users with `isAdmin: true` and valid `fcmToken`
- **Fix:**
  - Ensure admin users have `isAdmin: true` in Firestore
  - Ensure admins log in to set their FCM token
  - Check admin app calls `updateFCMToken()` on login

### 4. Rejected Technicians Not Growing

- **Log:** "Before rejectedTechnicians" and "After rejectedTechnicians" are the same
- **Cause:** App code not adding to `rejectedTechnicians` array
- **Fix:** Use `FieldValue.arrayUnion()` to add rejected technician

## Next Steps

1. **Deploy the function** with debug logging
2. **Trigger a warranty change** in your app
3. **Check the logs** in Firebase Console
4. **Share the log output** with me - the logs will tell us exactly what's wrong!

The debug logs will pinpoint the exact issue. Once we see the logs, we can fix the specific problem.
