import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';

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

class BookingService {
  BookingService._();
  static final BookingService _instance = BookingService._();
  factory BookingService() => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<String> createBooking(BookingModel booking) async {
    try {
      debugPrint('DEBUG: Starting createBooking for tour: ${booking.tourId}');
      final batch = _firestore.batch();

      final bookingRef = _firestore.collection('bookings').doc();
      batch.set(bookingRef, booking.toFirestore());

      final tourRef = _firestore.collection('tours').doc(booking.tourId);
      batch.update(tourRef, {
        'bookedSeats': FieldValue.increment(booking.seats),
        'updatedAt': Timestamp.now(),
      });

      debugPrint('DEBUG: Calling batch.commit()...');
      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('DEBUG: batch.commit() timed out after 15s');
          throw Exception(
            'Booking timed out. This usually happens due to poor network or security rule denials. Please check your internet and try again.',
          );
        },
      );
      debugPrint(
        'DEBUG: batch.commit() successful. Booking document created: ${bookingRef.id}',
      );

      return bookingRef.id;
    } catch (e) {
      debugPrint('DEBUG: createBooking failed with error: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Permission denied: You do not have permission to book this tour. Please ensure you are logged in as a Traveler.',
        );
      }
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  Future<void> cancelBooking(String bookingId, String tourId, int seats) async {
    try {
      final batch = _firestore.batch();

      final bookingRef = _firestore.collection('bookings').doc(bookingId);
      batch.update(bookingRef, {
        'status': BookingStatus.cancelled.name,
        'updatedAt': Timestamp.now(),
      });

      final tourRef = _firestore.collection('tours').doc(tourId);
      batch.update(tourRef, {
        'bookedSeats': FieldValue.increment(-seats),
        'updatedAt': Timestamp.now(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // FIRESTORE INDEX NEEDED:
  // 1) Copy this URL into a browser to create the index:
  //    https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNIcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9ib29raW5ncy9pbmRleGVzL18QARoOCgx0cmF2ZWxlcklkEAEaDQoJY3JlYXRlZEF0EAETjAoIX19uYW1lX18QAQ
  // 2) Wait until the index status is Enabled.
  Stream<List<BookingModel>> streamTravelerBookings(String travelerId) {
    return _firestore
        .collection('bookings')
        .where('travelerId', isEqualTo: travelerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          if (error.toString().contains('failed-precondition') ||
              error.toString().contains('requires an index')) {
            debugPrint('INDEX ERROR - streamTravelerBookings: $error');
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
        })
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList(),
        );
  }

  // FIRESTORE INDEX NEEDED:
  // 1) Copy this URL into a browser to create the index:
  //    https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNIcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9ib29raW5ncy9pbmRleGVzL18QARoMCghhZ2VuY3lJZBABGg0KCWNyZWF0ZWRBdBABE4wKCF9fbmFtZV9fEAE
  // 2) Wait until the index status is Enabled.
  Stream<List<BookingModel>> streamAgencyBookings(String agencyId) {
    return _firestore
        .collection('bookings')
        .where('agencyId', isEqualTo: agencyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          if (error.toString().contains('failed-precondition') ||
              error.toString().contains('requires an index')) {
            debugPrint('INDEX ERROR - streamAgencyBookings: $error');
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
        })
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<List<BookingModel>> getTourBookings(String tourId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('tourId', isEqualTo: tourId)
          .get();
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tour bookings: $e');
    }
  }

  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return BookingModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  Future<bool> hasBookingForTour(String userId, String tourId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('travelerId', isEqualTo: userId)
          .where('tourId', isEqualTo: tourId)
          .where(
            'status',
            whereIn: [
              BookingStatus.confirmed.name,
              BookingStatus.completed.name,
              BookingStatus
                  .pending
                  .name, // Should we show live track for pending? Maybe not.
              // Let's assume only confirmed or completed (or maybe pending if they just booked and payment is verifying)
              // Ideally only confirmed/completed.
            ],
          )
          .limit(1)
          .get();

      // If we want to be strict:
      // return snapshot.docs.any((doc) =>
      //   doc['status'] == BookingStatus.confirmed.name ||
      //   doc['status'] == BookingStatus.completed.name
      // );

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking booking status: $e');
      return false;
    }
  }
}
