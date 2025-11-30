import 'dart:developer';
import 'dart:io';

import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? phoneNumber;

  String _sanitizePhoneNumber(String input) {
    if (input.startsWith("+966")) {
      String countryCode = "+966";
      String numberPart = input.substring(4);
      String sanitizedNumberPart = _sanitizeNumberPart(numberPart);
      String result = countryCode + sanitizedNumberPart;
      return result;
    }
    String sanitizedNumberPart = _sanitizeNumberPart(input);
    return sanitizedNumberPart;
  }

  String _sanitizeNumberPart(String input) {
    String result = input.replaceAll(RegExp(r'\s'), '');
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const asciiDigits = '0123456789';
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], asciiDigits[i]);
    }
    return result;
  }

  String _sanitizeOTP(String input) {
    // Remove spaces and convert Arabic digits to ASCII for OTP
    String result = input.replaceAll(RegExp(r'\s'), '');
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const asciiDigits = '0123456789';
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], asciiDigits[i]);
    }
    return result;
  }

  String _formatToE164(String phoneNumber) {
    String sanitized = phoneNumber;
    if (sanitized.startsWith('+966')) {
      return sanitized;
    }
    while (sanitized.startsWith('0')) {
      sanitized = sanitized.substring(1);
    }
    String e164Number = '+966$sanitized';
    return e164Number;
  }

  String? _verificationId;

  Future<void> sendOTP(
    BuildContext context, {
    required String phoneNumber,
    required Function(String verificationId, {int? resendToken}) onCodeSent,
    required Function(FirebaseAuthException e) onError,
    int? forceResendingToken,
  }) async {
    String sanitizedPhoneNumber = _formatToE164(
      _sanitizePhoneNumber(phoneNumber),
    );
    try {
      if (kDebugMode) {
        debugPrint('✅ Phone number: $phoneNumber');
        print('📱 Platform: ${Platform.isIOS ? "iOS" : "Android"}');
        print('🔢 Sanitized number: $sanitizedPhoneNumber');
      }
      AuthServices.phoneNumber = sanitizedPhoneNumber;
      _verificationId = null;

      // iOS specific configuration for reCAPTCHA
      if (Platform.isIOS) {
        debugPrint('🍎 iOS detected - configuring Firebase Auth settings');
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: false,
          userAccessGroup: null,
        );
        debugPrint('🍎 iOS Firebase Auth settings configured');
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: sanitizedPhoneNumber,
        forceResendingToken: forceResendingToken,
        timeout: const Duration(
          seconds: 120,
        ), // 5 minutes timeout for OTP verification
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification
          try {
            AuthServices.phoneNumber = sanitizedPhoneNumber;
            await _auth.signInWithCredential(credential);
          } catch (e) {
            debugPrint("Auto verification failed: $e");
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint(
            "Firebase Auth verification failed: ${e.code} - ${e.message}",
          );

          // Handle reCAPTCHA specific errors more gracefully
          if (e.code == 'recaptcha-sdk-not-linked' ||
              e.code == 'web-context-cancelled' ||
              e.code == 'web-context-canceled') {
            debugPrint(
              "reCAPTCHA error (${e.code}) - this is expected on iOS, waiting for codeSent callback",
            );
            // Don't call onError - wait for codeSent callback
            return;
          }

          onError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint(
            "✅ OTP code sent successfully. Verification ID: $verificationId",
          );
          debugPrint(
            "📱 Platform: ${Platform.isIOS ? 'iOS' : 'Android'}, ResendToken: $resendToken",
          );
          onCodeSent(verificationId, resendToken: resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint(
            "Auto retrieval timeout for verification ID: $verificationId",
          );
        },
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        log("Firebase Auth error: ${e.code} - ${e.message}");

        // Special handling for reCAPTCHA errors
        if (e.code == 'recaptcha-sdk-not-linked') {
          log("reCAPTCHA SDK not linked - this might be a configuration issue");
        }

        onError(e);
      } else {
        onError(FirebaseAuthException(code: 'unknown', message: e.toString()));
      }
    }
  }

  Future<void> resendOTP({
    required String phoneNumber,
    required int? resendToken,
    required Function(String verificationId, {int? resendToken}) onCodeSent,
    required Function(FirebaseAuthException e) onError,
  }) async {
    String sanitizedPhoneNumber = _formatToE164(
      _sanitizePhoneNumber(phoneNumber),
    );
    try {
      // iOS specific configuration for reCAPTCHA
      if (Platform.isIOS) {
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: false,
          userAccessGroup: null,
        );
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: sanitizedPhoneNumber,
        forceResendingToken: resendToken,
        timeout: const Duration(
          seconds: 120,
        ), // 5 minutes timeout for OTP verification
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint(
            "Firebase Auth resend verification failed: ${e.code} - ${e.message}",
          );

          // Handle reCAPTCHA specific errors more gracefully
          if (e.code == 'recaptcha-sdk-not-linked' ||
              e.code == 'web-context-cancelled' ||
              e.code == 'web-context-canceled') {
            debugPrint(
              "reCAPTCHA error (${e.code}) - this is expected on iOS, waiting for codeSent callback",
            );
            // Don't call onError - wait for codeSent callback
            return;
          }

          onError(e);
        },
        codeSent: (String verificationId, int? token) {
          _verificationId = verificationId;
          onCodeSent(verificationId, resendToken: token);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          debugPrint(
            "Resend auto retrieval timeout for verification ID: $verificationId",
          );
        },
      );
    } catch (e) {
      debugPrint("Error resending OTP: $e");
      if (e is FirebaseAuthException) {
        // Special handling for reCAPTCHA errors
        if (e.code == 'recaptcha-sdk-not-linked') {
          debugPrint(
            "reCAPTCHA SDK not linked - this might be a configuration issue",
          );
        }

        onError(e);
      } else {
        onError(FirebaseAuthException(code: 'unknown', message: e.toString()));
      }
    }
  }

  Future<UserCredential> verifyOTP(
    BuildContext context,
    String otp, {
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      String sanitizedOTP = _sanitizeOTP(otp);

      // Additional validation for iOS
      if (sanitizedOTP.isEmpty || sanitizedOTP.length != 6) {
        throw FirebaseAuthException(
          code: 'invalid-verification-code',
          message: 'Invalid OTP format. Please enter a 6-digit code.',
        );
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: sanitizedOTP,
      );
      final tempUserCredential = await _auth.signInWithCredential(credential);
      final userPhoneNumber = tempUserCredential.user?.phoneNumber ?? '';

      AuthServices.phoneNumber = userPhoneNumber;

      return tempUserCredential;
    } catch (e) {
      debugPrint("Error verifying OTP: $e");
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            debugPrint("iOS: Invalid verification code provided");
            break;
          case 'session-expired':
            debugPrint("iOS: OTP session expired");
            break;
          case 'too-many-requests':
            debugPrint("iOS: Too many requests - temporarily blocked");
            break;
          case 'network-request-failed':
            debugPrint("iOS: Network request failed");
            break;
          default:
            debugPrint("iOS: Unknown error - ${e.code}: ${e.message}");
        }
        rethrow;
      } else {
        throw FirebaseAuthException(
          code: 'verification-failed',
          message: 'Failed to verify OTP: $e',
        );
      }
    }
  }

  // ✅ FIXED: Check USERS collection (workers) instead of customers
  Future<void> checkUser({
    required UserCredential userCredential,
    required BuildContext context,
  }) async {
    try {
      final uid = userCredential.user?.uid;
      if (uid == null) {
        debugPrint("Error: User UID is null");
        return;
      }

      // ✅ FIXED: Check workers collection
      final userDoc = await AppFirestore.usersCollectionRef.doc(uid).get();

      if (userDoc.exists) {
        LocalStore.putUID(uid);
        LocalStore.putlogoutStatus(false);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Signup(uid: uid)),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error in checkUser: $e");
      if (e is FirebaseAuthException) {
        rethrow;
      } else {
        throw FirebaseAuthException(
          code: 'check-user-failed',
          message: 'Failed to check user: $e',
        );
      }
    }
  }
}
