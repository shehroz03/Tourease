import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Added geolocator
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/live_location_service.dart';
import '../../models/tour_model.dart';
import '../../models/location_model.dart';
import '../../services/tour_service.dart';
import '../../services/chat_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/distance_utils.dart';
import '../../services/eta_service.dart';

class LiveTrackScreen extends StatefulWidget {
  final String tourId;
  const LiveTrackScreen({super.key, required this.tourId});

  @override
  State<LiveTrackScreen> createState() => _LiveTrackScreenState();
}

class _LiveTrackScreenState extends State<LiveTrackScreen> {
  final _tourService = TourService();
  final _chatService = ChatService();
  final _liveLocationService = LiveLocationService();
  final EtaProvider _etaProvider = LocalHaversineEtaProvider();
  TourModel? _tour;
  bool _isLoading = true;
  final MapController _mapController = MapController();
  LatLng? _userLocation; // User's GPS location

  @override
  void initState() {
    super.initState();
    debugPrint('LiveTrackScreen: Opening with tourId: ${widget.tourId}');
    _loadTour();
    _getUserLocation(); // Fetch user GPS
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        _fitBounds(); // Refit bounds with user location
      }
    } catch (e) {
      debugPrint('Error getting user location: $e');
    }
  }

  Future<void> _loadTour() async {
    try {
      debugPrint('LiveTrackScreen: Loading tour data for ${widget.tourId}');
      final tour = await _tourService.getTourById(widget.tourId);
      if (mounted) {
        setState(() {
          _tour = tour;
          _isLoading = false;
        });
        debugPrint(
          'LiveTrackScreen: Tour loaded successfully - ${tour?.title ?? "null"}',
        );
      }
    } catch (e) {
      debugPrint('LiveTrackScreen: Error loading tour - $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _fitBounds() {
    if (_tour == null) return;
    final points = _getBoundsPoints();
    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  List<LatLng> _getBoundsPoints() {
    final points = _getRoutePoints();
    if (_userLocation != null) {
      points.add(_userLocation!);
    }
    return points;
  }

  List<LatLng> _getRoutePoints() {
    if (_tour == null) return [];
    final points = <LatLng>[];
    // NOTE: Do NOT add userLocation here, as it distorts the polyline
    if (_tour!.startLocation != null) {
      points.add(LatLng(_tour!.startLocation!.lat, _tour!.startLocation!.lng));
    }
    for (var stop in _tour!.stops) {
      points.add(LatLng(stop.lat, stop.lng));
    }
    if (_tour!.endLocation != null) {
      points.add(LatLng(_tour!.endLocation!.lat, _tour!.endLocation!.lng));
    }
    return points;
  }

  TourStop? _getNextStop(LatLng? currentLoc) {
    if (_tour == null || _tour!.stops.isEmpty) return null;

    final now = DateTime.now();

    // If the tour hasn't ended yet, and it's active, don't show completed just based on today's time
    if (_tour!.status == TourStatus.active &&
        now.isBefore(_tour!.endDate.add(const Duration(days: 1)))) {
      // Return the first stop that hasn't been reached yet (simplification for demo)
      // In a real app, you'd track progress specifically
      return _tour!.stops.firstWhere(
        (s) => s.scheduledTime != null,
        orElse: () => _tour!.stops.first,
      );
    }

    final timeFormat = DateFormat('hh:mm a');

    for (var stop in _tour!.stops) {
      if (stop.scheduledTime != null) {
        try {
          final stopTime = timeFormat.parse(stop.scheduledTime!);
          final fullStopTime = DateTime(
            now.year,
            now.month,
            now.day,
            stopTime.hour,
            stopTime.minute,
          );
          if (fullStopTime.isAfter(now) || fullStopTime.isAtSameMomentAs(now)) {
            return stop;
          }
        } catch (_) {}
      }
    }

    // If no future stop found, but tour is active, show the last stop as the target
    // so it doesn't say "Trip Completed" prematurely.
    if (_tour != null && _tour!.stops.isNotEmpty) {
      return _tour!.stops.last;
    }

    return null;
  }

  bool _isTripCompleted() {
    if (_tour == null) return false;
    final now = DateTime.now();

    // A trip is only completed if status is explicitly completed
    // OR if it's way past the end date (e.g. 2 days after)
    // We want to be lenient so people can still track on the last day + buffer
    if (_tour!.status == TourStatus.completed) return true;

    // If active, even if dates are passed, maybe they are just running late.
    // But let's say 48 hours after end date it auto-completes visually.
    if (_tour!.status == TourStatus.active) {
      return now.isAfter(_tour!.endDate.add(const Duration(days: 2)));
    }

    return false;
  }

  Future<void> _makePhoneCall() async {
    // In a real app, fetch agency phone from tour/booking
    final phoneNumber = 'tel:+923001234567';
    final uri = Uri.parse(phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _openChat() async {
    if (_tour == null) return;

    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      final chatId = await _chatService.getOrCreateChat(
        travelerId: user.id,
        agencyId: _tour!.agencyId,
        tourId: _tour!.id,
      );
      if (mounted) {
        context.push('/chat/$chatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open chat: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_tour == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Track')),
        body: const Center(child: Text('Tour data not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Live Tracking'),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_tour!.stops.isEmpty && _tour!.startLocation == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Route data not available yet. Please contact the agency.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Map section
        Expanded(
          flex: 3,
          child: StreamBuilder<LatLng?>(
            stream: _liveLocationService.streamCurrentLocation(widget.tourId),
            builder: (context, locationSnapshot) {
              final currentLoc = locationSnapshot.data;
              return Stack(
                children: [
                  _buildMap(currentLoc),
                  // Next Stop Card
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildNextStopCard(currentLoc),
                  ),
                ],
              );
            },
          ),
        ),
        // Trip Itinerary panel
        Expanded(
          flex: 2,
          child: StreamBuilder<LatLng?>(
            stream: _liveLocationService.streamCurrentLocation(widget.tourId),
            builder: (context, locationSnapshot) {
              return _buildItineraryPanel(locationSnapshot.data);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMap(LatLng? currentLoc) {
    final points = _getRoutePoints();
    final markers = <Marker>[];

    // Start location
    if (_tour!.startLocation != null) {
      markers.add(
        Marker(
          point: LatLng(_tour!.startLocation!.lat, _tour!.startLocation!.lng),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.play_circle_fill,
            color: Colors.green,
            size: 40,
          ),
        ),
      );
    }

    // Stops
    for (var stop in _tour!.stops) {
      markers.add(
        Marker(
          point: LatLng(stop.lat, stop.lng),
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Text(
                  stop.name,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.location_on, color: Colors.blue, size: 24),
            ],
          ),
        ),
      );
    }

    // End location
    if (_tour!.endLocation != null) {
      markers.add(
        Marker(
          point: LatLng(_tour!.endLocation!.lat, _tour!.endLocation!.lng),
          width: 40,
          height: 40,
          child: const Icon(Icons.flag, color: Colors.red, size: 40),
        ),
      );
    }

    // Bus / Current Location
    if (currentLoc != null) {
      markers.add(
        Marker(
          point: currentLoc,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.directions_bus,
              color: Colors.blue,
              size: 30,
            ),
          ),
        ),
      );
    }

    // User Location (GPS) - Blue Dot
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
          ),
        ),
      );
    }

    if (points.isEmpty) {
      return const Center(child: Text('No route data available.'));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: points.first,
        initialZoom: 12,
        onMapReady: _fitBounds,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com-tourease-app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              strokeWidth: 6,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ),
          ],
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildNextStopCard(LatLng? currentLoc) {
    final nextStop = _getNextStop(currentLoc);
    final isCompleted = _isTripCompleted();

    // If trip ended
    if (isCompleted ||
        (nextStop == null && _tour!.status == TourStatus.completed)) {
      return Card(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Trip Completed',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
          ),
        ),
      );
    }

    // NEW LOGIC: Before Start - If the tour hasn't begun (currentLoc is null)
    if (currentLoc == null) {
      return Card(
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TOUR STARTING SOON',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tour!.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Waiting for agency to start broadcast...',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(_tour!.startDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'START',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (nextStop == null) {
      return Card(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Tour In Progress',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );
    }

    return FutureBuilder<EtaResult?>(
      future: _etaProvider.calculateEta(
        fromLat: currentLoc.latitude,
        fromLng: currentLoc.longitude,
        toLat: nextStop.lat,
        toLng: nextStop.lng,
      ),
      builder: (context, snapshot) {
        final etaResult = snapshot.data;
        final String etaLabel;

        if (etaResult != null) {
          etaLabel = formatEtaDuration(etaResult.duration);
        } else if (nextStop.scheduledTime != null) {
          etaLabel = 'At ${nextStop.scheduledTime}';
        } else {
          etaLabel = '...';
        }

        return Card(
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NEXT STOP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue[800],
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nextStop.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (etaResult != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Distance: ${etaResult.distanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        etaLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'LIVE ETA',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItineraryPanel(LatLng? currentLoc) {
    // Create a combined list of Start Location, Stops, and End Location
    final List<TourStop> allItems = [];
    if (_tour!.startLocation != null) {
      allItems.add(
        TourStop(
          name: '${_tour!.startLocation!.address} (Start)',
          lat: _tour!.startLocation!.lat,
          lng: _tour!.startLocation!.lng,
          order: -1,
          scheduledTime: DateFormat('hh:mm a').format(_tour!.startDate),
          note: 'Origin Point',
        ),
      );
    }
    allItems.addAll(_tour!.stops);
    if (_tour!.endLocation != null) {
      allItems.add(
        TourStop(
          name: '${_tour!.endLocation!.address} (End)',
          lat: _tour!.endLocation!.lat,
          lng: _tour!.endLocation!.lng,
          order: 9999,
          scheduledTime: DateFormat('hh:mm a').format(_tour!.endDate),
          note: 'Final Destination',
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trip Itinerary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _makePhoneCall,
                      icon: const Icon(Icons.phone),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                        foregroundColor: Colors.green,
                      ),
                      tooltip: 'Call Agency',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _openChat,
                      icon: const Icon(Icons.chat_bubble),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      tooltip: 'Chat with Agency',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Stops list
          Expanded(
            child: allItems.isEmpty
                ? const Center(child: Text('No stops available'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: allItems.length,
                    itemBuilder: (context, index) {
                      final stop = allItems[index];
                      final nextStop = _getNextStop(currentLoc);

                      var status = 'upcoming';
                      if (nextStop != null) {
                        if (stop.order < nextStop.order) {
                          status = 'completed';
                        } else if (stop.order == nextStop.order) {
                          status = 'current';
                        }
                      } else if (_tour!.status == TourStatus.completed) {
                        status = 'completed';
                      }

                      return _buildStopItem(
                        stop,
                        index,
                        status,
                        allItems.length,
                        currentLoc,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopItem(
    TourStop stop,
    int index,
    String status,
    int totalCount,
    LatLng? currentLoc,
  ) {
    final isLast = index == totalCount - 1;
    final isCompleted = status == 'completed';
    final isCurrent = status == 'current';

    final Color color = isCompleted
        ? Colors.grey
        : isCurrent
        ? Theme.of(context).primaryColor
        : Colors.grey[300]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCurrent ? color : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? Colors.white : color,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.grey)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? Colors.blue.withValues(alpha: 0.3)
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Stop details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          stop.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.grey
                                : isCurrent
                                ? Theme.of(context).primaryColor
                                : Colors.black87,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (isCurrent && currentLoc != null)
                        FutureBuilder<EtaResult?>(
                          future: _etaProvider.calculateEta(
                            fromLat: currentLoc.latitude,
                            fromLng: currentLoc.longitude,
                            toLat: stop.lat,
                            toLng: stop.lng,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ETA: ${formatEtaDuration(snapshot.data!.duration)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return _buildTimeBadge(stop.scheduledTime);
                          },
                        )
                      else
                        _buildTimeBadge(stop.scheduledTime),
                    ],
                  ),
                  if (stop.note != null && stop.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      stop.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBadge(String? time) {
    final displayTime = time ?? 'TBD';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: displayTime == 'TBD'
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayTime,
        style: TextStyle(
          fontSize: 12,
          color: displayTime == 'TBD' ? Colors.orange : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
