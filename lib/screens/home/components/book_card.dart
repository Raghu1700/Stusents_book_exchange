import 'package:flutter/material.dart';
import 'package:rive_animation/model/book.dart';
import 'package:rive_animation/services/book_service.dart';
import 'package:rive_animation/utils/avatar_generator.dart';
import 'package:intl/intl.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final bool showBookmarkButton;

  const BookCard({
    Key? key,
    required this.book,
    this.onTap,
    this.showBookmarkButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        elevation: 1,
        margin: const EdgeInsets.all(1),
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover - Replace with Animated Avatar
                AspectRatio(
                  aspectRatio: 1.0, // Square aspect ratio
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(4)),
                    child: AvatarGenerator.buildAnimatedAvatar(
                      book.title,
                      size: MediaQuery.of(context).size.width / 2 - 20,
                    ),
                  ),
                ),

                // Ultra compact book details
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with price overlay
                      Stack(
                        children: [
                          // Title
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Price as positioned badge in corner
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                formatter.format(book.price),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Bookmark button overlay
            if (showBookmarkButton && book.id != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: _BookmarkButton(bookId: book.id!),
              ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'like new':
        return Colors.green.shade700;
      case 'very good':
        return Colors.blue;
      case 'good':
        return Colors.blue.shade700;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _BookmarkButton extends StatefulWidget {
  final String bookId;

  const _BookmarkButton({
    Key? key,
    required this.bookId,
  }) : super(key: key);

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton> {
  final BookService _bookService = BookService();
  bool _isBookmarked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      final isBookmarked = await _bookService.isBookmarked(widget.bookId);
      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking bookmark status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleBookmark() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isBookmarked) {
        success = await _bookService.removeBookmark(widget.bookId);
      } else {
        success = await _bookService.bookmarkBook(widget.bookId);
      }

      if (success && mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      child: Align(
        alignment: Alignment.bottomRight,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: _isBookmarked ? Colors.amber : Colors.grey,
                ),
                onPressed: _toggleBookmark,
              ),
      ),
    );
  }
}
