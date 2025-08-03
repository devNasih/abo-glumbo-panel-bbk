import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
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

  // Account
  static Future<void> updateUserProfile(UserModel user) async {
    try {
      String userId = user.uid ?? '';

      if (userId.isNotEmpty) {
        Map<String, dynamic> userData = user.toJson();
        userData.remove('uid');
        userData['updatedAt'] = Timestamp.now();

        await AppFirestore.usersCollectionRef.doc(userId).update(userData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user profile: $e');
      }
      rethrow;
    }
  }

  static Future<List<LocationModel>> getDistricts() async {
    try {
      final snapshot = await AppFirestore.locationsCollectionRef.get();
      return snapshot.docs
          .map(
            (doc) => LocationModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching districts: $e');
      }
      return [];
    }
  }

  static Future<void> updateWorkerLanguage(String language) async {
    try {
      String userId = LocalStore.getUID() ?? '';
      if (userId.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No user logged in, cannot update worker language');
        }
        return;
      }
      await AppFirestore.usersCollectionRef.doc(userId).update({
        'lanCode': language,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating worker language: $e');
      }
    }
  }

  //
  static Stream<List<BookingModel>> getBookingsStream({
    String? bookingStatusCode,
  }) {
    String workerId = LocalStore.getUID() ?? '';
    Query query = AppFirestore.bookingsCollectionRef
        .where('agent.uid', isEqualTo: workerId)
        .where('bookingStatusCode', isEqualTo: bookingStatusCode)
        .orderBy(
          bookingStatusCode == 'A' ? 'acceptedAt' : 'completedAt',
          descending: true,
        );

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromDocumentSnapshot(doc))
          .toList();
    });
  }
}
