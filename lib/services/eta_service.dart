import '../utils/distance_utils.dart';

/// Represents the result of an ETA calculation.
class EtaResult {
  final Duration duration;
  final double distanceKm;

  const EtaResult({required this.duration, required this.distanceKm});
}

/// Abstract interface for ETA providers to allow swapping implementations (e.g., Haversine vs Routing API).
abstract class EtaProvider {
  Future<EtaResult?> calculateEta({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  });
}

/// A local ETA provider that uses the Haversine formula and a fixed average speed.
class LocalHaversineEtaProvider implements EtaProvider {
  final double speedKmPerHour;

  LocalHaversineEtaProvider({this.speedKmPerHour = 40});

  @override
  Future<EtaResult?> calculateEta({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final distanceKm = haversineDistanceKm(
      lat1: fromLat,
      lon1: fromLng,
      lat2: toLat,
      lon2: toLng,
    );

    final duration = estimateEta(
      distanceKm: distanceKm,
      speedKmPerHour: speedKmPerHour,
    );

    return EtaResult(duration: duration, distanceKm: distanceKm);
  }
}

/* 
FUTURE IMPLEMENTATION HINT:
class RoutingApiEtaProvider implements EtaProvider {
  @override
  Future<EtaResult?> calculateEta({ ... }) async {
    // 1. Call external routing API (Google/TomTom)
    // 2. Parse travel time and distance
    // 3. Return EtaResult
  }
}
*/
