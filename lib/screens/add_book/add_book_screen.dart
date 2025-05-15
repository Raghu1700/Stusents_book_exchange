import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rive_animation/services/book_service.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({Key? key}) : super(key: key);

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _sellerPhoneController =
      TextEditingController(); // Add phone number for GPay

  // Fixed values to avoid potential issues
  final String _selectedCategory = 'Standard';
  final String _selectedCondition = 'Good';
  String _selectedGrade = 'All'; // Default grade

  // List of available grades
  final List<String> _grades = [
    'All',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12'
  ];

  File? _coverImage;
  bool _isLoading = false;
  String _errorMessage = '';
  final BookService _bookService = BookService();

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _coverImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      // Don't show error to user to avoid crashes
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        print('Starting book submission process...');
        // Get price - default to 0 if parsing fails
        final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
        print('Title: ${_titleController.text.trim()}');
        print('Author: ${_authorController.text.trim()}');
        print('Price: $price');
        print('Category: $_selectedCategory');
        print('Condition: $_selectedCondition');
        print('Grade: $_selectedGrade');
        print('Seller Phone: ${_sellerPhoneController.text.trim()}');

        // Add book with minimal required fields
        final bookId = await _bookService.addBook(
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          category: _selectedCategory,
          description: _descriptionController.text.trim(),
          price: price,
          condition: _selectedCondition,
          grade: _selectedGrade,
          sellerPhone: _sellerPhoneController.text.trim(),
          edition: '',
          isbn: '',
          coverImage: _coverImage,
        );

        print('Book submission result - bookId: $bookId');

        if (bookId != null) {
          print('Book was successfully added with ID: $bookId');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Book added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            // Reset form to prevent resubmission
            _titleController.clear();
            _authorController.clear();
            _descriptionController.clear();
            _priceController.clear();
            _sellerPhoneController.clear();
            setState(() {
              _coverImage = null;
              _isLoading = false;
            });

            // Don't try to pop this screen since it's in bottom navigation
            // Just stay on the screen with cleared form
          }
        } else {
          setState(() {
            _errorMessage = 'Book could not be added. Please try again.';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again later.';
          _isLoading = false;
        });
        print('Error in _submitForm: $e');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _sellerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Book'),
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
                    // Book Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.book),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the book title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Author
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the author name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Grade Level Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Grade Level',
                        prefixIcon: Icon(Icons.school),
                      ),
                      value: _selectedGrade,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedGrade = newValue!;
                        });
                      },
                      items:
                          _grades.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Seller Phone Number (for GPay)
                    TextFormField(
                      controller: _sellerPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (for GPay)',
                        prefixIcon: Icon(Icons.phone),
                        hintText: 'Enter number for buyers to contact you',
                      ),
                      validator: (value) {
                        // Allow empty phone for optional field
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Book Cover Image - Optional
                    Center(
                      child: TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Add Book Cover (Optional)'),
                      ),
                    ),
                    if (_coverImage != null)
                      Center(
                        child: Container(
                          width: 150,
                          height: 200,
                          margin: EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_coverImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

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
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Add Book',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
