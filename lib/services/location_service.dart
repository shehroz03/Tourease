import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/location_model.dart';

class LocationService {
  /// Get current location using geolocator
  static Future<LocationData?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Use Photon/Nominatim for reverse geocoding
      final address = await reverseGeocode(
        position.latitude,
        position.longitude,
      );

      return LocationData(
        lat: position.latitude,
        lng: position.longitude,
        address: address,
      );
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  /// Geocode an address using Photon API (CORS friendly)
  static Future<LocationData?> geocodeAddress(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      // Photon is a fast, CORS-friendly geocoding API based on OSM
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=$encodedAddress&limit=1',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> features = data['features'] ?? [];

        if (features.isEmpty) return null;

        final feature = features[0];
        final coordinates = feature['geometry']['coordinates']; // [lng, lat]
        final properties = feature['properties'];

        final lng = coordinates[0].toDouble();
        final lat = coordinates[1].toDouble();

        // Construct display name
        final name = properties['name'] ?? '';
        final city = properties['city'] ?? properties['state'] ?? '';
        final country = properties['country'] ?? '';
        final displayName = [
          name,
          city,
          country,
        ].where((e) => e.isNotEmpty).join(', ');

        return LocationData(
          lat: lat,
          lng: lng,
          address: displayName.isEmpty ? address : displayName,
        );
      } else {
        // Fallback to nominatim with proxy if photon fails
        return _geocodeNominatimFallback(address);
      }
    } catch (e) {
      return _geocodeNominatimFallback(address);
    }
  }

  static Future<LocationData?> _geocodeNominatimFallback(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      String urlString =
          'https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1';
      if (kIsWeb) {
        urlString = 'https://corsproxy.io/?${Uri.encodeComponent(urlString)}';
      }
      final response = await http.get(
        Uri.parse(urlString),
        headers: kIsWeb ? {} : {'User-Agent': 'TourEase App'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isEmpty) return null;
        final result = results[0];
        return LocationData(
          lat: double.parse(result['lat']),
          lng: double.parse(result['lon']),
          address: result['display_name'],
        );
      }
    } catch (_) {}
    return null;
  }

  /// Reverse geocode coordinates
  static Future<String> reverseGeocode(double lat, double lng) async {
    try {
      // Try Photon first
      final url = Uri.parse(
        'https://photon.komoot.io/reverse?lon=$lng&lat=$lat',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> features = data['features'] ?? [];
        if (features.isNotEmpty) {
          final props = features[0]['properties'];
          final name = props['name'] ?? '';
          final city = props['city'] ?? props['state'] ?? '';
          final country = props['country'] ?? '';
          final displayName = [
            name,
            city,
            country,
          ].where((e) => e.isNotEmpty).join(', ');
          if (displayName.isNotEmpty) return displayName;
        }
      }
    } catch (_) {}

    // Fallback to Nominatim
    try {
      String urlString =
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json';
      if (kIsWeb) {
        urlString = 'https://corsproxy.io/?${Uri.encodeComponent(urlString)}';
      }
      final response = await http.get(
        Uri.parse(urlString),
        headers: kIsWeb ? {} : {'User-Agent': 'TourEase App'},
      );
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['display_name'] ?? '$lat, $lng';
      }
    } catch (_) {}

    return '$lat, $lng';
  }
}
