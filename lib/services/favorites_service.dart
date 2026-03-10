import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FavoritesService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add restaurant to favorites
  Future<void> addRestaurantFavorite(
    String restaurantId,
    String restaurantName,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('restaurants')
          .set(
            {restaurantId: restaurantName},
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Error adding restaurant favorite: $e');
      rethrow;
    }
  }

  // Remove restaurant from favorites
  Future<void> removeRestaurantFavorite(String restaurantId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('restaurants')
          .update({restaurantId: FieldValue.delete()});
    } catch (e) {
      debugPrint('Error removing restaurant favorite: $e');
      rethrow;
    }
  }

  // Check if restaurant is favorited
  Future<bool> isRestaurantFavorited(String restaurantId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('restaurants')
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        return data.containsKey(restaurantId);
      }
      return false;
    } catch (e) {
      debugPrint('Error checking restaurant favorite: $e');
      return false;
    }
  }

  // Add food item to favorites
  Future<void> addFoodItemFavorite(
    String restaurantId,
    String itemId,
    String itemName,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('items')
          .set(
            {
              itemId: {
                'name': itemName,
                'restaurantId': restaurantId,
              }
            },
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Error adding food item favorite: $e');
      rethrow;
    }
  }

  // Remove food item from favorites
  Future<void> removeFoodItemFavorite(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('items')
          .update({itemId: FieldValue.delete()});
    } catch (e) {
      debugPrint('Error removing food item favorite: $e');
      rethrow;
    }
  }

  // Check if food item is favorited
  Future<bool> isFoodItemFavorited(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('items')
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        return data.containsKey(itemId);
      }
      return false;
    } catch (e) {
      debugPrint('Error checking food item favorite: $e');
      return false;
    }
  }

  // Get all favorite restaurants
  Future<List<Map<String, dynamic>>> getFavoriteRestaurants() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('restaurants')
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        return data.entries
            .map((e) => {'id': e.key, 'name': e.value})
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting favorite restaurants: $e');
      return [];
    }
  }

  // Get all favorite food items
  Future<List<Map<String, dynamic>>> getFavoriteFoodItems() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('items')
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        return data.entries
            .map((e) => {
              'id': e.key,
              'name': e.value['name'],
              'restaurantId': e.value['restaurantId'],
            })
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting favorite food items: $e');
      return [];
    }
  }
}
