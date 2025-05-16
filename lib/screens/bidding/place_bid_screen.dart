import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rive_animation/model/book.dart';
import 'package:rive_animation/services/bid_service.dart';
import 'package:rive_animation/utils/avatar_generator.dart';
import 'package:rive_animation/components/animated_background.dart';
import 'package:rive_animation/components/animated_button.dart';
import 'package:rive_animation/screens/bidding/bids_screen.dart';

class PlaceBidScreen extends StatefulWidget {
  final Book book;

  const PlaceBidScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<PlaceBidScreen> createState() => _PlaceBidScreenState();
}

class _PlaceBidScreenState extends State<PlaceBidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bidController = TextEditingController();
  final _messageController = TextEditingController();
  final _bidderPhoneController = TextEditingController();

  final BidService _bidService = BidService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _bidController.text = widget.book.price.toString(); // Default to book price
  }

  @override
  void dispose() {
    _bidController.dispose();
    _messageController.dispose();
    _bidderPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitBid() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_bidController.text);
      final message = _messageController.text.trim();
      final phone = _bidderPhoneController.text.trim();

      // Debug print all data before submitting
      debugPrint('======== SUBMITTING BID ========');
      debugPrint('Book ID: ${widget.book.id}');
      debugPrint('Book Title: ${widget.book.title}');
      debugPrint('Bid Amount: $amount');
      debugPrint('Message: $message');
      debugPrint('Phone: $phone');

      // Place the bid
      final bidId = await _bidService.placeBid(
        bookId: widget.book.id!,
        bookTitle: widget.book.title,
        bidAmount: amount,
        message: message,
        bidderPhone: phone,
      );

      if (!mounted) return;

      // Check if bid was successful
      if (bidId != null) {
        debugPrint('Bid placed successfully with ID: $bidId');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Bid placed successfully! Redirecting to your Bids page...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Delay to allow Firestore to sync
        await Future.delayed(const Duration(seconds: 1));

        // Force refresh bid service to notify listeners
        _bidService.notifyBookUpdate();

        // Navigate to bids screen with replacement to ensure fresh page
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BidsScreen()),
            (route) => route.isFirst, // Keep only the first route in the stack
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to place bid. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _submitBid: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place a Bid'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBackground(
        blurSigma: 25.0,
        overlayColor: Colors.white.withOpacity(0.3),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Info Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Book Cover
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 80,
                              height: 120,
                              child: AvatarGenerator.buildAnimatedAvatar(
                                widget.book.title,
                                size: 80,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Book Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.book.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'by ${widget.book.author}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Listed price: ₹${widget.book.price.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bid Amount Field
                  Text(
                    'Your Bid Amount',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bidController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter your bid amount',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a bid amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null) {
                        return 'Please enter a valid amount';
                      }
                      if (amount <= 0) {
                        return 'Bid amount must be greater than 0';
                      }
                      if (amount >= widget.book.price) {
                        return 'Bid must be less than the listed price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Phone Number
                  TextFormField(
                    controller: _bidderPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Your Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      hintText: 'Enter your phone number for contact',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message
                  TextFormField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Message (Optional)',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.message),
                      hintText: 'Add any details about your bid',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitBid,
                      icon: const Icon(Icons.gavel),
                      label: _isSubmitting
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text("Submitting..."),
                              ],
                            )
                          : const Text("Submit Bid"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
