import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TechnicianChatService {
  late final DatabaseReference _rtdb;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TechnicianChatService() {
    _rtdb = FirebaseDatabase.instance.ref();
  }

  String get currentUserId => _auth.currentUser!.uid;

  String generateChatId(String bookingId, String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return '${bookingId}_${ids[0]}_${ids[1]}';
  }

  Future<String> initiateChat({
    required String bookingId,
    required String customerId,
    required String customerName,
    required String customerPhoto,
    required String technicianName,
    required String technicianPhoto,
  }) async {
    final chatId = generateChatId(bookingId, currentUserId, customerId);

    try {
      final chatRef = _rtdb.child('chats/$chatId');
      final snapshot = await chatRef.get();

      if (!snapshot.exists) {

        await chatRef.set({
          'bookingId': bookingId,
          'participants': {currentUserId: 'technician', customerId: 'customer'},
          'createdAt': ServerValue.timestamp,
          'lastMessage': '',
          'lastMessageTime': ServerValue.timestamp,
          'lastMessageBy': '',
          'customerUnreadCount': 0,
          'technicianUnreadCount': 0,
        });

        await _rtdb.child('userChats/$currentUserId/$chatId').set({
          'participantId': customerId,
          'participantName': customerName,
          'participantPhoto': customerPhoto,
          'participantType': 'customer',
          'bookingId': bookingId,
          'lastMessage': '',
          'lastMessageTime': ServerValue.timestamp,
          'unreadCount': 0,
        });

        await _rtdb.child('userChats/$customerId/$chatId').set({
          'participantId': currentUserId,
          'participantName': technicianName,
          'participantPhoto': technicianPhoto,
          'participantType': 'technician',
          'bookingId': bookingId,
          'lastMessage': '',
          'lastMessageTime': ServerValue.timestamp,
          'unreadCount': 0,
        });

        await _firestore.collection('bookings').doc(bookingId).update({
          'chatroomId': chatId,
        });

      } else {

        final techUserChatSnapshot = await _rtdb
            .child('userChats/$currentUserId/$chatId')
            .get();
        if (!techUserChatSnapshot.exists) {
          await _rtdb.child('userChats/$currentUserId/$chatId').set({
            'participantId': customerId,
            'participantName': customerName,
            'participantPhoto': customerPhoto,
            'participantType': 'customer',
            'bookingId': bookingId,
            'lastMessage': '',
            'lastMessageTime': ServerValue.timestamp,
            'unreadCount': 0,
          });
        }

        final custUserChatSnapshot = await _rtdb
            .child('userChats/$customerId/$chatId')
            .get();
        if (!custUserChatSnapshot.exists) {
          await _rtdb.child('userChats/$customerId/$chatId').set({
            'participantId': currentUserId,
            'participantName': technicianName,
            'participantPhoto': technicianPhoto,
            'participantType': 'technician',
            'bookingId': bookingId,
            'lastMessage': '',
            'lastMessageTime': ServerValue.timestamp,
            'unreadCount': 0,
          });
        }

        final bookingDoc = await _firestore
            .collection('bookings')
            .doc(bookingId)
            .get();
        if (bookingDoc.exists) {
          final existingChatRoomId = bookingDoc.data()?['chatroomId'];
          if (existingChatRoomId == null || existingChatRoomId != chatId) {
            await _firestore.collection('bookings').doc(bookingId).update({
              'chatroomId': chatId,
            });
          }
        }
      }

      return chatId;
    } catch (e) {
      throw Exception('Failed to initiate chat: $e');
    }
  }

  Future<void> sendMessage(
    String chatId,
    String message,
    String senderType,
    String receiverId,
    String senderName,
    String senderPhoto,
  ) async {
    try {
      final messageRef = _rtdb.child('messages/$chatId').push();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await messageRef.set({
        'senderId': currentUserId,
        'senderType': senderType,
        'text': message,
        'timestamp': timestamp,
        'status': 'sent',
        'mediaUrl': null,
        'mediaType': null,
      });

      await _rtdb.child('chats/$chatId').update({
        'lastMessage': message,
        'lastMessageTime': timestamp,
        'lastMessageBy': currentUserId,
      });

      String unreadField = (senderType == 'technician' || senderType == 'admin')
          ? 'customerUnreadCount'
          : 'technicianUnreadCount';
      await _rtdb
          .child('chats/$chatId/$unreadField')
          .set(ServerValue.increment(1));

      await _rtdb.child('userChats/$currentUserId/$chatId').update({
        'lastMessage': message,
        'lastMessageTime': timestamp,
      });

      // Check if receiver's userChats entry exists
      final receiverChatRef = _rtdb.child('userChats/$receiverId/$chatId');
      final receiverSnapshot = await receiverChatRef.get();

      if (receiverSnapshot.exists) {
        await receiverChatRef.update({
          'lastMessage': message,
          'lastMessageTime': timestamp,
          'unreadCount': ServerValue.increment(1),
        });
      } else {
        // Get bookingId from the chat
        final chatSnapshot = await _rtdb.child('chats/$chatId').get();
        String bookingId = '';
        if (chatSnapshot.exists) {
          final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
          bookingId = chatData['bookingId'] ?? '';
        }

        await receiverChatRef.set({
          'participantId': currentUserId,
          'participantName': senderName,
          'participantPhoto': senderPhoto,
          'participantType': senderType,
          'bookingId': bookingId,
          'lastMessage': message,
          'lastMessageTime': timestamp,
          'unreadCount': 1,
        });
      }

    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<DatabaseEvent> getMessagesStream(String chatId) {
    return _rtdb.child('messages/$chatId').orderByChild('timestamp').onValue;
  }

  Future<void> markAsRead(String chatId) async {
    try {
      await _rtdb.child('chats/$chatId/technicianUnreadCount').set(0);
      await _rtdb.child('userChats/$currentUserId/$chatId/unreadCount').set(0);
    } catch (e) {
      debugPrint('❌ Error marking as read: $e');
    }
  }

  Stream<DatabaseEvent> getChatListStream() {
    return _rtdb
        .child('userChats/$currentUserId')
        .orderByChild('lastMessageTime')
        .onValue;
  }

  Future<bool> chatExists(String chatId) async {
    final snapshot = await _rtdb.child('chats/$chatId').get();
    return snapshot.exists;
  }

  Future<Map<String, dynamic>?> getChatDetails(String chatId) async {
    final snapshot = await _rtdb.child('chats/$chatId').get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  Future<String?> getChatIdByBookingId(String bookingId) async {
    try {
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      if (bookingDoc.exists) {
        return bookingDoc.data()?['chatroomId'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting chat by booking ID: $e');
      return null;
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _rtdb.child('messages/$chatId/$messageId').remove();
  }

  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    String status,
  ) async {
    await _rtdb.child('messages/$chatId/$messageId').update({'status': status});
  }

  Future<int> getUnreadCount() async {
    final snapshot = await _rtdb.child('userChats/$currentUserId').get();
    if (!snapshot.exists) return 0;

    int totalUnread = 0;
    final chatsMap = Map<String, dynamic>.from(snapshot.value as Map);

    chatsMap.forEach((key, value) {
      final chat = Map<String, dynamic>.from(value);
      totalUnread += (chat['unreadCount'] as int? ?? 0);
    });

    return totalUnread;
  }

  Future<List<Map<String, dynamic>>> getAllChats() async {
    final snapshot = await _rtdb.child('userChats/$currentUserId').get();
    if (!snapshot.exists) return [];

    final chatsMap = Map<String, dynamic>.from(snapshot.value as Map);
    List<Map<String, dynamic>> chatsList = [];

    chatsMap.forEach((chatId, chatData) {
      final chat = Map<String, dynamic>.from(chatData);
      chat['chatId'] = chatId;
      chatsList.add(chat);
    });

    chatsList.sort((a, b) {
      final aTime = a['lastMessageTime'] ?? 0;
      final bTime = b['lastMessageTime'] ?? 0;
      return bTime.compareTo(aTime);
    });

    return chatsList;
  }

  Future<void> sendMediaMessage(
    String chatId,
    String mediaUrl,
    String mediaType,
    String receiverId,
    String senderName,
    String senderPhoto, {
    String? caption,
  }) async {
    final messageRef = _rtdb.child('messages/$chatId').push();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await messageRef.set({
      'senderId': currentUserId,
      'senderType': 'technician',
      'text': caption ?? '',
      'timestamp': timestamp,
      'status': 'sent',
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
    });

    final lastMessage = mediaType == 'image'
        ? '📷 Photo'
        : (mediaType == 'video' ? '🎥 Video' : caption ?? '');

    await _rtdb.child('chats/$chatId').update({
      'lastMessage': lastMessage,
      'lastMessageTime': timestamp,
      'lastMessageBy': currentUserId,
    });

    await _rtdb
        .child('chats/$chatId/customerUnreadCount')
        .set(ServerValue.increment(1));

    await _rtdb.child('userChats/$currentUserId/$chatId').update({
      'lastMessage': lastMessage,
      'lastMessageTime': timestamp,
    });

    final receiverChatRef = _rtdb.child('userChats/$receiverId/$chatId');
    final receiverSnapshot = await receiverChatRef.get();

    if (receiverSnapshot.exists) {
      await receiverChatRef.update({
        'lastMessage': lastMessage,
        'lastMessageTime': timestamp,
        'unreadCount': ServerValue.increment(1),
      });
    } else {
      final chatSnapshot = await _rtdb.child('chats/$chatId').get();
      String bookingId = '';
      if (chatSnapshot.exists) {
        final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
        bookingId = chatData['bookingId'] ?? '';
      }

      await receiverChatRef.set({
        'participantId': currentUserId,
        'participantName': senderName,
        'participantPhoto': senderPhoto,
        'participantType': 'technician',
        'bookingId': bookingId,
        'lastMessage': lastMessage,
        'lastMessageTime': timestamp,
        'unreadCount': 1,
      });
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final chatSnapshot = await _rtdb.child('chats/$chatId').get();
      if (chatSnapshot.exists) {
        final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
        final participants = Map<String, dynamic>.from(
          chatData['participants'] ?? {},
        );

        await _rtdb.child('messages/$chatId').remove();
        await _rtdb.child('chats/$chatId').remove();

        for (String userId in participants.keys) {
          await _rtdb.child('userChats/$userId/$chatId').remove();
        }

        if (chatData['bookingId'] != null) {
          await _firestore
              .collection('bookings')
              .doc(chatData['bookingId'])
              .update({'chatroomId': FieldValue.delete()});
        }
      }
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  Future<void> markAllChatsAsRead() async {
    final snapshot = await _rtdb.child('userChats/$currentUserId').get();
    if (!snapshot.exists) return;

    final chatsMap = Map<String, dynamic>.from(snapshot.value as Map);

    for (String chatId in chatsMap.keys) {
      await _rtdb.child('chats/$chatId/technicianUnreadCount').set(0);
      await _rtdb.child('userChats/$currentUserId/$chatId/unreadCount').set(0);
    }
  }

  Future<List<Map<String, dynamic>>> searchMessages(
    String chatId,
    String query,
  ) async {
    final snapshot = await _rtdb.child('messages/$chatId').get();
    if (!snapshot.exists) return [];

    final messagesMap = Map<String, dynamic>.from(snapshot.value as Map);
    List<Map<String, dynamic>> matchingMessages = [];

    messagesMap.forEach((messageId, messageData) {
      final message = Map<String, dynamic>.from(messageData);
      final text = (message['text'] as String? ?? '').toLowerCase();

      if (text.contains(query.toLowerCase())) {
        message['messageId'] = messageId;
        matchingMessages.add(message);
      }
    });

    matchingMessages.sort((a, b) {
      final aTime = a['timestamp'] ?? 0;
      final bTime = b['timestamp'] ?? 0;
      return aTime.compareTo(bTime);
    });

    return matchingMessages;
  }

  Future<Map<String, dynamic>?> getParticipantInfo(String chatId) async {
    final snapshot = await _rtdb
        .child('userChats/$currentUserId/$chatId')
        .get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    await _rtdb.child('chats/$chatId/typing/$currentUserId').set(isTyping);
  }

  Stream<bool> getTypingStatus(String chatId, String otherUserId) {
    return _rtdb.child('chats/$chatId/typing/$otherUserId').onValue.map((
      event,
    ) {
      if (event.snapshot.exists) {
        return event.snapshot.value as bool? ?? false;
      }
      return false;
    });
  }
}
