import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/live_location_service.dart';
import '../../services/tour_service.dart';
import '../../models/tour_model.dart';
import '../../theme/themed_background.dart';
import 'package:intl/intl.dart';

class LiveTourConsoleScreen extends StatefulWidget {
  final String tourId;
  final String tourTitle;

  const LiveTourConsoleScreen({
    super.key,
    required this.tourId,
    required this.tourTitle,
  });

  @override
  State<LiveTourConsoleScreen> createState() => _LiveTourConsoleScreenState();
}

class _LiveTourConsoleScreenState extends State<LiveTourConsoleScreen> {
  final _liveLocationService = LiveLocationService();
  final _tourService = TourService();
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  bool _isLoading = true;
  DateTime? _lastUpdateTime;
  String? _errorMessage;
  Position? _currentPosition;
  TourModel? _tour;

  @override
  void initState() {
    super.initState();
    _loadTourDetails();
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  Future<void> _loadTourDetails() async {
    try {
      final tour = await _tourService.getTourById(widget.tourId);
      if (mounted) {
        setState(() {
          _tour = tour;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load tour details';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _errorMessage = 'Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _errorMessage = 'Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(
          () => _errorMessage = 'Location permissions are permanently denied',
        );
        return;
      }

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            (Position position) {
              _updateLocation(position);
            },
            onError: (e) {
              if (mounted) {
                setState(() => _errorMessage = e.toString());
                _stopTracking();
              }
            },
          );

      setState(() {
        _isTracking = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    if (mounted) {
      setState(() {
        _isTracking = false;
      });
    }
  }

  Future<void> _completeTour() async {
    bool isFar = false;
    if (_currentPosition != null && _tour?.endLocation != null) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _tour!.endLocation!.lat,
        _tour!.endLocation!.lng,
      );
      if (distance > 1000) {
        // More than 1km away
        isFar = true;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFar ? 'Still far from destination!' : 'Complete Trip?'),
        content: Text(
          isFar
              ? 'You are still more than 1km away from the destination. Are you sure you want to end the tour now?'
              : 'This will end the live broadcast and mark the tour as completed for all travelers. Travelers will be invited to leave a review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFar ? Colors.orange : Colors.green,
            ),
            child: const Text('COMPLETE'),
          ),
        ],
      ),
    );

    if (confirmed == true && _tour != null) {
      try {
        setState(() => _isLoading = true);
        await _tourService.completeTour(_tour!.id);
        _stopTracking();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to complete trip: $e';
          });
        }
      }
    }
  }

  Future<void> _updateLocation(Position position) async {
    try {
      await _liveLocationService.updateCurrentLocation(
        widget.tourId,
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _lastUpdateTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Update failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tour Console'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: ThemedBackground(
        child: Container(
          padding: const EdgeInsets.only(
            top: 100,
            left: 24,
            right: 24,
            bottom: 24,
          ),
          width: double.infinity,
          child: Column(
            children: [
              // Tour Info Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tour?.title ?? widget.tourTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_tour != null)
                                  Text(
                                    DateFormat(
                                      'EEE, MMM d, yyyy',
                                    ).format(_tour!.startDate),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_tour != null) ...[
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Icon(
                              Icons.trip_origin,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _tour!.startLocation?.address ?? 'Start Point',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _tour!.endLocation?.address ?? 'End Point',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Status Section
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: (_isTracking ? Colors.green : Colors.grey)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (_isTracking ? Colors.green : Colors.grey)
                              .withValues(alpha: 0.2),
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        _isTracking ? Icons.sensors : Icons.sensors_off,
                        size: 80,
                        color: _isTracking ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _isTracking ? 'BROADCASTING LIVE' : 'GPS STANDBY',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _isTracking ? Colors.green : Colors.grey[600],
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isTracking
                          ? 'Your location is being shared with travelers'
                          : 'Location sharing is currently inactive',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (_lastUpdateTime != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          'Last Sync: ${DateFormat('hh:mm:ss a').format(_lastUpdateTime!)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    if (_isTracking && _currentPosition != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_errorMessage!.contains('disabled'))
                        TextButton(
                          onPressed: () => Geolocator.openLocationSettings(),
                          child: const Text('Open Settings'),
                        ),
                    ],
                  ],
                ),
              ),

              // Controls
              Row(
                children: [
                  if (_isTracking) ...[
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _completeTour,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle_outline),
                              Text(
                                'COMPLETE TRIP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _toggleTracking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTracking
                              ? Colors.red[400]
                              : Colors.green[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isTracking
                                  ? Icons.stop_circle
                                  : Icons.play_circle,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isTracking ? 'STOP' : 'START BROADCAST',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
