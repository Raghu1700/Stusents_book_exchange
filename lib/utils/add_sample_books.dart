import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rive_animation/model/book.dart';
import 'package:rive_animation/services/book_service.dart';

class SampleBooksUploader {
  final BookService _bookService = BookService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadSampleBooks() async {
    // Sample book data
    final List<Map<String, dynamic>> sampleBooks = [
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

    // Add each book to Firestore
    for (var bookData in sampleBooks) {
      try {
        // Get a reference to the book collection (changed from 'books' to 'book')
        final CollectionReference booksRef = _firestore.collection('book');

        // Create the book document with a unique ID
        await booksRef.add({
          'title': bookData['title'],
          'author': bookData['author'],
          'category': bookData['category'],
          'description': bookData['description'],
          'price': bookData['price'],
          'condition': bookData['condition'],
          'edition': bookData['edition'],
          'isbn': bookData['isbn'],
          'coverImageUrl': bookData['coverImageUrl'],
          'sellerId':
              'sample_seller', // You might want to update this with a real user ID
          'sellerName': 'Sample Seller',
          'sellerPhone': '123-456-7890',
          'createdAt': Timestamp.now(),
          'isAvailable': true,
          'tags': [bookData['category'], 'Sample']
        });

        print('Added book: ${bookData['title']}');
      } catch (e) {
        print('Error adding book ${bookData['title']}: $e');
      }
    }

    print('Finished adding sample books');
  }
}
