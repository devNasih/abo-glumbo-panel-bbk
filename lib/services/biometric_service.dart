import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticate(BuildContext context) async {
    try {
      return await _auth.authenticate(
        localizedReason:
            AppLocalizations.of(context)?.enableBiometricAuthentication ?? '',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await LocalStore.setBiometricAuthEnabled(
      enabled,
      LocalStore.getUID() ?? '',
    );
  }

  static Future<bool> isBiometricEnabled() async {
    return await LocalStore.getBiometricAuthEnabled(LocalStore.getUID() ?? '');
  }
}
