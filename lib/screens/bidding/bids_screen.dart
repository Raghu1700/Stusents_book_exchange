import 'package:flutter/material.dart';
import 'package:rive_animation/model/bid.dart';
import 'package:rive_animation/model/book.dart';
import 'package:rive_animation/services/bid_service.dart';
import 'package:rive_animation/services/book_service.dart';
import 'package:rive_animation/components/animated_background.dart';
import 'package:intl/intl.dart';

class BidsScreen extends StatefulWidget {
  const BidsScreen({Key? key}) : super(key: key);

  @override
  State<BidsScreen> createState() => _BidsScreenState();
}

class _BidsScreenState extends State<BidsScreen>
    with SingleTickerProviderStateMixin {
  final BidService _bidService = BidService();
  final BookService _bookService = BookService();

  late TabController _tabController;

  List<Bid> _myBids = [];
  List<Bid> _receivedBids = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBids();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBids() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load bids placed by the current user
      final myBids = await _bidService.getUserBids();

      // Load bids received on books the user is selling
      final receivedBids = await _bidService.getReceivedBids();

      if (mounted) {
        setState(() {
          _myBids = myBids;
          _receivedBids = receivedBids;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading bids. Please try again.';
        _isLoading = false;
      });
      print('Error loading bids: $e');
    }
  }

  Future<void> _handleBidAction(Bid bid, String action) async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;

      if (action == 'accept' || action == 'reject') {
        success = await _bidService.updateBidStatus(bid.id!, action);
      } else if (action == 'delete') {
        success = await _bidService.deleteBid(bid.id!);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'accept'
                  ? 'Bid accepted successfully!'
                  : action == 'reject'
                      ? 'Bid rejected'
                      : 'Bid deleted',
            ),
            backgroundColor: action == 'accept' ? Colors.green : Colors.orange,
          ),
        );

        // Reload bids
        _loadBids();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to ${action} bid. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again later.';
      });
      print('Error in _handleBidAction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bids'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Bids I Made'),
            Tab(text: 'Bids Received'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadBids,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : AnimatedBackground(
                  blurSigma: 25.0,
                  overlayColor: Colors.white.withOpacity(0.3),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Bids I Made Tab
                      _myBids.isEmpty
                          ? _buildEmptyState(
                              'You haven\'t placed any bids yet.')
                          : _buildBidsList(_myBids, 'my'),

                      // Bids Received Tab
                      _receivedBids.isEmpty
                          ? _buildEmptyState(
                              'You haven\'t received any bids on your books yet.')
                          : _buildBidsList(_receivedBids, 'received'),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Bids Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadBids,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidsList(List<Bid> bids, String type) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );

    return RefreshIndicator(
      onRefresh: _loadBids,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: bids.length,
        itemBuilder: (context, index) {
          final bid = bids[index];

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
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book title and bid amount
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          bid.bookTitle,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 8),

                  // Bid details
                  if (type == 'my')
                    Text(
                      'Placed on ${_formatDate(bid.createdAt.toDate())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Text(
                      'From: ${bid.bidderName} (${_formatDate(bid.createdAt.toDate())})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                  const SizedBox(height: 4),

                  if (bid.message != null && bid.message!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Message: ${bid.message}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Status chip
                  Container(
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

                  const SizedBox(height: 16),

                  // Action buttons
                  if (type == 'received' && bid.status == 'pending')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _handleBidAction(bid, 'reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _handleBidAction(bid, 'accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Accept'),
                        ),
                      ],
                    )
                  else if (type == 'my' && bid.status == 'pending')
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () => _handleBidAction(bid, 'delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Cancel Bid'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} mins ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final formatter = DateFormat('MMM d, yyyy');
      return formatter.format(date);
    }
  }
}
