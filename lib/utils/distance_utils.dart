import 'dart:math';

/// Calculates the distance between two points in kilometers using the Haversine formula.
double haversineDistanceKm({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const double earthRadiusKm = 6371.0;

  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);

  final a =
      pow(sin(dLat / 2), 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLon / 2), 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusKm * c;
}

double _toRadians(double degree) {
  return degree * pi / 180;
}

/// Estimates travel duration based on distance and average speed.
Duration estimateEta({required double distanceKm, double speedKmPerHour = 40}) {
  if (speedKmPerHour <= 0) return Duration.zero;
  final double fractionalHours = distanceKm / speedKmPerHour;
  final int totalMinutes = (fractionalHours * 60).round();
  return Duration(minutes: totalMinutes);
}

/// Formats a Duration into a human-readable ETA string.
String formatEtaDuration(Duration duration) {
  if (duration.inMinutes < 1) return 'Less than a minute';
  if (duration.inMinutes < 60) return 'In ${duration.inMinutes} mins';

  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;

  if (minutes == 0) return 'In $hours hr';
  return 'In $hours hr $minutes min';
}
