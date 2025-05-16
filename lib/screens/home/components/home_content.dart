import 'package:flutter/material.dart';
import 'package:rive_animation/components/animated_background.dart';
import 'dart:async';
import 'book_grid.dart';
import 'package:rive_animation/model/book.dart';
import 'package:rive_animation/services/book_service.dart';
import 'package:rive_animation/screens/book_details/book_details_screen.dart';
import 'package:rive_animation/utils/avatar_generator.dart';
import 'package:intl/intl.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  HomeContentState createState() => HomeContentState();
}

// Make the state class public so it can be accessed with a GlobalKey
class HomeContentState extends State<HomeContent>
    with AutomaticKeepAliveClientMixin {
  final BookService _bookService = BookService();
  List<Book> _recentBooks = [];
  bool _isLoading = true;
  StreamSubscription? _refreshSubscription;
  String? _selectedCategory;

  // Category list
  final List<String> _categories = [
    'Academics',
    'Fiction',
    'Non-Fiction',
    'Mystery',
    'Thriller',
    'Romance',
    'Sci-Fi',
    'Fantasy',
    'Biography',
    'Self-Help',
    'Reference',
    'Textbook',
    'Other'
  ];

  // Books organized by category
  Map<String, List<Book>> _categorizedBooks = {};
  bool _isLoadingCategorizedBooks = true;

  // Implement AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecentBooks();
    _loadCategorizedBooks();

    // Subscribe to the refresh stream
    _refreshSubscription = _bookService.refreshStream.listen((_) {
      // When a refresh notification is received, reload the books
      _loadRecentBooks();
      _loadCategorizedBooks();
    });
  }

  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    _refreshSubscription?.cancel();
    super.dispose();
  }

  // Public method to refresh books
  void refreshBooks() {
    _loadRecentBooks();
    _loadCategorizedBooks();
  }

  Future<void> _loadRecentBooks() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final books = await _bookService.getBooks(
          limit: 3); // Changed from 6 to 3 most recent books
      if (mounted) {
        setState(() {
          _recentBooks = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading recent books: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCategorizedBooks() async {
    try {
      setState(() {
        _isLoadingCategorizedBooks = true;
      });

      // Initialize an empty map for each category
      Map<String, List<Book>> categorizedBooks = {};
      for (String category in _categories) {
        categorizedBooks[category] = [];
      }

      // Load books for each category
      List<Future<void>> futures = [];

      for (String category in _categories) {
        futures.add(_loadBooksForCategory(category, categorizedBooks));
      }

      // Wait for all category queries to complete
      await Future.wait(futures);

      if (mounted) {
        setState(() {
          _categorizedBooks = categorizedBooks;
          _isLoadingCategorizedBooks = false;
        });
      }
    } catch (e) {
      print('Error loading categorized books: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategorizedBooks = false;
        });
      }
    }
  }

  Future<void> _loadBooksForCategory(
      String category, Map<String, List<Book>> categorizedBooks) async {
    try {
      // Use a simpler query that doesn't require a compound index
      final books = await _bookService.getBooksByCategory(category);

      if (books.isNotEmpty && mounted) {
        categorizedBooks[category] = books;
      }
    } catch (e) {
      print('Error loading books for category $category: $e');
    }
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Intel',
            fontSize: 14,
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        backgroundColor: Colors.white.withOpacity(0.9),
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
        checkmarkColor: Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return AnimatedBackground(
      blurSigma: 25.0,
      overlayColor: Colors.white.withOpacity(0.3),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recently Added Books Section
            SizedBox(
              height: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Recently Added',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _recentBooks.length,
                        itemBuilder: (context, index) {
                          final book = _recentBooks[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookDetailsScreen(book: book),
                                  ),
                                ).then((_) => refreshBooks());
                              },
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: Card(
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                  child: AvatarGenerator.buildAnimatedAvatar(
                                    book.title,
                                    size: 150,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Category Filter Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryChip('All', null),
                      ..._categories.map(
                          (category) => _buildCategoryChip(category, category)),
                    ],
                  ),
                ),
              ],
            ),

            // Categorized Books Sections
            Expanded(
              child: _selectedCategory != null
                  ? // Show selected category books only
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Text(
                            _selectedCategory!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: BookGrid(
                              skipFirstBooks: false,
                              category: _selectedCategory,
                            ),
                          ),
                        ),
                      ],
                    )
                  : // Show all categories
                  _isLoadingCategorizedBooks
                      ? const Center(child: CircularProgressIndicator())
                      : Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final books = _categorizedBooks[category] ?? [];

                              // Skip categories with no books
                              if (books.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedCategory = category;
                                            });
                                          },
                                          child: Text(
                                            'See All',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 200,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      itemCount: books.length,
                                      itemBuilder: (context, bookIndex) {
                                        final book = books[bookIndex];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 12),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      BookDetailsScreen(
                                                          book: book),
                                                ),
                                              ).then((_) => refreshBooks());
                                            },
                                            child: SizedBox(
                                              width: 130,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Book cover
                                                  Expanded(
                                                    child: AspectRatio(
                                                      aspectRatio: 0.7,
                                                      child: Card(
                                                        clipBehavior:
                                                            Clip.antiAlias,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        elevation: 2,
                                                        child: AvatarGenerator
                                                            .buildAnimatedAvatar(
                                                          book.title,
                                                          size: 150,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    book.title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    '₹${book.price.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
