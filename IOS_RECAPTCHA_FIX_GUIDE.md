# iOS reCAPTCHA SDK Linking Fix Guide

## Problem

The error `recaptcha-sdk-not-linked` occurs when Firebase Authentication tries to use reCAPTCHA for phone verification on iOS, but the reCAPTCHA SDK isn't properly linked to your app.

## Root Causes

1. Firebase pods not properly installed with reCAPTCHA support
2. Build cache corruption preventing proper SDK linking
3. Missing or stale build artifacts

## Solution Applied

### 1. **Added RecaptchaEnterprise Pod (CRITICAL FIX)**

The main issue is that the reCAPTCHA Enterprise SDK needs to be **explicitly added** to your iOS project. This is done by adding the following to your `Podfile`:

```ruby
pod 'RecaptchaEnterprise'
```

This pod provides the actual reCAPTCHA SDK that Firebase Phone Authentication requires on iOS.

### 2. Updated AppDelegate.swift

- Added explicit `import FirebaseAuth` for proper module linking
- Improved Firebase initialization with better error handling

### 3. Updated auth_services.dart

- Added safer configuration for `setSettings` with try-catch block
- Made `appVerificationDisabledForTesting` configurable (currently set to `false`)
- Added better error logging for Firebase Auth configuration

### 4. Updated Podfile

- **Added `pod 'RecaptchaEnterprise'`** - This is the key fix!
- Added post-install hook to ensure FirebaseAuth reCAPTCHA support
- Configured proper build settings for reCAPTCHA integration

## Steps to Complete the Fix

### Step 1: Run the Cleanup Script

Execute the provided cleanup script to properly clean and reinstall all dependencies:

```bash
chmod +x fix_ios_recaptcha.sh
./fix_ios_recaptcha.sh
```

This script:

- Cleans Flutter build artifacts
- Removes Pods directory and locks
- Updates CocoaPods repo
- Reinstalls pods with `--repo-update` flag

### Step 2: Open Xcode and Clean

```bash
open ios/Runner.xcworkspace
```

In Xcode:

1. Press `Cmd+Shift+K` to clean build folder
2. Close Xcode

### Step 3: Verify Firebase Configuration

Ensure your `GoogleService-Info.plist` is:

- Present in the project at `ios/Runner/GoogleService-Info.plist`
- Added to the build target (it already is)
- Contains valid Firebase credentials

Current values from your config:

- Bundle ID: `com.aboglumbo.cPanel`
- Project ID: `worker-app-tnext`
- Firebase API Key: ✓ Present
- REVERSED_CLIENT_ID: ✓ Present (needed for URL schemes)

### Step 4: Rebuild the App

```bash
flutter run -d ios --release
```

Or:

```bash
flutter run -d ios
```

## Testing reCAPTCHA Verification

### On Physical Device (Recommended)

- Full reCAPTCHA verification is performed
- Phone number will receive actual SMS OTP
- This is the production flow

### On Simulator (Development)

If you want to test without actual SMS:

1. Set `isTestMode = true` in `auth_services.dart` (lines ~88 and ~240)
2. Use test phone numbers like `+15555555555`
3. Use code `123456` as OTP
4. Remember to set it back to `false` for production

## Key Points

### URL Schemes

Your URL scheme is already configured in `Info.plist`:

```
com.googleusercontent.apps.629201660527-g3q673rcg9087klcj1hevmaolktfapsb
```

This is required for reCAPTCHA redirection.

### Verification Flow

1. `sendOTP()` is called with phone number
2. Firebase calls `verifyPhoneNumber` with reCAPTCHA
3. On iOS, `verificationFailed` with `recaptcha-sdk-not-linked` is expected if SDK isn't linked
4. Simultaneously, `codeSent` should be triggered with verification ID
5. User receives SMS and enters code
6. `verifyOTP()` completes authentication

### Error Handling

The code now gracefully handles `recaptcha-sdk-not-linked` error by:

- Logging it as expected on iOS
- Continuing to wait for `codeSent` callback
- Allowing SMS-based verification to proceed

## Troubleshooting

### If error persists after rebuild:

1. **Check Firebase pod version**: `pod outdated`
2. **Force update pods**: `cd ios && pod update && pod install --repo-update`
3. **Clear Xcode cache**: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
4. **Verify bundle ID matches**: Check `GoogleService-Info.plist` BUNDLE_ID against Xcode project settings

### If SMS isn't received:

1. Verify phone number format is correct: `+[country code][number]`
2. Check Firebase Console > Authentication > Phone numbers for verification status
3. Ensure SMS is enabled for your Firebase project in Google Cloud Console

### For development/testing:

Set `isTestMode = true` to avoid actual SMS charges during development.

## Next Steps

1. Run the cleanup script
2. Rebuild the app
3. Test on a physical iOS device
4. Monitor the debug logs to confirm proper reCAPTCHA initialization

## Files Modified

- `ios/Runner/AppDelegate.swift`
- `ios/Podfile`
- `lib/services/auth_services.dart`
- `fix_ios_recaptcha.sh` (new script)
