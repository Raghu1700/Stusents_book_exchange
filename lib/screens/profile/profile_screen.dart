import 'package:flutter/material.dart';
import 'package:rive_animation/main.dart' show authService;
import 'package:rive_animation/screens/onboding/onboding_screen.dart';
import 'package:rive_animation/services/payment_service.dart';
import 'package:rive_animation/model/user_payment_settings.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get current user information
    final currentUser = authService.getCurrentUser();
    final userEmail = currentUser?.email ?? 'No email';
    final userName = userEmail.split('@')[0];
    final userPhone = currentUser?.displayName ?? 'No phone number';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Phone: $userPhone",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Member since: January 2024",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              "Account",
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              context,
              icon: Icons.person_outline,
              title: "Edit Profile",
              onTap: () {},
            ),
            _buildProfileMenuItem(
              context,
              icon: Icons.notifications_outlined,
              title: "Notifications",
              onTap: () {},
            ),
            _buildProfileMenuItem(
              context,
              icon: Icons.payment_outlined,
              title: "Payment Methods",
              onTap: () {
                _showPaymentSettingsDialog(context);
              },
            ),
            const SizedBox(height: 24),
            Text(
              "Books",
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              context,
              icon: Icons.auto_stories_outlined,
              title: "My Books for Sale",
              onTap: () {},
            ),
            _buildProfileMenuItem(
              context,
              icon: Icons.history_outlined,
              title: "Purchase History",
              onTap: () {},
            ),
            _buildProfileMenuItem(
              context,
              icon: Icons.lightbulb_outline,
              title: "My Bids",
              onTap: () {},
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await authService.signOut();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully signed out'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Navigate to the onboarding screen after sign out
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const OnbodingScreen(),
                        ),
                        (route) => false, // Remove all previous routes
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error signing out: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.grey[50],
      ),
    );
  }

  void _showPaymentSettingsDialog(BuildContext context) async {
    final paymentService = PaymentService();
    final settings = await paymentService.getUserPaymentSettings();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PaymentSettingsSheet(initialSettings: settings),
    );
  }
}

class PaymentSettingsSheet extends StatefulWidget {
  final UserPaymentSettings initialSettings;

  const PaymentSettingsSheet({
    Key? key,
    required this.initialSettings,
  }) : super(key: key);

  @override
  State<PaymentSettingsSheet> createState() => _PaymentSettingsSheetState();
}

class _PaymentSettingsSheetState extends State<PaymentSettingsSheet> {
  late final TextEditingController _phoneController;
  late final TextEditingController _upiController;
  late final TextEditingController _bankDetailsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController =
        TextEditingController(text: widget.initialSettings.phoneNumber);
    _upiController = TextEditingController(text: widget.initialSettings.upiId);
    _bankDetailsController =
        TextEditingController(text: widget.initialSettings.bankDetails);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _upiController.dispose();
    _bankDetailsController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newSettings = UserPaymentSettings(
        phoneNumber: _phoneController.text.trim(),
        upiId: _upiController.text.trim(),
        bankDetails: _bankDetailsController.text.trim(),
      );

      await PaymentService().updatePaymentSettings(newSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating payment settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Settings',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Phone Number
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
              helperText: 'Used for WhatsApp and UPI payments',
            ),
          ),
          const SizedBox(height: 16),

          // UPI ID
          TextFormField(
            controller: _upiController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'UPI ID',
              prefixIcon: Icon(Icons.account_balance_wallet),
              helperText: 'Your UPI ID for receiving payments',
            ),
          ),
          const SizedBox(height: 16),

          // Bank Details
          TextFormField(
            controller: _bankDetailsController,
            keyboardType: TextInputType.multiline,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bank Details',
              prefixIcon: Icon(Icons.account_balance),
              helperText: 'Account number, IFSC, etc.',
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Payment Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
