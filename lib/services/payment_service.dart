import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_payment_settings.dart';
import '../main.dart' show authService;

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // Cache the payment settings
  UserPaymentSettings? _cachedSettings;

  // Get current user's payment settings
  Future<UserPaymentSettings> getUserPaymentSettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    final user = authService.getCurrentUser();
    if (user == null) {
      return UserPaymentSettings.empty();
    }

    // In a real app, this would fetch data from Firestore
    // For now, we're just using the phone number from the user's displayName
    final phoneNumber = user.displayName;

    _cachedSettings = UserPaymentSettings(
      phoneNumber: phoneNumber,
      // For demo purposes, we'll generate dummy UPI and bank details
      // In a real app, these would come from Firestore
      upiId: phoneNumber != null ? '${user.email?.split('@')[0]}@upi' : null,
      bankDetails: phoneNumber != null ? 'SBI Account: XXXX4321' : null,
    );

    return _cachedSettings!;
  }

  // Update user payment settings
  Future<void> updatePaymentSettings(UserPaymentSettings settings) async {
    final user = authService.getCurrentUser();
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Update the phone number in the user profile
    if (settings.phoneNumber != null && settings.phoneNumber!.isNotEmpty) {
      try {
        await user.updateProfile(displayName: settings.phoneNumber);
      } catch (e) {
        throw Exception('Failed to update phone number: $e');
      }
    }

    // In a real app, would save to Firestore here
    // For now, just update the cache
    _cachedSettings = settings;
  }

  // Clear cached settings
  void clearCache() {
    _cachedSettings = null;
  }
}
