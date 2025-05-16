import 'package:flutter/material.dart';
import 'package:rive_animation/model/book.dart';
import 'package:rive_animation/services/book_service.dart';
import 'package:rive_animation/services/auth_service.dart';
import 'package:rive_animation/services/bid_service.dart';
import 'package:rive_animation/model/bid.dart';
import 'package:rive_animation/screens/bidding/place_bid_screen.dart';
import 'package:rive_animation/utils/avatar_generator.dart';
import 'package:rive_animation/components/animated_background.dart';
import 'package:rive_animation/components/animated_button.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive_animation/main.dart' show authService;

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final BookService _bookService = BookService();
  final BidService _bidService = BidService();
  bool _isBookmarked = false;
  bool _isLoading = true;
  bool _isOwner = false;
  bool _hasBids = false;
  List<Bid> _bids = [];
  String? _currentUserPhone;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    _checkOwnership();
    _loadCurrentUserPhone();
    if (widget.book.id != null) {
      _checkBidsStatus();
    }
  }

  Future<void> _loadCurrentUserPhone() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final userData = await authService.getUserData(currentUser.uid);
        if (userData != null && mounted) {
          setState(() {
            _currentUserPhone = userData['phoneNumber'];
          });
        }
      } catch (e) {
        print('Error loading user phone: $e');
      }
    }
  }

  Future<void> _checkBookmarkStatus() async {
    if (widget.book.id != null) {
      try {
        final isBookmarked = await _bookService.isBookmarked(widget.book.id!);
        if (mounted) {
          setState(() {
            _isBookmarked = isBookmarked;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error checking bookmark status: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkOwnership() async {
    if (widget.book.id != null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && widget.book.sellerId == currentUser.uid) {
        setState(() {
          _isOwner = true;
        });
      }
    }
  }

  Future<void> _checkBidsStatus() async {
    try {
      final bids = await _bidService.getBidsForBook(widget.book.id!);
      if (mounted) {
        setState(() {
          _hasBids = bids.isNotEmpty;
          _bids = bids;
        });
      }
    } catch (e) {
      print('Error checking bids status: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    if (widget.book.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isBookmarked) {
        success = await _bookService.removeBookmark(widget.book.id!);
      } else {
        success = await _bookService.bookmarkBook(widget.book.id!);
      }

      if (success && mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBookmarked
                ? 'Book added to favorites'
                : 'Book removed from favorites'),
            backgroundColor: _isBookmarked ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _contactSeller() async {
    String? phoneNumber = widget.book.sellerPhone;

    // If seller phone is not provided, use the current user's phone
    if (phoneNumber == null || phoneNumber.isEmpty) {
      phoneNumber = _currentUserPhone;
    }

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final bookTitle = widget.book.title;
      final price = NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 2,
      ).format(widget.book.price);

      // Create SMS URI
      final uri = Uri.parse(
          'sms:$phoneNumber?body=Hi, I am interested in your book "$bookTitle" priced at $price on the Student Book Exchange app.');

      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          // Fallback if SMS can't be launched
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Contact seller at: $phoneNumber'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error launching SMS: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending SMS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No contact information available. Please update your profile with a phone number.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _contactSellerWhatsApp() async {
    String? phoneNumber = widget.book.sellerPhone;

    // If seller phone is not provided, use the current user's phone
    if (phoneNumber == null || phoneNumber.isEmpty) {
      phoneNumber = _currentUserPhone;
    }

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // Format phone number - remove any spaces or special characters
      phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // Add country code if not present (assuming Indian numbers)
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '91$phoneNumber';
      }

      final bookTitle = widget.book.title;
      final price = NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 2,
      ).format(widget.book.price);

      // Create WhatsApp URI
      final message =
          'Hi, I am interested in your book "$bookTitle" priced at $price on the Student Book Exchange app.';
      final encodedMessage = Uri.encodeComponent(message);
      final uri = Uri.parse('https://wa.me/$phoneNumber?text=$encodedMessage');

      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not launch WhatsApp'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Error launching WhatsApp: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening WhatsApp: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No contact information available. Please update your profile with a phone number.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _shareBook() {
    final message =
        'Check out this book: "${widget.book.title}" by ${widget.book.author}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share: $message'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _navigateToPlaceBid() async {
    if (widget.book.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot place bid on this book'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceBidScreen(book: widget.book),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your bid has been submitted to the seller!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showBids() async {
    if (widget.book.id == null || !_isOwner) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bids for "${widget.book.title}"',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_bids.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.currency_exchange,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Bids Yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'There are no bids on this book yet.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _bids.length,
                    itemBuilder: (context, index) {
                      final bid = _bids[index];
                      final formatter = NumberFormat.currency(
                        symbol: '₹',
                        decimalDigits: 2,
                      );

                      // Determine color based on status
                      Color statusColor;
                      switch (bid.status) {
                        case 'accepted':
                          statusColor = Colors.green;
                          break;
                        case 'rejected':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.orange;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bidder and amount
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            bid.bidderName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      formatter.format(bid.bidAmount),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Message
                              if (bid.message != null &&
                                  bid.message!.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8, left: 36),
                                  child: Text(
                                    'Message: ${bid.message}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),

                              // Phone number
                              if (bid.bidderPhone != null &&
                                  bid.bidderPhone!.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, left: 36),
                                  child: Text(
                                    'Phone: ${bid.bidderPhone}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),

                              // Status chip
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, left: 36),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    bid.status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              // Action buttons for pending bids
                              if (bid.status == 'pending')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () async {
                                          await _bidService.updateBidStatus(
                                              bid.id!, 'reject');
                                          Navigator.pop(context);
                                          _checkBidsStatus();
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          minimumSize: const Size(0, 36),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await _bidService.updateBidStatus(
                                              bid.id!, 'accepted');
                                          Navigator.pop(context);
                                          _checkBidsStatus();

                                          // Show message
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Bid accepted! The book is now marked as sold.'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(0, 36),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                        ),
                                        child: const Text('Accept'),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ).then((_) {
      // Refresh data when returning
      if (widget.book.id != null) {
        _checkBidsStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );

    return Scaffold(
      body: AnimatedBackground(
        blurSigma: 25.0,
        overlayColor: Colors.white.withOpacity(0.3),
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 400,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.1),
                              Colors.white.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Hero(
                          tag: widget.book.id ?? widget.book.title,
                          child: AvatarGenerator.buildAnimatedAvatar(
                            widget.book.title,
                            size: 300,
                          ),
                        ),
                      ),
                    ),
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.black87,
                      ),
                    ),
                    actions: [
                      if (!_isOwner)
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isBookmarked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  _isBookmarked ? Colors.red : Colors.black87,
                            ),
                            onPressed: _isLoading ? null : _toggleBookmark,
                          ),
                        ),
                    ],
                  ),

                  // Book Details
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.book.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Author
                          Text(
                            'by ${widget.book.author}',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontFamily: 'Intel',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Price
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              formatter.format(widget.book.price),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Description
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.book.description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.5,
                              fontFamily: 'Intel',
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Details Section
                          Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Condition', widget.book.condition),
                          _buildDetailRow('Category', widget.book.category),
                          _buildDetailRow('Grade', widget.book.grade),
                          const SizedBox(height: 24),

                          // Seller Information Section
                          Text(
                            'Seller Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Name', widget.book.sellerName),
                          if (widget.book.sellerPhone != null &&
                              widget.book.sellerPhone!.isNotEmpty)
                            _buildDetailRow('Phone', widget.book.sellerPhone!),
                          const SizedBox(
                              height: 100), // Space for bottom buttons
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Action Buttons
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: !_isOwner
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _navigateToPlaceBid,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.currency_rupee, size: 24),
                              label: const Text(
                                'Place Your Bid',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _contactSellerWhatsApp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF25D366), // WhatsApp green
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.chat, size: 24),
                              label: const Text(
                                'Contact Seller on WhatsApp',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ElevatedButton.icon(
                          onPressed: _showBids,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.currency_exchange, size: 24),
                          label: Text(
                            _hasBids
                                ? 'View Bids (${_bids.length})'
                                : 'No Bids Yet',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Intel',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Intel',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'like new':
        return Colors.green.shade700;
      case 'very good':
        return Colors.blue;
      case 'good':
        return Colors.blue.shade700;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
