import 'package:cloud_firestore/cloud_firestore.dart';

class Bid {
  final String? id;
  final String bookId;
  final String bookTitle;
  final String bidderId;
  final String bidderName;
  final String? bidderPhone;
  final double bidAmount;
  final String? message;
  final Timestamp createdAt;
  final String status; // 'pending', 'accepted', 'rejected'

  Bid({
    this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bidderId,
    required this.bidderName,
    this.bidderPhone,
    required this.bidAmount,
    this.message,
    required this.createdAt,
    this.status = 'pending',
  });

  // Factory method to create a Bid from a Firestore document
  factory Bid.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data;
    try {
      data = doc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing bid document data: $e');
      data = {};
    }

    return Bid(
      id: doc.id,
      bookId: data['bookId'] ?? '',
      bookTitle: data['bookTitle'] ?? '',
      bidderId: data['bidderId'] ?? '',
      bidderName: data['bidderName'] ?? 'Anonymous',
      bidderPhone: data['bidderPhone'],
      bidAmount: _parseAmount(data['bidAmount']),
      message: data['message'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'pending',
    );
  }

  // Helper to safely parse bid amount
  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Convert Bid to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'bidderId': bidderId,
      'bidderName': bidderName,
      if (bidderPhone != null) 'bidderPhone': bidderPhone,
      'bidAmount': bidAmount,
      if (message != null) 'message': message,
      'createdAt': createdAt,
      'status': status,
    };
  }

  // Create a copy of the bid with updated fields
  Bid copyWith({
    String? id,
    String? bookId,
    String? bookTitle,
    String? bidderId,
    String? bidderName,
    String? bidderPhone,
    double? bidAmount,
    String? message,
    Timestamp? createdAt,
    String? status,
  }) {
    return Bid(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      bidderId: bidderId ?? this.bidderId,
      bidderName: bidderName ?? this.bidderName,
      bidderPhone: bidderPhone ?? this.bidderPhone,
      bidAmount: bidAmount ?? this.bidAmount,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
