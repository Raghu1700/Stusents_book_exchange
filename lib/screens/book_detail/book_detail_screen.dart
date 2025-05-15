import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../model/course.dart';

// Simple enum for our internal use
enum LaunchMode {
  externalApplication,
}

class BookDetailScreen extends StatefulWidget {
  final Course book;

  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final TextEditingController _bidController = TextEditingController();
  bool _isPlacingBid = false;
  final List<Bid> _bids = [];

  @override
  void initState() {
    super.initState();
    _loadSampleBids();
  }

  void _loadSampleBids() {
    final price = widget.book.price;
    if (price.startsWith('₹')) {
      final priceValue = double.tryParse(price.substring(1)) ?? 0.0;
      // Generate some sample bids
      _bids.add(
        Bid(
          amount: (priceValue * 0.85).toStringAsFixed(2),
          bidder: "Alex Johnson",
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          status: BidStatus.pending,
        ),
      );
      _bids.add(
        Bid(
          amount: (priceValue * 0.8).toStringAsFixed(2),
          bidder: "Emily Williams",
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          status: BidStatus.accepted,
        ),
      );
      _bids.add(
        Bid(
          amount: (priceValue * 0.75).toStringAsFixed(2),
          bidder: "Michael Brown",
          timestamp: DateTime.now().subtract(const Duration(days: 4)),
          status: BidStatus.rejected,
        ),
      );
    }
  }

  void _placeBid() {
    if (_bidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bid amount')),
      );
      return;
    }

    final bidAmount = double.tryParse(_bidController.text);
    if (bidAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _isPlacingBid = true;
    });

    // Simulate network delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _bids.insert(
            0,
            Bid(
              amount: bidAmount.toStringAsFixed(2),
              bidder: "You (John Doe)",
              timestamp: DateTime.now(),
              status: BidStatus.pending,
            ),
          );
          _isPlacingBid = false;
          _bidController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your bid has been placed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showPaymentDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PaymentDetailsSheet(book: widget.book),
    );
  }

  Future<void> _contactSellerOnWhatsApp() async {
    final phone = widget.book.sellerPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Seller\'s WhatsApp number is not available')),
      );
      return;
    }

    final whatsappUrl =
        'https://wa.me/+91$phone?text=Hi, I am interested in your book "${widget.book.title}" listed for ${widget.book.price} on the Student Book Exchange app.';

    try {
      // Display a dialog instead of launching WhatsApp
      _showWhatsAppDialog(context, whatsappUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showWhatsAppDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact via WhatsApp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('To contact the seller via WhatsApp, use this link:'),
            const SizedBox(height: 12),
            Text(url, style: const TextStyle(color: Colors.blue)),
            const SizedBox(height: 12),
            const Text('Copy the link and open it in your browser.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
            child: const Text('Copy Link'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to favorites')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book header
            Container(
              padding: const EdgeInsets.all(16),
              color: widget.book.color.withOpacity(0.15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      color: widget.book.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        widget.book.iconSrc,
                        width: 60,
                        height: 60,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Subject: ${widget.book.subject}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          "Class: ${widget.book.bookClass}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              widget.book.price,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: widget.book.color,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _showPaymentDetails,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.payment),
                                  label: const Text('Pay'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _contactSellerOnWhatsApp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                        0xFF25D366), // WhatsApp green
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.chat),
                                  label: const Text('WhatsApp'),
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

            // Book details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Seller Information",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    title: Text(widget.book.seller),
                    subtitle: const Text("Rating: ★★★★☆ (4.2)"),
                  ),
                  const Divider(),
                  Text(
                    "Description",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.book.description ??
                        "No description provided for this book.",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Condition: ${widget.book.condition ?? 'Not specified'}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),

                  // Bidding section
                  Text(
                    "Place a Bid",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bidController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Your Bid Amount (INR)',
                            prefixIcon: Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(),
                            hintText: 'Enter your bid',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isPlacingBid ? null : _placeBid,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.book.color,
                            disabledBackgroundColor:
                                widget.book.color.withOpacity(0.5),
                          ),
                          child: _isPlacingBid
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Place Bid'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bids list
                  Text(
                    "Bids (${_bids.length})",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _bids.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              'No bids yet. Be the first to bid!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _bids.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final bid = _bids[index];
                            return ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    '₹${bid.amount}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bid.status == BidStatus.accepted
                                          ? Colors.green
                                          : bid.status == BidStatus.rejected
                                              ? Colors.red
                                              : Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      bid.status.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${bid.bidder} • ${_formatDate(bid.timestamp)}',
                              ),
                              trailing: bid.bidder.startsWith('You')
                                  ? const Icon(
                                      Icons.person_pin_circle,
                                      color: Colors.blue,
                                    )
                                  : null,
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class PaymentDetailsSheet extends StatelessWidget {
  final Course book;

  const PaymentDetailsSheet({Key? key, required this.book}) : super(key: key);

  Future<void> _launchWhatsApp(BuildContext context) async {
    final phone = book.sellerPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Seller\'s WhatsApp number is not available')),
      );
      return;
    }

    final whatsappUrl =
        'https://wa.me/+91$phone?text=Hi, I am interested in your book "${book.title}" listed for ${book.price} on the Student Book Exchange app. I would like to proceed with the payment.';

    try {
      // Display a dialog instead of launching WhatsApp
      _showWhatsAppDialog(context, whatsappUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showWhatsAppDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact via WhatsApp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('To contact the seller via WhatsApp, use this link:'),
            const SizedBox(height: 12),
            Text(url, style: const TextStyle(color: Colors.blue)),
            const SizedBox(height: 12),
            const Text('Copy the link and open it in your browser.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
            child: const Text('Copy Link'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Details',
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
          Text(
            'Book: ${book.title}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Price: ${book.price}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),

          // Seller Information
          Text(
            'Seller Information',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          _buildInfoItem(Icons.person, 'Name', book.seller),
          if (book.sellerPhone != null)
            _buildInfoItem(Icons.phone, 'Phone', book.sellerPhone!),
          const SizedBox(height: 10),

          // Payment Options
          Text(
            'Payment Options',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),

          // UPI Option
          if (book.sellerUPI != null)
            _buildPaymentOption(
              context,
              Icons.account_balance_wallet,
              'UPI Payment',
              book.sellerUPI!,
              Colors.purple.shade100,
            ),

          const SizedBox(height: 10),

          // Bank Transfer Option
          if (book.bankDetails != null)
            _buildPaymentOption(
              context,
              Icons.account_balance,
              'Bank Transfer',
              book.bankDetails!,
              Colors.blue.shade100,
            ),

          const SizedBox(height: 20),

          // Contact on WhatsApp button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchWhatsApp(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // WhatsApp green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.chat),
              label: const Text('Contact Seller on WhatsApp'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    IconData icon,
    String title,
    String details,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(details),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: details));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class Bid {
  final String amount;
  final String bidder;
  final DateTime timestamp;
  final BidStatus status;

  Bid({
    required this.amount,
    required this.bidder,
    required this.timestamp,
    this.status = BidStatus.pending,
  });
}

enum BidStatus { pending, accepted, rejected }
