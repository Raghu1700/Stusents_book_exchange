import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive_animation/model/bid.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BidService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ensure collection names are consistent
  static const String bidsCollection = 'bids';
  static const String booksCollection = 'book';

  // Stream controller to notify when bids are updated
  final StreamController<bool> _refreshController =
      StreamController<bool>.broadcast();

  // Stream that can be listened to for updates
  Stream<bool> get refreshStream => _refreshController.stream;

  // Method to notify listeners that bids have been updated
  void notifyBookUpdate() {
    _refreshController.add(true);
  }

  // Dispose the controller when not needed
  void dispose() {
    _refreshController.close();
  }

  // Place a new bid
  Future<String?> placeBid({
    required String bookId,
    required String bookTitle,
    required double bidAmount,
    String? message,
    String? bidderPhone,
  }) async {
    try {
      debugPrint('===== PLACING BID =====');
      debugPrint('Book ID: $bookId');
      debugPrint('Book Title: $bookTitle');
      debugPrint('Bid Amount: $bidAmount');
      debugPrint('Message: $message');
      debugPrint('Bidder Phone: $bidderPhone');

      // Validation
      if (bookId.isEmpty) {
        throw Exception('Book ID cannot be empty');
      }

      if (bidAmount <= 0) {
        throw Exception('Bid amount must be greater than zero');
      }

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint(
          'Current User: ${currentUser.uid} (${currentUser.displayName ?? 'Anonymous'})');

      // Prepare bid data
      final Map<String, dynamic> bidData = {
        'bookId': bookId,
        'bookTitle': bookTitle,
        'bidderId': currentUser.uid,
        'bidderName': currentUser.displayName ?? 'Anonymous',
        'bidAmount': bidAmount,
        'createdAt': Timestamp.now(),
        'status': 'pending',
      };

      if (message != null && message.isNotEmpty) {
        bidData['message'] = message;
      }

      if (bidderPhone != null && bidderPhone.isNotEmpty) {
        bidData['bidderPhone'] = bidderPhone;
      }

      debugPrint('Bid data prepared: $bidData');
      debugPrint('Adding to collection: $bidsCollection');

      // Add to Firestore with specific error handling
      DocumentReference bidRef;
      try {
        bidRef = await _firestore.collection(bidsCollection).add(bidData);
        debugPrint('Bid saved to Firestore with ID: ${bidRef.id}');
      } catch (e) {
        debugPrint('CRITICAL ERROR saving bid to Firestore: $e');
        return null;
      }

      // Double check success by reading the document back
      try {
        final savedBid =
            await _firestore.collection(bidsCollection).doc(bidRef.id).get();
        if (savedBid.exists) {
          debugPrint('Verified bid was saved: ${savedBid.data()}');
        } else {
          debugPrint('WARNING: Could not verify bid was saved!');
          // Try to recreate if verification failed
          await _firestore
              .collection(bidsCollection)
              .doc(bidRef.id)
              .set(bidData);
        }
      } catch (e) {
        debugPrint('Error verifying bid was saved: $e');
      }

      // Also update the book document to indicate it has bids
      try {
        await _firestore.collection(booksCollection).doc(bookId).update({
          'hasBids': true,
        });
        debugPrint('Book updated with hasBids flag');
      } catch (e) {
        debugPrint('Error updating book hasBids flag: $e');
        // Continue despite this error
      }

      debugPrint('===== BID PLACED SUCCESSFULLY =====');

      // Notify listeners that bids have been updated
      notifyBookUpdate();

      return bidRef.id;
    } catch (e) {
      debugPrint('ERROR placing bid: $e');
      return null;
    }
  }

  // Get all bids for a specific book
  Future<List<Bid>> getBidsForBook(String bookId) async {
    try {
      debugPrint('Getting bids for book: $bookId');
      final querySnapshot = await _firestore
          .collection(bidsCollection)
          .where('bookId', isEqualTo: bookId)
          .orderBy('bidAmount', descending: true)
          .get();

      debugPrint('Found ${querySnapshot.docs.length} bids for book $bookId');
      return querySnapshot.docs.map((doc) => Bid.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting bids for book: $e');
      return [];
    }
  }

  // Get all bids placed by the current user
  Future<List<Bid>> getUserBids() async {
    try {
      debugPrint('===== FETCHING USER BIDS =====');
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint(
          'Current User: ${currentUser.uid} (${currentUser.displayName ?? 'Anonymous'})');

      // Simplify query to avoid index errors - removed orderBy
      final querySnapshot = await _firestore
          .collection(bidsCollection)
          .where('bidderId', isEqualTo: currentUser.uid)
          .get();

      debugPrint('Found ${querySnapshot.docs.length} bids placed by user');

      List<Bid> bids =
          querySnapshot.docs.map((doc) => Bid.fromFirestore(doc)).toList();

      // Debug: log all bid statuses
      for (var bid in bids) {
        debugPrint('User bid (${bid.id}) status: ${bid.status}');
      }

      debugPrint('===== USER BIDS FETCHED =====');
      return bids;
    } catch (e) {
      debugPrint('ERROR getting user bids: $e');
      return [];
    }
  }

  // Get all bids received on books the current user is selling
  Future<List<Bid>> getReceivedBids() async {
    try {
      debugPrint('===== FETCHING RECEIVED BIDS =====');
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // First, get all books that the user is selling
      final booksSnapshot = await _firestore
          .collection(booksCollection)
          .where('sellerId', isEqualTo: currentUser.uid)
          .get();

      if (booksSnapshot.docs.isEmpty) {
        debugPrint('No books found for this seller');
        return [];
      }

      // Extract book IDs
      final bookIds = booksSnapshot.docs.map((doc) => doc.id).toList();
      debugPrint('Found ${bookIds.length} books by this seller');

      final List<Bid> bids = [];

      // Query each book individually to avoid whereIn with orderBy index issues
      for (String bookId in bookIds) {
        try {
          final bidsSnapshot = await _firestore
              .collection(bidsCollection)
              .where('bookId', isEqualTo: bookId)
              .get();

          final bookBids =
              bidsSnapshot.docs.map((doc) => Bid.fromFirestore(doc)).toList();

          // Debug: log all bid statuses for this book
          for (var bid in bookBids) {
            debugPrint('Book $bookId - Bid (${bid.id}) status: ${bid.status}');
          }

          bids.addAll(bookBids);
        } catch (e) {
          debugPrint('Error getting bids for book $bookId: $e');
          // Continue with next book
        }
      }

      debugPrint('===== RECEIVED BIDS FETCHED: ${bids.length} =====');
      return bids;
    } catch (e) {
      debugPrint('Error getting received bids: $e');
      return [];
    }
  }

  // Update the status of a bid (accept or reject)
  Future<bool> updateBidStatus(String bidId, String status) async {
    try {
      debugPrint('===== UPDATING BID STATUS =====');
      debugPrint('Bid ID: $bidId, New Status: $status');

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the bid
      final bidDoc =
          await _firestore.collection(bidsCollection).doc(bidId).get();
      if (!bidDoc.exists) {
        throw Exception('Bid not found');
      }

      final bid = Bid.fromFirestore(bidDoc);
      debugPrint('Found bid for book: ${bid.bookTitle}');

      // Get the book to verify ownership
      final bookDoc =
          await _firestore.collection(booksCollection).doc(bid.bookId).get();
      if (!bookDoc.exists) {
        throw Exception('Book not found');
      }

      final bookData = bookDoc.data() as Map<String, dynamic>;
      if (bookData['sellerId'] != currentUser.uid) {
        throw Exception('You can only accept/reject bids for your own books');
      }

      // Update the bid status - don't delete, just update status
      debugPrint('Updating bid status to: $status');
      await _firestore.collection(bidsCollection).doc(bidId).update({
        'status': status,
      });
      debugPrint('Bid status updated successfully!');

      // If accepting the bid, update the book as no longer available
      if (status == 'accepted') {
        debugPrint('Accepting bid, updating book availability');
        await _firestore.collection(booksCollection).doc(bid.bookId).update({
          'isAvailable': false,
          'soldToBidder': bid.bidderId,
          'soldAt': Timestamp.now(),
          'soldPrice': bid.bidAmount,
        });
        debugPrint('Book marked as sold successfully!');
      }

      debugPrint('===== BID STATUS UPDATE COMPLETED =====');
      return true;
    } catch (e) {
      debugPrint('Error updating bid status: $e');
      return false;
    }
  }

  // Delete a bid (can only be done by the bidder)
  Future<bool> deleteBid(String bidId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the bid
      final bidDoc =
          await _firestore.collection(bidsCollection).doc(bidId).get();
      if (!bidDoc.exists) {
        throw Exception('Bid not found');
      }

      final bid = Bid.fromFirestore(bidDoc);

      // Verify that the current user is the bidder
      if (bid.bidderId != currentUser.uid) {
        throw Exception('You can only delete your own bids');
      }

      // Delete the bid
      await _firestore.collection(bidsCollection).doc(bidId).delete();

      // Check if this was the only bid for the book and update the book accordingly
      final otherBidsSnapshot = await _firestore
          .collection(bidsCollection)
          .where('bookId', isEqualTo: bid.bookId)
          .limit(1)
          .get();

      if (otherBidsSnapshot.docs.isEmpty) {
        // No other bids found, update the book
        await _firestore.collection(booksCollection).doc(bid.bookId).update({
          'hasBids': false,
        });
      }

      return true;
    } catch (e) {
      print('Error deleting bid: $e');
      return false;
    }
  }

  // Get all bids placed by the current user that were accepted
  Future<List<Bid>> getAcceptedUserBids() async {
    try {
      debugPrint('===== FETCHING ACCEPTED USER BIDS =====');
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      // Query bids placed by the current user with status "accepted"
      final querySnapshot = await _firestore
          .collection(bidsCollection)
          .where('bidderId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      debugPrint(
          'Found ${querySnapshot.docs.length} accepted bids placed by user');

      // Get more details about the books
      List<Bid> acceptedBids = [];
      for (var doc in querySnapshot.docs) {
        final bid = Bid.fromFirestore(doc);

        // Try to get the seller's contact information
        try {
          final bookDoc = await _firestore
              .collection(booksCollection)
              .doc(bid.bookId)
              .get();
          if (bookDoc.exists) {
            final bookData = bookDoc.data() as Map<String, dynamic>;
            String? sellerPhone = bookData['sellerPhone'];
            String sellerId = bookData['sellerId'] ?? '';

            // If seller phone is not in the book document, try to get it from the user's profile
            if ((sellerPhone == null || sellerPhone.isEmpty) &&
                sellerId.isNotEmpty) {
              final userDoc =
                  await _firestore.collection('users').doc(sellerId).get();
              if (userDoc.exists) {
                final userData = userDoc.data() as Map<String, dynamic>;
                sellerPhone = userData['phoneNumber'];
              }
            }

            debugPrint('Book seller phone: $sellerPhone');

            // Only add the bid if we found the book
            acceptedBids.add(bid);
          }
        } catch (e) {
          debugPrint('Error getting book details for bid ${bid.id}: $e');
          // Still add the bid even if we couldn't get book details
          acceptedBids.add(bid);
        }
      }

      debugPrint('===== ACCEPTED USER BIDS FETCHED =====');
      return acceptedBids;
    } catch (e) {
      debugPrint('ERROR getting accepted user bids: $e');
      return [];
    }
  }

  // Get all bids received that the current user has accepted
  Future<List<Bid>> getAcceptedReceivedBids() async {
    try {
      debugPrint('===== FETCHING BIDS ACCEPTED BY USER =====');
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // First, get all books that the user is selling
      final booksSnapshot = await _firestore
          .collection(booksCollection)
          .where('sellerId', isEqualTo: currentUser.uid)
          .get();

      if (booksSnapshot.docs.isEmpty) {
        return [];
      }

      // Extract book IDs
      final bookIds = booksSnapshot.docs.map((doc) => doc.id).toList();
      final List<Bid> acceptedBids = [];

      // Query each book for accepted bids
      for (String bookId in bookIds) {
        try {
          final bidsSnapshot = await _firestore
              .collection(bidsCollection)
              .where('bookId', isEqualTo: bookId)
              .where('status', isEqualTo: 'accepted')
              .get();

          acceptedBids
              .addAll(bidsSnapshot.docs.map((doc) => Bid.fromFirestore(doc)));
        } catch (e) {
          debugPrint('Error getting accepted bids for book $bookId: $e');
          // Continue with next book
        }
      }

      debugPrint('===== BIDS ACCEPTED BY USER FETCHED =====');
      return acceptedBids;
    } catch (e) {
      debugPrint('Error getting bids accepted by user: $e');
      return [];
    }
  }
}
