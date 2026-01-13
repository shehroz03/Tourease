import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class AdminService {
  AdminService._();
  static final AdminService _instance = AdminService._();
  factory AdminService() => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<List<UserModel>> streamAgenciesByStatus(VerificationStatus status) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'agency')
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          // Handle index errors gracefully
          if (error.toString().contains('failed-precondition') ||
              error.toString().contains('requires an index')) {
            debugPrint('INDEX ERROR - streamAgenciesByStatus: $error');
            if (error.toString().contains(
              'https://console.firebase.google.com',
            )) {
              final urlMatch = RegExp(
                r'https://console\.firebase\.google\.com[^\s]+',
              ).firstMatch(error.toString());
              if (urlMatch != null) {
                debugPrint('CREATE INDEX URL: ${urlMatch.group(0)}');
              }
            }
          }
          // Return empty list on error instead of crashing
          return <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        })
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  Future<void> approveAgency(String agencyId, String adminId) async {
    try {
      // Update agency status
      await _firestore.collection('users').doc(agencyId).update({
        'verified': true,
        'status': VerificationStatus.verified.name,
        'approvedBy': adminId,
        'approvedAt': Timestamp.now(),
        'rejectionReason': null,
        'updatedAt': Timestamp.now(),
      });

      // Update all tours belonging to this agency
      final toursSnapshot = await _firestore
          .collection('tours')
          .where('agencyId', isEqualTo: agencyId)
          .get();

      final batch = _firestore.batch();
      for (var doc in toursSnapshot.docs) {
        batch.update(doc.reference, {
          'agencyVerified': true,
          'agencyStatus': VerificationStatus.verified.name,
        });
      }
      await batch.commit();

      // Create notification for the agency
      final notificationService = NotificationService();
      final notification = NotificationModel(
        id: '', // Will be set by Firestore
        userId: agencyId,
        type: NotificationType.verificationApproved,
        title: 'Verification Approved! 🎉',
        message:
            'Congratulations! Your agency verification has been approved. You can now create and manage tours.',
        read: false,
        createdAt: DateTime.now(),
        data: {
          'adminId': adminId,
          'approvedAt': Timestamp.now().millisecondsSinceEpoch,
        },
      );
      await notificationService.createNotification(notification);
    } catch (e) {
      throw Exception('Failed to approve agency: $e');
    }
  }

  Future<void> rejectAgency(String agencyId, String reason) async {
    try {
      // Update agency status
      await _firestore.collection('users').doc(agencyId).update({
        'verified': false,
        'status': VerificationStatus.rejected.name,
        'rejectionReason': reason,
        'updatedAt': Timestamp.now(),
      });

      // Update all tours belonging to this agency
      final toursSnapshot = await _firestore
          .collection('tours')
          .where('agencyId', isEqualTo: agencyId)
          .get();

      final batch = _firestore.batch();
      for (var doc in toursSnapshot.docs) {
        batch.update(doc.reference, {
          'agencyVerified': false,
          'agencyStatus': VerificationStatus.rejected.name,
        });
      }
      await batch.commit();

      // Create notification for the agency
      final notificationService = NotificationService();
      final notification = NotificationModel(
        id: '', // Will be set by Firestore
        userId: agencyId,
        type: NotificationType.verificationRejected,
        title: 'Verification Rejected',
        message:
            'Your agency verification has been rejected. Reason: $reason. You can submit new documents for review.',
        read: false,
        createdAt: DateTime.now(),
        data: {'rejectionReason': reason},
      );
      await notificationService.createNotification(notification);
    } catch (e) {
      throw Exception('Failed to reject agency: $e');
    }
  }

  Future<void> revokeAgency(String agencyId) async {
    try {
      await _firestore.collection('users').doc(agencyId).update({
        'verified': false,
        'status': VerificationStatus.pending.name,
        'approvedBy': null,
        'approvedAt': null,
        'updatedAt': Timestamp.now(),
      });

      // Also reset tours
      final toursSnapshot = await _firestore
          .collection('tours')
          .where('agencyId', isEqualTo: agencyId)
          .get();

      final batch = _firestore.batch();
      for (var doc in toursSnapshot.docs) {
        batch.update(doc.reference, {
          'agencyVerified': false,
          'agencyStatus': VerificationStatus.pending.name,
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to revoke agency: $e');
    }
  }

  Future<Map<String, int>> getDashboardStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final toursSnapshot = await _firestore.collection('tours').get();

      final users = usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      final totalUsers = users.length;
      final totalAgencies = users
          .where((u) => u.role == UserRole.agency)
          .length;
      final pendingAgencies = users
          .where(
            (u) =>
                u.role == UserRole.agency &&
                u.status == VerificationStatus.pending,
          )
          .length;
      final verifiedAgencies = users
          .where(
            (u) =>
                u.role == UserRole.agency &&
                u.status == VerificationStatus.verified,
          )
          .length;
      final totalTours = toursSnapshot.docs.length;

      return {
        'totalUsers': totalUsers,
        'totalAgencies': totalAgencies,
        'pendingAgencies': pendingAgencies,
        'verifiedAgencies': verifiedAgencies,
        'totalTours': totalTours,
      };
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }
}
