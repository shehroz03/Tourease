import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agency_earnings_model.dart';
import '../models/withdrawal_request_model.dart';

class EarningsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or calculate earnings
  Future<AgencyEarningsModel> getAgencyEarnings(String agencyId) async {
    final docRef = _firestore.collection('agency_earnings').doc(agencyId);
    final doc = await docRef.get();

    if (doc.exists) {
      return AgencyEarningsModel.fromFirestore(doc);
    }

    // Default if not exists
    return AgencyEarningsModel(
      agencyId: agencyId,
      totalEarnings: 0,
      totalWithdrawn: 0,
      availableBalance: 0,
      lastUpdatedAt: DateTime.now(),
    );
  }

  // Recalculate total earnings from completed bookings
  // This helps ensure accurate data if bookings are updated elsewhere
  Future<void> recalculateTotalEarnings(String agencyId) async {
    // Fetch all completed bookings
    // Fetch all bookings for agency
    // We filter client-side for flexibility with 'completed' OR 'confirmed'
    // AND 'paymentStatus' == 'paid'.
    final bookingsSnapshot = await _firestore
        .collection('bookings')
        .where('agencyId', isEqualTo: agencyId)
        .get();

    double total = 0;
    for (var doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'];
      final paymentStatus = data['paymentStatus'];

      // Check earnings criteria
      if ((status == 'completed' || status == 'confirmed') &&
          paymentStatus == 'paid') {
        // Use actual amount paid if available, else total price
        total += (data['amountPaid'] ?? data['totalPrice'] ?? 0).toDouble();
      }
    }

    // Get current earnings doc to preserve totalWithdrawn
    final docRef = _firestore.collection('agency_earnings').doc(agencyId);
    final doc = await docRef.get();
    double withdrawn = 0;

    if (doc.exists) {
      withdrawn = (doc.data()?['totalWithdrawn'] ?? 0).toDouble();
    }

    final available = total - withdrawn;

    await docRef.set({
      'totalEarnings': total,
      'totalWithdrawn': withdrawn,
      'availableBalance': available,
      'lastUpdatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // Stream earnings for dashboard
  Stream<AgencyEarningsModel> streamEarnings(String agencyId) {
    return _firestore
        .collection('agency_earnings')
        .doc(agencyId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return AgencyEarningsModel.fromFirestore(doc);
          } else {
            return AgencyEarningsModel(
              agencyId: agencyId,
              totalEarnings: 0,
              totalWithdrawn: 0,
              availableBalance: 0,
              lastUpdatedAt: DateTime.now(),
            );
          }
        });
  }

  // Request withdrawal
  Future<void> requestWithdrawal(
    String agencyId,
    double amount, {
    String? bankName,
    String? accountHolderName,
    String? accountNumber,
  }) async {
    final earningsRef = _firestore.collection('agency_earnings').doc(agencyId);
    final withdrawalsRef = _firestore.collection('withdrawals').doc();

    return _firestore.runTransaction((transaction) async {
      final earningsDoc = await transaction.get(earningsRef);

      AgencyEarningsModel earnings;
      if (!earningsDoc.exists) {
        // Should not happen if recalculate was called, but safety check
        earnings = AgencyEarningsModel(
          agencyId: agencyId,
          totalEarnings: 0,
          totalWithdrawn: 0,
          availableBalance: 0,
          lastUpdatedAt: DateTime.now(),
        );
      } else {
        earnings = AgencyEarningsModel.fromFirestore(earningsDoc);
      }

      if (earnings.availableBalance < amount) {
        throw Exception("Insufficient funds.");
      }

      // Create withdrawal request
      final request = WithdrawalRequestModel(
        id: withdrawalsRef.id,
        agencyId: agencyId,
        amount: amount,
        status: WithdrawalStatus.pending,
        createdAt: DateTime.now(),
        bankName: bankName,
        accountHolderName: accountHolderName,
        accountNumber: accountNumber,
      );

      transaction.set(withdrawalsRef, request.toFirestore());

      // Update earnings
      transaction.set(earningsRef, {
        'totalWithdrawn': earnings.totalWithdrawn + amount,
        'availableBalance': earnings.availableBalance - amount,
        'totalEarnings': earnings.totalEarnings, // Keep calculated total
        'lastUpdatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    });
  }
}
