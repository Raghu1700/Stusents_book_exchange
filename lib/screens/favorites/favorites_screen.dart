import 'package:flutter/material.dart';
import 'package:rive_animation/model/book.dart';
import 'package:rive_animation/screens/home/components/book_card.dart';
import 'package:rive_animation/services/book_service.dart';
import 'package:rive_animation/screens/book_details/book_details_screen.dart';
import 'package:rive_animation/components/animated_background.dart';
import 'package:rive_animation/components/animated_button.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final BookService _bookService = BookService();
  List<Book> _bookmarkedBooks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadBookmarkedBooks();
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
    _animationController.dispose();
    super.dispose();
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
    Widget content;

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_errorMessage.isNotEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontFamily: 'Intel',
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 24),
            AnimatedButton(
              onPressed: _loadBookmarkedBooks,
              text: 'Try Again',
              icon: Icons.refresh,
              backgroundColor: Theme.of(context).primaryColor,
              width: 200,
            ),
          ],
        ),
      );
    } else if (_bookmarkedBooks.isEmpty) {
      content = FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'No Favorite Books Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Books you add to favorites will appear here',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Intel',
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tip: Tap the heart icon on any book to add it to your favorites',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Intel',
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Favorites',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_bookmarkedBooks.length} ${_bookmarkedBooks.length == 1 ? 'book' : 'books'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Intel',
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadBookmarkedBooks,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
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
                      ).then((_) => _loadBookmarkedBooks());
                    },
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: AnimatedBackground(
        blurSigma: 25.0,
        overlayColor: Colors.white.withOpacity(0.3),
        child: SafeArea(
          child: content,
        ),
      ),
    );
  }
}
