import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import 'package:uuid/uuid.dart';

/*
 * HOW TO CREATE REQUIRED FIRESTORE INDEXES
 * 
 * 1) For each URL in the comments below, copy and open it in a browser.
 * 2) In Firebase console, you will see the index configuration.
 * 3) Simply click "Create index" / "Save" button.
 * 4) Wait until the index status becomes "Enabled" (may take a few minutes).
 * 5) Once enabled, the query will work without errors.
 * 
 * Note: If you see a "query requires an index" error, check the browser console
 * for the exact URL and update the comment with that URL.
 */

class ChatService {
  ChatService._();
  static final ChatService _instance = ChatService._();
  factory ChatService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // FIRESTORE INDEX NEEDED:
  // 1) Copy this URL into a browser to create the index:
  //    https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNIcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9jaGF0cy9pbmRleGVzL18QARoOCgx0cmF2ZWxlcklkEAEaDAoIYWdlbmN5SWQQARoNCgl0b3VySWQQAROMCghfX25hbWVfXxAB
  // 2) Wait until the index status is Enabled.
  Future<String> getOrCreateChat({
    required String travelerId,
    required String agencyId,
    required String tourId,
  }) async {
    // Use a deterministic id (v5) for the chat document to avoid duplicates
    // and race conditions when two parties attempt to create the same chat.
    final deterministicId = _uuid.v5(
      Namespace.url.value,
      '$travelerId:$agencyId:$tourId',
    );

    // 1) Try to find an existing chat via a direct doc read (fast)
    try {
      final doc = await _firestore
          .collection('chats')
          .doc(deterministicId)
          .get();
      if (doc.exists) return doc.id;
    } catch (_) {
      // ignore and continue to more expensive checks
    }

    // 2) Try composite query (fast when index exists). If it fails due to
    // missing index, we fall back to a tour-based query and client-side filter.
    try {
      final existingChat = await _firestore
          .collection('chats')
          .where('travelerId', isEqualTo: travelerId)
          .where('agencyId', isEqualTo: agencyId)
          .where('tourId', isEqualTo: tourId)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) return existingChat.docs.first.id;
    } catch (e) {
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('requires an index')) {
        // Fallback: query by tourId and filter locally (no composite index required)
        try {
          final tourChats = await _firestore
              .collection('chats')
              .where('tourId', isEqualTo: tourId)
              .get();
          for (final doc in tourChats.docs) {
            final data = doc.data();
            if (data['travelerId'] == travelerId &&
                data['agencyId'] == agencyId) {
              return doc.id;
            }
          }
        } catch (_) {
          // ignore and attempt to create a deterministic chat below
        }
      } else {
        // Some other query error - bubble up
        throw Exception('Failed to query existing chat: $e');
      }
    }

    // 3) Create the chat using a transaction with deterministic id to prevent
    // duplicates and to provide atomicity. Add a timeout so UI doesn't hang.
    final chat = ChatModel(
      id: deterministicId,
      tourId: tourId,
      travelerId: travelerId,
      agencyId: agencyId,
      lastMessage: null,
      updatedAt: DateTime.now(),
    );

    try {
      final result = await _firestore
          .runTransaction((tx) async {
            final docRef = _firestore.collection('chats').doc(deterministicId);
            final snapshot = await tx.get(docRef);
            if (snapshot.exists) return docRef.id;
            tx.set(docRef, chat.toFirestore());
            return docRef.id;
          })
          .timeout(const Duration(seconds: 12));

      return result;
    } catch (e) {
      // Provide helpful diagnostic information for common index errors
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('requires an index')) {
        if (e.toString().contains('https://console.firebase.google.com')) {
          final urlMatch = RegExp(
            r'https://console\.firebase\.google\.com[^\s]+',
          ).firstMatch(e.toString());
          if (urlMatch != null) {
            // Include the index creation url in the thrown exception to help debugging
            throw Exception(
              'Failed to ensure chat exists (missing index). Create index: ${urlMatch.group(0)}',
            );
          }
        }
      }
      throw Exception('Failed to create or ensure chat: $e');
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    try {
      final batch = _firestore.batch();

      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final message = MessageModel(
        id: messageRef.id,
        senderId: senderId,
        text: text,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      batch.set(messageRef, message.toFirestore());

      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': imageUrl != null && (text.isEmpty) ? '[Image]' : text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    debugPrint('ChatService: Streaming messages for chatId: $chatId');
    if (chatId.isEmpty) {
      debugPrint('ChatService: ERROR - Empty chatId passed to streamMessages');
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            'ChatService: Received ${snapshot.docs.length} messages for $chatId',
          );
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        })
        .handleError((error) {
          debugPrint(
            'ChatService: Error in streamMessages for $chatId: $error',
          );
          throw error;
        });
  }

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      await messageRef.update({
        'text': newText,
        'edited': true,
        'editedAt': Timestamp.now(),
      });

      // We intentionally do not update the chat's lastMessage here to avoid
      // accidental overwrite; updating lastMessage requires careful checks
      // (e.g., whether the edited message is actually the most recent), which
      // is better handled by separate logic if desired.
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      await messageRef.update({
        'deleted': true,
        'deletedAt': Timestamp.now(),
        'text': '[Message deleted]',
      });

      // Recompute lastMessage: find latest non-deleted message
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('deleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      final chatRef = _firestore.collection('chats').doc(chatId);
      if (messagesSnapshot.docs.isNotEmpty) {
        final latest = MessageModel.fromFirestore(messagesSnapshot.docs.first);
        await chatRef.update({
          'lastMessage': latest.imageUrl != null && (latest.text.isEmpty)
              ? '[Image]'
              : latest.text,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await chatRef.update({
          'lastMessage': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // FIRESTORE INDEX NEEDED (create BOTH indexes - one for traveler, one for agency):
  // For TRAVELER chats:
  // 1) Copy this URL into a browser to create the index:
  //    https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNIcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9jaGF0cy9pbmRleGVzL18QARoOCgx0cmF2ZWxlcklkEAEaDQoJdXBkYXRlZEF0EAETjAoIX19uYW1lX18QAQ
  // 2) Wait until the index status is Enabled.
  // For AGENCY chats:
  // 1) Copy this URL into a browser to create the index:
  //    https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNIcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9jaGF0cy9pbmRleGVzL18QARoMCghhZ2VuY3lJZBABGg0KCXVwZGF0ZWRBdBABE4wKCF9fbmFtZV9fEAE
  // 2) Wait until the index status is Enabled.
  Stream<List<ChatModel>> streamUserChats(String userId, String role) {
    debugPrint('ChatService: Streaming chats for user: $userId (role: $role)');
    final field = (role == 'traveler' || role == 'admin')
        ? 'travelerId'
        : 'agencyId';

    return _firestore
        .collection('chats')
        .where(field, isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            'ChatService: Received ${snapshot.docs.length} chats for $userId',
          );
          return snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();
        })
        .handleError((error) {
          debugPrint('ChatService: Error in streamUserChats: $error');
          if (error.toString().contains('failed-precondition') ||
              error.toString().contains('requires an index')) {
            if (error.toString().contains(
              'https://console.firebase.google.com',
            )) {
              final urlMatch = RegExp(
                r'https://console\.firebase\.google\.com[^\s]+',
              ).firstMatch(error.toString());
              if (urlMatch != null) {
                debugPrint('CREATE INDEX URL: ${urlMatch.group(0)}');
              }
            }
          }
          throw error;
        });
  }

  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (doc.exists) {
        return ChatModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get chat: $e');
    }
  }
}
