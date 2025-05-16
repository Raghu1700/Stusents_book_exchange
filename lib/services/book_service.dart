import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rive_animation/model/book.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String booksCollection = 'book';
  final String userBookmarksCollection = 'user_bookmarks';

  // Get all books with pagination
  Future<List<Book>> getBooks({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? category,
  }) async {
    try {
      print('----- getBooks method -----');
      print('Retrieving books from collection: $booksCollection');
      print('Category filter: $category');

      // Start with a basic query on the books collection
      Query query = _firestore.collection(booksCollection);

      // Only add where clauses if needed
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
        print('Added category filter: $category');
      }

      // Add order
      query = query.orderBy('createdAt', descending: true);

      // Add pagination if needed
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
        print('Using pagination with lastDocument');
      }

      // Apply the limit
      query = query.limit(limit);
      print('Set limit to: $limit');

      // Execute the query
      print('Executing Firestore query...');
      final querySnapshot = await query.get();
      print('Query executed. Found ${querySnapshot.docs.length} books');

      // Map the documents to Book objects
      List<Book> books = querySnapshot.docs.map((doc) {
        try {
          print('Processing document ID: ${doc.id}');
          return Book.fromFirestore(doc);
        } catch (e) {
          print('Error converting doc ${doc.id} to Book: $e');
          // Return a placeholder book in case of error
          return Book(
            id: doc.id,
            title: 'Error loading book',
            author: 'Unknown',
            category: 'Standard',
            description: 'This book could not be loaded correctly',
            price: 0.0,
            sellerId: '',
            sellerName: 'Unknown',
            createdAt: Timestamp.now(),
          );
        }
      }).toList();

      print('Converted ${books.length} documents to Book objects');
      print('----- getBooks method end -----');

      return books;
    } catch (e) {
      print('Error in getBooks method: $e');
      print(StackTrace.current);
      return [];
    }
  }

  // Get books by category
  Stream<List<Book>> getBooksByCategory(String category) {
    return _firestore
        .collection(booksCollection)
        .where('category', isEqualTo: category)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList());
  }

  // Get books by seller
  Stream<List<Book>> getBooksBySeller(String sellerId) {
    return _firestore
        .collection(booksCollection)
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList());
  }

  // Get a single book by ID
  Future<Book?> getBookById(String bookId) async {
    try {
      final doc =
          await _firestore.collection(booksCollection).doc(bookId).get();
      if (doc.exists) {
        return Book.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting book by ID: $e');
      return null;
    }
  }

  // Add a new book - Simplified with no image upload
  Future<String?> addBook({
    required String title,
    required String author,
    required String category,
    required String description,
    required double price,
    required String condition,
    String? grade,
    String? sellerPhone,
    String? edition,
    String? isbn,
    List<String>? tags,
    File?
        coverImage, // Keep parameter for backward compatibility, but don't use it
    String? subject,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Error: User not authenticated');
        return null; // Return null instead of throwing to prevent crashes
      }

      print('Current user ID: ${currentUser.uid}');
      print('Current user name: ${currentUser.displayName ?? 'Anonymous'}');

      // Prepare book data with only essential fields
      final Map<String, dynamic> bookData = {
        'title': title,
        'author': author,
        'description': description,
        'price': price,
        'sellerId': currentUser.uid,
        'sellerName': currentUser.displayName ?? 'Anonymous',
        'createdAt': Timestamp.now(),
        'condition': condition,
        'isAvailable': true,
        'category': category.isNotEmpty ? category : 'Standard',
        'grade': grade ?? 'All',
        'subject': subject ?? 'Other',
      };

      // Add seller phone if provided
      if (sellerPhone != null && sellerPhone.isNotEmpty) {
        bookData['sellerPhone'] = sellerPhone;
      }

      // Add to Firestore - explicit collection reference
      print('Adding book to Firestore, collection: $booksCollection');
      print('Book data: $bookData');

      try {
        // Use the collection reference directly
        final DocumentReference docRef =
            await _firestore.collection(booksCollection).add(bookData);

        // Verify the document was created
        final docSnapshot = await docRef.get();
        print('Book document created: ${docSnapshot.exists}');
        print('Book added successfully with ID: ${docRef.id}');

        return docRef.id;
      } catch (e) {
        print('Error adding book to Firestore: $e');
        print(StackTrace.current);
        return null;
      }
    } catch (e) {
      print('Error in addBook method: $e');
      print(StackTrace.current);
      return null;
    }
  }

  // Update a book - Simplified with no image handling
  Future<bool> updateBook({
    required String bookId,
    String? title,
    String? author,
    String? category,
    String? description,
    double? price,
    bool? isAvailable,
    String? condition,
    String? edition,
    String? isbn,
    List<String>? tags,
    File?
        coverImage, // Keep parameter for backward compatibility, but don't use it
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the existing book document
      final bookDoc =
          await _firestore.collection(booksCollection).doc(bookId).get();
      if (!bookDoc.exists) {
        throw Exception('Book not found');
      }

      final existingBook = Book.fromFirestore(bookDoc);

      // Verify that the current user is the seller
      if (existingBook.sellerId != currentUser.uid) {
        throw Exception('You can only update your own books');
      }

      // Update fields
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (author != null) updateData['author'] = author;
      if (category != null) updateData['category'] = category;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (isAvailable != null) updateData['isAvailable'] = isAvailable;
      if (condition != null) updateData['condition'] = condition;
      if (edition != null) updateData['edition'] = edition;
      if (isbn != null) updateData['isbn'] = isbn;
      if (tags != null) updateData['tags'] = tags;

      // Update in Firestore
      await _firestore
          .collection(booksCollection)
          .doc(bookId)
          .update(updateData);
      return true;
    } catch (e) {
      print('Error updating book: $e');
      return false;
    }
  }

  // Delete a book - Simplified with no image handling
  Future<bool> deleteBook(String bookId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the book document
      final bookDoc =
          await _firestore.collection(booksCollection).doc(bookId).get();
      if (!bookDoc.exists) {
        throw Exception('Book not found');
      }

      final book = Book.fromFirestore(bookDoc);

      // Verify that the current user is the seller
      if (book.sellerId != currentUser.uid) {
        throw Exception('You can only delete your own books');
      }

      // Delete document from Firestore
      await _firestore.collection(booksCollection).doc(bookId).delete();
      return true;
    } catch (e) {
      print('Error deleting book: $e');
      return false;
    }
  }

  // Search books by title, author, or tags
  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      query = query.toLowerCase();

      // Search by title, author, and description
      final titleQuerySnapshot = await _firestore
          .collection(booksCollection)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .where('isAvailable', isEqualTo: true)
          .get();

      final authorQuerySnapshot = await _firestore
          .collection(booksCollection)
          .where('author', isGreaterThanOrEqualTo: query)
          .where('author', isLessThanOrEqualTo: query + '\uf8ff')
          .where('isAvailable', isEqualTo: true)
          .get();

      // Search by ISBN (exact match)
      final isbnQuerySnapshot = await _firestore
          .collection(booksCollection)
          .where('isbn', isEqualTo: query)
          .where('isAvailable', isEqualTo: true)
          .get();

      // Combine results and remove duplicates
      final Map<String, Book> uniqueBooks = {};

      // Add books from title search
      for (var doc in titleQuerySnapshot.docs) {
        final book = Book.fromFirestore(doc);
        uniqueBooks[doc.id] = book;
      }

      // Add books from author search
      for (var doc in authorQuerySnapshot.docs) {
        final book = Book.fromFirestore(doc);
        uniqueBooks[doc.id] = book;
      }

      // Add books from ISBN search
      for (var doc in isbnQuerySnapshot.docs) {
        final book = Book.fromFirestore(doc);
        uniqueBooks[doc.id] = book;
      }

      return uniqueBooks.values.toList();
    } catch (e) {
      print('Error searching books: $e');
      return [];
    }
  }

  // Add book to user's bookmarks
  Future<bool> bookmarkBook(String bookId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userBookmarksRef = _firestore
          .collection(userBookmarksCollection)
          .doc(currentUser.uid)
          .collection('bookmarks')
          .doc(bookId);

      await userBookmarksRef.set({
        'bookId': bookId,
        'addedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error bookmarking book: $e');
      return false;
    }
  }

  // Remove book from user's bookmarks
  Future<bool> removeBookmark(String bookId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(userBookmarksCollection)
          .doc(currentUser.uid)
          .collection('bookmarks')
          .doc(bookId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing bookmark: $e');
      return false;
    }
  }

  // Get user's bookmarked books
  Future<List<Book>> getBookmarkedBooks() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get bookmarks
      final bookmarksSnapshot = await _firestore
          .collection(userBookmarksCollection)
          .doc(currentUser.uid)
          .collection('bookmarks')
          .orderBy('addedAt', descending: true)
          .get();

      if (bookmarksSnapshot.docs.isEmpty) {
        return [];
      }

      // Get book IDs from bookmarks
      final bookIds = bookmarksSnapshot.docs.map((doc) => doc.id).toList();

      // Get book documents using a batched approach
      final List<Book> books = [];

      // Process in batches of 10 to avoid too many concurrent Firestore queries
      for (int i = 0; i < bookIds.length; i += 10) {
        final end = (i + 10 < bookIds.length) ? i + 10 : bookIds.length;
        final batchIds = bookIds.sublist(i, end);

        final booksSnapshot = await _firestore
            .collection(booksCollection)
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        books.addAll(booksSnapshot.docs.map((doc) => Book.fromFirestore(doc)));
      }

      return books;
    } catch (e) {
      print('Error getting bookmarked books: $e');
      return [];
    }
  }

  // Check if a book is bookmarked
  Future<bool> isBookmarked(String bookId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final docSnapshot = await _firestore
          .collection(userBookmarksCollection)
          .doc(currentUser.uid)
          .collection('bookmarks')
          .doc(bookId)
          .get();

      return docSnapshot.exists;
    } catch (e) {
      print('Error checking bookmark status: $e');
      return false;
    }
  }

  // Get available book categories
  Future<List<String>> getCategories() async {
    try {
      // Get categories from existing books
      final querySnapshot = await _firestore.collection(booksCollection).get();

      // Extract unique categories from existing books
      final Set<String> uniqueCategories = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('category') && data['category'] != null) {
          uniqueCategories.add(data['category'] as String);
        }
      }

      if (uniqueCategories.isNotEmpty) {
        return uniqueCategories.toList()..sort();
      }

      // Default categories if none are found
      return [
        'Textbook',
        'Reference',
        'Fiction',
        'Non-Fiction',
        'Science',
        'Engineering',
        'Mathematics',
        'Computer Science',
        'Business',
        'Arts',
        'Humanities',
        'Social Sciences',
        'Medicine',
        'Law',
        'Other'
      ];
    } catch (e) {
      print('Error getting categories: $e');
      // Return default categories on error
      return [
        'Textbook',
        'Reference',
        'Fiction',
        'Non-Fiction',
        'Science',
        'Engineering',
        'Mathematics',
        'Computer Science',
        'Other'
      ];
    }
  }
}
