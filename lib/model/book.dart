import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String? id;
  final String title;
  final String author;
  final String category;
  final String description;
  final double price;
  final String sellerId;
  final String sellerName;
  final String? sellerPhone;
  final String? coverImageUrl;
  final Timestamp createdAt;
  final bool isAvailable;
  final String condition;
  final String grade; // Student grade level (1, 2, 3, etc.)

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    required this.price,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhone,
    this.coverImageUrl,
    required this.createdAt,
    this.isAvailable = true,
    this.condition = 'Good',
    this.grade = 'All', // Default to "All" grades
  });

  // Factory method to create a Book from a Firestore document
  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data;
    try {
      data = doc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing document data: $e');
      data = {};
    }

    // Use null-safe getters with defaults for all fields
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      category: data['category'] ?? 'Standard',
      description: data['description'] ?? '',
      price: _parsePrice(data['price']),
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Anonymous',
      sellerPhone: data['sellerPhone'],
      coverImageUrl: data['coverImageUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isAvailable: data['isAvailable'] ?? true,
      condition: data['condition'] ?? 'Good',
      grade: data['grade'] ?? 'All',
    );
  }

  // Helper to safely parse price
  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Convert Book to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'category': category,
      'description': description,
      'price': price,
      'sellerId': sellerId,
      'sellerName': sellerName,
      if (sellerPhone != null) 'sellerPhone': sellerPhone,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      'createdAt': createdAt,
      'isAvailable': isAvailable,
      'condition': condition,
      'grade': grade,
    };
  }

  // Create a copy of the book with updated fields
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? category,
    String? description,
    double? price,
    String? sellerId,
    String? sellerName,
    String? sellerPhone,
    String? coverImageUrl,
    Timestamp? createdAt,
    bool? isAvailable,
    String? condition,
    String? grade,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
      condition: condition ?? this.condition,
      grade: grade ?? this.grade,
    );
  }
}
