import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tour_model.dart';

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

class TourService {
  TourService._();
  static final TourService _instance = TourService._();
  factory TourService() => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<String> createTour(TourModel tour) async {
    try {
      final docRef = await _firestore
          .collection('tours')
          .add(tour.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create tour: $e');
    }
  }

  Future<void> updateTour(String tourId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore.collection('tours').doc(tourId).update(data);
    } catch (e) {
      throw Exception('Failed to update tour: $e');
    }
  }

  Future<void> deleteTour(String tourId) async {
    try {
      await _firestore.collection('tours').doc(tourId).delete();
    } catch (e) {
      throw Exception('Failed to delete tour: $e');
    }
  }

  Future<TourModel?> getTourById(String tourId) async {
    try {
      final doc = await _firestore.collection('tours').doc(tourId).get();
      if (doc.exists) {
        return TourModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get tour: $e');
    }
  }

  // FIRESTORE INDEX NEEDED:
  // 1) Copy this URL into a browser to create the index:
  //    https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNIcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy90b3Vycy9pbmRleGVzL18QARoMCghhZ2VuY3lJZBABGg0KCWNyZWF0ZWRBdBABE4wKCF9fbmFtZV9fEAE
  // 2) Wait until the index status is Enabled.
  Future<List<TourModel>> getAgencyTours(String agencyId) async {
    try {
      final snapshot = await _firestore
          .collection('tours')
          .where('agencyId', isEqualTo: agencyId)
          .get();
      final tours = snapshot.docs
          .map((doc) => TourModel.fromFirestore(doc))
          .toList();
      // Sort client-side to avoid index requirement
      tours.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tours;
    } catch (e) {
      throw Exception('Failed to get agency tours: $e');
    }
  }

  Stream<List<TourModel>> streamAgencyTours(String agencyId) {
    return _firestore
        .collection('tours')
        .where('agencyId', isEqualTo: agencyId)
        .snapshots()
        .map((snapshot) {
          final tours = snapshot.docs
              .map((doc) => TourModel.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid index requirement
          tours.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tours;
        });
  }

  // FIRESTORE INDEX NEEDED:
  // 1) Copy this URL into a browser to create the index:
  //    https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy90b3Vycy9pbmRleGVzL18QARoKCgZzdGF0dXMQARoNCglzdGFydERhdGUQARoMCghfX25hbWVfXxAB
  // 2) Wait until the index status is Enabled.
  Stream<List<TourModel>> streamActiveTours({
    String? userId,
    bool showAll = false,
  }) {
    // We fetch all tours and filter client-side to be more resilient
    return streamAllTours().map((tours) {
      final filtered = tours.where((t) {
        // 1. Admin shows all
        if (showAll) return true;

        // 2. Agency shows their own tours regardless of status
        if (userId != null && t.agencyId == userId) return true;

        // 3. Regular view: only active and verified tours
        final isActive = t.status == TourStatus.active;
        final isVerified = t.agencyVerified;
        return isActive && isVerified;
      }).toList();

      // Sort by startDate client-side
      filtered.sort((a, b) => a.startDate.compareTo(b.startDate));
      return filtered;
    });
  }

  Future<List<TourModel>> searchTours({
    String? location,
    String? category,
    double? minPrice,
    double? maxPrice,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('tours')
          .where('status', isEqualTo: 'active');

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      var tours = snapshot.docs
          .map((doc) => TourModel.fromFirestore(doc))
          .toList();

      if (minPrice != null) {
        tours = tours.where((t) => t.price >= minPrice).toList();
      }
      if (maxPrice != null) {
        tours = tours.where((t) => t.price <= maxPrice).toList();
      }
      if (startDate != null) {
        tours = tours
            .where(
              (t) =>
                  t.startDate.isAfter(startDate) ||
                  t.startDate.isAtSameMomentAs(startDate),
            )
            .toList();
      }
      if (endDate != null) {
        tours = tours
            .where(
              (t) =>
                  t.endDate.isBefore(endDate) ||
                  t.endDate.isAtSameMomentAs(endDate),
            )
            .toList();
      }

      return tours;
    } catch (e) {
      throw Exception('Failed to search tours: $e');
    }
  }

  Future<List<TourModel>> getAllTours() async {
    try {
      final snapshot = await _firestore.collection('tours').get();
      return snapshot.docs.map((doc) => TourModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get all tours: $e');
    }
  }

  Stream<List<TourModel>> streamAllTours() {
    return _firestore
        .collection('tours')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TourModel.fromFirestore(doc)).toList(),
        );
  }

  Future<void> completeTour(String tourId) async {
    try {
      final batch = _firestore.batch();

      final tourRef = _firestore.collection('tours').doc(tourId);
      batch.update(tourRef, {
        'status': TourStatus.completed.name,
        'updatedAt': Timestamp.now(),
      });

      // Update all confirmed bookings to completed
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('tourId', isEqualTo: tourId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (var doc in bookingsSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'completed',
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to complete tour: $e');
    }
  }
}
