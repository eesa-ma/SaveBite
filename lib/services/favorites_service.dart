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
    String? imageUrl,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('restaurants')
          .set({
            restaurantId: {'name': restaurantName, 'imageUrl': imageUrl ?? ''},
          }, SetOptions(merge: true));
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
    String? imageUrl,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('items')
          .set({
            itemId: {
              'name': itemName,
              'restaurantId': restaurantId,
              'imageUrl': imageUrl ?? '',
            },
          }, SetOptions(merge: true));
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

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc('restaurants')
        .get();

    if (doc.exists) {
      final data = doc.data() ?? {};
      final favorites = await Future.wait(
        data.entries.map((entry) async {
          final rawValue = entry.value;
          String name = 'Restaurant';
          String imageUrl = '';

          if (rawValue is Map<String, dynamic>) {
            name = (rawValue['name'] ?? 'Restaurant').toString();
            imageUrl = (rawValue['imageUrl'] ?? '').toString();
          } else {
            name = rawValue.toString();
          }

          var shouldInclude = true;

          try {
            final restaurantDoc = await _firestore
                .collection('restaurants')
                .doc(entry.key)
                .get();
            final restaurantData = restaurantDoc.data();

            if (restaurantData == null) {
              shouldInclude = false;
            } else {
              final status = (restaurantData['status'] ?? 'pending')
                  .toString()
                  .toLowerCase();
              // Only surface restaurants that are approved for customers.
              shouldInclude = status == 'approved';
              name = (restaurantData['name'] ?? name).toString();
              imageUrl = (restaurantData['imageUrl'] ?? imageUrl).toString();
            }
          } catch (e) {
            debugPrint('Error fetching restaurant favorite metadata: $e');
            shouldInclude = false;
          }

          if (imageUrl.isEmpty && shouldInclude) {
            try {
              final restaurantDoc = await _firestore
                  .collection('restaurants')
                  .doc(entry.key)
                  .get();
              final restaurantData = restaurantDoc.data();
              if (restaurantData != null) {
                name = (restaurantData['name'] ?? name).toString();
                imageUrl = (restaurantData['imageUrl'] ?? '').toString();
              }
            } catch (e) {
              debugPrint('Error fetching restaurant favorite metadata: $e');
            }
          }

          return shouldInclude
              ? {'id': entry.key, 'name': name, 'imageUrl': imageUrl}
              : null;
        }),
      );

      return favorites.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  // Get all favorite food items
  Future<List<Map<String, dynamic>>> getFavoriteFoodItems() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc('items')
        .get();

    if (doc.exists) {
      final data = doc.data() ?? {};
      final favorites = await Future.wait(
        data.entries.map((entry) async {
          final rawValue = entry.value;
          String name = 'Item';
          String restaurantId = '';
          String imageUrl = '';

          if (rawValue is Map<String, dynamic>) {
            name = (rawValue['name'] ?? 'Item').toString();
            restaurantId = (rawValue['restaurantId'] ?? '').toString();
            imageUrl = (rawValue['imageUrl'] ?? '').toString();
          }

          if (imageUrl.isEmpty || restaurantId.isEmpty) {
            try {
              final itemDoc = await _firestore
                  .collection('foodItems')
                  .doc(entry.key)
                  .get();
              final itemData = itemDoc.data();
              if (itemData != null) {
                name = (itemData['name'] ?? name).toString();
                restaurantId = (itemData['restaurantId'] ?? restaurantId)
                    .toString();
                imageUrl = (itemData['imageUrl'] ?? imageUrl).toString();
              }
            } catch (e) {
              debugPrint('Error fetching food favorite metadata: $e');
            }
          }

          return {
            'id': entry.key,
            'name': name,
            'restaurantId': restaurantId,
            'imageUrl': imageUrl,
          };
        }),
      );

      return favorites;
    }
    return [];
  }
}
