import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_payment_settings.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get user information by ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      // Get user document from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return {
          'email': 'Unknown',
          'phoneNumber': 'Not available',
          'displayName': 'Unknown Seller',
        };
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Get phone number from user data or from Firebase Auth display name
      String? phoneNumber = userData['phoneNumber'];
      if (phoneNumber == null || phoneNumber.isEmpty) {
        // Try to get from the current user if it's the same user
        if (currentUserId == userId) {
          final currentUser = _auth.currentUser;
          phoneNumber = currentUser?.displayName;
        }
      }

      return {
        'email': userData['email'] ?? 'Unknown',
        'phoneNumber': phoneNumber ?? 'Not available',
        'displayName': userData['displayName'] ?? 'Seller',
      };
    } catch (e) {
      print('Error getting user by ID: $e');
      return {
        'email': 'Error',
        'phoneNumber': 'Error',
        'displayName': 'Error',
      };
    }
  }

  // Get user payment settings
  Future<UserPaymentSettings> getUserPaymentSettings(String userId) async {
    try {
      // First try to get from user document
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return UserPaymentSettings.empty();
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Get phone number from user data or from Firebase Auth display name
      String? phoneNumber = userData['phoneNumber'];
      if (phoneNumber == null || phoneNumber.isEmpty) {
        // Try to get from the current user if it's the same user
        if (currentUserId == userId) {
          final currentUser = _auth.currentUser;
          phoneNumber = currentUser?.displayName;
        }
      }

      // For demo purposes, generate UPI ID from email if available
      String? email = userData['email'];
      String? upiId;
      if (email != null && email.contains('@')) {
        upiId = '${email.split('@')[0]}@upi';
      }

      return UserPaymentSettings(
        phoneNumber: phoneNumber,
        upiId: upiId,
        bankDetails: userData['bankDetails'],
      );
    } catch (e) {
      print('Error getting user payment settings: $e');
      return UserPaymentSettings.empty();
    }
  }
}
