import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/models/banner.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/highlighted_services.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:aboglumbo_bbk_panel/models/tipping.dart';
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

  static Future<List<Map<String, dynamic>>> getUserNotifications({
    int limit = 20,
    bool onlyUnread = false,
  }) async {
    try {
      String userId = LocalStore.getUID() ?? '';
      if (userId.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No user logged in, cannot retrieve notifications');
        }
        return [];
      }

      Query query = AppFirestore.notificationsCollectionRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (onlyUnread) {
        query = query.where('isRead', isEqualTo: false);
      }

      QuerySnapshot querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error retrieving notifications: $e');
      }
      return [];
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

  static Stream<List<BookingModel>> getBookingsStreamByStatus(
    String bookingStatusCode,
  ) {
    Query query = AppFirestore.bookingsCollectionRef
        .where('bookingStatusCode', isEqualTo: bookingStatusCode)
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  static Stream<List<CategoryModel>> getAllCategoriesStream() {
    return AppFirestore.categoriesCollectionRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  static Stream<List<ServiceModel>> getAllServicesStream() {
    return AppFirestore.servicesCollectionRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceModel.fromQueryDocumentSnapshot(doc))
          .toList();
    });
  }

  static Stream<List<HighlightedServicesModel>>
  getAllHighlightedServicesStream() {
    return AppFirestore.highlightedServicesCollectionRef.snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => HighlightedServicesModel.fromQueryDocumentSnapshot(doc))
          .toList();
    });
  }

  static Stream<List<BannerModel>> getAllBannersStream() {
    return AppFirestore.bannersCollectionRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BannerModel.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  static Stream<List<UserModel>> getAllAgentsStream() {
    return AppFirestore.usersCollectionRef
        .where('isAdmin', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  static Stream<List<TippingModel>> getTippingStream() {
    return AppFirestore.tippingCollectionRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TippingModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Clear Tip Wallet
  static Future<bool> clearTippingAmount(String agentId) async {
    try {
      await AppFirestore.tippingCollectionRef.doc(agentId).update({
        'totalTip': 0.0,
        'lastTipAmount': 0.0,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing tipping amount: $e');
      }
      return false;
    }
  }

  static Future<bool> approveOrRejectAgent(
    String agentId,
    bool isApproved,
  ) async {
    try {
      await AppFirestore.usersCollectionRef.doc(agentId).update({
        'isVerified': isApproved,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error approving/rejecting agent: $e');
      }
      return false;
    }
  }

  // Banners
  static Future<bool> addBanner(BannerModel banner, String bannerId) async {
    try {
      await AppFirestore.bannersCollectionRef
          .doc(bannerId)
          .set(banner.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding banner: $e');
      }
      return false;
    }
  }

  static Future<bool> updateBanner(BannerModel banner) async {
    try {
      await AppFirestore.bannersCollectionRef
          .doc(banner.id)
          .update(banner.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating banner: $e');
      }
      return false;
    }
  }

  static Future<bool> deleteBanner(String bannerId) async {
    try {
      await AppFirestore.bannersCollectionRef.doc(bannerId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting banner: $e');
      }
      return false;
    }
  }

  static Stream<List<UserModel>> getCatagoryWiseWorkersStream(
    String categoryId,
  ) async* {
    // Find the category name and pass
    final docSnapshot = await AppFirestore.categoriesCollectionRef
        .doc(categoryId)
        .get();
    final data = docSnapshot.data() as Map<String, dynamic>?;
    String categoryName = data?['name'] ?? '';

    Query query = AppFirestore.usersCollectionRef
        .where('isVerified', isEqualTo: true)
        .where('isAdmin', isNotEqualTo: true)
        .where('jobRoles', arrayContains: categoryName);

    yield* query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<bool> isEmailRegistered(String email) async {
    try {
      final snapshot = await AppFirestore.usersCollectionRef
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking email registration: $e');
      }
      return false;
    }
  }

  static Future<bool> checkThePhoneExists(String phone) async {
    final snapshot = await AppFirestore.usersCollectionRef
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<bool> cancelBooking(String bookingId) async {
    try {
      await AppFirestore.bookingsCollectionRef.doc(bookingId).update({
        'bookingStatusCode': 'P',
        'acceptedAt': FieldValue.delete(),
        'cancelledBy': 'worker',
        'agent': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error canceling booking: $e');
      }
      return false;
    }
  }

  static Future<bool> completeBooking(String bookingId) async {
    try {
      await AppFirestore.bookingsCollectionRef.doc(bookingId).update({
        'bookingStatusCode': 'C',
        'isStarted': false,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error completing booking: $e');
      }
      return false;
    }
  }
}
