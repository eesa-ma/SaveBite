import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamRestaurants(
    String ownerId,
  ) {
    return _firestore
        .collection('restaurants')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<DocumentReference<Map<String, dynamic>>> addRestaurant({
    required String ownerId,
    required String name,
    required String address,
    required String phone,
    required String email,
    required String hours,
    required bool isOpen,
    required double latitude,
    required double longitude,
    required String imageUrl,
  }) {
    return _firestore.collection('restaurants').add({
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'hours': hours,
      'isOpen': isOpen,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMenuItems(
    String restaurantId,
  ) {
    return _firestore
        .collection('foodItems')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamOrders(
    String restaurantId,
  ) {
    return _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots();
  }

  Future<void> addMenuItem({
    required String restaurantId,
    required String name,
    required String category,
    required double price,
    required int quantityAvailable,
    required String imageUrl,
  }) {
    return _firestore.collection('foodItems').add({
      'restaurantId': restaurantId,
      'name': name,
      'description': category,
      'category': category,
      'price': price,
      'quantityAvailable': quantityAvailable,
      'isAvailable': quantityAvailable > 0,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMenuItem(String foodId, Map<String, dynamic> updates) {
    return _firestore.collection('foodItems').doc(foodId).update(updates);
  }

  Future<void> deleteMenuItem(String foodId) {
    return _firestore.collection('foodItems').doc(foodId).delete();
  }

  Future<void> updateOrderStatus(String orderId, String status) {
    return _firestore.collection('orders').doc(orderId).update({
      'status': status,
    });
  }

  Future<void> updateRestaurantStatus(String restaurantId, bool isOpen) {
    return _firestore.collection('restaurants').doc(restaurantId).update({
      'isOpen': isOpen,
    });
  }

  Future<void> _deleteQueryInBatches(Query<Map<String, dynamic>> query) async {
    while (true) {
      final snapshot = await query.limit(400).get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < 400) {
        break;
      }
    }
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    final orderIds = <String>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? lastOrderDoc;

    while (true) {
      Query<Map<String, dynamic>> query = _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy(FieldPath.documentId)
          .limit(400);

      if (lastOrderDoc != null) {
        query = query.startAfterDocument(lastOrderDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      orderIds.addAll(snapshot.docs.map((doc) => doc.id));
      lastOrderDoc = snapshot.docs.last;

      if (snapshot.docs.length < 400) {
        break;
      }
    }

    await _deleteQueryInBatches(
      _firestore
          .collection('foodItems')
          .where('restaurantId', isEqualTo: restaurantId),
    );

    await _deleteQueryInBatches(
      _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId),
    );

    await _deleteQueryInBatches(
      _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: restaurantId),
    );

    // Some legacy review docs may not include restaurantId, so also delete by orderId.
    for (var i = 0; i < orderIds.length; i += 10) {
      final chunk = orderIds.sublist(
        i,
        (i + 10) > orderIds.length ? orderIds.length : (i + 10),
      );
      await _deleteQueryInBatches(
        _firestore.collection('reviews').where('orderId', whereIn: chunk),
      );
    }

    await _firestore.collection('restaurants').doc(restaurantId).delete();
  }
}
