import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/book.dart';
import '../../services/favorites_service.dart';
import '../../services/user_service.dart';
import '../../model/user_payment_settings.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late Book book;
  final FavoritesService _favoritesService = FavoritesService();
  final UserService _userService = UserService();
  bool _isLoading = false;
  bool _isLoadingSeller = true;
  Map<String, dynamic>? _sellerInfo;
  UserPaymentSettings? _paymentSettings;

  @override
  void initState() {
    super.initState();
    book = widget.book;
    _checkFavoriteStatus();
    _loadSellerInfo();
  }

  Future<void> _loadSellerInfo() async {
    setState(() {
      _isLoadingSeller = true;
    });

    try {
      final sellerInfo = await _userService.getUserById(book.sellerId);
      final paymentSettings =
          await _userService.getUserPaymentSettings(book.sellerId);

      if (mounted) {
        setState(() {
          _sellerInfo = sellerInfo;
          _paymentSettings = paymentSettings;
          _isLoadingSeller = false;
        });
      }
    } catch (e) {
      print('Error loading seller info: $e');
      if (mounted) {
        setState(() {
          _isLoadingSeller = false;
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorite = await _favoritesService.isBookFavorite(book.id);
      if (mounted && isFavorite != book.isFavorite) {
        setState(() {
          book = book.copyWith(isFavorite: isFavorite);
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newStatus = await _favoritesService.toggleFavorite(book);

      if (mounted) {
        setState(() {
          book = book.copyWith(isFavorite: newStatus);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite status: $e')),
        );
      }
    }
  }

  // Open WhatsApp chat with the seller
  Future<void> _openWhatsAppChat() async {
    if (_paymentSettings == null || !_paymentSettings!.hasPhoneNumber) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller phone number not available')),
      );
      return;
    }

    String phoneNumber = _paymentSettings!.phoneNumber!;
    // Remove any spaces or special characters from the phone number
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Add country code if not present
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+91$phoneNumber'; // Assuming India country code
    }

    final whatsappUrl =
        'https://wa.me/$phoneNumber?text=Hello! I am interested in your book "${book.title}" listed on BookExchange app.';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open WhatsApp')),
          );
        }
      }
    } catch (e) {
      print('Error opening WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening WhatsApp: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          // Favorite button
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    book.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: book.isFavorite ? Colors.red : Colors.white,
                  ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book image
            book.imageUrl.isNotEmpty
                ? Image.network(
                    book.imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child:
                        const Icon(Icons.book, size: 100, color: Colors.grey),
                  ),

            // Book details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and author
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by ${book.author}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price and condition
                  Row(
                    children: [
                      Text(
                        '\$${book.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getConditionColor(book.condition),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          book.condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Seller information
                  const Text(
                    'Seller Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _isLoadingSeller
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(_sellerInfo?['displayName'] ??
                                  'Unknown Seller'),
                              subtitle: Text(_sellerInfo?['email'] ??
                                  'No email available'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (_paymentSettings?.hasPhoneNumber == true)
                              ListTile(
                                leading: const Icon(Icons.phone),
                                title: Text(_paymentSettings!.phoneNumber!),
                                subtitle: const Text('Mobile number for GPay'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            const SizedBox(height: 16),

                            // Contact buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (_paymentSettings?.hasPhoneNumber == true)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.message),
                                    label: const Text('WhatsApp'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _openWhatsAppChat,
                                  ),
                              ],
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get color based on book condition
  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'like new':
        return Colors.teal;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
