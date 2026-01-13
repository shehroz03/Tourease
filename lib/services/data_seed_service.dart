import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';

/// Service to seed dummy data for completed tours and reviews
/// This helps visualize the booking history and review sections
class DataSeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seeds dummy completed bookings and reviews for a traveler
  /// Call this once when a user first logs in or from a debug menu
  Future<void> seedDummyDataForTraveler(String travelerId) async {
    try {
      // Check if dummy data already exists
      final existingBookings = await _firestore
          .collection('bookings')
          .where('travelerId', isEqualTo: travelerId)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      if (existingBookings.docs.isNotEmpty) {
        debugPrint('Dummy data already exists for traveler $travelerId');
        return;
      }

      // Get some existing tours to create bookings for
      final tours = await _firestore.collection('tours').limit(8).get();

      if (tours.docs.isEmpty) {
        debugPrint('No tours available to create dummy bookings');
        return;
      }

      final now = DateTime.now();
      final dummyBookings = <BookingModel>[];
      final dummyReviews = <ReviewModel>[];

      // Create 5 completed bookings with reviews
      for (int i = 0; i < 5 && i < tours.docs.length; i++) {
        final tour = tours.docs[i];
        final tourData = tour.data();
        final agencyId = tourData['agencyId'] ?? '';

        // Create completed booking with varied dates
        final bookingRef = _firestore.collection('bookings').doc();
        final daysAgo = 60 - (i * 12); // Spread over 2 months
        final booking = BookingModel(
          id: bookingRef.id,
          tourId: tour.id,
          travelerId: travelerId,
          agencyId: agencyId,
          status: BookingStatus.completed,
          totalPrice: (100.0 + (i * 75.0)), // Varied prices
          seats: (i % 3) + 1, // 1-3 seats
          createdAt: now.subtract(Duration(days: daysAgo + 5)),
          updatedAt: now.subtract(Duration(days: daysAgo - 3)),
          paymentStatus: PaymentStatus.paid,
          paymentMethod: i % 2 == 0 ? 'Credit Card' : 'PayPal',
          paymentReference:
              'PAY-DUMMY-${DateTime.now().millisecondsSinceEpoch}-$i',
          paidAt: now.subtract(Duration(days: daysAgo + 4)),
          amountPaid: (100.0 + (i * 75.0)),
        );

        dummyBookings.add(booking);

        // Create review for this booking with varied ratings
        final reviewRef = _firestore.collection('reviews').doc();
        final ratings = [5, 4, 5, 4, 5]; // Mostly positive
        final review = ReviewModel(
          id: reviewRef.id,
          bookingId: booking.id,
          tourId: tour.id,
          agencyId: agencyId,
          travelerId: travelerId,
          travelerName: 'Demo User',
          rating: ratings[i],
          comment: _getDummyReviewComment(i),
          createdAt: now.subtract(Duration(days: daysAgo - 5)),
          updatedAt: now.subtract(Duration(days: daysAgo - 5)),
          isApproved: true,
        );

        dummyReviews.add(review);
      }

      // Write to Firestore
      final batch = _firestore.batch();

      for (final booking in dummyBookings) {
        final ref = _firestore.collection('bookings').doc(booking.id);
        batch.set(ref, booking.toFirestore());
      }

      for (final review in dummyReviews) {
        final ref = _firestore.collection('reviews').doc(review.id);
        batch.set(ref, review.toFirestore());
      }

      await batch.commit();

      debugPrint(
        'Successfully seeded ${dummyBookings.length} completed bookings and ${dummyReviews.length} reviews',
      );
    } catch (e) {
      debugPrint('Error seeding dummy data: $e');
    }
  }

  /// Seeds dummy reviews for existing tours
  /// This helps populate the tour detail pages with sample reviews
  Future<void> seedDummyReviewsForTours() async {
    try {
      // Get all tours
      final tours = await _firestore.collection('tours').limit(10).get();

      if (tours.docs.isEmpty) {
        debugPrint('No tours available to create dummy reviews');
        return;
      }

      final now = DateTime.now();
      final batch = _firestore.batch();
      int reviewCount = 0;

      for (final tour in tours.docs) {
        final tourData = tour.data();
        final agencyId = tourData['agencyId'] ?? '';

        // Check if tour already has reviews
        final existingReviews = await _firestore
            .collection('reviews')
            .where('tourId', isEqualTo: tour.id)
            .limit(1)
            .get();

        if (existingReviews.docs.isNotEmpty) {
          continue; // Skip if already has reviews
        }

        // Create 2-4 dummy reviews per tour
        final numReviews = 2 + (reviewCount % 3);
        for (int i = 0; i < numReviews; i++) {
          final reviewRef = _firestore.collection('reviews').doc();
          final review = ReviewModel(
            id: reviewRef.id,
            bookingId: 'dummy-booking-${tour.id}-$i',
            tourId: tour.id,
            agencyId: agencyId,
            travelerId: 'dummy-traveler-$i',
            travelerName: _getDummyTravelerName(i),
            rating: 3 + (i % 3), // Mix of 3, 4, and 5 stars
            comment: _getDummyReviewComment(i),
            createdAt: now.subtract(Duration(days: 5 + i * 7)),
            updatedAt: now.subtract(Duration(days: 5 + i * 7)),
            isApproved: true,
          );

          batch.set(reviewRef, review.toFirestore());
          reviewCount++;
        }
      }

      if (reviewCount > 0) {
        await batch.commit();
        debugPrint('Successfully seeded $reviewCount dummy reviews for tours');
      }
    } catch (e) {
      debugPrint('Error seeding dummy reviews: $e');
    }
  }

  /// Seeds global activity for all users to show a populated platform
  Future<void> seedGlobalActivity() async {
    try {
      final tours = await _firestore.collection('tours').limit(10).get();
      if (tours.docs.isEmpty) return;

      final now = DateTime.now();
      final batch = _firestore.batch();

      final travelerNames = [
        'Ahmed Khan',
        'Sara Malik',
        'Zainab Bibi',
        'Ali Raza',
        'Fatima Sahiba',
        'Usman Jadoon',
        'Hina Pervez',
        'Bilal Shah',
        'Zeeshan Ahmed',
        'Madiha Noor',
        'Hamza Ali',
        'Esha Rehan',
      ];

      for (int i = 0; i < travelerNames.length; i++) {
        final tour = tours.docs[i % tours.docs.length];
        final tourData = tour.data();
        final agencyId = tourData['agencyId'] ?? '';
        final travelerId = 'dummy-traveler-$i';

        // Create completed booking
        final bookingRef = _firestore.collection('bookings').doc();
        final daysAgo = 5 + (i * 3);

        final booking = BookingModel(
          id: bookingRef.id,
          tourId: tour.id,
          travelerId: travelerId,
          agencyId: agencyId,
          status: BookingStatus.completed,
          totalPrice: (tourData['price'] ?? 150.0).toDouble(),
          seats: (i % 2) + 1,
          createdAt: now.subtract(Duration(days: daysAgo + 10)),
          updatedAt: now.subtract(Duration(days: daysAgo)),
          paymentStatus: PaymentStatus.paid,
          paidAt: now.subtract(Duration(days: daysAgo + 9)),
        );

        batch.set(bookingRef, booking.toFirestore());

        // Create review - Last 3 are pending (not approved)
        final reviewRef = _firestore.collection('reviews').doc();
        final isApproved = i < travelerNames.length - 3;

        final review = ReviewModel(
          id: reviewRef.id,
          bookingId: booking.id,
          tourId: tour.id,
          agencyId: agencyId,
          travelerId: travelerId,
          travelerName: travelerNames[i],
          rating: (i % 5 == 0) ? 4 : 5, // Mix 4 and 5 stars
          comment: _getDummyReviewComment(i),
          createdAt: now.subtract(Duration(days: daysAgo - 1)),
          updatedAt: now.subtract(Duration(days: daysAgo - 1)),
          isApproved: isApproved,
        );

        batch.set(reviewRef, review.toFirestore());
      }

      await batch.commit();
      debugPrint(
        'Seeded global activity for ${travelerNames.length} travelers',
      );
    } catch (e) {
      debugPrint('Error seeding global activity: $e');
    }
  }

  /// Removes old demo agencies and tours that might have broken links
  Future<void> cleanOldShowcaseData() async {
    try {
      final batch = _firestore.batch();

      // Old IDs that might have broken images
      final oldTourIds = [
        'tour-k2-basecamp',
        'tour-lahore-heritage',
        'tour-astola-diving',
      ];
      for (var id in oldTourIds) {
        batch.delete(_firestore.collection('tours').doc(id));
      }

      // We don't necessarily want to delete agencies as they might have other data,
      // but we will update them in seedShowcaseData anyway.

      await batch.commit();
      debugPrint('Cleaned up old showcase data');
    } catch (e) {
      debugPrint('Error cleaning showcase data: $e');
    }
  }

  /// Seeds multiple high-quality agencies, tours, and traveler history
  Future<void> seedShowcaseData(
    String travelerId, {
    String travelerName = 'Demo Traveler',
  }) async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      // Definitions of Demo Agencies
      final demoAgencies = [
        {
          'id': 'agency-adventure-elite',
          'name': 'Elite Adventure Pakistan',
          'description':
              'Luxury expeditions to the Northern Areas. K2 Basecamp, Hunza, and Skardu experts.',
          'photoUrl':
              'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=400',
          'city': 'Skardu',
        },
        {
          'id': 'agency-heritage-tours',
          'name': 'Heritage & Sufi Trails',
          'description':
              'Discover the rich history of Lahore, Multan, and Mohenjo-daro with expert historians.',
          'photoUrl':
              'https://images.unsplash.com/photo-1529963183134-61a90db47eaf?q=80&w=400',
          'city': 'Lahore',
        },
        {
          'id': 'agency-coastal-escapes',
          'name': 'Coastal Escapes',
          'description':
              'Exclusive beach resorts and scuba diving experiences in Gwadar and Astola Island.',
          'photoUrl':
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=400',
          'city': 'Karachi',
        },
      ];

      for (var agency in demoAgencies) {
        final agencyRef = _firestore
            .collection('users')
            .doc(agency['id'] as String);
        batch.set(agencyRef, {
          'name': agency['name'],
          'email': '${(agency['id'] as String).replaceAll('-', '')}@demo.com',
          'role': 'agency',
          'verified': true,
          'status': 'verified',
          'photoUrl': agency['photoUrl'],
          'description': agency['description'],
          'city': agency['city'],
          'country': 'Pakistan',
          'averageRating': (4.8 + (agency['id'].hashCode.abs() % 3) * 0.1)
              .toDouble(),
          'reviewCount': 100 + (agency['id'].hashCode.abs() % 100),
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      }

      // Definitions of Demo Tours
      final demoTours = [
        {
          'id': 'tour-k2-basecamp-elite',
          'agencyId': 'agency-adventure-elite',
          'agencyName': 'Elite Adventure Pakistan',
          'title': 'K2 Base Camp & Concordia',
          'price': 2500.0,
          'category': 'Adventure',
          'location': 'Karakoram Range',
          'image':
              'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=800',
        },
        {
          'id': 'tour-lahore-walled-city',
          'agencyId': 'agency-heritage-tours',
          'agencyName': 'Heritage & Sufi Trails',
          'title': 'Lahore: The Walled City Experience',
          'price': 120.0,
          'category': 'Cultural',
          'location': 'Lahore',
          'image':
              'https://images.unsplash.com/photo-1529963183134-61a90db47eaf?q=80&w=800',
        },
        {
          'id': 'tour-astola-island-diving',
          'agencyId': 'agency-coastal-escapes',
          'agencyName': 'Coastal Escapes',
          'title': 'Astola Island: Emerald Sea Diving',
          'price': 750.0,
          'category': 'Beach',
          'location': 'Gwadar',
          'image':
              'https://images.unsplash.com/photo-1506466010722-395aa2bef877?q=80&w=800',
        },
      ];

      for (var tour in demoTours) {
        final tourRef = _firestore
            .collection('tours')
            .doc(tour['id'] as String);
        batch.set(tourRef, {
          'title': tour['title'],
          'agencyId': tour['agencyId'],
          'agencyName': tour['agencyName'],
          'description':
              'A professionally curated ${tour['category']} experience exploring the beauty of ${tour['location']}. Limited seats available for this exclusive journey.',
          'location': tour['location'],
          'price': tour['price'],
          'coverImage': tour['image'],
          'category': tour['category'],
          'startDate': Timestamp.fromDate(now.add(const Duration(days: 45))),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 55))),
          'averageRating': 4.9,
          'reviewCount': 35,
          'status': 'active', // Important for visibility
          'agencyVerified': true,
          'agencyStatus': 'verified',
          'seats': 20,
          'bookedSeats': 5 + (tour['id'].hashCode.abs() % 10),
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));

        // Create completed history for the current traveler
        final bookingId = 'demo-booking-h-${tour['id']}-$travelerId';
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        batch.set(bookingRef, {
          'tourId': tour['id'],
          'travelerId': travelerId,
          'agencyId': tour['agencyId'],
          'status': 'completed',
          'totalPrice': tour['price'],
          'seats': 1 + (tour['id'].hashCode.abs() % 2),
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 90)),
          ),
          'updatedAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 80)),
          ),
          'paymentStatus': 'paid',
          'paidAt': Timestamp.fromDate(now.subtract(const Duration(days: 89))),
        }, SetOptions(merge: true));

        // Create review tied to that history
        final reviewRef = _firestore
            .collection('reviews')
            .doc('demo-review-h-${tour['id']}-$travelerId');
        batch.set(reviewRef, {
          'bookingId': bookingId,
          'tourId': tour['id'],
          'agencyId': tour['agencyId'],
          'travelerId': travelerId,
          'travelerName': travelerName,
          'rating': 5,
          'comment':
              'One of the most life-changing experiences! The team at ${tour['agencyName']} were professional and the ${tour['title']} was breathtaking. Everything exceeded my expectations.',
          'isApproved': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 79)),
          ),
          'updatedAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 79)),
          ),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('High-quality platform seeding complete');
    } catch (e) {
      debugPrint('Error seeding showcase data: $e');
    }
  }

  String _getDummyReviewComment(int index) {
    final comments = [
      'Absolutely amazing experience! Our tour guide was incredibly knowledgeable and made the whole trip memorable. The itinerary was well-planned and we got to see all the major attractions without feeling rushed. Highly recommend this tour to anyone visiting the area!',
      'Great tour with stunning scenery and excellent organization. The agency was very professional and accommodating to all our needs. We especially loved the local cuisine stops and the photo opportunities at sunset. Would definitely book again!',
      'Wonderful experience from start to finish! The guide was friendly and spoke excellent English. Everything was organized perfectly - from pickup to drop-off. The group size was just right, not too crowded. Perfect for families!',
      'Fantastic tour that exceeded all expectations! The locations were breathtaking and our guide shared so many interesting historical facts. The pace was comfortable and there was plenty of time for photos. Best tour we\'ve taken!',
      'Highly recommend this tour! The value for money is excellent. Our guide went above and beyond to ensure everyone had a great time. The lunch provided was delicious and the transportation was comfortable. Will definitely recommend to friends!',
      'Very enjoyable tour with beautiful destinations. The guide was patient and answered all our questions. Some minor delays but nothing that affected the overall experience. The sunset view was absolutely worth it!',
      'Excellent service throughout! The agency was responsive to all our queries before the tour. The actual tour was well-paced with good mix of activities and rest time. Great photo opportunities and wonderful memories created!',
      'Amazing tour with professional guides! The itinerary was perfect - not too rushed but we still saw everything important. The group was friendly and the guide made sure everyone was comfortable. Would book this agency again without hesitation!',
      'One of the best tours we\'ve experienced! Everything was seamless from booking to completion. The guide\'s passion for the area really showed and made the tour special. Highly professional service!',
      'Wonderful day out! The tour was well-organized and the guide was very knowledgeable. We learned so much about the local culture and history. The lunch stop was a nice touch. Definitely worth every penny!',
    ];
    return comments[index % comments.length];
  }

  String _getDummyTravelerName(int index) {
    final names = [
      'Sarah Johnson',
      'Michael Chen',
      'Emma Williams',
      'David Martinez',
      'Lisa Anderson',
      'James Taylor',
      'Maria Garcia',
      'Robert Brown',
      'Zoe Wilson',
      'Jack Robinson',
    ];
    return names[index % names.length];
  }

  /// Comprehensive seeding for all agencies and tours
  /// This ensures EVERY agency profile shows reviews and professional ratings
  Future<void> seedReviewsForAllAgenciesAndTours() async {
    try {
      final now = DateTime.now();

      // 1. Get all tours
      final toursSnapshot = await _firestore.collection('tours').get();
      if (toursSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      Map<String, List<int>> agencyRatings = {}; // agencyId -> list of ratings

      for (final tourDoc in toursSnapshot.docs) {
        final tourId = tourDoc.id;
        final tourData = tourDoc.data();
        final agencyId = tourData['agencyId'] ?? '';
        if (agencyId.isEmpty) continue;

        // Check if tour already has reviews to avoid duplicates
        final existing = await _firestore
            .collection('reviews')
            .where('tourId', isEqualTo: tourId)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) continue;

        // Add 3-5 reviews for this tour
        final int reviewCount = 3 + (tourId.hashCode.abs() % 3);
        final List<int> currentTourRatings = [];

        for (int i = 0; i < reviewCount; i++) {
          final reviewRef = _firestore.collection('reviews').doc();
          // Varied ratings: 4 or 5 stars mostly
          final rating = (i == 0 && tourId.length % 2 == 0) ? 4 : 5;
          currentTourRatings.add(rating);

          final review = ReviewModel(
            id: reviewRef.id,
            bookingId: 'demo-b-$tourId-$i',
            tourId: tourId,
            agencyId: agencyId,
            travelerId: 'demo-t-${(tourId + i.toString()).hashCode.abs()}',
            travelerName: _getDummyTravelerName(i + tourId.length),
            rating: rating,
            comment: _getDummyReviewComment(i + tourId.hashCode.abs()),
            createdAt: now.subtract(Duration(days: 2 + i * 5)),
            updatedAt: now.subtract(Duration(days: 2 + i * 5)),
            isApproved: true,
          );

          batch.set(reviewRef, review.toFirestore());

          // Track for agency aggregates
          agencyRatings.putIfAbsent(agencyId, () => []).add(rating);
        }

        // Calculate tour aggregates
        final tourAvg =
            currentTourRatings.reduce((a, b) => a + b) /
            currentTourRatings.length;
        batch.update(_firestore.collection('tours').doc(tourId), {
          'averageRating': tourAvg,
          'reviewCount': currentTourRatings.length,
        });
      }

      // 2. Update all Agency aggregates
      for (final agencyId in agencyRatings.keys) {
        final ratings = agencyRatings[agencyId]!;
        final avg = ratings.reduce((a, b) => a + b) / ratings.length;
        batch.update(_firestore.collection('users').doc(agencyId), {
          'averageRating': avg,
          'reviewCount': ratings.length,
        });
      }

      await batch.commit();
      debugPrint(
        'Successfully seeded reviews for ${toursSnapshot.docs.length} tours and updated ${agencyRatings.keys.length} agencies',
      );
    } catch (e) {
      debugPrint('Error in seedReviewsForAllAgenciesAndTours: $e');
    }
  }

  /// Removes all dummy data (for testing purposes)
  Future<void> removeDummyData(String travelerId) async {
    try {
      // Remove dummy bookings
      final bookings = await _firestore
          .collection('bookings')
          .where('travelerId', isEqualTo: travelerId)
          .where('paymentReference', isGreaterThanOrEqualTo: 'PAY-DUMMY-')
          .where('paymentReference', isLessThan: 'PAY-DUMMY-\uf8ff')
          .get();

      final batch = _firestore.batch();
      for (final doc in bookings.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Removed ${bookings.docs.length} dummy bookings');
    } catch (e) {
      debugPrint('Error removing dummy data: $e');
    }
  }
}
