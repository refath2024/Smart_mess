import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/premium_request.dart';

class PremiumRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference for premium requests
  CollectionReference get _premiumRequestsCollection =>
      _firestore.collection('premium_requests');

  /// Submit a new premium request
  Future<String?> submitPremiumRequest({
    required String mealType,
    required String preferredMeal,
    required DateTime requestedDate,
    required String reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user data from user_requests collection
      final userDoc = await _firestore
          .collection('user_requests')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final userData = userDoc.data()!;
      final cost = PremiumMealOptions.getCostForMeal(preferredMeal);

      final premiumRequest = PremiumRequest(
        id: '', // Will be set by Firestore
        userId: user.uid,
        userName: userData['name'] ?? '',
        userRank: userData['rank'] ?? '',
        baNumber: userData['ba_no'] ?? '',
        requestType: 'premium_meal',
        mealType: mealType,
        preferredMeal: preferredMeal,
        requestedDate: requestedDate,
        reason: reason,
        status: 'pending',
        createdAt: DateTime.now(),
        additionalCost: cost,
      );

      final docRef = await _premiumRequestsCollection.add(premiumRequest.toMap());
      
      return docRef.id;
    } catch (e) {
      print('Error submitting premium request: $e');
      return null;
    }
  }

  /// Get user's premium requests
  Stream<List<PremiumRequest>> getUserPremiumRequests() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _premiumRequestsCollection
        .where('user_id', isEqualTo: user.uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PremiumRequest.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Get all pending premium requests (for admin)
  Stream<List<PremiumRequest>> getPendingPremiumRequests() {
    return _premiumRequestsCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PremiumRequest.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Get all premium requests (for admin)
  Stream<List<PremiumRequest>> getAllPremiumRequests() {
    return _premiumRequestsCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PremiumRequest.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Approve a premium request (admin only)
  Future<bool> approvePremiumRequest(String requestId, String adminName) async {
    try {
      await _premiumRequestsCollection.doc(requestId).update({
        'status': 'approved',
        'approved_by': adminName,
        'approved_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error approving premium request: $e');
      return false;
    }
  }

  /// Reject a premium request (admin only)
  Future<bool> rejectPremiumRequest(
    String requestId, 
    String adminName, 
    String rejectionReason,
  ) async {
    try {
      await _premiumRequestsCollection.doc(requestId).update({
        'status': 'rejected',
        'approved_by': adminName,
        'approved_at': FieldValue.serverTimestamp(),
        'rejection_reason': rejectionReason,
      });
      return true;
    } catch (e) {
      print('Error rejecting premium request: $e');
      return false;
    }
  }

  /// Get premium requests for a specific date (for kitchen planning)
  Future<List<PremiumRequest>> getApprovedRequestsForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _premiumRequestsCollection
          .where('status', isEqualTo: 'approved')
          .where('requested_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('requested_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs.map((doc) {
        return PremiumRequest.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error getting premium requests for date: $e');
      return [];
    }
  }

  /// Delete a premium request (user can delete only pending requests)
  Future<bool> deletePremiumRequest(String requestId) async {
    try {
      final doc = await _premiumRequestsCollection.doc(requestId).get();
      
      if (!doc.exists) {
        throw Exception('Request not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      
      // Only allow deletion of pending requests
      if (data['status'] != 'pending') {
        throw Exception('Can only delete pending requests');
      }

      // Verify ownership
      final user = _auth.currentUser;
      if (user == null || data['user_id'] != user.uid) {
        throw Exception('Unauthorized');
      }

      await _premiumRequestsCollection.doc(requestId).delete();
      return true;
    } catch (e) {
      print('Error deleting premium request: $e');
      return false;
    }
  }

  /// Get premium request statistics
  Future<Map<String, dynamic>> getPremiumRequestStats() async {
    try {
      final allRequests = await _premiumRequestsCollection.get();
      
      int totalRequests = allRequests.docs.length;
      int pendingRequests = 0;
      int approvedRequests = 0;
      int rejectedRequests = 0;
      double totalRevenue = 0.0;

      for (final doc in allRequests.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? '';
        
        switch (status) {
          case 'pending':
            pendingRequests++;
            break;
          case 'approved':
            approvedRequests++;
            totalRevenue += (data['additional_cost']?.toDouble() ?? 0.0);
            break;
          case 'rejected':
            rejectedRequests++;
            break;
        }
      }

      return {
        'total_requests': totalRequests,
        'pending_requests': pendingRequests,
        'approved_requests': approvedRequests,
        'rejected_requests': rejectedRequests,
        'total_revenue': totalRevenue,
        'approval_rate': totalRequests > 0 ? (approvedRequests / totalRequests * 100) : 0.0,
      };
    } catch (e) {
      print('Error getting premium request stats: $e');
      return {
        'total_requests': 0,
        'pending_requests': 0,
        'approved_requests': 0,
        'rejected_requests': 0,
        'total_revenue': 0.0,
        'approval_rate': 0.0,
      };
    }
  }
}