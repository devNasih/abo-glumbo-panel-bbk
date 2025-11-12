import 'package:aboglumbo_bbk_panel/main.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';

class LocalStore {
  // ============================================
  // UID Management
  // ============================================
  static Future<void> putUID(String uid) {
    // Also store as last valid UID for biometric authentication
    MyApp.box.put('last_valid_uid', uid);
    return MyApp.box.put('uid', uid);
  }

  static String? getUID() {
    return MyApp.box.get('uid');
  }

  // Get the last valid UID (for biometric auth after logout)
  static String? getLastValidUID() {
    return MyApp.box.get('last_valid_uid');
  }

  // clear uid
  static Future<void> clearUID() {
    return MyApp.box.delete('uid');
  }

  // ============================================
  // Logout Status
  // ============================================
  static Future<void> putlogoutStatus(bool isLoggedOut) async {
    await MyApp.box.put('is_logged_out', isLoggedOut);
  }

  static bool getLogoutStatus() {
    return MyApp.box.get('is_logged_out', defaultValue: false) ?? false;
  }

  static Future<void> clearLogoutStatus() async {
    await MyApp.box.delete('is_logged_out');
  }

  // ============================================
  // Remember Me Feature
  // ============================================
  static Future<void> putRememberMe(bool rememberMe) async {
    return MyApp.box.put('remember_me', rememberMe);
  }

  static bool getRememberMe() {
    return MyApp.box.get('remember_me', defaultValue: false) ?? false;
  }

  static Future<void> clearRememberMe() async {
    return MyApp.box.delete('remember_me');
  }

  // ============================================
  // Phone Number Storage (NEW - for phone authentication)
  // ============================================

  /// Save phone number for Remember Me feature
  static Future<void> rememberPhone(String phone) async {
    await MyApp.box.put('remember_phone', phone);
    await MyApp.box.flush();
  }

  /// Get remembered phone number
  static String? getRememberedPhone() {
    return MyApp.box.get('remember_phone');
  }

  /// Clear remembered phone number
  static Future<void> clearRememberedPhone() async {
    await MyApp.box.delete('remember_phone');
    await MyApp.box.flush();
  }

  // ============================================
  // Language Preference
  // ============================================
  static Future<String> putUserlanguage(String lang) async {
    await MyApp.box.put('user_language', lang);
    await MyApp.box.flush();
    return lang;
  }

  static String getUserlanguage() {
    return MyApp.box.get('user_language', defaultValue: 'en');
  }

  // ============================================
  // Biometric Authentication (per-user UID)
  // ============================================
  static Future<bool> setBiometricAuthEnabled(
    bool isEnabled,
    String uid,
  ) async {
    await MyApp.box.put('biometric_auth_enabled_$uid', isEnabled);
    await MyApp.box.flush();
    return true;
  }

  static bool getBiometricAuthEnabled(String uid) {
    return MyApp.box.get('biometric_auth_enabled_$uid', defaultValue: false) ??
        false;
  }

  // ============================================
  // Active Booking Tracking
  // ============================================
  static Future<void> setActiveBookingId(String bookingId) async {
    await MyApp.box.put('active_booking_id', bookingId);
    await MyApp.box.flush();
  }

  static String? getActiveBookingId() {
    return MyApp.box.get('active_booking_id');
  }

  static Future<void> clearActiveBookingId() async {
    await MyApp.box.delete('active_booking_id');
  }

  // ============================================
  // User Data Cache (for offline/quick access)
  // ============================================
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
    await MyApp.box.flush();
  }

  // ============================================
  // Utility: Clear All Auth Data on Logout
  // ============================================
  static Future<void> clearAllAuthData() async {
    await clearUID();
    await clearCachedUserData();
    await clearActiveBookingId();

    // ✅ FIXED: Only clear phone if Remember Me is disabled
    if (!getRememberMe()) {
      await clearRememberedPhone();
      await clearRememberMe();
    }

    // ✅ Don't clear Remember Me checkbox state
    // await clearRememberMe(); // Remove this line

    await MyApp.box.flush();
  }
}
