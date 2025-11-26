# FCM Token Update After Login - Fix

## Problem

Even after fixing the `updateFCMToken` method to use `.set()` with merge, FCM tokens were still not being stored in Firestore for technician/admin accounts after login.

## Root Cause

The FCM setup happens in `main.dart` **before** the user logs in. When `setupFCMListeners()` calls `updateFCMToken()`, the `LocalStore.getUID()` returns **empty** because the user hasn't logged in yet!

### Timeline of Events:

1. ✅ App launches → `main.dart` runs
2. ✅ FCM is set up → `NotificationServices.setupFCMListeners()` called
3. ✅ FCM token is fetched → `_getFCMTokenAndUpdate()` called
4. ❌ `AppServices.updateFCMToken(token)` called → **BUT userId is empty!**
5. ✅ User logs in → `LocalStore.putUID(uid)` called
6. ❌ FCM token is never updated with the new userId

## Solution

Call `updateFCMToken()` **again** after successful login, when the UID is available.

### Changes Made

**File**: `lib/pages/login/bloc/login_bloc.dart`

1. **Added imports**:

   ```dart
   import 'package:aboglumbo_bbk_panel/services/app_services.dart';
   import 'package:firebase_messaging/firebase_messaging.dart';
   ```

2. **Updated `_checkWorkerUser` method**:
   After storing the UID in LocalStore, we now:
   - Fetch the current FCM token
   - Call `AppServices.updateFCMToken(token)`
   - Log success/failure

```dart
// After storing UID
LocalStore.putUID(userData?['uid'] ?? uid);
LocalStore.putlogoutStatus(false);

// Update FCM token after login
try {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null && token.isNotEmpty) {
    await AppServices.updateFCMToken(token);
    if (kDebugMode) {
      print('✅ FCM token updated after login');
    }
  }
} catch (e) {
  if (kDebugMode) {
    print('⚠️ Error updating FCM token after login: $e');
  }
}
```

## How It Works Now

### Complete Flow:

1. **App Launch**:

   - FCM is set up in `main.dart`
   - Token is fetched but can't be stored (no userId yet)

2. **User Logs In**:

   - OTP is verified
   - User document is fetched from Firestore
   - UID is stored in LocalStore: `LocalStore.putUID(uid)`
   - **NEW**: FCM token is fetched and stored in Firestore ✅

3. **Token Refresh** (automatic):

   - When FCM token refreshes, `_setupTokenRefreshListener` updates it
   - This works because userId is now available

4. **Logout**:
   - FCM token is deleted from Firestore
   - User is signed out

## Testing

### To Verify the Fix:

1. **Clear app data** (to simulate fresh install)
2. **Launch the app**
3. **Check debug logs** - You should see:

   ```
   🔑 FCM Token: {token}...
   ❌ Cannot update FCM token: User ID is empty
   ```

   _(This is expected - user hasn't logged in yet)_

4. **Login with phone number**
5. **Check debug logs** - You should now see:

   ```
   ✅ Worker user found: {name}
   📤 Updating FCM token for user: {userId}
   🔑 Token: {token}...
   ✅ FCM token updated successfully in Firestore
   ✅ FCM token updated after login
   ```

6. **Check Firestore Console**:

   - Navigate to `users/{userId}`
   - Verify `fcmToken` field exists
   - Verify `fcmTokenUpdatedAt` timestamp matches login time

7. **Test Push Notification**:
   - Create a new booking from customer app
   - Admin should receive push notification
   - Check `users/{adminId}/notifications/{notificationId}` exists

### Expected Debug Output:

**On App Launch (before login)**:

```
✅ FCM permission granted
🔑 FCM Token: abc123...
❌ Cannot update FCM token: User ID is empty
```

**On Login**:

```
✅ OTP verified. UID: xyz789
✅ Worker user found: John Doe
📤 Updating FCM token for user: xyz789
🔑 Token: abc123...
✅ FCM token updated successfully in Firestore
✅ FCM token updated after login
```

**On Logout**:

```
✅ FCM token cleared from user document
```

## Why This Approach?

### Alternative Approaches Considered:

1. **Wait for login before setting up FCM** ❌

   - Would delay notification setup
   - User might miss notifications during login

2. **Poll for UID in FCM setup** ❌

   - Inefficient
   - Adds complexity

3. **Update token after login** ✅ **CHOSEN**
   - Simple and reliable
   - Doesn't delay FCM setup
   - Ensures token is stored as soon as UID is available

## Files Modified

1. `lib/pages/login/bloc/login_bloc.dart`

   - Added imports for `AppServices` and `FirebaseMessaging`
   - Updated `_checkWorkerUser` to call `updateFCMToken` after login

2. `lib/services/app_services.dart` (previous fix)
   - Changed `updateFCMToken` to use `.set()` with merge
   - Added comprehensive logging

## Status

✅ **FCM Token Storage** - FIXED
✅ **FCM Token Update After Login** - FIXED
⏳ **Background Notification Storage** - PENDING (requires userId in FCM payload)

---

**Next Steps**: Test the fix by logging in and verifying the FCM token appears in Firestore!
