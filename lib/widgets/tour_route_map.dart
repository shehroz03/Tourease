import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/tour_model.dart';
import '../models/location_model.dart';

class TourRouteMap extends StatelessWidget {
  final TourModel tour;
  final double height;

  const TourRouteMap({
    super.key,
    required this.tour,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    // Check if route data exists
    if (tour.startLocation == null && tour.endLocation == null && tour.stops.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.route, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Route not configured yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Collect all points
    final List<LatLng> routePoints = [];
    final List<Marker> markers = [];

    // Add start location
    if (tour.startLocation != null) {
      final startLatLng = LatLng(tour.startLocation!.lat, tour.startLocation!.lng);
      routePoints.add(startLatLng);
      markers.add(
        Marker(
          point: startLatLng,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    // Add stops (sorted by order)
    final sortedStops = List<TourStop>.from(tour.stops)..sort((a, b) => a.order.compareTo(b.order));
    for (final stop in sortedStops) {
      final stopLatLng = LatLng(stop.lat, stop.lng);
      routePoints.add(stopLatLng);
      markers.add(
        Marker(
          point: stopLatLng,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '${stop.order + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Add end location
    if (tour.endLocation != null) {
      final endLatLng = LatLng(tour.endLocation!.lat, tour.endLocation!.lng);
      routePoints.add(endLatLng);
      markers.add(
        Marker(
          point: endLatLng,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.stop, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    if (routePoints.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No route data available')),
      );
    }

    // Calculate bounds
    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (final point in routePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    // Calculate center and zoom
    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    // Calculate appropriate zoom level based on bounds
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    
    double zoom = 13.0;
    if (maxDiff > 0.1) zoom = 10.0;
    if (maxDiff > 0.5) zoom = 8.0;
    if (maxDiff > 1.0) zoom = 6.0;
    if (maxDiff < 0.01) zoom = 15.0;
    if (maxDiff < 0.001) zoom = 17.0;

    // Create polyline
    final polyline = Polyline(
      points: routePoints,
      strokeWidth: 3.0,
      color: Colors.blue,
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tourease.app',
              maxZoom: 19,
            ),
            PolylineLayer(
              polylines: [polyline],
            ),
            MarkerLayer(
              markers: markers,
            ),
          ],
        ),
      ),
    );
  }
}
