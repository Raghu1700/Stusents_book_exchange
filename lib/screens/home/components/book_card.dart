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
      symbol: '₹',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        margin: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover Image with Favorite Button overlay
            Stack(
              children: [
                // Book Cover Image
                AspectRatio(
                  aspectRatio: 1.0, // Square aspect ratio
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                    child: AvatarGenerator.buildAnimatedAvatar(
                      book.title,
                      size: MediaQuery.of(context).size.width / 2 - 16,
                    ),
                  ),
                ),

                // Heart Icon for adding to favorites
                if (showBookmarkButton)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _BookmarkButton(bookId: book.id!),
                    ),
                  ),
              ],
            ),

            // Book information - make this more compact
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Name - Author
                  Text(
                    "${book.title} - ${book.author}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // Class only (simplified layout)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Class: ${book.grade}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Price (moved inline to save vertical space)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          formatter.format(book.price),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
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
      ),
    );
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
    return _isLoading
        ? const SizedBox(
            width: 30,
            height: 30,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
        : IconButton(
            icon: Icon(
              _isBookmarked ? Icons.favorite : Icons.favorite_border,
              color: _isBookmarked ? Colors.red : Colors.white,
              size: 22,
            ),
            onPressed: _toggleBookmark,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 22,
          );
  }
}
