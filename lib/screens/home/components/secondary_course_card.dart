import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../model/course.dart';
import '../../book_detail/book_detail_screen.dart';

class SecondaryCourseCard extends StatelessWidget {
  const SecondaryCourseCard({
    super.key,
    required this.title,
    this.iconsSrc = "assets/icons/ios.svg",
    this.colorl = const Color(0xFF7553F6),
    this.subject,
    this.bookClass,
    this.price,
    this.seller,
    this.iconSrc,
    this.color,
  });

  final String title;
  final String? iconsSrc;
  final Color? colorl;
  final String? subject;
  final String? bookClass;
  final String? price;
  final String? seller;
  final String? iconSrc;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Check if we're being used in book mode
    final bool isBookCard =
        subject != null && bookClass != null && price != null && seller != null;

    // Use either new properties or fall back to old ones
    final effectiveIconSrc = iconSrc ?? iconsSrc ?? "assets/icons/code.svg";
    final effectiveColor = color ?? colorl ?? const Color(0xFF7553F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isBookCard ? effectiveColor.withOpacity(0.2) : effectiveColor,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: isBookCard ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isBookCard) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Subject: $subject • Class: $bookClass",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price!,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              // Navigate to book detail page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookDetailScreen(
                                    book: Course(
                                      title: title,
                                      iconSrc: effectiveIconSrc,
                                      color: effectiveColor,
                                      subject: subject!,
                                      bookClass: bookClass!,
                                      price: price!,
                                      seller: seller!,
                                    ),
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: effectiveColor,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 40),
                            ),
                            child: const Text("Contact"),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              // Toggle favorite
                            },
                            style: IconButton.styleFrom(
                              foregroundColor: effectiveColor,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(40, 40),
                            ),
                            icon: const Icon(Icons.favorite_border_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  const Text(
                    "Watch video - 15 mins",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isBookCard) ...[
            SizedBox(
              height: 40,
              width: 40,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: effectiveColor.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Positioned.fill(
                    child: SvgPicture.asset(
                      effectiveIconSrc,
                      height: 20,
                      width: 20,
                      colorFilter:
                          ColorFilter.mode(effectiveColor, BlendMode.srcIn),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(
              height: 40,
              child: VerticalDivider(
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(effectiveIconSrc),
          ],
        ],
      ),
    );
  }
}

// Define SecondaryBookCard as an alias for SecondaryCourseCard for better semantics
typedef SecondaryBookCard = SecondaryCourseCard;
