import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class AppServices {
  // NOTIFICTIONS
  static Future<void> updateFCMToken(String token) async {
    try {
      String userId = LocalStore.getUID() ?? '';
      if (userId.isNotEmpty) {
        await AppFirestore.usersCollectionRef.doc(userId).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating FCM token: $e');
      }
    }
  }

  static Future<void> storeNotificationInFirestore(
    RemoteMessage message,
  ) async {
    try {
      String userId = LocalStore.getUID() ?? '';
      String title =
          message.notification?.title ??
          message.data['title'] ??
          'New Notification';
      String body =
          message.notification?.body ??
          message.data['body'] ??
          'You have a new notification';
      Timestamp sentTime = message.sentTime != null
          ? Timestamp.fromDate(message.sentTime!)
          : Timestamp.now();

      Map<String, dynamic> notificationData = {
        'userId': userId,
        'title': title,
        'body': body,
        'data': message.data.isNotEmpty ? message.data : {},
        'messageId': message.messageId ?? '',
        'sentTime': sentTime,
        'createdAt': Timestamp.now(),
        'isRead': false,
        'category': message.data['category']?.toString() ?? 'general',
        'action': message.data['action']?.toString() ?? '',
        'platform': message.data['platform']?.toString() ?? 'mobile',
      };

      await AppFirestore.notificationsCollectionRef.add(notificationData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error storing notification: $e');
      }
    }
  }

  // LOGIN
  static Future<bool> checkTheMailExists(String email) async {
    final snapshot = await AppFirestore.usersCollectionRef
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
