# Notification Storage Fix for Admin Accounts

## Problem Summary

Notifications sent to admin technicians were not being received in the technician app and were not being stored in the notification subcollection. The issue was that there was no `notifications` subcollection being created under admin user documents in Firestore.

## Root Cause

The problem was in the `storeNotificationInFirestore` method in `app_services.dart`. This method is called when the app receives FCM notifications (both in foreground and background). It was storing notifications in the wrong location:

**Before (Incorrect):**

```dart
await AppFirestore.notificationsCollectionRef.add(notificationData);
```

This stored notifications in a root-level `notifications` collection instead of the user-specific subcollection.

**After (Correct):**

```dart
await AppFirestore.usersCollectionRef
    .doc(userId)
    .collection('notifications')
    .add(notificationData);
```

This now stores notifications in the correct path: `users/{userId}/notifications`

## Changes Made

### File: `lib/services/app_services.dart`

1. **Updated `storeNotificationInFirestore` method:**

   - Changed storage location from root `notifications` collection to user-specific subcollection `users/{userId}/notifications`
   - Simplified notification data structure to match Cloud Functions format (using `titleEn`, `titleAr`, `bodyEn`, `bodyAr`, `data`, `read`, `createdAt`)
   - Added early return if `userId` is empty to prevent errors
   - Removed unnecessary fields that were not being used

2. **Removed unused code:**
   - Removed `isCurrentUserAdmin` variable (no longer needed)
   - Removed `_determineNotificationTargetRole` method (no longer needed)
   - Removed `sentTime` and `targetRole` variables (no longer needed)

## How It Works Now

### Cloud Functions (Already Working Correctly)

The Cloud Functions in `functions/index.js` were already correctly storing notifications:

```javascript
await admin
  .firestore()
  .collection(collectionName) // "users" for technicians/admins
  .doc(targetId)
  .collection("notifications")
  .add({
    titleEn,
    titleAr,
    bodyEn,
    bodyAr,
    data: data || {},
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
```

### App Services (Now Fixed)

The app now stores notifications in the same location when receiving FCM messages:

```dart
await AppFirestore.usersCollectionRef
    .doc(userId)
    .collection('notifications')
    .add(notificationData);
```

### Reading Notifications (Already Working Correctly)

The `getNotificationsStream` method was already reading from the correct location:

```dart
return AppFirestore.usersCollectionRef
    .doc(userId)
    .collection('notifications')
    .orderBy('createdAt', descending: true)
    .snapshots()
```

## User Model Structure

As mentioned, for admin technicians:

- They are stored in the `users` collection (same as regular technicians)
- The `isAdmin` field determines if they are admin (`true`) or regular technician (`false`)
- Both admin and regular technicians receive notifications in their `users/{userId}/notifications` subcollection

## Testing Recommendations

1. Send a notification to an admin technician account
2. Verify the notification appears in Firestore at: `users/{adminUserId}/notifications/{notificationId}`
3. Verify the notification appears in the technician app's notification page
4. Test both foreground and background notification reception
5. Test marking notifications as read
6. Test deleting notifications

## Impact

- ✅ Admin technicians will now receive and see notifications
- ✅ Notifications will be properly stored in Firestore subcollections
- ✅ No impact on regular technician notifications (they were already working)
- ✅ No impact on customer notifications (different collection path)
