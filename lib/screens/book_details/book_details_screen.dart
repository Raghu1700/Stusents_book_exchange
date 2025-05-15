import 'package:flutter/material.dart';
import 'package:rive_animation/model/book.dart';
import 'package:rive_animation/services/book_service.dart';
import 'package:intl/intl.dart';
import 'package:rive_animation/screens/bidding/place_bid_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive_animation/services/bid_service.dart';
import 'package:rive_animation/model/bid.dart';
import 'package:rive_animation/utils/avatar_generator.dart';

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

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    _checkOwnership();
    if (widget.book.id != null) {
      _checkBidsStatus();
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
    if (widget.book.sellerPhone != null &&
        widget.book.sellerPhone!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contact seller at: ${widget.book.sellerPhone}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No contact information available'),
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
                        symbol: '\$',
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
      symbol: '\$',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _isBookmarked ? Icons.favorite : Icons.favorite_border,
                    color: _isBookmarked ? Colors.red : Colors.white,
                  ),
            onPressed: _isLoading ? null : _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareBook,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Image - Replace with Animated Avatar
            SizedBox(
              width: double.infinity,
              height: 250,
              child: Center(
                child: AvatarGenerator.buildAnimatedAvatar(
                  widget.book.title,
                  size: 200,
                ),
              ),
            ),

            // Book Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.book.title,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Author
                  Text(
                    'by ${widget.book.author}',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Price, Grade, and Condition
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            formatter.format(widget.book.price),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Grade
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Grade: ${widget.book.grade}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Condition
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getConditionColor(widget.book.condition),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.book.condition,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.book.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Seller Information
                  Text(
                    'Seller Information',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                widget.book.sellerName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Contact through GPay:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.book.sellerPhone ??
                                'No phone number provided',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _contactSeller,
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Contact Seller'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Show different buttons based on user role
                              if (_isOwner && _hasBids)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _showBids,
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('View Bids'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      side:
                                          const BorderSide(color: Colors.blue),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                )
                              else if (!_isOwner)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _navigateToPlaceBid,
                                    icon: const Icon(Icons.attach_money),
                                    label: const Text('Place a Bid'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).primaryColor,
                                      side: BorderSide(
                                          color:
                                              Theme.of(context).primaryColor),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
