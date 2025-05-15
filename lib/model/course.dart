import 'package:flutter/material.dart' show Color;

class Course {
  final String title;
  final String iconSrc;
  final Color color;
  final String subject;
  final String bookClass;
  final String price;
  final String seller;
  final String? description;
  final String? condition;
  final bool isFavorite;
  final String? sellerPhone; // For WhatsApp
  final String? sellerUPI; // UPI ID for payment
  final String? bankDetails; // Bank account details

  Course({
    required this.title,
    required this.iconSrc,
    required this.color,
    required this.subject,
    required this.bookClass,
    required this.price,
    required this.seller,
    this.description,
    this.condition,
    this.isFavorite = false,
    this.sellerPhone,
    this.sellerUPI,
    this.bankDetails,
  });

  Course copyWith({
    String? title,
    String? iconSrc,
    Color? color,
    String? subject,
    String? bookClass,
    String? price,
    String? seller,
    String? description,
    String? condition,
    bool? isFavorite,
    String? sellerPhone,
    String? sellerUPI,
    String? bankDetails,
  }) {
    return Course(
      title: title ?? this.title,
      iconSrc: iconSrc ?? this.iconSrc,
      color: color ?? this.color,
      subject: subject ?? this.subject,
      bookClass: bookClass ?? this.bookClass,
      price: price ?? this.price,
      seller: seller ?? this.seller,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      isFavorite: isFavorite ?? this.isFavorite,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerUPI: sellerUPI ?? this.sellerUPI,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }
}

// Sample data for the app
List<Course> availableBooks = [
  Course(
    title: "Mathematics Textbook",
    iconSrc: "assets/icons/book.svg",
    color: const Color(0xFF7553F6),
    subject: "Mathematics",
    bookClass: "10th Grade",
    price: "₹1800",
    seller: "John Doe",
    description:
        "Comprehensive mathematics textbook covering algebra, geometry, and trigonometry.",
    condition: "Like New",
    sellerPhone: "9876543210",
    sellerUPI: "johndoe@upi",
    bankDetails: "SBI Account: 1234567890, IFSC: SBIN0001234",
  ),
  Course(
    title: "Physics Fundamentals",
    iconSrc: "assets/icons/book.svg",
    color: const Color(0xFF00A9F1),
    subject: "Physics",
    bookClass: "11th Grade",
    price: "₹2200",
    seller: "Jane Smith",
    description:
        "Essential physics textbook covering mechanics, thermodynamics, and electromagnetism.",
    condition: "Good",
    sellerPhone: "8765432109",
    sellerUPI: "janesmith@upi",
    bankDetails: "HDFC Account: 0987654321, IFSC: HDFC0000987",
  ),
  Course(
    title: "Chemistry Basics",
    iconSrc: "assets/icons/book.svg",
    color: const Color(0xFF22B07D),
    subject: "Chemistry",
    bookClass: "9th Grade",
    price: "₹1500",
    seller: "Robert Johnson",
    description:
        "Introductory chemistry textbook with experiments and exercises.",
    condition: "Fair",
    sellerPhone: "7654321098",
    sellerUPI: "robertj@upi",
    bankDetails: "ICICI Account: 8901234567, IFSC: ICIC0001234",
  ),
  Course(
    title: "English Literature",
    iconSrc: "assets/icons/book.svg",
    color: const Color(0xFFF7534A),
    subject: "English",
    bookClass: "12th Grade",
    price: "₹1600",
    seller: "Emily Davis",
    description:
        "Collection of classic literature works with analysis and commentary.",
    condition: "Very Good",
    sellerPhone: "6543210987",
    sellerUPI: "emilyd@upi",
    bankDetails: "Axis Account: 6789012345, IFSC: UTIB0001234",
  ),
];

List<Course> recentlyAddedBooks = [
  Course(
    title: "Biology Essentials",
    iconSrc: "assets/icons/book.svg",
    color: const Color(0xFF2E5EAA),
    subject: "Biology",
    bookClass: "10th Grade",
    price: "₹1300",
    seller: "Michael Wilson",
    description: "Covers cell biology, genetics, evolution, and ecology.",
    condition: "Good",
    sellerPhone: "9876543211",
    sellerUPI: "michaelw@upi",
    bankDetails: "PNB Account: 5432167890, IFSC: PUNB0001234",
  ),
  Course(
    title: "World History",
    iconSrc: "assets/icons/book.svg",
    color: const Color(0xFFE7926F),
    subject: "History",
    bookClass: "11th Grade",
    price: "₹1100",
    seller: "Sarah Johnson",
    description:
        "Comprehensive world history textbook from ancient civilizations to modern times.",
    condition: "Like New",
    sellerPhone: "8765432100",
    sellerUPI: "sarahj@upi",
    bankDetails: "BOB Account: 6543210987, IFSC: BARB0001234",
  ),
  Course(
    title: "Computer Science",
    iconSrc: "assets/icons/book.svg",
    color: const Color(0xFF59AABD),
    subject: "Computer Science",
    bookClass: "12th Grade",
    price: "₹2500",
    seller: "David Miller",
    description:
        "Introduction to programming, algorithms, and data structures.",
    condition: "Very Good",
    sellerPhone: "7654321090",
    sellerUPI: "davidm@upi",
    bankDetails: "Canara Account: 3456789012, IFSC: CNRB0001234",
  ),
];
