import 'package:aboglumbo_bbk_panel/main.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';

class LocalStore {
  static Future<void> putUID(String uid) {
    return MyApp.box.put('uid', uid);
  }

  static String? getUID() {
    return MyApp.box.get('uid');
  }

  // clear uid
  static Future<void> clearUID() {
    return MyApp.box.delete('uid');
  }

  // WORKER LOGOUT STATUS
  static Future<void> putlogoutStatus(bool isLoggedOut) async {
    await MyApp.box.put('is_logged_out', isLoggedOut);
  }

  static bool getLogoutStatus() {
    return MyApp.box.get('is_logged_out', defaultValue: false) ?? false;
  }

  static Future<void> clearLogoutStatus() async {
    await MyApp.box.delete('is_logged_out');
  }

  // Remember me feature
  static Future<void> putRememberMe(bool rememberMe) async {
    return MyApp.box.put('remember_me', rememberMe);
  }

  static bool getRememberMe() {
    return MyApp.box.get('remember_me', defaultValue: false) ?? false;
  }

  static Future<void> clearRememberMe() async {
    return MyApp.box.delete('remember_me');
  }

  static Future<void> rememberEmailAndPassword(
    String email,
    String password,
  ) async {
    await MyApp.box.put('remember_email', email);
    await MyApp.box.put('remember_password', password);
  }

  static String? getRememberedEmail() {
    return MyApp.box.get('remember_email');
  }

  static String? getRememberedPassword() {
    return MyApp.box.get('remember_password');
  }

  static Future<void> clearRememberedCredentials() async {
    await MyApp.box.delete('remember_email');
    await MyApp.box.delete('remember_password');
  }

  static Future<String> putUserlanguage(String lang) async {
    await MyApp.box.put('user_language', lang);
    await MyApp.box.flush();
    return lang;
  }

  static String getUserlanguage() {
    return MyApp.box.get('user_language', defaultValue: 'en');
  }

  // Biometric
  static Future<bool> setBiometricAuthEnabled(
    bool isEnabled,
    String uid,
  ) async {
    await MyApp.box.put('biometric_auth_enabled_$uid', isEnabled);
    return true;
  }

  static bool getBiometricAuthEnabled(String uid) {
    return MyApp.box.get('biometric_auth_enabled_$uid', defaultValue: false) ??
        false;
  }

  static Future<void> setActiveBookingId(String bookingId) async {
    await MyApp.box.put('active_booking_id', bookingId);
  }

  static String? getActiveBookingId() {
    return MyApp.box.get('active_booking_id');
  }

  // User Data Storage
  static Future<void> storeUserData(UserModel user) async {
    await MyApp.box.put('cached_user_data', user.toJson());
    await MyApp.box.flush();
  }

  static UserModel? getCachedUserData() {
    final userData = MyApp.box.get('cached_user_data');
    if (userData != null && userData is Map) {
      try {
        return UserModel.fromJson(Map<String, dynamic>.from(userData));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearCachedUserData() async {
    await MyApp.box.delete('cached_user_data');
  }
}
