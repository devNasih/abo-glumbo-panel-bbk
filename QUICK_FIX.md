# Quick Fix Commands for iOS reCAPTCHA Issue

## One-Step Fix (Recommended)

```bash
cd /Users/muhammadrafih/Documents/abo-glumbo-panel-bbk
./fix_ios_recaptcha.sh
```

## Manual Step-by-Step Fix

```bash
# Step 1: Clean Flutter
flutter clean && flutter pub get

# Step 2: Clean iOS build artifacts
cd ios
rm -rf Pods Pods.lock
rm -rf Flutter/Flutter.podspec
rm -rf Build .symlinks Flutter/Flutter.framework

# Step 3: Update pods and reinstall
pod repo update
pod install --repo-update
cd ..

# Step 4: Clean Xcode
open ios/Runner.xcworkspace
# In Xcode: Cmd+Shift+K (clean build folder)
# Close Xcode

# Step 5: Rebuild the app
flutter run -d ios --release
```

## Quick Test Commands

```bash
# Test on iOS device
flutter run -d ios

# Test on iOS simulator
flutter run

# Run with verbose logging
flutter run -d ios -v
```

## Key Files Changed

1. **ios/Podfile** - **CRITICAL: Added `pod 'RecaptchaEnterprise'`** to link the reCAPTCHA SDK
2. **ios/Runner/AppDelegate.swift** - Added FirebaseAuth import and better initialization
3. **lib/services/auth_services.dart** - Safer Firebase Auth configuration with try-catch
4. **fix_ios_recaptcha.sh** - Added Xcode DerivedData cleanup

## What the Fix Does

✅ **Adds RecaptchaEnterprise pod** - This is the main fix that links the reCAPTCHA SDK to your app
✅ Ensures Firebase pods are properly linked with reCAPTCHA support
✅ Clears corrupted build cache (including Xcode DerivedData) that prevents SDK linking
✅ Configures Podfile to explicitly enable reCAPTCHA integration
✅ Adds better error handling in auth service
✅ Maintains SMS-based OTP flow as fallback

## Expected Behavior After Fix

**For Physical Device:**

- ✅ Phone number verification request is sent to Firebase
- ✅ Firebase processes reCAPTCHA verification (happens silently)
- ✅ User receives SMS with OTP code
- ✅ User enters code and completes sign-in

**For Simulator (Testing):**

- Set `isTestMode = true` in `auth_services.dart` (line ~88 and ~240)
- Use test phone: `+15555555555`
- Use test OTP: `123456`
- Switch back to `false` for production

## Debugging

Monitor these logs to confirm proper initialization:

```
🟢 [AUTH SERVICE] sendOTP method called
🔢 [AUTH SERVICE] Sanitized number: +966[number]
📱 [AUTH SERVICE] Platform: iOS
🍎 [AUTH SERVICE] iOS detected - configuring Firebase Auth settings
🍎 [AUTH SERVICE] iOS Firebase Auth settings configured
📞 [AUTH SERVICE] Calling Firebase verifyPhoneNumber...
✅ [AUTH SERVICE] codeSent callback triggered
```

If you see `recaptcha-sdk-not-linked` error AFTER running the fix script, check:

1. Firebase pod version is up to date: `pod outdated`
2. GoogleService-Info.plist is valid
3. Bundle ID matches: `com.aboglumbo.cPanel`
4. Clear Xcode DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
