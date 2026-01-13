import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  const AuthService();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final now = DateTime.now();
        final user = UserModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          role: role,
          verified: role == UserRole.traveler,
          status: role == UserRole.traveler
              ? VerificationStatus.verified
              : VerificationStatus.pending,
          verificationDocuments: [],
          createdAt: now,
          updatedAt: now,
        );

        await _firestore
            .collection('users')
            .doc(user.id)
            .set(user.toFirestore());

        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint(
        'AuthService.signIn: Attempting to sign in with email: $email',
      );
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint(
        'AuthService.signIn: Firebase Auth successful, UID: ${credential.user?.uid}',
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        debugPrint(
          'AuthService.signIn: Fetching user data from Firestore for UID: $uid',
        );

        final userDoc = await _firestore.collection('users').doc(uid).get();

        if (!userDoc.exists) {
          debugPrint(
            'AuthService.signIn: User document missing. Creating default traveler profile.',
          );
          // Auto-create missing document for old auth accounts
          final now = DateTime.now();
          final newUser = UserModel(
            id: uid,
            email: email,
            name: email.split('@')[0],
            role: UserRole.traveler,
            verified: true,
            status: VerificationStatus.verified,
            createdAt: now,
            updatedAt: now,
          );
          await _firestore
              .collection('users')
              .doc(uid)
              .set(newUser.toFirestore());
          return newUser;
        }

        final data = userDoc.data() as Map<String, dynamic>;
        if (data['role'] == null) {
          debugPrint(
            'AuthService.signIn: Role field missing. Updating to traveler.',
          );
          await _firestore.collection('users').doc(uid).update({
            'role': UserRole.traveler.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          // Re-fetch or update locally
          data['role'] = UserRole.traveler.name;
        }

        final userModel = UserModel.fromFirestore(userDoc);
        debugPrint(
          'AuthService.signIn: User data loaded successfully - role: ${userModel.role.name}',
        );
        return userModel;
      }
      debugPrint('AuthService.signIn: No user returned from Firebase Auth');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AuthService.signIn: FirebaseAuthException - code: ${e.code}, message: ${e.message}',
      );
      throw Exception(_getAuthErrorMessage(e));
    } catch (e, stackTrace) {
      debugPrint('AuthService.signIn: Exception - $e');
      debugPrint('AuthService.signIn: Stack trace - $stackTrace');
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Simple local cache to speed up repeated lookups
  static final Map<String, UserModel> _userCache = {};

  Future<UserModel?> getUserById(String userId) async {
    try {
      if (_userCache.containsKey(userId)) {
        return _userCache[userId];
      }
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        _userCache[userId] = user;
        return user;
      }
      debugPrint('User document not found for userId: $userId');
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      rethrow;
    }
  }

  void clearCache() => _userCache.clear();

  Stream<UserModel?> streamUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      _userCache.remove(userId); // Clear cache so next fetch gets fresh data
      data['updatedAt'] = Timestamp.now();
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) throw Exception('No authenticated user');

    try {
      final credential = EmailAuthProvider.credential(
        email: firebaseUser.email ?? '',
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(credential);
      await firebaseUser.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to change password');
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  Future<void> deleteUserAccount({
    required String userId,
    required String password,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) throw Exception('No authenticated user');
    if (firebaseUser.uid != userId) {
      throw Exception('Authenticated user mismatch');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: firebaseUser.email ?? '',
        password: password,
      );
      await firebaseUser.reauthenticateWithCredential(credential);

      // Delete Firestore user document first
      await _firestore.collection('users').doc(userId).delete();

      // Delete Firebase Auth user
      await firebaseUser.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to delete account');
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}
