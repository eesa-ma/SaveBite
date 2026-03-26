import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int COMPLAINT_SUSPENSION_THRESHOLD = 5;

  /// Submit a food safety report
  Future<void> submitReport({
    required String userId,
    required String restaurantId,
    required String restaurantName,
    required String foodId,
    required String foodName,
    required String orderId,
    required String reason,
    required String description,
  }) async {
    try {
      // Step 1: Create the report document
      final reportRef = _firestore.collection('reports').doc();
      await reportRef.set({
        'userId': userId,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'foodId': foodId,
        'foodName': foodName,
        'orderId': orderId,
        'reason': reason,
        'description': description,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Step 2: Get restaurant data
      final restaurantRef = _firestore
          .collection('restaurants')
          .doc(restaurantId);
      final restaurantSnapshot = await restaurantRef.get();

      if (restaurantSnapshot.exists) {
        final data = restaurantSnapshot.data() ?? {};
        final currentComplaintCount = (data['complaintCount'] as int?) ?? 0;
        final newComplaintCount = currentComplaintCount + 1;
        final ownerRef = data['ownerId'] as String?;

        // Step 3: Update complaint count
        await restaurantRef.update({'complaintCount': newComplaintCount});

        // Step 4: Suspend restaurant if threshold reached
        if (newComplaintCount >= COMPLAINT_SUSPENSION_THRESHOLD) {
          await restaurantRef.update({
            'status': 'suspended',
            'isOpen': false,
            'suspendedAt': FieldValue.serverTimestamp(),
            'suspensionReason': 'Multiple food safety complaints',
          });
        }

        // Step 5: Create notification for owner
        if (ownerRef != null) {
          await _firestore.collection('notifications').doc().set({
            'userId': ownerRef,
            'type': 'complaint',
            'title': 'New Food Safety Complaint',
            'message':
                'A customer has filed a food safety complaint for "$foodName".',
            'restaurantId': restaurantId,
            'reportId': reportRef.id,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Get all reports for admin
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get reports for a specific restaurant
  Stream<QuerySnapshot<Map<String, dynamic>>> streamRestaurantReports(
    String restaurantId,
  ) {
    return _firestore
        .collection('reports')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get reports by status
  Stream<QuerySnapshot<Map<String, dynamic>>> streamReportsByStatus(
    String status,
  ) {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Mark report as reviewed
  Future<void> markReportAsReviewed(
    String reportId,
    String adminId, {
    String? adminNotes,
  }) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'reviewed',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
        'adminNotes': adminNotes,
      });
    } catch (e) {
      throw Exception('Failed to mark report as reviewed: $e');
    }
  }

  /// Mark report as resolved
  Future<void> markReportAsResolved(String reportId, String adminId) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'resolved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
      });
    } catch (e) {
      throw Exception('Failed to mark report as resolved: $e');
    }
  }

  /// Suspend a restaurant
  Future<void> suspendRestaurant(String restaurantId, {String? reason}) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'status': 'suspended',
        'isOpen': false,
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspensionReason': reason ?? 'Suspended due to complaints',
      });
    } catch (e) {
      throw Exception('Failed to suspend restaurant: $e');
    }
  }

  /// Unsuspend a restaurant
  Future<void> unsuspendRestaurant(String restaurantId) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'status': 'approved',
        'isOpen': true,
        'suspendedAt': null,
        'suspensionReason': null,
      });
    } catch (e) {
      throw Exception('Failed to unsuspend restaurant: $e');
    }
  }

  /// Get complaint count for a restaurant
  Future<int> getRestaurantComplaintCount(String restaurantId) async {
    try {
      final doc = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .get();
      if (doc.exists) {
        return (doc.data()?['complaintCount'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      throw Exception('Failed to fetch complaint count: $e');
    }
  }

  /// Delete a report (admin action)
  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }
}
