# Warranty Notification Debugging Guide

## Issue

Admin notifications are not being sent when:

1. Customer requests warranty repair (A → R)
2. Technician rejects warranty repair (new entry in rejectedTechnicians)

## Debugging Steps Added

I've added comprehensive debug logging to the `notifyOnWarrantyRequestStatusChange` function. The logs will help identify exactly where the issue is.

### Debug Logs to Check

When you trigger a warranty status change, check Firebase Functions logs for these messages:

#### 1. Function Trigger Check

```
[WARRANTY DEBUG] Booking {bookingId}:
  Before Status: {status}
  After Status: {status}
  Before rejectedTechnicians: {count}
  After rejectedTechnicians: {count}
```

**What to look for:**

- If you DON'T see this log, the function isn't triggering at all
- Check if the function is deployed: `firebase deploy --only functions`

#### 2. Status Detection Check

```
[WARRANTY DEBUG] ✅ Status detected: {status} for booking {bookingId}
```

OR

```
[WARRANTY DEBUG] ⚠️ No status change detected for booking {bookingId} - notifications will NOT be sent
[WARRANTY DEBUG] This could mean the warranty change doesn't match any known patterns
```

**What to look for:**

- If you see "No status change detected", the warranty data structure might not match expected format
- Expected statuses: `repair_requested`, `technician_rejected`, etc.

#### 3. Admin Token Check

```
[WARRANTY DEBUG] Admin notification check for status: {status}
[WARRANTY DEBUG] Admin tokens found: {count}
```

**What to look for:**

- If count is 0, no admin users have valid FCM tokens
- Check admin users in Firestore have `isAdmin: true` and `fcmToken` field

#### 4. Notification Sending Check

```
[WARRANTY DEBUG] Sending notification to admin {uid}
[WARRANTY DEBUG] ✅ Notification sent to admin {uid}
```

OR

```
[WARRANTY DEBUG] ⚠️ No admin tokens available - admins won't be notified!
```

## Common Issues & Solutions

### Issue 1: Function Not Triggering

**Symptom:** No debug logs appear at all

**Solutions:**

1. Deploy the functions:

   ```bash
   cd functions
   firebase deploy --only functions:notifyOnWarrantyRequestStatusChange
   ```

2. Check Firebase Console > Functions to ensure it's deployed

### Issue 2: Status Not Detected

**Symptom:** You see "No status change detected"

**Possible Causes:**

#### A. Warranty Status Code Issue (A → R)

The warranty status might not be changing correctly. Check:

- `beforeData.warranty.warrantyStatusCode` should be `'A'`
- `afterData.warranty.warrantyStatusCode` should be `'R'`
- Make sure the field name is exactly `warrantyStatusCode` (case-sensitive)

**Fix in your app:** When customer requests repair, update:

```dart
await FirebaseFirestore.instance
  .collection('bookings')
  .doc(bookingId)
  .update({
    'warranty.warrantyStatusCode': 'R',
    'warranty.requestedOn': FieldValue.serverTimestamp(),
  });
```

#### B. Rejected Technicians Issue

The array might not be growing correctly. Check:

- `beforeData.warranty.rejectedTechnicians` array length
- `afterData.warranty.rejectedTechnicians` array length should be +1
- New entry should have: `{uid, name, phone, reason, rejectedAt}`

**Fix in your app:** When technician rejects, update:

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

### Issue 3: No Admin Tokens

**Symptom:** "Admin tokens found: 0"

**Solutions:**

1. **Check admin users exist:**

   ```javascript
   // In Firebase Console > Firestore
   // Check users collection for documents with isAdmin: true
   ```

2. **Check FCM tokens are stored:**

   - Admin users must have `fcmToken` field
   - Token must not be empty string
   - Token is set when admin logs in

3. **Verify admin login updates FCM token:**
   Check your admin app's login code includes:
   ```dart
   await FirebaseFirestore.instance
     .collection('users')
     .doc(userId)
     .update({
       'fcmToken': fcmToken,
       'lanCode': languageCode,
     });
   ```

### Issue 4: Notifications Sent But Not Received

**Symptom:** Logs show "✅ Notification sent" but admin doesn't receive it

**Solutions:**

1. **Check FCM token validity:**

   - Token might be expired or invalid
   - Admin needs to re-login to refresh token

2. **Check notification permissions:**

   - Admin app must have notification permissions enabled
   - Check device notification settings

3. **Check Firebase Cloud Messaging:**
   - Verify FCM is properly configured in Firebase Console
   - Check if messages are being delivered in Firebase Console > Cloud Messaging

## Testing the Fix

### Test 1: Customer Requests Warranty Repair

1. Create a completed booking with warranty status 'A'
2. In your customer app, request warranty repair
3. Check Firebase Functions logs for debug messages
4. Verify admin receives notification

### Test 2: Technician Rejects Warranty

1. Create a warranty repair request (status 'R')
2. Assign to a technician
3. Have technician reject the warranty
4. Check Firebase Functions logs for debug messages
5. Verify admin receives notification with technician name and reason

## Viewing Logs

### Firebase Console

1. Go to Firebase Console > Functions
2. Click on `notifyOnWarrantyRequestStatusChange`
3. Click "Logs" tab
4. Look for `[WARRANTY DEBUG]` messages

### Command Line

```bash
firebase functions:log --only notifyOnWarrantyRequestStatusChange
```

## Next Steps

1. **Deploy the updated function** with debug logging
2. **Trigger a warranty status change** (A → R or technician rejection)
3. **Check the logs** and identify which step is failing
4. **Share the logs** with me so I can help diagnose the specific issue

The debug logs will tell us exactly where the problem is!
