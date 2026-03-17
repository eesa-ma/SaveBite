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
      final staleRestaurantIds = <String>[];

      final favorites = await Future.wait<Map<String, dynamic>?>(
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

          try {
            final restaurantDoc = await _firestore
                .collection('restaurants')
                .doc(entry.key)
                .get();

            if (!restaurantDoc.exists) {
              staleRestaurantIds.add(entry.key);
              return null;
            }

            final restaurantData = restaurantDoc.data() ?? {};
            name = (restaurantData['name'] ?? name).toString();
            imageUrl = (restaurantData['imageUrl'] ?? imageUrl).toString();
          } catch (e) {
            debugPrint('Error fetching restaurant favorite metadata: $e');
          }

          return {'id': entry.key, 'name': name, 'imageUrl': imageUrl};
        }),
      );

      if (staleRestaurantIds.isNotEmpty) {
        final updates = <String, dynamic>{
          for (final id in staleRestaurantIds) id: FieldValue.delete(),
        };

        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .doc('restaurants')
              .update(updates);
        } catch (e) {
          debugPrint('Error removing stale restaurant favorites: $e');
        }
      }

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
      final staleItemIds = <String>[];

      final favorites = await Future.wait<Map<String, dynamic>?>(
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

          try {
            final itemDoc = await _firestore
                .collection('foodItems')
                .doc(entry.key)
                .get();

            if (!itemDoc.exists) {
              staleItemIds.add(entry.key);
              return null;
            }

            final itemData = itemDoc.data() ?? {};
            name = (itemData['name'] ?? name).toString();
            restaurantId = (itemData['restaurantId'] ?? restaurantId).toString();
            imageUrl = (itemData['imageUrl'] ?? imageUrl).toString();
          } catch (e) {
            debugPrint('Error fetching food favorite metadata: $e');
          }

          return {
            'id': entry.key,
            'name': name,
            'restaurantId': restaurantId,
            'imageUrl': imageUrl,
          };
        }),
      );

      if (staleItemIds.isNotEmpty) {
        final updates = <String, dynamic>{
          for (final id in staleItemIds) id: FieldValue.delete(),
        };

        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .doc('items')
              .update(updates);
        } catch (e) {
          debugPrint('Error removing stale food item favorites: $e');
        }
      }

      return favorites.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}
