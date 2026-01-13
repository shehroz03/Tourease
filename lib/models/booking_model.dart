import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, cancelled, completed }

enum PaymentStatus { unpaid, paid, failed, refunded }

class BookingModel {
  final String id;
  final String tourId;
  final String travelerId;
  final String agencyId;
  final BookingStatus status;
  final double totalPrice;
  final int seats;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Payment fields
  final PaymentStatus paymentStatus;
  final String? paymentMethod;
  final String? paymentReference;
  final DateTime? paidAt;
  final double? amountPaid;

  BookingModel({
    required this.id,
    required this.tourId,
    required this.travelerId,
    required this.agencyId,
    this.status = BookingStatus.pending,
    required this.totalPrice,
    this.seats = 1,
    required this.createdAt,
    required this.updatedAt,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentMethod,
    this.paymentReference,
    this.paidAt,
    this.amountPaid,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      tourId: data['tourId'] ?? '',
      travelerId: data['travelerId'] ?? '',
      agencyId: data['agencyId'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      seats: data['seats'] ?? 1,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == data['paymentStatus'],
        orElse: () => PaymentStatus.unpaid,
      ),
      paymentMethod: data['paymentMethod'],
      paymentReference: data['paymentReference'],
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      amountPaid: data['amountPaid'] != null
          ? (data['amountPaid'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tourId': tourId,
      'travelerId': travelerId,
      'agencyId': agencyId,
      'status': status.name,
      'totalPrice': totalPrice,
      'seats': seats,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'amountPaid': amountPaid,
    };
  }

  BookingModel copyWith({
    String? id,
    String? tourId,
    String? travelerId,
    String? agencyId,
    BookingStatus? status,
    double? totalPrice,
    int? seats,
    DateTime? createdAt,
    DateTime? updatedAt,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    String? paymentReference,
    DateTime? paidAt,
    double? amountPaid,
  }) {
    return BookingModel(
      id: id ?? this.id,
      tourId: tourId ?? this.tourId,
      travelerId: travelerId ?? this.travelerId,
      agencyId: agencyId ?? this.agencyId,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      seats: seats ?? this.seats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      paidAt: paidAt ?? this.paidAt,
      amountPaid: amountPaid ?? this.amountPaid,
    );
  }
}
