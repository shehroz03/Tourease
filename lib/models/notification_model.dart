import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  verificationApproved,
  verificationRejected,
  bookingConfirmed,
  bookingCancelled,
  messageReceived,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? data; // Additional data like agencyId, bookingId, etc.

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.read = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.messageReceived,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      read: data['read'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      if (data != null) 'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    bool? read,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}






