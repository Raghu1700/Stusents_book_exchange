import 'package:flutter/material.dart';
import 'package:rive_animation/model/book.dart';
import 'package:rive_animation/screens/home/components/book_card.dart';
import 'package:rive_animation/services/book_service.dart';
import 'package:rive_animation/screens/book_details/book_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final BookService _bookService = BookService();
  List<Book> _bookmarkedBooks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBookmarkedBooks();
  }

  Future<void> _loadBookmarkedBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final books = await _bookService.getBookmarkedBooks();
      setState(() {
        _bookmarkedBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bookmarked books: $e');
      setState(() {
        _errorMessage = 'Failed to load your favorites. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
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
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBookmarkedBooks,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_bookmarkedBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No favorite books yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Books you add to favorites will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadBookmarkedBooks,
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _bookmarkedBooks.length,
          itemBuilder: (context, index) {
            final book = _bookmarkedBooks[index];
            return BookCard(
              book: book,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailsScreen(book: book),
                  ),
                ).then(
                    (_) => _loadBookmarkedBooks()); // Refresh after returning
              },
            );
          },
        ),
      ),
    );
  }
}
