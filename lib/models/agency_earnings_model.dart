import 'package:cloud_firestore/cloud_firestore.dart';

class AgencyEarningsModel {
  final String agencyId;
  final double totalEarnings;
  final double totalWithdrawn;
  final double availableBalance;
  final DateTime lastUpdatedAt;

  AgencyEarningsModel({
    required this.agencyId,
    required this.totalEarnings,
    required this.totalWithdrawn,
    required this.availableBalance,
    required this.lastUpdatedAt,
  });

  factory AgencyEarningsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgencyEarningsModel(
      agencyId: doc.id,
      totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
      totalWithdrawn: (data['totalWithdrawn'] ?? 0).toDouble(),
      availableBalance: (data['availableBalance'] ?? 0).toDouble(),
      lastUpdatedAt: data['lastUpdatedAt'] != null
          ? (data['lastUpdatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalEarnings': totalEarnings,
      'totalWithdrawn': totalWithdrawn,
      'availableBalance': availableBalance,
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
    };
  }
}
