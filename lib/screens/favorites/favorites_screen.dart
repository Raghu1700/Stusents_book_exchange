import 'package:flutter/material.dart';
import '../../model/course.dart';
import '../home/components/secondary_course_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // Sample favorite books (in a real app, this would come from a database)
  List<Course> favoriteBooks = [
    Course(
      title: "Physics Fundamentals",
      iconSrc: "assets/icons/book.svg",
      color: const Color(0xFF00A9F1),
      subject: "Physics",
      bookClass: "11th Grade",
      price: "\$30",
      seller: "Jane Smith",
      description:
          "Essential physics textbook covering mechanics, thermodynamics, and electromagnetism.",
      condition: "Good",
      isFavorite: true,
    ),
    Course(
      title: "World History",
      iconSrc: "assets/icons/book.svg",
      color: const Color(0xFFE7926F),
      subject: "History",
      bookClass: "11th Grade",
      price: "\$15",
      seller: "Sarah Johnson",
      description:
          "Comprehensive world history textbook from ancient civilizations to modern times.",
      condition: "Like New",
      isFavorite: true,
    ),
  ];

  void _removeFromFavorites(int index) {
    setState(() {
      favoriteBooks.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Book removed from favorites'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Favorite Books",
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Books you've saved for later",
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: favoriteBooks.isEmpty
                  ? Center(
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
                            'Books you save will appear here',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: favoriteBooks.length,
                      itemBuilder: (context, index) {
                        final book = favoriteBooks[index];
                        return Dismissible(
                          key: Key(book.title),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) {
                            _removeFromFavorites(index);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: SecondaryCourseCard(
                              title: book.title,
                              iconSrc: book.iconSrc,
                              color: book.color,
                              subject: book.subject,
                              bookClass: book.bookClass,
                              price: book.price,
                              seller: book.seller,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
