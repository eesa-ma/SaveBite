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
      'createdAt': FieldValue.serverTimestamp(),
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
    required String description,
    required double price,
    required int quantityAvailable,
  }) {
    return _firestore.collection('foodItems').add({
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'quantityAvailable': quantityAvailable,
      'isAvailable': quantityAvailable > 0,
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
}
