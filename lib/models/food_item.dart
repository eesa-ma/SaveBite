import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final int quantityAvailable;
  final bool isAvailable;
  final DateTime? createdAt;

  FoodItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.quantityAvailable,
    required this.isAvailable,
    required this.createdAt,
  });

  factory FoodItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final priceValue = data['price'];
    final quantityValue = data['quantityAvailable'];
    final createdAtValue = data['createdAt'];

    return FoodItem(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? 'Item',
      description: data['description'] ?? '',
      price: (priceValue is num) ? priceValue.toDouble() : 0.0,
      quantityAvailable: (quantityValue is num) ? quantityValue.toInt() : 0,
      isAvailable: data['isAvailable'] ?? false,
      createdAt: createdAtValue is Timestamp ? createdAtValue.toDate() : null,
    );
  }
}
