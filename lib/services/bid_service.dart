import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive_animation/model/bid.dart';

class BidService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String bidsCollection = 'bids';
  final String booksCollection = 'book';

  // Place a new bid
  Future<String?> placeBid({
    required String bookId,
    required String bookTitle,
    required double bidAmount,
    String? message,
    String? bidderPhone,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

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

      // Add to Firestore
      final DocumentReference bidRef =
          await _firestore.collection(bidsCollection).add(bidData);

      // Also update the book document to indicate it has bids
      await _firestore.collection(booksCollection).doc(bookId).update({
        'hasBids': true,
      });

      return bidRef.id;
    } catch (e) {
      print('Error placing bid: $e');
      return null;
    }
  }

  // Get all bids for a specific book
  Future<List<Bid>> getBidsForBook(String bookId) async {
    try {
      final querySnapshot = await _firestore
          .collection(bidsCollection)
          .where('bookId', isEqualTo: bookId)
          .orderBy('bidAmount', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Bid.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting bids for book: $e');
      return [];
    }
  }

  // Get all bids placed by the current user
  Future<List<Bid>> getUserBids() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(bidsCollection)
          .where('bidderId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Bid.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting user bids: $e');
      return [];
    }
  }

  // Get all bids received on books the current user is selling
  Future<List<Bid>> getReceivedBids() async {
    try {
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

      // Then, get all bids for those books
      final List<Bid> bids = [];

      // Process in batches of 10 to avoid too many concurrent Firestore queries
      for (int i = 0; i < bookIds.length; i += 10) {
        final end = (i + 10 < bookIds.length) ? i + 10 : bookIds.length;
        final batchIds = bookIds.sublist(i, end);

        final bidsSnapshot = await _firestore
            .collection(bidsCollection)
            .where('bookId', whereIn: batchIds)
            .orderBy('createdAt', descending: true)
            .get();

        bids.addAll(bidsSnapshot.docs.map((doc) => Bid.fromFirestore(doc)));
      }

      return bids;
    } catch (e) {
      print('Error getting received bids: $e');
      return [];
    }
  }

  // Update the status of a bid (accept or reject)
  Future<bool> updateBidStatus(String bidId, String status) async {
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

      // Update the bid status
      await _firestore.collection(bidsCollection).doc(bidId).update({
        'status': status,
      });

      // If accepting the bid, update the book as no longer available
      if (status == 'accepted') {
        await _firestore.collection(booksCollection).doc(bid.bookId).update({
          'isAvailable': false,
          'soldToBidder': bid.bidderId,
          'soldAt': Timestamp.now(),
          'soldPrice': bid.bidAmount,
        });
      }

      return true;
    } catch (e) {
      print('Error updating bid status: $e');
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
}
