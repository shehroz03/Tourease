import 'package:cloud_firestore/cloud_firestore.dart';

enum WithdrawalStatus { pending, approved, rejected }

class WithdrawalRequestModel {
  final String id;
  final String agencyId;
  final double amount;
  final WithdrawalStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? bankName;
  final String? accountHolderName;
  final String? accountNumber;

  WithdrawalRequestModel({
    required this.id,
    required this.agencyId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.bankName,
    this.accountHolderName,
    this.accountNumber,
  });

  factory WithdrawalRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WithdrawalRequestModel(
      id: doc.id,
      agencyId: data['agencyId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
      bankName: data['bankName'],
      accountHolderName: data['accountHolderName'],
      accountNumber: data['accountNumber'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'agencyId': agencyId,
      'amount': amount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null
          ? Timestamp.fromDate(processedAt!)
          : null,
      'bankName': bankName,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
    };
  }
}
