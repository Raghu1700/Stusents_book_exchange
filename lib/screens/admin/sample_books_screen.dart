import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SampleBooksScreen extends StatefulWidget {
  const SampleBooksScreen({Key? key}) : super(key: key);

  @override
  State<SampleBooksScreen> createState() => _SampleBooksScreenState();
}

class _SampleBooksScreenState extends State<SampleBooksScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isSuccess = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _sampleBooks = [
    {
      'title': 'Data Structures and Algorithms',
      'author': 'Robert Sedgewick',
      'category': 'Computer Science',
      'description':
          'A comprehensive guide to data structures and algorithms, with examples in Java.',
      'price': 45.99,
      'condition': 'Good',
      'edition': '4th Edition',
      'isbn': '9780321573513',
      'coverImageUrl':
          'https://images.unsplash.com/photo-1544383835-bda2bc66a55d?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    },
    {
      'title': 'Introduction to Algorithms',
      'author': 'Thomas H. Cormen',
      'category': 'Computer Science',
      'description':
          'The bible of algorithms, used in computer science courses worldwide.',
      'price': 55.00,
      'condition': 'Like New',
      'edition': '3rd Edition',
      'isbn': '9780262033848',
      'coverImageUrl':
          'https://images.unsplash.com/photo-1532012197267-da84d127e765?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    },
    {
      'title': 'Calculus: Early Transcendentals',
      'author': 'James Stewart',
      'category': 'Mathematics',
      'description':
          'A classic calculus textbook covering single variable and multivariable calculus.',
      'price': 39.99,
      'condition': 'Good',
      'edition': '8th Edition',
      'isbn': '9781285741550',
      'coverImageUrl':
          'https://images.unsplash.com/photo-1565116175827-64847f972a3f?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    },
    {
      'title': 'Physics for Scientists and Engineers',
      'author': 'Raymond A. Serway',
      'category': 'Science',
      'description':
          'Comprehensive physics textbook with applications in science and engineering.',
      'price': 65.75,
      'condition': 'Fair',
      'edition': '9th Edition',
      'isbn': '9781133947271',
      'coverImageUrl':
          'https://images.unsplash.com/photo-1576094033020-68d8598108f1?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    },
    {
      'title': 'Organic Chemistry',
      'author': 'Paula Yurkanis Bruice',
      'category': 'Science',
      'description':
          'A student-centered approach to understanding organic chemistry concepts.',
      'price': 72.50,
      'condition': 'Very Good',
      'edition': '8th Edition',
      'isbn': '9780134042282',
      'coverImageUrl':
          'https://images.unsplash.com/photo-1578496479932-143df4a6659a?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    }
  ];

  Future<void> _addSampleBooks() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Adding sample books...';
      _isSuccess = false;
    });

    try {
      // Add each sample book to Firestore
      for (final book in _sampleBooks) {
        await _firestore.collection('book').add({
          'title': book['title'],
          'author': book['author'],
          'category': book['category'],
          'description': book['description'],
          'price': book['price'],
          'condition': book['condition'],
          'edition': book['edition'],
          'isbn': book['isbn'],
          'coverImageUrl': book['coverImageUrl'],
          'sellerId': 'sample_seller',
          'sellerName': 'Sample Seller',
          'sellerPhone': '123-456-7890',
          'createdAt': Timestamp.now(),
          'isAvailable': true,
          'tags': [book['category'], 'Sample']
        });

        // Update status message after adding each book
        setState(() {
          _statusMessage = 'Added book: ${book['title']}';
        });
        await Future.delayed(
            const Duration(milliseconds: 500)); // Short delay to see progress
      }

      setState(() {
        _statusMessage = 'All sample books added successfully!';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addSingleBook() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Adding a single test book...';
      _isSuccess = false;
    });

    try {
      // Add a simple test book
      await _firestore.collection('book').add({
        'title': 'Test Book',
        'author': 'Test Author',
        'category': 'Test Category',
        'description': 'This is a test book for debugging purposes.',
        'price': 9.99,
        'condition': 'New',
        'edition': '1st Edition',
        'isbn': '1234567890',
        'coverImageUrl': 'https://via.placeholder.com/150',
        'sellerId': 'test_user',
        'sellerName': 'Test User',
        'sellerPhone': '555-123-4567',
        'createdAt': Timestamp.now(),
        'isAvailable': true,
        'tags': ['Test', 'Debug']
      });

      setState(() {
        _statusMessage = 'Test book added successfully!';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sample Books'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Book Upload Tool',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This tool will add sample books directly to your Firestore "book" collection.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Column(
                children: [
                  // Add Sample Books Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _addSampleBooks,
                      icon: const Icon(Icons.book),
                      label: const Text('Add All Sample Books'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add Test Book Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _addSingleBook,
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Add Single Test Book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      _isSuccess ? Colors.green.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess ? Colors.green : Colors.grey,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSuccess ? 'Success' : 'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isSuccess
                            ? Colors.green.shade800
                            : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _isSuccess
                            ? Colors.green.shade800
                            : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Sample books preview
            const Text(
              'Sample Books to Add:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...List.generate(
              _sampleBooks.length,
              (index) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: NetworkImage(
                            _sampleBooks[index]['coverImageUrl'] as String),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(
                    _sampleBooks[index]['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Author: ${_sampleBooks[index]['author']}'),
                      Text('Category: ${_sampleBooks[index]['category']}'),
                      Text('Price: \$${_sampleBooks[index]['price']}'),
                      Text('Condition: ${_sampleBooks[index]['condition']}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
