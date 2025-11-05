import 'dart:async';
import 'dart:math';
import 'package:aboglumbo_bbk_panel/models/payout_request.dart';
import 'package:aboglumbo_bbk_panel/models/transaction.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';
import 'package:aboglumbo_bbk_panel/helpers/custom_exception.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/models/banner.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/customer.dart';
import 'package:aboglumbo_bbk_panel/models/customer_support.dart';
import 'package:aboglumbo_bbk_panel/models/faq.dart';
import 'package:aboglumbo_bbk_panel/models/highlighted_services.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:aboglumbo_bbk_panel/models/tipping.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class AppServices {
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

  static Future<void> clearFCMToken() async {
    try {
      String userId = LocalStore.getUID() ?? '';
      if (userId.isNotEmpty) {
        await AppFirestore.usersCollectionRef.doc(userId).update({
          'fcmToken': FieldValue.delete(),
        });
        if (kDebugMode) {
          print('✅ FCM token cleared from user document');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing FCM token from user document: $e');
      }
    }
  }

  static Future<void> storeNotificationInFirestore(
    RemoteMessage message,
  ) async {
    try {
      String userId = '';
      bool isCurrentUserAdmin = false;

      // Check if Hive is available (only in foreground)
      try {
        if (Hive.isBoxOpen('myBox')) {
          userId = LocalStore.getUID() ?? '';
          UserModel? currentUser = LocalStore.getCachedUserData();
          isCurrentUserAdmin = currentUser?.isAdmin ?? false;
        } else {
          // Background execution - try to get userId from message data
          userId = message.data['userId']?.toString() ?? '';
          isCurrentUserAdmin =
              message.data['isAdmin'] == 'true' ||
              message.data['targetRole'] == 'admin';

          debugPrint('⚠️ Background notification - Hive not available');
        }
      } catch (e) {
        debugPrint('⚠️ Error accessing LocalStore: $e');
        // Continue with empty userId if Hive is not available
        userId = message.data['userId']?.toString() ?? '';
      }

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

      String targetRole = _determineNotificationTargetRole(
        message,
        isCurrentUserAdmin,
      );

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
        'targetRole': targetRole,
        'userRole': isCurrentUserAdmin ? 'admin' : 'worker',
        'isBackgroundReceived': !Hive.isBoxOpen(
          'myBox',
        ), // Track if received in background
      };

      await AppFirestore.notificationsCollectionRef.add(notificationData);

      debugPrint('✅ Notification stored in Firestore successfully');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error storing notification in Firestore: $e');
      }
    }
  }

  static String _determineNotificationTargetRole(
    RemoteMessage message,
    bool isCurrentUserAdmin,
  ) {
    if (message.data.containsKey('targetRole')) {
      return message.data['targetRole'].toString();
    }

    String title = message.notification?.title ?? message.data['title'] ?? '';
    String body = message.notification?.body ?? message.data['body'] ?? '';
    String content = '$title $body'.toLowerCase();

    if (content.contains('admin') ||
        content.contains('new booking request') ||
        content.contains('طلب حجز جديد') ||
        content.contains('agent assigned') ||
        content.contains('تم تعيين عامل')) {
      return 'admin';
    }

    if (content.contains('assigned') ||
        content.contains('booking') ||
        content.contains('تم تعيينك') ||
        content.contains('حجز جديد') ||
        message.data['category'] == 'booking') {
      return 'worker';
    }

    return isCurrentUserAdmin ? 'admin' : 'worker';
  }

  static Future<bool> checkTheMailExists(String email) async {
    final snapshot = await AppFirestore.usersCollectionRef
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<void> updateUserProfile(
    UserModel user, {
    bool updateProfileUrl = false,
    bool updateDocUrl = false,
  }) async {
    try {
      String userId = user.uid ?? '';

      if (userId.isNotEmpty) {
        // Only include fields that are being updated
        Map<String, dynamic> userData = {
          'name': user.name,
          'phone': user.phone,
          'districtName': user.districtName,
          'jobRoles': user.jobRoles,
          'updatedAt': Timestamp.now(),
        };

        // Only add image URLs if they were actually updated
        if (updateProfileUrl && user.profileUrl != null) {
          userData['profileUrl'] = user.profileUrl;
        }

        if (updateDocUrl && user.docUrl != null) {
          userData['docUrl'] = user.docUrl;
        }

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

  static Future<String> getCurrentUserRole() async {
    try {
      UserModel? cachedUser = LocalStore.getCachedUserData();
      if (cachedUser != null) {
        return cachedUser.isAdmin == true ? 'admin' : 'worker';
      }

      String userId = LocalStore.getUID() ?? '';
      if (userId.isNotEmpty) {
        DocumentSnapshot userDoc = await AppFirestore.usersCollectionRef
            .doc(userId)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          bool isAdmin = userData['isAdmin'] ?? false;
          return isAdmin ? 'admin' : 'worker';
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting current user role: $e');
      }
    }
    return 'worker';
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

      UserModel? currentUser = LocalStore.getCachedUserData();
      bool isCurrentUserAdmin = currentUser?.isAdmin ?? false;
      String currentUserRole = isCurrentUserAdmin ? 'admin' : 'worker';

      Query query = AppFirestore.notificationsCollectionRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (onlyUnread) {
        query = query.where('isRead', isEqualTo: false);
      }

      QuerySnapshot querySnapshot = await query.limit(limit * 2).get();

      List<Map<String, dynamic>> allNotifications = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      List<Map<String, dynamic>> filteredNotifications = [];

      for (var notification in allNotifications) {
        String? targetRole = notification['targetRole']?.toString();
        String? userRole = notification['userRole']?.toString();

        bool shouldInclude =
            targetRole == null ||
            targetRole == currentUserRole ||
            targetRole == 'both' ||
            userRole == currentUserRole;

        if (shouldInclude && filteredNotifications.length < limit) {
          filteredNotifications.add(notification);
        }
      }

      if (kDebugMode) {
        print(
          '📱 Retrieved ${filteredNotifications.length} notifications for $currentUserRole',
        );
      }

      return filteredNotifications;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error retrieving notifications: $e');
      }
      return [];
    }
  }

  static Stream<List<BookingModel>> getBookingsStream({
    String? bookingStatusCode,
  }) {
    String workerId = LocalStore.getUID() ?? '';

    if (bookingStatusCode == 'X') {
      final workerCancel = AppFirestore.bookingsCollectionRef
          .where('cancelledWorkerUids', arrayContains: workerId)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .toList();
          });

      final adminCancel = AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: 'R')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .toList();
          });

      final customerCancel = AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: 'XC')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .toList();
          });

      return Rx.combineLatest3(customerCancel, adminCancel, workerCancel, (
        List<BookingModel> customer,
        List<BookingModel> admin,
        List<BookingModel> worker,
      ) {
        final combined = [...customer, ...admin, ...worker];

        combined.sort((a, b) {
          final aTime = _getComparisonTimestamp(a);
          final bTime = _getComparisonTimestamp(b);
          return bTime.compareTo(aTime);
        });

        return combined;
      });
    } else if (bookingStatusCode == 'CP') {
      return AppFirestore.bookingsCollectionRef
          .where('agent.uid', isEqualTo: workerId)
          .where('bookingStatusCode', isEqualTo: 'C')
          .where('paymentCompleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .toList();
          });
    } else {
      return AppFirestore.bookingsCollectionRef
          .where('agent.uid', isEqualTo: workerId)
          .where('bookingStatusCode', isEqualTo: bookingStatusCode)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .toList();
          });
    }
  }

  static int _getComparisonTimestamp(BookingModel booking) {
    if (booking.bookingStatusCode == 'XC') {
      return (booking.cancelledAt?.millisecondsSinceEpoch ?? 0);
    } else if (booking.bookingStatusCode == 'R') {
      return (booking.updatedAt?.millisecondsSinceEpoch ?? 0);
    } else {
      final workerCancelTime = _getWorkerCancelledAtTimestamp(booking);
      return workerCancelTime;
    }
  }

  static int _getWorkerCancelledAtTimestamp(BookingModel booking) {
    final currentWorkerId = LocalStore.getUID() ?? '';

    for (var worker in booking.cancelledWorkers) {
      if (worker.uid == currentWorkerId) {
        final timestamp = worker.cancelledAt;
        return timestamp.toDate().millisecondsSinceEpoch;
      }
    }
    return 0;
  }

  static Stream<List<BookingModel>> getBookingsStreamByStatus(
    String bookingStatusCode,
  ) {
    if (bookingStatusCode == 'X') {
      final customerCancelled = AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: 'XC')
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .toList();
            return list;
          })
          .startWith([]);

      final adminCancelled = AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: 'R')
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .toList();
            return list;
          })
          .startWith([]);

      return Rx.combineLatest2(customerCancelled, adminCancelled, (
        List<BookingModel> customer,
        List<BookingModel> admin,
      ) {
        final combined = [...customer, ...admin];

        combined.sort((a, b) {
          final aTime = _getComparisonTimestamp(a);
          final bTime = _getComparisonTimestamp(b);
          return bTime.compareTo(aTime); // Swap to descending
        });

        return combined;
      });
    }
    if (bookingStatusCode == 'CP') {
      return AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: 'c')
          .where('paymentCompleted', isEqualTo: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .toList(),
          );
    } else {
      Query query = AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: bookingStatusCode)
          .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => BookingModel.fromDocumentSnapshot(doc))
            .toList();
      });
    }
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

  static Future<List<CategoryModel>> getCategoriesByIds(
    List<String> categoryIds,
  ) async {
    if (categoryIds.isEmpty) return [];

    // Split into chunks of 10 due to Firestore whereIn limit
    List<List<String>> chunks = [];
    for (int i = 0; i < categoryIds.length; i += 10) {
      chunks.add(categoryIds.sublist(i, min(i + 10, categoryIds.length)));
    }

    // Fetch all chunks in parallel
    List<Future<QuerySnapshot>> futures = chunks
        .map(
          (chunk) => FirebaseFirestore.instance
              .collection('categories')
              .where(FieldPath.documentId, whereIn: chunk)
              .get(),
        )
        .toList();

    List<QuerySnapshot> snapshots = await Future.wait(futures);

    List<CategoryModel> categories = [];
    for (var snapshot in snapshots) {
      categories.addAll(
        snapshot.docs
            .map(
              (doc) => CategoryModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList(),
      );
    }

    return categories;
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
      return snapshot.docs
          .map(
            (doc) => TippingModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  static Future<bool> clearTippingAmount(
    String agentId,
    String transactionId,
    XFile? image,
    TippingModel? tipmodel,
  ) async {
    try {
      String? imageUrl;
      if (image != null) {
        imageUrl = await _uploadProofImage(agentId, image);
        if (imageUrl == null) {
          if (kDebugMode) {
            print('❌ Failed to upload proof image');
          }
          return false;
        }
      }
      final model = AllTipsModel(
        agentId: agentId,
        createdAt: DateTime.now(),
        totalTipAmount: tipmodel?.cardtip,
        paymentMethod: "card",
        id: agentId,
        proofs: [
          {'transactionId': transactionId, 'proofImageUrl': imageUrl},
        ],
      );
      await AppFirestore.tippingCollectionRef
          .doc(agentId)
          .collection('tipPayoutCollectionsRef')
          .doc(agentId)
          .set({"": model.toJson()});

      await AppFirestore.tippingCollectionRef.doc(agentId).update({
        'cardtip': 0.0,
        'cashtip': 0.0,
        'payoutRequested': false,
        'updatedAt': Timestamp.now(),
        'payoutAmount': FieldValue.increment(tipmodel?.cardtip ?? 0.0),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing tipping amount: $e');
      }
      return false;
    }
  }

  static Future<String?> _uploadProofImage(String agentId, XFile image) async {
    try {
      // Read image as bytes
      final Uint8List imageData = await image.readAsBytes();

      // Create a unique filename with timestamp
      final String fileName =
          'payment_proof_${agentId}_${DateTime.now().millisecondsSinceEpoch}.${image.name.split('.').last}';

      // Create Firebase Storage reference
      final Reference storageRef = AppFireStorage.payoutProofsStorageRef
          .child('tip_payment_proofs')
          .child(agentId)
          .child(fileName);

      // Set metadata for the file
      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(image.name),
        customMetadata: {
          'uploadedBy': 'admin',
          'agentId': agentId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload the file
      final UploadTask uploadTask = storageRef.putData(imageData, metadata);

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('✅ Image uploaded successfully: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading image: $e');
      }
      return null;
    }
  }

  // Helper method to determine content type based on file extension
  static String _getContentType(String fileName) {
    final String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
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

  static Future<bool> cancelBooking(
    String bookingId, {
    required String agentUid,
    required String agentName,
  }) async {
    try {
      final cancelledAt = DateTime.now();

      await AppFirestore.bookingsCollectionRef.doc(bookingId).update({
        'cancelledWorkers': FieldValue.arrayUnion([
          {'uid': agentUid, 'agentName': agentName, 'cancelledAt': cancelledAt},
        ]),
        'cancelledWorkerUids': FieldValue.arrayUnion([agentUid]),
        'agent': FieldValue.delete(),
        'bookingStatusCode': 'P',
        'acceptedAt': FieldValue.delete(),
        'cancelledBy': 'worker',
        'updatedAt': cancelledAt,
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

  static Future<void> addFaq(FaqModel faqEntry) async {
    try {
      final querySnapshot = await AppFirestore.faqCollectionRef
          .where('stand', isEqualTo: faqEntry.stand)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw DuplicateStandException(
          'FAQ with the same stand already exists.',
        );
      }

      final newFaqId = AppFirestore.faqCollectionRef.doc().id;
      final faqToSave = FaqModel(
        faqEntry.stand,
        id: newFaqId,
        questionEn: faqEntry.questionEn,
        questionAr: faqEntry.questionAr,
        answerEn: faqEntry.answerEn,
        answerAr: faqEntry.answerAr,
      );

      await AppFirestore.faqCollectionRef.doc(newFaqId).set(faqToSave.toMap());
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateFaq(FaqModel faqEntry) async {
    try {
      await AppFirestore.faqCollectionRef
          .doc(faqEntry.id)
          .update(faqEntry.toMap());
    } catch (e) {
      rethrow;
    }
  }

  static Stream<List<FaqModel>> getFaqStream() {
    return AppFirestore.faqCollectionRef
        .orderBy('stand', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => FaqModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  static Future<bool> deleteFaq(String faqId) async {
    try {
      await AppFirestore.faqCollectionRef.doc(faqId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting FAQ: $e');
      }
      return false;
    }
  }

  static Stream<List<CustomerModel>> getAllCustomersStream() {
    return AppFirestore.customersCollectionRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    CustomerModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  static Future<bool> blockUnblockCustomer(
    String customerId,
    bool isBlocked,
  ) async {
    try {
      await AppFirestore.customersCollectionRef.doc(customerId).update({
        'isBlocked': isBlocked,
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

  static Future<String?> getCategoryIdByJobRoleOnce(String jobRole) async {
    QuerySnapshot snapshot = await AppFirestore.categoriesCollectionRef
        .where('name', isEqualTo: jobRole)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot
          .docs
          .first
          .id; // Or use data()['id'] if stored in document
    } else {
      return null;
    }
  }

  static Future addCustomerServiceDetails(CustomerSupportModel contact) async {
    final uid = AppFirestore.customerServiceCollectionRef.doc().id;

    // Create a new contact model with the generated ID
    final contactWithId = contact.copyWith(id: uid);

    // Save the document with the ID included in the data
    await AppFirestore.customerServiceCollectionRef
        .doc(uid)
        .set(contactWithId.toJson());
  }

  static Stream<List<CustomerSupportModel>> getCustomerServiceStreamByType(
    String type,
  ) {
    return AppFirestore.customerServiceCollectionRef
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => CustomerSupportModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  static Future<bool> deleteCustomerService(String id) async {
    try {
      await AppFirestore.customerServiceCollectionRef.doc(id).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting customer service: $e');
      }
      return false;
    }
  }

  static Future<bool> updateCustomerService(
    CustomerSupportModel contact,
  ) async {
    try {
      await AppFirestore.customerServiceCollectionRef
          .doc(contact.id)
          .update(contact.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating customer service: $e');
      }
      return false;
    }
  }

  // In app_services.dart
  static Future<List<CustomerSupportModel>> getCustomerServiceByType(
    String type,
  ) async {
    try {
      final querySnapshot = await AppFirestore.customerServiceCollectionRef
          .where('type', isEqualTo: type)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CustomerSupportModel.fromJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Method to get a single contact by ID
  static Future<CustomerSupportModel?> getCustomerServiceById(String id) async {
    try {
      final docSnapshot = await AppFirestore.customerServiceCollectionRef
          .doc(id)
          .get();

      if (docSnapshot.exists) {
        return CustomerSupportModel.fromJson(
          docSnapshot.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  static Stream<List<CustomerSupportModel>> getCustomerSupportdata() {
    return AppFirestore.customerServiceCollectionRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          List<CustomerSupportModel> customerSupportList = snapshot.docs
              .map(
                (doc) => CustomerSupportModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
          return customerSupportList;
        });
  }

  static Future<TippingModel> getWorkerTippingData(String workerId) async {
    final snapshot = await AppFirestore.tippingCollectionRef
        .where('agentId', isEqualTo: workerId)
        .get();
    return TippingModel.fromJson(
      snapshot.docs.first.data() as Map<String, dynamic>,
    );
  }

  static Future<double> getTotalTipping(String workerId) async {
    final snapshot = await AppFirestore.tippingCollectionRef
        .doc(workerId)
        .collection('total')
        .where('id', isEqualTo: workerId)
        .get();

    // Check if snapshot has documents before accessing .first
    if (snapshot.docs.isEmpty) {
      return 0.0;
    }

    return snapshot.docs.first['amount'] ?? 0.0;
  }

  static Future<List<TransactionModel>> getWorkerTransactions(
    String workerId,
  ) async {
    final snapshot = await AppFirestore.transactionsCollectionRef
        .where('workerId', isEqualTo: workerId)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              TransactionModel.fromJson(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  static Stream<List<PayoutAccountModel>> getPayoutAccount(String userId) {
    return AppFirestore.usersCollectionRef.doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return <PayoutAccountModel>[];

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null || data['payoutAccounts'] == null) {
        return <PayoutAccountModel>[];
      }

      return List<PayoutAccountModel>.from(
        data['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
      );
    });
  }

  // Add a new payout account
  static Future<void> addPayoutAccount({
    required String userId,
    required String accountHolderName,
    required String accountNumber,
    required String bankName,
    required String ifscCode,
    required String accountType,
    required bool isPrimary,
  }) async {
    // Get current user document
    final userDoc = await AppFirestore.usersCollectionRef.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    List<PayoutAccountModel> currentAccounts = [];
    if (userData != null && userData['payoutAccounts'] != null) {
      currentAccounts = List<PayoutAccountModel>.from(
        userData['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
      );
    }

    // If setting as primary, remove primary status from all other accounts
    if (isPrimary) {
      currentAccounts = currentAccounts.map((account) {
        return account.copyWith(isPrimary: false);
      }).toList();
    }

    // Create new account with unique ID
    final newAccount = PayoutAccountModel(
      id: const Uuid().v4(),
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      bankName: bankName,
      ifscCode: ifscCode.toUpperCase(),
      accountType: accountType,
      isPrimary: isPrimary,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    // Add new account to the list
    currentAccounts.add(newAccount);

    // Update the user document
    await AppFirestore.usersCollectionRef.doc(userId).update({
      'payoutAccounts': currentAccounts.map((a) => a.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update an existing payout account
  static Future<void> updatePayoutAccount({
    required String userId,
    required String accountId,
    required String accountHolderName,
    required String accountNumber,
    required String bankName,
    required String ifscCode,
    required String accountType,
    required bool isPrimary,
  }) async {
    // Get current user document
    final userDoc = await AppFirestore.usersCollectionRef.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null || userData['payoutAccounts'] == null) {
      throw Exception('No payout accounts found');
    }

    List<PayoutAccountModel> currentAccounts = List<PayoutAccountModel>.from(
      userData['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
    );

    // Find the account to update
    final accountIndex = currentAccounts.indexWhere((a) => a.id == accountId);
    if (accountIndex == -1) {
      throw Exception('Account not found');
    }

    // If setting as primary, remove primary status from all other accounts
    if (isPrimary) {
      currentAccounts = currentAccounts.map((account) {
        return account.copyWith(isPrimary: false);
      }).toList();
    }

    // Update the account
    currentAccounts[accountIndex] = currentAccounts[accountIndex].copyWith(
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      bankName: bankName,
      ifscCode: ifscCode.toUpperCase(),
      accountType: accountType,
      isPrimary: isPrimary,
      updatedAt: Timestamp.now(),
    );

    // Update the user document
    await AppFirestore.usersCollectionRef.doc(userId).update({
      'payoutAccounts': currentAccounts.map((a) => a.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Set a payout account as primary
  static Future<void> setPrimaryPayoutAccount({
    required String userId,
    required String accountId,
  }) async {
    // Get current user document
    final userDoc = await AppFirestore.usersCollectionRef.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null || userData['payoutAccounts'] == null) {
      throw Exception('No payout accounts found');
    }

    List<PayoutAccountModel> currentAccounts = List<PayoutAccountModel>.from(
      userData['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
    );

    // Update all accounts - set all to non-primary, then set the target as primary
    currentAccounts = currentAccounts.map((account) {
      if (account.id == accountId) {
        return account.copyWith(isPrimary: true, updatedAt: Timestamp.now());
      } else {
        return account.copyWith(isPrimary: false);
      }
    }).toList();

    // Update the user document
    await AppFirestore.usersCollectionRef.doc(userId).update({
      'payoutAccounts': currentAccounts.map((a) => a.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a payout account
  static Future<void> deletePayoutAccount({
    required String userId,
    required String accountId,
  }) async {
    // Get current user document
    final userDoc = await AppFirestore.usersCollectionRef.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null || userData['payoutAccounts'] == null) {
      throw Exception('No payout accounts found');
    }

    List<PayoutAccountModel> currentAccounts = List<PayoutAccountModel>.from(
      userData['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
    );

    // Remove the account
    currentAccounts.removeWhere((account) => account.id == accountId);

    // Update the user document
    await AppFirestore.usersCollectionRef.doc(userId).update({
      'payoutAccounts': currentAccounts.map((a) => a.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get primary payout account
  static Future<PayoutAccountModel?> getPrimaryPayoutAccount(
    String userId,
  ) async {
    final userDoc = await AppFirestore.usersCollectionRef.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null || userData['payoutAccounts'] == null) {
      return null;
    }

    List<PayoutAccountModel> accounts = List<PayoutAccountModel>.from(
      userData['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
    );

    try {
      return accounts.firstWhere((account) => account.isPrimary);
    } catch (e) {
      return null;
    }
  }

  // Get all payout accounts (not as stream)
  static Future<List<PayoutAccountModel>> getPayoutAccountsList(
    String userId,
  ) async {
    final userDoc = await AppFirestore.usersCollectionRef.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null || userData['payoutAccounts'] == null) {
      return <PayoutAccountModel>[];
    }

    return List<PayoutAccountModel>.from(
      userData['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
    );
  }

  static Future<void> requestPayout(String amount, String? userId) async {
    final newId = AppFirestore.payoutCollectionRef.doc().id;

    userId ??= LocalStore.getUID() ?? '';

    final primaryBankAcount = await getPrimaryPayoutAccount(userId);

    await AppFirestore.payoutCollectionRef.doc(newId).set({
      'id': newId,
      'amount': amount,
      'userId': userId,
      'status': 'P',
      'payoutAccount': primaryBankAcount
          ?.toJson(), // Convert to JSON before saving
      'createdAt': Timestamp.now(),
    });
  }

  static Stream<List<PayoutRequestModel>> getPayoutRequestsById(String userId) {
    return AppFirestore.payoutCollectionRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => PayoutRequestModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  static Future<void> deletePayoutRequest(String payoutRequestId) async {
    await AppFirestore.payoutCollectionRef.doc(payoutRequestId).delete();
  }

  static Stream<List<PayoutRequestModel>> getAllPayoutRequests() {
    return AppFirestore.payoutCollectionRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                PayoutRequestModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  static Future<double> getWorkerAvailableBalance(String workerId) async {
    final balance = await AppFirestore.usersCollectionRef
        .doc(workerId)
        .get()
        .then(
          (snapshot) =>
              (snapshot.data() as Map<String, dynamic>?)?['availableBalance'] ??
              0.0,
        );
    return balance;
  }

  static Future<double> getWorkerPaidAmounts(String workerId) async {
    final paidAmounts = await AppFirestore.usersCollectionRef
        .doc(workerId)
        .get()
        .then(
          (snapshot) =>
              (snapshot.data() as Map<String, dynamic>?)?['paidAmounts'] ?? 0.0,
        );
    return paidAmounts;
  }

  static Future<UserModel> getWorkerById(String workerId) async {
    final snapshot = await AppFirestore.usersCollectionRef.doc(workerId).get();
    return UserModel.fromJson(snapshot.data() as Map<String, dynamic>);
  }

  static Stream<List<TippingModel>> getTipsPayoutStream() {
    return AppFirestore.tippingCollectionRef.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => TippingModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  static Future<List<AllTipsModel>> getTipsById(String workerId) async {
    try {
      // Get the specific document
      final docSnapshot = await AppFirestore.tippingCollectionRef
          .doc(workerId)
          .collection("totalTipsCollectionRef")
          .doc(workerId)
          .get();

      if (!docSnapshot.exists) {
        debugPrint('No tips document found for worker: $workerId');
        return [];
      }

      final data = docSnapshot.data();
      if (data == null) {
        debugPrint('No data found for worker: $workerId');
        return [];
      }
      if (data['tipData'] == null) {
        debugPrint('No tipdata field found');
        return [];
      }

      // Get the tipdata array field and convert to List<AllTipsModel>
      final List<dynamic> tipdataList = data['tipData'] as List<dynamic>;

      final List<AllTipsModel> tipsList = tipdataList
          .map(
            (tipJson) => AllTipsModel.fromJson(tipJson as Map<String, dynamic>),
          )
          .toList();

      debugPrint('Fetched ${tipsList.length} tips for worker: $workerId');
      return tipsList;
    } catch (e) {
      debugPrint('Error fetching tips: $e');
      return [];
    }
  }

  /// Fetches job categories from Firebase and returns them as a Map
  static Future<Map<String, Map<String, String>>> fetchJobCategories() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .get();

      final Map<String, Map<String, String>> categories = {};

      for (var doc in snapshot.docs) {
        final category = CategoryModel.fromQuerySnapshot(doc);

        // Use the category ID as the key, and create the localization map
        categories[category.id ?? doc.id] = {
          'en': category.name ?? '',
          'ar': category.name_ar ?? category.name ?? '',
        };
      }

      return categories;
    } catch (e) {
      debugPrint('Error fetching job categories: $e');
      return {};
    }
  }

  // ---------------------------------------------------------------------------------------------------------

  /// Stream for stats only (backward compatible)

  /// Build stats stream combining completed, latest, accepted, and rating
  static Stream<Map<String, dynamic>> _getStatsStream(String uid) {
    final completed = AppFirestore.bookingsCollectionRef
        .where('agent.uid', isEqualTo: uid)
        .where('bookingStatusCode', isEqualTo: 'C')
        .where('paymentCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

    final latest = AppFirestore.bookingsCollectionRef
        .where('agent.uid', isEqualTo: uid)
        .where('bookingStatusCode', isEqualTo: 'P')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

    final accepted = AppFirestore.bookingsCollectionRef
        .where('agent.uid', isEqualTo: uid)
        .where('bookingStatusCode', isEqualTo: 'A')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

    final paymentPending = AppFirestore.bookingsCollectionRef
        .where('agent.uid', isEqualTo: uid)
        .where('bookingStatusCode', isEqualTo: 'C')
        .where('paymentCompleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

    final Stream<double> rating = AppFirestore.bookingsCollectionRef
        .where('bookingStatusCode', isEqualTo: 'C')
        .where('agent.uid', isEqualTo: uid)
        .where('review', isNull: false)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .where((doc) => doc['review'] != null)
              .map((doc) => doc['review'])
              .toList();

          if (reviews.isEmpty) return 0.0;

          final ratings = reviews
              .map((review) => review['rating'])
              .where((rating) => rating != null)
              .map((rating) => (rating as num).toDouble())
              .toList();

          if (ratings.isEmpty) return 0.0;

          final sum = ratings.reduce((a, b) => a + b);
          return sum / ratings.length;
        });

    return Rx.combineLatest5<
      int,
      int,
      int,
      int,
      double,
      Map<String, dynamic>
    >(completed, latest, accepted, paymentPending, rating, (
      int completedCount,
      int latestCount,
      int acceptedCount,
      int paymentPendingCount,
      double avgRating,
    ) {
      debugPrint(
        '✅ Stats Combined - Completed: $completedCount, Latest: $latestCount, '
        'Accepted: $acceptedCount, Rating: ${avgRating.toStringAsFixed(1)}',
      );
      return {
        'completed': completedCount,
        'latest': latestCount,
        'accepted': acceptedCount,
        'paymentPending': paymentPendingCount,
        'rating': avgRating.toStringAsFixed(1),
      };
    });
  }

  /// Real-time stream for transactions
  static Stream<List<TransactionModel>> _getTransactionsRealTimeStream(
    String uid,
  ) {
    return AppFirestore.transactionsCollectionRef
        .where('workerId', isEqualTo: uid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => TransactionModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        )
        .handleError((error) {
          debugPrint('❌ Error fetching transactions stream: $error');
          return <TransactionModel>[];
        });
  }

  /// Real-time stream for tips
  static Stream<List<AllTipsModel>> _getTipsRealTimeStream(String uid) {
    return AppFirestore.tippingCollectionRef
        .doc(uid)
        .collection("totalTipsCollectionRef")
        .doc(uid)
        .snapshots()
        .map((docSnap) {
          if (!docSnap.exists) return <AllTipsModel>[];

          final data = docSnap.data();
          if (data?['tipData'] == null) return <AllTipsModel>[];

          final List<dynamic> tipdataList = data!['tipData'] as List<dynamic>;

          return tipdataList
              .map(
                (tipJson) =>
                    AllTipsModel.fromJson(tipJson as Map<String, dynamic>),
              )
              .toList();
        })
        .handleError((error) {
          debugPrint('❌ Error fetching tips stream: $error');
          return <AllTipsModel>[];
        });
  }

  /// Real-time stream for paid amounts
  static Stream<double> _getPaidAmountsStream(String uid) {
    return AppFirestore.usersCollectionRef
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return 0.0;

          final data = snapshot.data() as Map<String, dynamic>?;
          return (data?['paidAmounts'] as num?)?.toDouble() ?? 0.0;
        })
        .handleError((error) {
          debugPrint('❌ Error fetching paid amounts stream: $error');
          return 0.0;
        });
  }

  // ========== REFRESH CONTROL WITH STREAMS ==========

  /// StreamController to trigger manual refreshes
  final _dashboardRefreshController = StreamController<int>.broadcast();

  /// Get the refresh trigger stream
  Stream<int> get dashboardRefreshTrigger => _dashboardRefreshController.stream;

  /// Trigger manual refresh by adding a timestamp
  void triggerDashboardRefresh() {
    debugPrint('🔄 Manual dashboard refresh triggered');
    _dashboardRefreshController.add(DateTime.now().millisecondsSinceEpoch);
  }

  /// Dispose the refresh controller (call in app cleanup)
  void disposeDashboardRefresh() {
    _dashboardRefreshController.close();
  }

  /// Complete dashboard stream with manual refresh support
  static Stream<DashboardDataStream> getCompleteDashboardStreamWithRefresh(
    String uid,
    Stream<int> refreshTrigger,
  ) {
    debugPrint(
      '🚀 Setting up complete dashboard stream with refresh for: $uid',
    );

    return refreshTrigger
        .startWith(0) // Start immediately
        .switchMap((_) {
          debugPrint('📊 Dashboard data refresh initiated');
          return Rx.combineLatest4(
            _getStatsStream(uid),

            _getTransactionsRealTimeStream(uid),
            _getTipsRealTimeStream(uid),
            _getPaidAmountsStream(uid),
            (
              Map<String, dynamic> stats,

              List<TransactionModel> transactions,
              List<AllTipsModel> tips,
              double paidAmounts,
            ) {
              debugPrint('📊 Dashboard stream updated - combining all data');

              double cashPayments = 0.0;
              double cardPayments = 0.0;

              for (var transaction in transactions) {
                final status = transaction.paymentStatus.toLowerCase();
                if (status == 'completed' || status == 'paid') {
                  final method = transaction.paymentMethod.toLowerCase();
                  if (method == 'cash on hands') {
                    cashPayments += transaction.amount;
                  } else if (method == 'cards') {
                    cardPayments += transaction.amount;
                  }
                }
              }

              final totalEarnings = cashPayments + cardPayments - paidAmounts;

              return DashboardDataStream(
                stats: stats,
                totalEarnings: totalEarnings,
                transactions: transactions,
                tips: tips,
                paidAmounts: paidAmounts,
              );
            },
          );
        })
        .handleError((error) {
          debugPrint('❌ Dashboard stream error: $error');
          return DashboardDataStream(
            stats: {
              'completed': 0,
              'latest': 0,
              'accepted': 0,
              'rating': '0.0',
            },
            totalEarnings: 0.0,
            transactions: [],
            tips: [],
            paidAmounts: 0.0,
          );
        });
  }

  // Get unread notifications count
  static Future<int> getUnreadNotificationsCount() async {
    try {
      String userId = LocalStore.getUID() ?? '';
      if (userId.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No user logged in, cannot retrieve unread count');
        }
        return 0;
      }

      final querySnapshot = await AppFirestore.notificationsCollectionRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting unread notifications count: $e');
      }
      return 0;
    }
  }

  // Stream for real-time unread count
  static Stream<int> getUnreadNotificationsCountStream() {
    try {
      String userId = LocalStore.getUID() ?? '';
      if (userId.isEmpty) {
        return Stream.value(0);
      }

      return AppFirestore.notificationsCollectionRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting unread notifications stream: $e');
      }
      return Stream.value(0);
    }
  }

  // Mark single notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await AppFirestore.notificationsCollectionRef.doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
      if (kDebugMode) {
        print('✅ Notification marked as read: $notificationId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking notification as read: $e');
      }
      return false;
    }
  }

  /// Stream user data
  static Stream<UserModel> getUserStream(String uid) {
    return AppFirestore.usersCollectionRef
        .doc(uid)
        .snapshots()
        .map(
          (snapshot) =>
              UserModel.fromJson(snapshot.data() as Map<String, dynamic>),
        );
  }

  // Mark all notifications as read for current user
  static Future<bool> markAllNotificationsAsRead() async {
    try {
      String userId = LocalStore.getUID() ?? '';
      if (userId.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No user logged in, cannot mark all as read');
        }
        return false;
      }

      final unreadNotifications = await AppFirestore.notificationsCollectionRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
      if (kDebugMode) {
        print(
          '✅ All notifications marked as read: ${unreadNotifications.docs.length}',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking all notifications as read: $e');
      }
      return false;
    }
  }
}

class DashboardDataStream {
  final Map<String, dynamic> stats;
  final double totalEarnings;
  final List<TransactionModel> transactions;
  final List<AllTipsModel> tips;
  final double paidAmounts;

  const DashboardDataStream({
    required this.stats,
    required this.totalEarnings,
    required this.transactions,
    required this.tips,
    required this.paidAmounts,
  });

  // Helper to get specific stats
  int get completedBookings => (stats['completed'] as int?) ?? 0;
  int get latestRequests => (stats['latest'] as int?) ?? 0;
  int get acceptedBookings => (stats['accepted'] as int?) ?? 0;
  double get rating =>
      double.tryParse(stats['rating']?.toString() ?? '0') ?? 0.0;
}
