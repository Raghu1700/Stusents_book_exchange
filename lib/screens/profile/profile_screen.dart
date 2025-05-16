import 'package:flutter/material.dart';
import 'package:rive_animation/main.dart' show authService;
import 'package:rive_animation/screens/onboding/onboding_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rive_animation/components/animated_background.dart';
import 'package:rive_animation/services/bid_service.dart';
import 'package:rive_animation/model/bid.dart';
import 'package:rive_animation/utils/whatsapp_launcher.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<Bid> _acceptedBids = [];
  List<Bid> _bidsAccepted = [];
  bool _loadingBids = false;
  final BidService _bidService = BidService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBids();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final currentUser = authService.getCurrentUser();

      if (currentUser != null) {
        // Get user data from Firestore
        final userData = await authService.getUserData(currentUser.uid);

        setState(() {
          _userData = userData;
          _isLoading = false;
        });

        print("User data loaded: $_userData");
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBids() async {
    setState(() {
      _loadingBids = true;
    });

    try {
      // Load bids you placed that were accepted
      final acceptedBids = await _bidService.getAcceptedUserBids();

      // Load bids you accepted from others
      final bidsAccepted = await _bidService.getAcceptedReceivedBids();

      setState(() {
        _acceptedBids = acceptedBids;
        _bidsAccepted = bidsAccepted;
        _loadingBids = false;
      });

      print(
          "Loaded ${_acceptedBids.length} accepted bids and ${_bidsAccepted.length} bids accepted");
    } catch (e) {
      print("Error loading bids: $e");
      setState(() {
        _loadingBids = false;
      });
    }
  }

  Future<void> _contactViaWhatsApp(
      String? phoneNumber, String bookTitle, double price) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No contact information available for this user.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final priceFormatted =
        NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(price);
    final message =
        'Hi, I\'m contacting you regarding the book "$bookTitle" priced at $priceFormatted on the Student Book Exchange app. Can we arrange the exchange?';

    await WhatsAppLauncher.launchWhatsApp(
      phoneNumber: phoneNumber,
      message: message,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Get current user information
    final currentUser = authService.getCurrentUser();
    if (currentUser == null) {
      return const SafeArea(
        child: Center(
          child: Text("Please log in to view your profile"),
        ),
      );
    }

    final userEmail = currentUser.email ?? 'No email';
    final fullName = _userData != null &&
            _userData!.containsKey('fullName') &&
            _userData!['fullName'] != null &&
            _userData!['fullName'].toString().isNotEmpty
        ? _userData!['fullName']
        : userEmail.split('@')[0];

    final userPhone = _userData != null &&
            _userData!.containsKey('phoneNumber') &&
            _userData!['phoneNumber'] != null
        ? _userData!['phoneNumber']
        : 'No phone number';

    return AnimatedBackground(
      blurSigma: 20.0,
      overlayColor: Colors.white.withOpacity(0.1),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: () async {
              await _loadUserData();
              await _loadBids();
            },
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                const SizedBox(height: 32),

                // Profile avatar and name
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    fullName.toString(),
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Username",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Username info card (showing the display name again for clarity)
                _buildInfoCard(
                  title: "Display Name",
                  value: fullName.toString(),
                  icon: Icons.person_outline,
                  subtitle: "Visible to other users",
                ),
                const SizedBox(height: 16),

                // Email info card
                _buildInfoCard(
                  title: "Email",
                  value: userEmail,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),

                // Phone info card
                _buildInfoCard(
                  title: "Phone Number",
                  value: userPhone,
                  icon: Icons.phone_outlined,
                  subtitle: "Used for WhatsApp contact",
                ),
                const SizedBox(height: 24),

                // Accepted Bids section
                _buildSectionHeader("Accepted Bids"),

                _loadingBids
                    ? const Center(child: CircularProgressIndicator())
                    : _acceptedBids.isEmpty
                        ? _buildEmptyState("No bids accepted yet")
                        : Column(
                            children: _acceptedBids
                                .map((bid) => _buildBidCard(
                                      bid: bid,
                                      isSeller: false,
                                      onContactPressed: () {
                                        // Try to get seller phone from the book document
                                        // For simplicity, this will just use whatever bidderPhone we have
                                        _contactViaWhatsApp(
                                          bid.bidderPhone,
                                          bid.bookTitle,
                                          bid.bidAmount,
                                        );
                                      },
                                    ))
                                .toList(),
                          ),

                const SizedBox(height: 24),

                // Bids You Accepted section
                _buildSectionHeader("Bids You Accepted"),

                _loadingBids
                    ? const Center(child: CircularProgressIndicator())
                    : _bidsAccepted.isEmpty
                        ? _buildEmptyState("You haven't accepted any bids yet")
                        : Column(
                            children: _bidsAccepted
                                .map((bid) => _buildBidCard(
                                      bid: bid,
                                      isSeller: true,
                                      onContactPressed: () {
                                        _contactViaWhatsApp(
                                          bid.bidderPhone,
                                          bid.bookTitle,
                                          bid.bidAmount,
                                        );
                                      },
                                    ))
                                .toList(),
                          ),

                const SizedBox(height: 32),

                // Logout Button
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidCard({
    required Bid bid,
    required bool isSeller,
    required VoidCallback onContactPressed,
  }) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bid.bookTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bid Amount: ${formatter.format(bid.bidAmount)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACCEPTED',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (bid.message != null && bid.message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Message: ${bid.message}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: onContactPressed,
                  icon: const Icon(Icons.message),
                  label: Text(isSeller ? 'Contact Buyer' : 'Contact Seller'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp green
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
