import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

enum TourStatus { draft, active, inactive, completed }

class TourModel {
  final String id;
  final String agencyId;
  final String agencyName;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final String category;
  final int seats;
  final int bookedSeats;
  final String? coverImage;
  final List<String> galleryImages;
  final TourStatus status;
  final LocationData? startLocation;
  final LocationData? endLocation;
  final List<TourStop> stops;
  final bool agencyVerified;
  final String agencyStatus;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TourModel({
    required this.id,
    required this.agencyId,
    required this.agencyName,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.category,
    required this.seats,
    this.bookedSeats = 0,
    this.coverImage,
    this.galleryImages = const [],
    this.status = TourStatus.draft,
    this.agencyVerified = false,
    this.agencyStatus = 'pending',
    this.startLocation,
    this.endLocation,
    this.stops = const [],
    this.averageRating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  int get availableSeats => seats - bookedSeats;

  factory TourModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TourModel(
      id: doc.id,
      agencyId: data['agencyId'] ?? '',
      agencyName: data['agencyName'] ?? 'Unknown Agency',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      seats: data['seats'] ?? 0,
      bookedSeats: data['bookedSeats'] ?? 0,
      coverImage: data['coverImage'],
      galleryImages: data['galleryImages'] != null
          ? List<String>.from(data['galleryImages'] as List)
          : [],
      status: TourStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TourStatus.draft,
      ),
      agencyVerified: data['agencyVerified'] ?? false,
      agencyStatus: data['agencyStatus'] ?? 'pending',
      startLocation: data['startLocation'] != null
          ? LocationData.fromMap(data['startLocation'] as Map<String, dynamic>)
          : null,
      endLocation: data['endLocation'] != null
          ? LocationData.fromMap(data['endLocation'] as Map<String, dynamic>)
          : null,
      stops: data['stops'] != null
          ? (data['stops'] as List)
                .map((e) => TourStop.fromMap(e as Map<String, dynamic>))
                .toList()
          : [],
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'agencyId': agencyId,
      'agencyName': agencyName,
      'title': title,
      'description': description,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'price': price,
      'category': category,
      'seats': seats,
      'bookedSeats': bookedSeats,
      'coverImage': coverImage,
      'galleryImages': galleryImages,
      'status': status.name,
      'agencyVerified': agencyVerified,
      'agencyStatus': agencyStatus,
      'startLocation': startLocation?.toMap(),
      'endLocation': endLocation?.toMap(),
      'stops': stops.map((stop) => stop.toMap()).toList(),
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TourModel copyWith({
    String? id,
    String? agencyId,
    String? agencyName,
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    String? category,
    int? seats,
    int? bookedSeats,
    String? coverImage,
    TourStatus? status,
    bool? agencyVerified,
    String? agencyStatus,
    LocationData? startLocation,
    LocationData? endLocation,
    List<TourStop>? stops,
    List<String>? galleryImages,
    double? averageRating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TourModel(
      id: id ?? this.id,
      agencyId: agencyId ?? this.agencyId,
      agencyName: agencyName ?? this.agencyName,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      price: price ?? this.price,
      category: category ?? this.category,
      seats: seats ?? this.seats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      coverImage: coverImage ?? this.coverImage,
      status: status ?? this.status,
      agencyVerified: agencyVerified ?? this.agencyVerified,
      agencyStatus: agencyStatus ?? this.agencyStatus,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      stops: stops ?? this.stops,
      galleryImages: galleryImages ?? this.galleryImages,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
