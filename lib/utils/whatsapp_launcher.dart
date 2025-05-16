import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  /// Formats a phone number for WhatsApp by ensuring it has the country code and removing spaces or special characters
  static String formatPhoneNumber(String phoneNumber) {
    // Remove any spaces or special characters
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Add country code if not present (assuming Indian numbers)
    if (!phoneNumber.startsWith('+')) {
      if (phoneNumber.startsWith('91')) {
        phoneNumber = '+$phoneNumber';
      } else {
        phoneNumber = '+91$phoneNumber';
      }
    }

    return phoneNumber;
  }

  /// Launches WhatsApp with the given phone number and message
  static Future<bool> launchWhatsApp({
    required String phoneNumber,
    required String message,
    required BuildContext context,
  }) async {
    try {
      // Format the phone number
      final formattedPhone = formatPhoneNumber(phoneNumber);
      debugPrint('Formatted phone number: $formattedPhone');

      // Encode the message
      final encodedMessage = Uri.encodeComponent(message);

      // Remove the + from the phone number for wa.me links
      final waPhoneNumber = formattedPhone.replaceAll('+', '');
      final uri =
          Uri.parse('https://wa.me/$waPhoneNumber?text=$encodedMessage');

      debugPrint('Launching WhatsApp with URI: $uri');

      if (await canLaunchUrl(uri)) {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (!launched) {
          _showError(
              'Could not launch WhatsApp. Please make sure WhatsApp is installed.',
              context);
          return false;
        }
        return true;
      } else {
        _showError('WhatsApp is not available on this device.', context);
        return false;
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      _showError('Error: $e', context);
      return false;
    }
  }

  // Shows an error message
  static void _showError(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
