import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String reportId;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final String foodId;
  final String foodName;
  final String orderId;
  final String reason;
  final String description;
  final String status; // pending, reviewed, resolved
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy; // admin who reviewed
  final String? adminNotes;

  Report({
    required this.reportId,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.foodId,
    required this.foodName,
    required this.orderId,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.adminNotes,
  });

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAtValue = data['createdAt'];
    final reviewedAtValue = data['reviewedAt'];

    return Report(
      reportId: doc.id,
      userId: data['userId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      foodId: data['foodId'] ?? '',
      foodName: data['foodName'] ?? '',
      orderId: data['orderId'] ?? '',
      reason: data['reason'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
      reviewedAt: reviewedAtValue is Timestamp
          ? reviewedAtValue.toDate()
          : null,
      reviewedBy: data['reviewedBy'],
      adminNotes: data['adminNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'foodId': foodId,
      'foodName': foodName,
      'orderId': orderId,
      'reason': reason,
      'description': description,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
