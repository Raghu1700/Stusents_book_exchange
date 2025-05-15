import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../model/course.dart';
import '../../book_detail/book_detail_screen.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.title,
    this.iconSrc = "assets/icons/code.svg",
    this.color = const Color(0xFF7553F6),
    this.subject,
    this.bookClass,
    this.price,
    this.seller,
  });

  final String title;
  final String iconSrc;
  final Color color;
  final String? subject;
  final String? bookClass;
  final String? price;
  final String? seller;

  @override
  Widget build(BuildContext context) {
    final bool isBookCard =
        subject != null && bookClass != null && price != null && seller != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 320,
      width: 260,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SvgPicture.asset(
                      iconSrc,
                      height: 24,
                      width: 24,
                      colorFilter:
                          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isBookCard) ...[
                  Text(
                    "Subject: $subject",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Class: $bookClass",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  const Text(
                    "Build and animate an iOS app from scratch",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
                const Spacer(),
                if (isBookCard) ...[
                  Text(
                    "Price: $price",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Seller: $seller",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to book detail page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailScreen(
                                book: Course(
                                  title: title,
                                  iconSrc: iconSrc,
                                  color: color,
                                  subject: subject!,
                                  bookClass: bookClass!,
                                  price: price!,
                                  seller: seller!,
                                ),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: color,
                          minimumSize: const Size(24, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon:
                            const Icon(Icons.shopping_cart_outlined, size: 16),
                        label: const Text("Buy"),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.favorite_border_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // Implement save functionality
                        },
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Define BookCard as an alias for CourseCard for better semantics
typedef BookCard = CourseCard;
