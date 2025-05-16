import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:rive_animation/model/book.dart';
import 'package:rive_animation/screens/home/components/book_card.dart';
import 'package:rive_animation/services/book_service.dart';
import 'package:rive_animation/screens/book_details/book_details_screen.dart';

class BookGrid extends StatefulWidget {
  final String? category;
  final String? sellerId;
  final String? searchQuery;
  final bool skipFirstBooks;
  final int skipCount;
  final int? limit;
  final String? grade;

  const BookGrid({
    Key? key,
    this.category,
    this.sellerId,
    this.searchQuery,
    this.skipFirstBooks = false,
    this.skipCount = 2,
    this.limit,
    this.grade,
  }) : super(key: key);

  @override
  State<BookGrid> createState() => _BookGridState();
}

class _BookGridState extends State<BookGrid> {
  final BookService _bookService = BookService();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _refreshSubscription;

  List<Book> _books = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _hasMore = true;
  bool _isSearching = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _scrollController.addListener(_scrollListener);

    // Subscribe to the refresh stream
    _refreshSubscription = _bookService.refreshStream.listen((_) {
      // When a refresh notification is received, reload the books
      _refreshBooks();
    });
  }

  @override
  void didUpdateWidget(BookGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.category != oldWidget.category ||
        widget.sellerId != oldWidget.sellerId ||
        widget.searchQuery != oldWidget.searchQuery ||
        widget.skipFirstBooks != oldWidget.skipFirstBooks ||
        widget.skipCount != oldWidget.skipCount ||
        widget.grade != oldWidget.grade ||
        widget.limit != oldWidget.limit) {
      _resetList();
      _loadBooks();
    }
  }

  void _resetList() {
    setState(() {
      _books = [];
      _lastDocument = null;
      _hasMore = true;
      _errorMessage = '';
      _isInitialLoading = true;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreBooks();
    }
  }

  Future<void> _loadBooks() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('----------------------');
      print('BookGrid: Loading books...');
      print('Collection name: ${_bookService.booksCollection}');
      print('SearchQuery: ${widget.searchQuery}, Category: ${widget.category}');
      print('----------------------');

      List<Book> loadedBooks = [];

      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        // Search books
        setState(() {
          _isSearching = true;
        });

        try {
          final searchResults =
              await _bookService.searchBooks(widget.searchQuery!);
          print('Search results: Found ${searchResults.length} books');
          loadedBooks = searchResults;
        } catch (e) {
          print('Error during search: $e');
          // Return empty list on error rather than crashing
          loadedBooks = [];
        }

        setState(() {
          _books = loadedBooks;
          _hasMore = false; // Search doesn't support pagination for now
          _isLoading = false;
          _isInitialLoading = false;
          _isSearching = false;
        });
      } else {
        // Get books with pagination
        print(
            'Fetching books from Firestore collection: ${_bookService.booksCollection}');

        int fetchLimit = widget.limit ?? 10;
        if (widget.skipFirstBooks && _books.isEmpty) {
          // On first load in skip mode, load more to account for skipped books
          fetchLimit = fetchLimit + widget.skipCount;
        }

        try {
          final books = await _bookService.getBooks(
            limit: fetchLimit,
            lastDocument: _lastDocument,
            category: widget.category,
            grade: widget.grade,
          );

          print('Loaded ${books.length} books from Firestore');

          // If we need to skip the first books (for home screen)
          if (widget.skipFirstBooks &&
              _books.isEmpty &&
              books.length > widget.skipCount) {
            loadedBooks = books.skip(widget.skipCount).toList();
          } else {
            loadedBooks = books;
          }

          if (books.isNotEmpty) {
            for (var book in books) {
              print('Book: ${book.title} by ${book.author} - ID: ${book.id}');
            }
          } else {
            print('No books found in Firestore collection');
          }
        } catch (e) {
          print('Error fetching books: $e');
          loadedBooks = [];
        }

        setState(() {
          _books.addAll(loadedBooks);
          _isLoading = false;
          _isInitialLoading = false;
          _hasMore = widget.limit == null &&
              loadedBooks.length ==
                  10; // Only enable pagination if no limit is set
          // Skip pagination for now to avoid potential errors
          _lastDocument = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading books. Please try again.';
        _isLoading = false;
        _isInitialLoading = false;
      });
      print("Error in BookGrid: $e");
      print(StackTrace.current);
    }
  }

  Future<void> _loadMoreBooks() async {
    if (!_isSearching && !_isLoading && _hasMore) {
      _loadBooks();
    }
  }

  Future<void> _refreshBooks() async {
    _resetList();
    await _loadBooks();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _refreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Books',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshBooks,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_isInitialLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading books..."),
          ],
        ),
      );
    }

    if (_books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.book_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                  ? 'No books found for "${widget.searchQuery}"'
                  : widget.category != null
                      ? 'No books available in ${widget.category} category'
                      : 'No books available',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshBooks,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshBooks,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 8,
          mainAxisSpacing: 12,
        ),
        itemCount: _books.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _books.length) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final book = _books[index];
          return BookCard(
            book: book,
            showBookmarkButton: true,
            onTap: () {
              // Navigate to book details screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailsScreen(book: book),
                ),
              ).then((_) =>
                  _refreshBooks()); // Refresh after returning to show updated bookmark status
            },
          );
        },
      ),
    );
  }
}

// Utility class to create a DocumentSnapshot
class SnapshotUtility {
  static DocumentSnapshot createDocumentSnapshot(DocumentReference docRef) {
    // This is a workaround as we cannot directly create a DocumentSnapshot
    // In a real app, you would store the actual DocumentSnapshot from a query
    return FirebaseFirestore.instance.doc(docRef.path).snapshots().first
        as DocumentSnapshot;
  }
}
