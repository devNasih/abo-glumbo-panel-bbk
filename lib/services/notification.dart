import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'app_services.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  await AppServices.storeNotificationInFirestore(message);
}

class NotificationServices {
  static bool _isInitialized = false;
  static bool _tokenRefreshListenerSet = false;
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> setupFCMListeners() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        showNotification(
          id: notification.hashCode,
          title: notification.title ?? 'Notification',
          body: notification.body ?? '',
          payload: json.encode(message.data),
        );
        AppServices.storeNotificationInFirestore(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null) {
        AppServices.storeNotificationInFirestore(message);
      }
    });
  }

  static Future<void> initializeFCM() async {
    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _getFCMTokenAndUpdate();
        _setupTokenRefreshListener();
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  static Future<void> _getFCMTokenAndUpdate() async {
    try {
      String? token;

      if (Platform.isIOS) {
        // Wait for APNS token with timeout
        await _waitForAPNSToken();
        token = await _firebaseMessaging.getToken();
      } else {
        token = await _firebaseMessaging.getToken();
      }

      if (token != null && token.isNotEmpty) {
        await AppServices.updateFCMToken(token);
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  static Future<void> _waitForAPNSToken() async {
    try {
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      // Wait up to 10 seconds for APNS token
      int attempts = 0;
      while (attempts < 20) {
        // 20 attempts * 500ms = 10 seconds
        await Future.delayed(const Duration(milliseconds: 500));
        apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          return;
        }
        attempts++;
      }
    } catch (e) {
      debugPrint('❌ Error waiting for APNS token: $e');
    }
  }

  static void _setupTokenRefreshListener() {
    if (_tokenRefreshListenerSet) {
      return;
    }

    _firebaseMessaging.onTokenRefresh.listen(
      (fcmToken) {
        if (fcmToken.isNotEmpty) {
          AppServices.updateFCMToken(fcmToken)
              .then((_) {
                debugPrint('✅ Refreshed FCM Token updated successfully');
              })
              .catchError((error) {
                debugPrint('❌ Error updating refreshed FCM token: $error');
              });
        }
      },
      onError: (error) {
        debugPrint('❌ Error in token refresh listener: $error');
      },
    );

    _tokenRefreshListenerSet = true;
    debugPrint('🔄 Token refresh listener set up successfully');
  }

  static Future<void> refreshFCMToken() async {
    try {
      debugPrint('🔄 Manually refreshing FCM token...');
      await _getFCMTokenAndUpdate();
    } catch (e) {
      debugPrint('❌ Error manually refreshing FCM token: $e');
    }
  }

  static Future<String?> getCurrentFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('🔑 Current FCM Token: ${token.substring(0, 20)}...');
      } else {
        debugPrint('❌ No FCM token available');
      }
      return token;
    } catch (e) {
      debugPrint('❌ Error getting current FCM token: $e');
      return null;
    }
  }

  static Future<void> deleteFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      debugPrint('🗑️ FCM token deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  static Future<void> debugFCMStatus() async {
    try {
      debugPrint('🔍 FCM Debug Status:');
      debugPrint('   - Initialized: $_isInitialized');
      debugPrint('   - Token refresh listener set: $_tokenRefreshListenerSet');

      String? token = await getCurrentFCMToken();
      if (token != null) {
        debugPrint('   - Current token available: Yes');
        debugPrint('   - Token length: ${token.length}');
      } else {
        debugPrint('   - Current token available: No');
      }

      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        debugPrint(
          '   - APNS Token available: ${apnsToken != null ? "Yes" : "No"}',
        );
      }

      NotificationSettings settings = await _firebaseMessaging
          .getNotificationSettings();
      debugPrint('   - Permission status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('❌ Error getting FCM debug status: $e');
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'abo_glumbo_channel',
          'Abo Glumbo Notifications',
          channelDescription:
              'Notifications related to Abo Glumbo tasks and updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          visibility: NotificationVisibility.public,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  static Future<void> checkForInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

    if (initialMessage != null) {
      if (initialMessage.notification != null) {
        AppServices.storeNotificationInFirestore(initialMessage);
      }
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null) {
        AppServices.storeNotificationInFirestore(message);
      }
    });
  }
}
