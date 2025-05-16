import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rive_animation/services/book_service.dart';
import 'package:rive_animation/components/animated_background.dart';
import 'package:rive_animation/components/animated_button.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({Key? key}) : super(key: key);

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _sellerPhoneController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedCategory = 'Textbook';
  String _selectedCondition = 'Good';
  String _selectedGrade = 'All';

  final List<String> _categories = [
    'Textbook',
    'Reference',
    'Guide',
    'Novel',
    'Other'
  ];

  final List<String> _conditions = [
    'New',
    'Like New',
    'Very Good',
    'Good',
    'Fair',
    'Poor'
  ];

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

  final List<String> _subjects = [
    'Mathematics',
    'Science',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'Hindi',
    'Social Studies',
    'History',
    'Geography',
    'Computer Science',
    'Economics',
    'Business Studies',
    'Accountancy',
    'Other'
  ];

  String _selectedSubject = 'Mathematics';

  bool _isLoading = false;
  String _errorMessage = '';
  final BookService _bookService = BookService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _sellerPhoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        fontFamily: 'Intel',
        color: Colors.grey[700],
      ),
      hintStyle: TextStyle(
        fontFamily: 'Intel',
        color: Colors.grey[500],
      ),
      prefixIcon: Icon(
        icon,
        color: Theme.of(context).primaryColor,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.red.withOpacity(0.5),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
      errorStyle: const TextStyle(
        fontFamily: 'Intel',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Book'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBackground(
        blurSigma: 25.0,
        overlayColor: Colors.white.withOpacity(0.3),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text(
                            'Sell Your Book',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fill in the details of your book to list it for sale',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Intel',
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),

                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Book Title
                                TextFormField(
                                  controller: _titleController,
                                  style: const TextStyle(
                                    fontFamily: 'Intel',
                                    fontSize: 16,
                                  ),
                                  decoration: _buildInputDecoration(
                                    label: 'Book Title',
                                    icon: Icons.book,
                                    hint: 'Enter the book title',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter the book title';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Author
                                TextFormField(
                                  controller: _authorController,
                                  style: const TextStyle(
                                    fontFamily: 'Intel',
                                    fontSize: 16,
                                  ),
                                  decoration: _buildInputDecoration(
                                    label: 'Author',
                                    icon: Icons.person,
                                    hint: 'Enter the author\'s name',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter the author name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Category Dropdown
                                DropdownButtonFormField<String>(
                                  decoration: _buildInputDecoration(
                                    label: 'Book Type',
                                    icon: Icons.category,
                                  ),
                                  value: _selectedCategory,
                                  style: const TextStyle(
                                    fontFamily: 'Intel',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedCategory = newValue!;
                                    });
                                  },
                                  items: _categories
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: const TextStyle(
                                          fontFamily: 'Intel',
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),

                                // Subject Dropdown
                                DropdownButtonFormField<String>(
                                  decoration: _buildInputDecoration(
                                    label: 'Subject',
                                    icon: Icons.subject,
                                  ),
                                  value: _selectedSubject,
                                  style: const TextStyle(
                                    fontFamily: 'Intel',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedSubject = newValue!;
                                    });
                                  },
                                  items: _subjects
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: const TextStyle(
                                          fontFamily: 'Intel',
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),

                                // Grade Level Dropdown
                                DropdownButtonFormField<String>(
                                  decoration: _buildInputDecoration(
                                    label: 'Grade Level',
                                    icon: Icons.school,
                                  ),
                                  value: _selectedGrade,
                                  style: const TextStyle(
                                    fontFamily: 'Intel',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedGrade = newValue!;
                                    });
                                  },
                                  items: _grades.map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: const TextStyle(
                                          fontFamily: 'Intel',
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),

                                // Condition Dropdown
                                DropdownButtonFormField<String>(
                                  decoration: _buildInputDecoration(
                                    label: 'Book Condition',
                                    icon: Icons.assignment_turned_in,
                                  ),
                                  value: _selectedCondition,
                                  style: const TextStyle(
                                    fontFamily: 'Intel',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedCondition = newValue!;
                                    });
                                  },
                                  items: _conditions
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: const TextStyle(
                                          fontFamily: 'Intel',
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),

                                // Description
                                TextFormField(
                                  controller: _descriptionController,
                                  style: const TextStyle(
                                    fontFamily: 'Intel',
                                    fontSize: 16,
                                  ),
                                  maxLines: 3,
                                  decoration: _buildInputDecoration(
                                    label: 'Description',
                                    icon: Icons.description,
                                    hint: 'Enter book description',
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Price
                                TextFormField(
                                  controller: _priceController,
                                  style: const TextStyle(
                                    fontFamily: 'Intel',
                                    fontSize: 16,
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  decoration: _buildInputDecoration(
                                    label: 'Price',
                                    icon: Icons.currency_rupee,
                                    hint: 'Enter the price',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter the price';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Phone Number
                                TextFormField(
                                  controller: _sellerPhoneController,
                                  style: const TextStyle(
                                    fontFamily: 'Intel',
                                    fontSize: 16,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  decoration: _buildInputDecoration(
                                    label: 'Contact Number',
                                    icon: Icons.phone,
                                    hint: 'Enter your WhatsApp number',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your phone number';
                                    }
                                    if (value.length < 10) {
                                      return 'Please enter a valid phone number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),

                                // Submit Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: _submitForm,
                                    icon: const Icon(Icons.add_circle),
                                    label: const Text(
                                      'PUBLISH BOOK',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),

                                if (_errorMessage.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontFamily: 'Intel',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

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
          coverImage: null,
          subject: _selectedSubject,
        );

        if (bookId != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Book added successfully!',
                style: TextStyle(
                  fontFamily: 'Intel',
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Clear form
          _titleController.clear();
          _authorController.clear();
          _descriptionController.clear();
          _priceController.clear();
          _sellerPhoneController.clear();
          setState(() {
            _isLoading = false;
            _selectedCategory = 'Textbook';
            _selectedCondition = 'Good';
            _selectedGrade = 'All';
            _selectedSubject = 'Mathematics';
          });
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
}
