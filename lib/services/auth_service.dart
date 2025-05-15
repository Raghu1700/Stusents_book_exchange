import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String usersCollection = 'users';

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailAndPassword({
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user data from Firestore
      if (userCredential.user != null) {
        final userData = await getUserData(userCredential.user!.uid);

        return {
          'success': true,
          'uid': userCredential.user?.uid,
          'email': userCredential.user?.email,
          'userData': userData,
        };
      }

      return {
        'success': true,
        'uid': userCredential.user?.uid,
        'email': userCredential.user?.email,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'code': e.code,
        'message': _getMessageFromErrorCode(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Register with email and password
  Future<Map<String, dynamic>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      if (userCredential.user != null) {
        await _createUserProfile(
          userCredential.user!.uid,
          email,
          fullName,
          phoneNumber,
        );

        // Update display name in Firebase Auth
        await userCredential.user!.updateProfile(
          displayName: fullName,
        );
      }

      return {
        'success': true,
        'uid': userCredential.user?.uid,
        'email': userCredential.user?.email,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'code': e.code,
        'message': _getMessageFromErrorCode(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(
    String uid,
    String email,
    String? fullName,
    String? phoneNumber,
  ) async {
    await _firestore.collection(usersCollection).doc(uid).set({
      'uid': uid,
      'email': email,
      'fullName': fullName ?? '',
      'phoneNumber': phoneNumber ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'profileImageUrl': '',
    });
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final docSnapshot =
          await _firestore.collection(usersCollection).doc(uid).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String uid,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (fullName != null) updateData['fullName'] = fullName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (profileImageUrl != null)
        updateData['profileImageUrl'] = profileImageUrl;

      await _firestore.collection(usersCollection).doc(uid).update(updateData);

      // Update Firebase Auth display name if provided
      if (fullName != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateProfile(
          displayName: fullName,
        );
      }

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent successfully.',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'code': e.code,
        'message': _getMessageFromErrorCode(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Helper method to get human-readable error messages
  String _getMessageFromErrorCode(String errorCode) {
    switch (errorCode) {
      case "invalid-email":
        return "Please enter a valid email address.";
      case "user-disabled":
        return "This account has been disabled.";
      case "user-not-found":
        return "No account found with this email.";
      case "wrong-password":
        return "Incorrect password. Please try again.";
      case "email-already-in-use":
        return "This email is already registered. Please use a different email or try logging in.";
      case "operation-not-allowed":
        return "This operation is not allowed. Please contact support.";
      case "weak-password":
        return "The password is too weak. Please use a stronger password.";
      case "too-many-requests":
        return "Too many login attempts. Please try again later.";
      case "network-request-failed":
        return "Network error. Please check your internet connection.";
      default:
        return "Authentication error: $errorCode";
    }
  }
}
