import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../models/booking_model.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService _instance = ReviewService._();
  factory ReviewService() => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _reviewsCollection =>
      _firestore.collection('reviews');

  /// Get a review by ID
  Future<ReviewModel?> getReviewById(String reviewId) async {
    final doc = await _reviewsCollection.doc(reviewId).get();
    if (!doc.exists) return null;
    return ReviewModel.fromFirestore(doc);
  }

  /// Get a review for a specific booking and traveler
  Future<ReviewModel?> getReviewForBooking(
    String bookingId,
    String travelerId,
  ) async {
    final snapshot = await _reviewsCollection
        .where('bookingId', isEqualTo: bookingId)
        .where('travelerId', isEqualTo: travelerId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ReviewModel.fromFirestore(snapshot.docs.first);
  }

  /// Submit a review (Create or Update)
  Future<void> submitReview({
    required BookingModel booking,
    required String travelerName,
    String? travelerPhotoUrl,
    required int rating,
    String? comment,
  }) async {
    final existingReview = await getReviewForBooking(
      booking.id,
      booking.travelerId,
    );

    if (existingReview != null) {
      // Update existing
      await _reviewsCollection.doc(existingReview.id).update({
        'rating': rating,
        'comment': comment,
        'updatedAt': Timestamp.now(),
      });
    } else {
      // Create new
      await _reviewsCollection.add({
        'bookingId': booking.id,
        'tourId': booking.tourId,
        'agencyId': booking.agencyId,
        'travelerId': booking.travelerId,
        'travelerName': travelerName,
        'travelerPhotoUrl': travelerPhotoUrl,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isApproved': false, // Default to pending
        'rejectionReason': null, // Ensure explicit null
      });
    }

    // Note: Do NOT update tour/agency averageRating yet
    // Only update after admin approves the review
  }

  /// Aggregation logic
  Future<void> _updateAggregates(String tourId, String agencyId) async {
    // 1. Update Tour Aggregates
    final tourReviewsSnapshot = await _reviewsCollection
        .where('tourId', isEqualTo: tourId)
        .where('isApproved', isEqualTo: true)
        .get();

    if (tourReviewsSnapshot.docs.isNotEmpty) {
      final reviews = tourReviewsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      final int count = reviews.length;
      final double totalRating = reviews.fold(
        0.0,
        (acc, r) => acc + (r['rating'] as num).toDouble(),
      );
      final double average = totalRating / count;

      await _firestore.collection('tours').doc(tourId).update({
        'averageRating': average,
        'reviewCount': count,
      });
    }

    // 2. Update Agency Aggregates
    final agencyReviewsSnapshot = await _reviewsCollection
        .where('agencyId', isEqualTo: agencyId)
        .where('isApproved', isEqualTo: true)
        .get();

    if (agencyReviewsSnapshot.docs.isNotEmpty) {
      final reviews = agencyReviewsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      final int count = reviews.length;
      final double totalRating = reviews.fold(
        0.0,
        (acc, r) => acc + (r['rating'] as num).toDouble(),
      );
      final double average = totalRating / count;

      await _firestore.collection('users').doc(agencyId).update({
        'averageRating': average,
        'reviewCount': count,
      });
    }
  }

  /// Stream reviews for a tour
  Stream<List<ReviewModel>> streamReviewsForTour(String tourId) {
    return _reviewsCollection
        .where('tourId', isEqualTo: tourId)
        .where('isApproved', isEqualTo: true)
        .snapshots() // removed orderBy
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }

  /// Stream all reviews for a specific agency (Public View - Approved only)
  Stream<List<ReviewModel>> streamApprovedReviewsForAgency(String agencyId) {
    return _reviewsCollection
        .where('agencyId', isEqualTo: agencyId)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }

  /// Stream all reviews for a specific agency (Internal/Agency View - All statuses)
  Stream<List<ReviewModel>> streamReviewsForAgency(String agencyId) {
    return _reviewsCollection
        .where('agencyId', isEqualTo: agencyId)
        .snapshots() // removed isApproved filter to show all reviews to agency
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }

  /// Stream reviews written by a specific traveler
  Stream<List<ReviewModel>> streamReviewsForTraveler(String travelerId) {
    return _reviewsCollection
        .where('travelerId', isEqualTo: travelerId)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }

  /// Report a review
  Future<void> reportReview(String reviewId, String reason) async {
    await _reviewsCollection.doc(reviewId).update({
      'isReported': true,
      'reportReason': reason,
      'reportedAt': Timestamp.now(),
    });
  }

  /// Dismiss a report (Keep review)
  Future<void> dismissReport(String reviewId) async {
    await _reviewsCollection.doc(reviewId).update({
      'isReported': false,
      'reportReason': FieldValue.delete(),
      'reportedAt': FieldValue.delete(),
    });
  }

  /// Delete a review (Admin action)
  Future<void> deleteReview(String reviewId) async {
    final doc = await _reviewsCollection.doc(reviewId).get();
    if (!doc.exists) return;

    final review = ReviewModel.fromFirestore(doc);
    await _reviewsCollection.doc(reviewId).delete();

    // Re-calculate aggregates
    await _updateAggregates(review.tourId, review.agencyId);
  }

  /// Stream reported reviews
  Stream<List<ReviewModel>> streamReportedReviews() {
    return _reviewsCollection
        .where('isReported', isEqualTo: true)
        .snapshots() // removed orderBy
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          reviews.sort(
            (a, b) => (b.reportedAt ?? b.createdAt).compareTo(
              a.reportedAt ?? a.createdAt,
            ),
          );
          return reviews;
        });
  }

  /// Stream all reviews for admin moderation (pending + approved + rejected)
  Stream<List<ReviewModel>> streamAllReviewsForAdmin() {
    return _reviewsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream only pending reviews
  Stream<List<ReviewModel>> streamPendingReviews() {
    return _reviewsCollection
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .where((r) => r.rejectionReason == null)
              .toList();

          // Sort client-side to avoid needing a composite index
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return reviews;
        });
  }

  /// Approve a review
  Future<void> approveReview(String reviewId) async {
    await _reviewsCollection.doc(reviewId).update({
      'isApproved': true,
      'rejectionReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // We must fetch the review to know which tour/agency to update aggregates for
    final doc = await _reviewsCollection.doc(reviewId).get();
    if (doc.exists) {
      final review = ReviewModel.fromFirestore(doc);
      await _updateAggregates(review.tourId, review.agencyId);
    }
  }

  /// Reject a review with reason
  Future<void> rejectReview(String reviewId, String reason) async {
    await _reviewsCollection.doc(reviewId).update({
      'isApproved': false,
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // We must fetch the review to know which tour/agency to update aggregates for
    // (In case it was previously approved and now rejected, aggregates change)
    final doc = await _reviewsCollection.doc(reviewId).get();
    if (doc.exists) {
      final review = ReviewModel.fromFirestore(doc);
      await _updateAggregates(review.tourId, review.agencyId);
    }
  }

  /// Stream all approved reviews globally (for Recent Activity)
  Stream<List<ReviewModel>> streamAllReviews({int limit = 10}) {
    return _reviewsCollection
        .where('isApproved', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }
}
