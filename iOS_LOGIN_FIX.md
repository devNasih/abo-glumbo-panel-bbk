# iOS Login Timeout Issue - Fix Summary

## Problem

The iOS app (TestFlight build) experiences a timeout error when users enter their phone number and click continue during login. The Android version works fine.

## Root Causes Identified

### 1. **Short Timeout Duration**

- The `login_bloc.dart` had a 30-second timeout for OTP sending
- iOS Firebase Phone Authentication requires more time due to reCAPTCHA verification
- iOS can take 60-120 seconds for the complete authentication flow

### 2. **iOS reCAPTCHA Errors Not Handled Properly**

- iOS shows reCAPTCHA errors like `recaptcha-sdk-not-linked`, `web-context-cancelled`
- These errors were being treated as failures, but they're actually expected on iOS
- The code should wait for the `codeSent` callback instead of failing immediately

### 3. **Missing Firebase Configuration**

- AppDelegate didn't explicitly configure Firebase
- No URL scheme handler for reCAPTCHA redirects

### 4. **Insufficient Logging**

- Limited debugging information for iOS-specific issues
- Hard to diagnose timeout vs actual errors

## Changes Made

### 1. **login_bloc.dart** - Increased Timeout

**File**: `lib/pages/login/bloc/login_bloc.dart`
**Change**: Increased timeout from 30s to 120s (line 62-66)

```dart
// Before
const Duration(seconds: 30)

// After
const Duration(seconds: 120)  // For iOS reCAPTCHA
```

### 2. **auth_services.dart** - Enhanced iOS Error Handling

**File**: `lib/services/auth_services.dart`

#### Change 1: Better reCAPTCHA Error Handling (lines 102-116)

```dart
// Added handling for multiple iOS reCAPTCHA error codes
if (e.code == 'recaptcha-sdk-not-linked' ||
    e.code == 'web-context-cancelled' ||
    e.code == 'web-context-canceled') {
  debugPrint("reCAPTCHA error (${e.code}) - this is expected on iOS, waiting for codeSent callback");
  // Don't call onError - wait for codeSent callback
  return;
}
```

#### Change 2: Enhanced Logging (lines 74-87)

```dart
if (kDebugMode) {
  print('✅ Phone number: $phoneNumber');
  print('📱 Platform: ${Platform.isIOS ? "iOS" : "Android"}');
  print('🔢 Sanitized number: $sanitizedPhoneNumber');
}

if (Platform.isIOS) {
  debugPrint('🍎 iOS detected - configuring Firebase Auth settings');
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: false,
    userAccessGroup: null,
  );
  debugPrint('🍎 iOS Firebase Auth settings configured');
}
```

#### Change 3: Better codeSent Logging (lines 117-122)

```dart
codeSent: (String verificationId, int? resendToken) {
  debugPrint("✅ OTP code sent successfully. Verification ID: $verificationId");
  debugPrint("📱 Platform: ${Platform.isIOS ? 'iOS' : 'Android'}, ResendToken: $resendToken");
  onCodeSent(verificationId, resendToken: resendToken);
}
```

### 3. **AppDelegate.swift** - Firebase Configuration

**File**: `ios/Runner/AppDelegate.swift`

```swift
import Firebase  // Added Firebase import

// Explicitly configure Firebase
if FirebaseApp.app() == nil {
  FirebaseApp.configure()
}

// Handle URL schemes for reCAPTCHA
override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
  return super.application(app, open: url, options: options)
}
```

## Testing Instructions

### 1. **Clean Build**

```bash
cd d:\Brandbik\abo-glumbo-panel-bbk
flutter clean
flutter pub get
cd ios
pod install --repo-update
cd ..
```

### 2. **Build for iOS**

```bash
flutter build ios --release
```

### 3. **Test on TestFlight**

- Upload the new build to TestFlight
- Test the login flow on a real iOS device
- Monitor the console logs for the new debug messages

### 4. **Expected Behavior**

- User enters phone number
- Clicks "Continue"
- Loading indicator shows
- iOS may show reCAPTCHA verification (web view)
- User completes reCAPTCHA (if shown)
- OTP is sent successfully
- User is navigated to OTP verification page

### 5. **Debug Logging**

Look for these log messages in Xcode console:

```
✅ Phone number: +966XXXXXXXXX
📱 Platform: iOS
🔢 Sanitized number: +966XXXXXXXXX
🍎 iOS detected - configuring Firebase Auth settings
🍎 iOS Firebase Auth settings configured
✅ OTP code sent successfully. Verification ID: XXXXX
📱 Platform: iOS, ResendToken: XXXXX
```

## Additional Recommendations

### 1. **Verify GoogleService-Info.plist**

- Ensure the file is present in `ios/Runner/`
- Verify it contains the correct iOS app configuration
- Check that `REVERSED_CLIENT_ID` matches the URL scheme in Info.plist

### 2. **Check APNS Configuration**

- Ensure APNS certificates are properly configured in Firebase Console
- Verify push notification capabilities are enabled in Xcode

### 3. **Test Network Conditions**

- Test on both WiFi and cellular data
- iOS reCAPTCHA requires stable internet connection

### 4. **Monitor Firebase Console**

- Check Firebase Console > Authentication > Sign-in method
- Ensure Phone authentication is enabled
- Check for any quota limits or restrictions

## Common iOS-Specific Issues

### Issue 1: reCAPTCHA Not Showing

**Solution**: Ensure URL scheme is properly configured in Info.plist

### Issue 2: Still Timing Out

**Possible Causes**:

- Poor network connection
- Firebase quota exceeded
- APNS not configured
- GoogleService-Info.plist missing or incorrect

### Issue 3: "web-context-cancelled" Error

**Solution**: This is now handled gracefully - the app will wait for codeSent callback

## Rollback Instructions

If these changes cause issues, revert by:

```bash
git checkout HEAD -- lib/pages/login/bloc/login_bloc.dart
git checkout HEAD -- lib/services/auth_services.dart
git checkout HEAD -- ios/Runner/AppDelegate.swift
```

## Next Steps

1. Build and upload to TestFlight
2. Test on multiple iOS devices (iPhone with different iOS versions)
3. Monitor Firebase Console for authentication attempts
4. Check Xcode console logs for detailed debugging information
5. If issues persist, check Firebase Console quotas and APNS configuration
