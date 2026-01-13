import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';

class MapLocationPicker extends StatefulWidget {
  final LocationData? initialLocation;
  final String title;

  const MapLocationPicker({
    super.key,
    this.initialLocation,
    this.title = 'Select Location',
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.lat,
        widget.initialLocation!.lng,
      );
      _selectedAddress = widget.initialLocation!.address;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_selectedLocation!, 15.0);
      });
    }
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _selectedLocation = point;
      _isLoadingAddress = true;
    });

    try {
      final address = await LocationService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (!mounted) return;
      setState(() {
        _selectedAddress = address;
        _isLoadingAddress = false;
      });
    } catch (e) {
      setState(() {
        _selectedAddress =
            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final location = await LocationService.getCurrentLocation();
      if (!mounted) return;

      if (location != null) {
        setState(() {
          _selectedLocation = LatLng(location.lat, location.lng);
          _selectedAddress = location.address;
        });
        _mapController.move(_selectedLocation!, 15.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _useCurrentLocation,
            tooltip: 'Use Current Location',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation ?? const LatLng(0, 0),
                initialZoom: _selectedLocation != null ? 15.0 : 2.0,
                minZoom: 3.0,
                maxZoom: 18.0,
                onTap: _onMapTap,
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
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 50,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingAddress)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                else if (_selectedLocation != null) ...[
                  Text(
                    _selectedAddress ?? 'Loading address...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ] else
                  Text(
                    'Tap on the map to select a location',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedLocation != null
                            ? () {
                                if (_selectedLocation != null) {
                                  Navigator.pop(
                                    context,
                                    LocationData(
                                      lat: _selectedLocation!.latitude,
                                      lng: _selectedLocation!.longitude,
                                      address:
                                          _selectedAddress ??
                                          'Selected location',
                                    ),
                                  );
                                }
                              }
                            : null,
                        child: const Text('Select'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
