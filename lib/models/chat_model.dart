import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String tourId;
  final String travelerId;
  final String agencyId;
  final String? lastMessage;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.tourId,
    required this.travelerId,
    required this.agencyId,
    this.lastMessage,
    required this.updatedAt,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      tourId: data['tourId'] ?? '',
      travelerId: data['travelerId'] ?? '',
      agencyId: data['agencyId'] ?? '',
      lastMessage: data['lastMessage'],
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tourId': tourId,
      'travelerId': travelerId,
      'agencyId': agencyId,
      'lastMessage': lastMessage,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final bool edited;
  final DateTime? editedAt;
  final bool deleted;
  final DateTime? deletedAt;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.edited = false,
    this.editedAt,
    this.deleted = false,
    this.deletedAt,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'] as String?,
      edited: data['edited'] == true,
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      deleted: data['deleted'] == true,
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'edited': edited,
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
      'deleted': deleted,
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
