class LocationData {
  final double lat;
  final double lng;
  final String address;

  LocationData({required this.lat, required this.lng, required this.address});

  Map<String, dynamic> toMap() {
    return {'lat': lat, 'lng': lng, 'address': address};
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
    );
  }

  LocationData copyWith({double? lat, double? lng, String? address}) {
    return LocationData(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
    );
  }
}

class TourStop {
  final String name;
  final double lat;
  final double lng;
  final int order;
  final String? note;
  final String? scheduledTime;

  TourStop({
    required this.name,
    required this.lat,
    required this.lng,
    required this.order,
    this.note,
    this.scheduledTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      'order': order,
      'note': note,
      'scheduledTime': scheduledTime,
    };
  }

  factory TourStop.fromMap(Map<String, dynamic> map) {
    return TourStop(
      name: map['name'] ?? '',
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
      order: map['order'] ?? 0,
      note: map['note'],
      scheduledTime: map['scheduledTime'],
    );
  }

  TourStop copyWith({
    String? name,
    double? lat,
    double? lng,
    int? order,
    String? note,
    String? scheduledTime,
  }) {
    return TourStop(
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      order: order ?? this.order,
      note: note ?? this.note,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }
}
