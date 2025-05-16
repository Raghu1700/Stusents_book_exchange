import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rive_animation/model/book.dart';
import 'package:rive_animation/services/bid_service.dart';
import 'package:rive_animation/utils/avatar_generator.dart';
import 'package:rive_animation/components/animated_background.dart';
import 'package:rive_animation/components/animated_button.dart';

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
      final bidId = await _bidService.placeBid(
        bookId: widget.book.id!,
        bookTitle: widget.book.title,
        bidAmount: amount,
      );

      if (!mounted) return;

      if (bidId != null) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to place bid. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
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
                  AnimatedButton(
                    onPressed: _submitBid,
                    text: 'Submit Bid',
                    icon: Icons.gavel,
                    isLoading: _isSubmitting,
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
