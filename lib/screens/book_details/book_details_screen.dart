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
      debugPrint('Checking bids status for book: ${widget.book.id}');
      final bids = await _bidService.getBidsForBook(widget.book.id!);

      // Check if current user has placed any bids
      final currentUser = FirebaseAuth.instance.currentUser;
      final userHasBid = currentUser != null &&
          bids.any((bid) => bid.bidderId == currentUser.uid);

      if (mounted) {
        setState(() {
          _hasBids = userHasBid || bids.isNotEmpty;
          _bids = bids;
        });
      }
      debugPrint(
          'Checked bids status: Has bids = $_hasBids, User has bid = $userHasBid, Total bids: ${bids.length}');
    } catch (e) {
      debugPrint('Error checking bids status: $e');
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
      try {
        // Format phone number - remove any spaces or special characters
        phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

        // Add country code if not present (assuming Indian numbers)
        if (!phoneNumber.startsWith('+')) {
          if (phoneNumber.startsWith('91')) {
            phoneNumber = '+$phoneNumber';
          } else {
            phoneNumber = '+91$phoneNumber';
          }
        }

        print('Formatted phone number: $phoneNumber');

        final bookTitle = widget.book.title;
        final price = NumberFormat.currency(
          symbol: '₹',
          decimalDigits: 2,
        ).format(widget.book.price);

        // Create WhatsApp URI - Use wa.me format which is more reliable
        final message =
            'Hi, I am interested in your book "$bookTitle" priced at $price on the Student Book Exchange app.';
        final encodedMessage = Uri.encodeComponent(message);

        // Remove the + from the phone number for wa.me links
        final waPhoneNumber = phoneNumber.replaceAll('+', '');
        final uri =
            Uri.parse('https://wa.me/$waPhoneNumber?text=$encodedMessage');

        print('Launching WhatsApp with URI: $uri');

        if (await canLaunchUrl(uri)) {
          final launched =
              await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (!launched) {
            _showWhatsAppError(
                'Could not launch WhatsApp. Please make sure WhatsApp is installed.');
          }
        } else {
          _showWhatsAppError('WhatsApp is not available on this device.');
        }
      } catch (e) {
        print('Error launching WhatsApp: $e');
        _showWhatsAppError('Error: $e');
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

  void _showWhatsAppError(String message) {
    if (mounted) {
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

  Future<void> _removeBook() async {
    if (widget.book.id == null || !_isOwner) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Book'),
        content: const Text(
          'Are you sure you want to remove this book? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _bookService.deleteBook(widget.book.id!);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book successfully removed'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Go back to the previous screen
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove book. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error removing book: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        actions: [
          if (widget.book.id != null)
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.favorite : Icons.favorite_border,
                color: _isBookmarked ? Colors.red : Colors.white,
              ),
              onPressed: _toggleBookmark,
            ),
        ],
      ),
      body: AnimatedBackground(
        blurSigma: 25.0,
        overlayColor: Colors.white.withOpacity(0.3),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Image
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AvatarGenerator.buildAnimatedAvatar(
                      widget.book.title,
                      size: 200,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Book Details Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book Name
                      Text(
                        widget.book.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Book Details Table
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(2),
                        },
                        children: [
                          _buildTableRow('Class', widget.book.grade),
                          _buildTableRow('Subject', widget.book.category),
                          _buildTableRow(
                              'Price', formatter.format(widget.book.price)),
                          _buildTableRow('Condition', widget.book.condition),
                          _buildTableRow('Seller', widget.book.sellerName),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Contact buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text('SMS'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _contactSeller,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.message),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _contactSellerWhatsApp,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Place Bid Button
              if (!_isOwner && widget.book.id != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.gavel),
                    label: Text(_hasBids ? 'View Your Bid' : 'Place Bid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaceBidScreen(
                            book: widget.book,
                          ),
                        ),
                      ).then((_) {
                        // Refresh bid status when returning from place bid screen
                        debugPrint(
                            'Returned from bid screen, refreshing status');
                        _checkBidsStatus();

                        // Also notify bid service of update
                        _bidService.notifyBookUpdate();
                      });
                    },
                  ),
                ),

              // Book Owner Actions
              if (_isOwner && widget.book.id != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    // View Bids Button
                    if (_hasBids)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.attach_money),
                          label: const Text('View Bids'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _showBids,
                        ),
                      ),
                    if (_hasBids) const SizedBox(width: 16),
                    // Remove Book Button
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove Book'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _removeBook,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
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
