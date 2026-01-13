import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class LiveLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'live_locations';

  /// Stream current location for a tour
  Stream<LatLng?> streamCurrentLocation(String tourId) {
    return _firestore.collection(_collection).doc(tourId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      final data = snapshot.data()!;
      return LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      );
    });
  }

  /// Update current location (Agency/Guide side)
  Future<void> updateCurrentLocation(
    String tourId,
    double lat,
    double lng,
  ) async {
    await _firestore.collection(_collection).doc(tourId).set({
      'lat': lat,
      'lng': lng,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
