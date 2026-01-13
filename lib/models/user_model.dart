import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { traveler, agency, admin }

enum VerificationStatus { pending, verified, rejected }

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;
  final UserRole role;
  final bool verified;
  final VerificationStatus status;
  final List<String> verificationDocuments;
  final String? rejectionReason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? city;
  final String? country;
  final String? address; // Maps to officeAddress
  final String? whatsapp;
  final int? yearsOfExperience;
  final List<String> specializedDestinations;
  final String? description;
  final double averageRating;
  final int reviewCount;

  // New features for Agency Profile & Verification
  final String? ownerName;
  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final String? businessLicenseUrl;
  final String? accreditationId;
  final String? businessLicenseNumber;
  final String? cnicNumber;
  final String? websiteUrl;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? tiktokUrl;
  final String? bankAccountNumber;
  final String? bankAccountHolderName;
  final String? bankName;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.photoUrl,
    required this.role,
    this.verified = false,
    this.status = VerificationStatus.pending,
    this.verificationDocuments = const [],
    this.rejectionReason,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.city,
    this.country,
    this.address,
    this.whatsapp,
    this.yearsOfExperience,
    this.specializedDestinations = const [],
    this.description,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.ownerName,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.businessLicenseUrl,
    this.accreditationId,
    this.businessLicenseNumber,
    this.cnicNumber,
    this.websiteUrl,
    this.facebookUrl,
    this.instagramUrl,
    this.tiktokUrl,
    this.bankAccountNumber,
    this.bankAccountHolderName,
    this.bankName,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse role - handle case sensitivity and provide debug info
    final roleString = data['role']?.toString().trim().toLowerCase();
    UserRole role;
    try {
      role = UserRole.values.firstWhere(
        (e) => e.name.toLowerCase() == roleString,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'UserModel.fromFirestore: WARNING - Role "$roleString" not found for user ${doc.id}, defaulting to traveler',
        );
      }
      role = UserRole.traveler;
    }

    // Parse status
    final statusString = data['status']?.toString().toLowerCase();
    VerificationStatus status;
    try {
      status = VerificationStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == statusString,
      );
    } catch (e) {
      status = VerificationStatus.pending;
    }

    // Safe Date Parsing Helper
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UserModel(
      id: doc.id,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      role: role,
      verified: data['verified'] == true,
      status: status,
      verificationDocuments:
          (data['verificationDocuments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rejectionReason: data['rejectionReason']?.toString(),
      approvedBy: data['approvedBy']?.toString(),
      approvedAt: parseDate(data['approvedAt']),
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(data['updatedAt']) ?? DateTime.now(),
      city: data['city']?.toString(),
      country: data['country']?.toString(),
      address: data['address']?.toString(),
      whatsapp: data['whatsapp']?.toString(),
      yearsOfExperience: int.tryParse(data['yearsOfExperience'].toString()),
      specializedDestinations:
          (data['specializedDestinations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: data['description']?.toString(),
      averageRating:
          double.tryParse(data['averageRating']?.toString() ?? '0') ?? 0.0,
      reviewCount: int.tryParse(data['reviewCount']?.toString() ?? '0') ?? 0,
      ownerName: data['ownerName']?.toString(),
      cnicFrontUrl: data['cnicFrontUrl']?.toString(),
      cnicBackUrl: data['cnicBackUrl']?.toString(),
      businessLicenseUrl: data['businessLicenseUrl']?.toString(),
      accreditationId: data['accreditationId']?.toString(),
      businessLicenseNumber: data['businessLicenseNumber']?.toString(),
      cnicNumber: data['cnicNumber']?.toString(),
      websiteUrl: data['websiteUrl']?.toString(),
      facebookUrl: data['facebookUrl']?.toString(),
      instagramUrl: data['instagramUrl']?.toString(),
      tiktokUrl: data['tiktokUrl']?.toString(),
      bankAccountNumber: data['bankAccountNumber']?.toString(),
      bankAccountHolderName: data['bankAccountHolderName']?.toString(),
      bankName: data['bankName']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role.name,
      'verified': verified,
      'status': status.name,
      'verificationDocuments': verificationDocuments,
      'rejectionReason': rejectionReason,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'city': city,
      'country': country,
      'address': address,
      'whatsapp': whatsapp,
      'yearsOfExperience': yearsOfExperience,
      'specializedDestinations': specializedDestinations,
      'description': description,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'ownerName': ownerName,
      'cnicFrontUrl': cnicFrontUrl,
      'cnicBackUrl': cnicBackUrl,
      'businessLicenseUrl': businessLicenseUrl,
      'accreditationId': accreditationId,
      'businessLicenseNumber': businessLicenseNumber,
      'cnicNumber': cnicNumber,
      'websiteUrl': websiteUrl,
      'facebookUrl': facebookUrl,
      'instagramUrl': instagramUrl,
      'tiktokUrl': tiktokUrl,
      'bankAccountNumber': bankAccountNumber,
      'bankAccountHolderName': bankAccountHolderName,
      'bankName': bankName,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? photoUrl,
    UserRole? role,
    bool? verified,
    VerificationStatus? status,
    List<String>? verificationDocuments,
    String? rejectionReason,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? city,
    String? country,
    String? address,
    String? whatsapp,
    int? yearsOfExperience,
    List<String>? specializedDestinations,
    String? description,
    double? averageRating,
    int? reviewCount,
    String? ownerName,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? businessLicenseUrl,
    String? accreditationId,
    String? businessLicenseNumber,
    String? cnicNumber,
    String? websiteUrl,
    String? facebookUrl,
    String? instagramUrl,
    String? tiktokUrl,
    String? bankAccountNumber,
    String? bankAccountHolderName,
    String? bankName,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      verified: verified ?? this.verified,
      status: status ?? this.status,
      verificationDocuments:
          verificationDocuments ?? this.verificationDocuments,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      city: city ?? this.city,
      country: country ?? this.country,
      address: address ?? this.address,
      whatsapp: whatsapp ?? this.whatsapp,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      specializedDestinations:
          specializedDestinations ?? this.specializedDestinations,
      description: description ?? this.description,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      ownerName: ownerName ?? this.ownerName,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
      businessLicenseUrl: businessLicenseUrl ?? this.businessLicenseUrl,
      accreditationId: accreditationId ?? this.accreditationId,
      businessLicenseNumber:
          businessLicenseNumber ?? this.businessLicenseNumber,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountHolderName:
          bankAccountHolderName ?? this.bankAccountHolderName,
      bankName: bankName ?? this.bankName,
    );
  }
}
