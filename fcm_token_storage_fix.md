# FCM Token Storage Fix - Technician/Admin App

## Problem

FCM tokens were not being stored in the Firestore `users` collection when technicians/admins logged into the panel app. This prevented them from receiving push notifications.

## Root Cause

The `updateFCMToken` method in `lib/services/app_services.dart` was using `.update()` which **fails silently** if the user document doesn't exist or if there's a permission issue.

```dart
// ❌ OLD CODE - Fails silently
await AppFirestore.usersCollectionRef.doc(userId).update({
  'fcmToken': token,
});
```

## Solution

Changed to use `.set()` with `SetOptions(merge: true)`, which:

1. **Creates** the document if it doesn't exist
2. **Updates** the document if it already exists
3. **Doesn't overwrite** other fields (merge: true)
4. **Provides better error handling**

```dart
// ✅ NEW CODE - Works reliably
await AppFirestore.usersCollectionRef.doc(userId).set({
  'fcmToken': token,
  'fcmTokenUpdatedAt': Timestamp.now(),
}, SetOptions(merge: true));
```

## Changes Made

### File: `lib/services/app_services.dart`

**Enhanced `updateFCMToken` method:**

1. **Added validation**: Check if userId is empty before attempting update
2. **Added logging**: Debug prints to track token updates
3. **Changed to `.set()` with merge**: Ensures token is stored even if document doesn't exist
4. **Added timestamp**: Track when token was last updated
5. **Added fallback**: Try again with merge if first attempt fails
6. **Better error messages**: Clear debug output for troubleshooting

## How It Works Now

### On App Launch / Login:

1. FCM listeners are set up in `main.dart` (line 128)
2. `NotificationServices.setupFCMListeners()` is called
3. Token is fetched via `_getFCMTokenAndUpdate()`
4. `AppServices.updateFCMToken(token)` is called
5. Token is stored in `users/{userId}` with `fcmToken` and `fcmTokenUpdatedAt` fields

### On Logout:

1. `AppServices.clearFCMToken()` is called
2. Token is deleted from Firestore using `FieldValue.delete()`
3. User document remains but `fcmToken` field is removed

## Testing

### To Verify the Fix:

1. **Login to the technician/admin app**
2. **Check Firestore Console**:

   - Navigate to `users/{userId}`
   - Verify `fcmToken` field exists
   - Verify `fcmTokenUpdatedAt` timestamp is recent

3. **Check Debug Logs**:

   ```
   📤 Updating FCM token for user: {userId}
   🔑 Token: {first 20 chars}...
   ✅ FCM token updated successfully in Firestore
   ```

4. **Test Push Notifications**:
   - Create a new booking (should trigger admin notification)
   - Verify notification is received on device
   - Check Firestore: `users/{userId}/notifications/{notificationId}` should exist

### To Test Logout:

1. **Logout from the app**
2. **Check Firestore Console**:

   - Navigate to `users/{userId}`
   - Verify `fcmToken` field is removed
   - Other fields should remain intact

3. **Check Debug Logs**:
   ```
   ✅ FCM token cleared from user document
   ```

## Comparison with Customer App

Both apps now use the same pattern:

| Feature            | Customer App                    | Technician App                     |
| ------------------ | ------------------------------- | ---------------------------------- |
| **Collection**     | `customers`                     | `users`                            |
| **Method**         | `.set()` with merge             | `.set()` with merge ✅             |
| **Fields**         | `fcmToken`, `fcmTokenUpdatedAt` | `fcmToken`, `fcmTokenUpdatedAt` ✅ |
| **On Login**       | Token stored                    | Token stored ✅                    |
| **On Logout**      | Token deleted                   | Token deleted ✅                   |
| **Error Handling** | Comprehensive                   | Comprehensive ✅                   |

## Next Steps

1. ✅ **Test the fix** - Login to admin/technician account and verify token is stored
2. ✅ **Monitor logs** - Check for successful token updates
3. ✅ **Test notifications** - Create a booking and verify admin receives notification
4. ⏳ **Fix background notifications** - Add `userId` to FCM payload (separate issue)

## Related Issues

This fix addresses the FCM token storage issue. However, there's still a separate issue with **background notification storage** where notifications received when the app is in the background cannot be stored because the `userId` is not included in the FCM data payload.

To fully resolve all notification issues, we also need to:

- Add `userId` to the FCM data payload in Cloud Functions
- This will allow background notifications to be stored correctly

---

**Status**: ✅ FCM Token Storage - FIXED
**Status**: ⏳ Background Notification Storage - PENDING
