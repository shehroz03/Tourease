import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String bookingId;
  final String tourId;
  final String agencyId;
  final String travelerId;
  final String travelerName; // Optional but good for UI
  final String? travelerPhotoUrl; // Optional but good for UI
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isApproved;
  final bool isReported;
  final String? reportReason;
  final DateTime? reportedAt;
  final String? rejectionReason; // NEW

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.tourId,
    required this.agencyId,
    required this.travelerId,
    required this.travelerName,
    this.travelerPhotoUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.isApproved = false, // Default: pending moderation
    this.isReported = false,
    this.reportReason,
    this.reportedAt,
    this.rejectionReason, // NEW
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      tourId: data['tourId'] ?? '',
      agencyId: data['agencyId'] ?? '',
      travelerId: data['travelerId'] ?? '',
      travelerName: data['travelerName'] ?? 'Traveler',
      travelerPhotoUrl: data['travelerPhotoUrl'],
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isApproved: data['isApproved'] ?? false,
      isReported: data['isReported'] ?? false,
      reportReason: data['reportReason'],
      reportedAt: data['reportedAt'] != null
          ? (data['reportedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: data['rejectionReason'], // NEW
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'tourId': tourId,
      'agencyId': agencyId,
      'travelerId': travelerId,
      'travelerName': travelerName,
      'travelerPhotoUrl': travelerPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isApproved': isApproved,
      'isReported': isReported,
      'reportReason': reportReason,
      'reportedAt': reportedAt != null ? Timestamp.fromDate(reportedAt!) : null,
      'rejectionReason': rejectionReason, // NEW
    };
  }

  ReviewModel copyWith({
    String? id,
    String? bookingId,
    String? tourId,
    String? agencyId,
    String? travelerId,
    String? travelerName,
    String? travelerPhotoUrl,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isApproved,
    bool? isReported,
    String? reportReason,
    DateTime? reportedAt,
    String? rejectionReason, // NEW
  }) {
    return ReviewModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      tourId: tourId ?? this.tourId,
      agencyId: agencyId ?? this.agencyId,
      travelerId: travelerId ?? this.travelerId,
      travelerName: travelerName ?? this.travelerName,
      travelerPhotoUrl: travelerPhotoUrl ?? this.travelerPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isApproved: isApproved ?? this.isApproved,
      isReported: isReported ?? this.isReported,
      reportReason: reportReason ?? this.reportReason,
      reportedAt: reportedAt ?? this.reportedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason, // NEW
    );
  }

  static ReviewModel empty() {
    return ReviewModel(
      id: '',
      bookingId: '',
      tourId: '',
      agencyId: '',
      travelerId: '',
      travelerName: '',
      rating: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
