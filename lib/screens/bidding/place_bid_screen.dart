import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rive_animation/model/book.dart';
import 'package:rive_animation/services/bid_service.dart';
import 'package:rive_animation/utils/avatar_generator.dart';

class PlaceBidScreen extends StatefulWidget {
  final Book book;

  const PlaceBidScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<PlaceBidScreen> createState() => _PlaceBidScreenState();
}

class _PlaceBidScreenState extends State<PlaceBidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bidAmountController = TextEditingController();
  final _messageController = TextEditingController();
  final _bidderPhoneController = TextEditingController();

  final BidService _bidService = BidService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _bidAmountController.text =
        widget.book.price.toString(); // Default to book price
  }

  @override
  void dispose() {
    _bidAmountController.dispose();
    _messageController.dispose();
    _bidderPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitBid() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final bidAmount =
            double.tryParse(_bidAmountController.text.trim()) ?? 0.0;

        final bidId = await _bidService.placeBid(
          bookId: widget.book.id!,
          bookTitle: widget.book.title,
          bidAmount: bidAmount,
          message: _messageController.text.trim(),
          bidderPhone: _bidderPhoneController.text.trim(),
        );

        setState(() {
          _isLoading = false;
        });

        if (bidId != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your bid has been placed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          setState(() {
            _errorMessage = 'Failed to place your bid. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred. Please try again later.';
        });
        print('Error in _submitBid: $e');
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book info section
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Book cover with animated avatar
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

                            // Book details
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
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Listed price: \$${widget.book.price.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Grade: ${widget.book.grade}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bid form
                    Text(
                      'Your Bid Information',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Bid Amount
                    TextFormField(
                      controller: _bidAmountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Your Bid Amount',
                        prefixIcon: Icon(Icons.attach_money),
                        hintText: 'Enter your bid amount',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a bid amount';
                        }

                        final amount = double.tryParse(value);
                        if (amount == null) {
                          return 'Please enter a valid number';
                        }

                        if (amount <= 0) {
                          return 'Bid amount must be greater than zero';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

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

                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitBid,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Place Bid',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Your bid will be sent to the seller for review',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
