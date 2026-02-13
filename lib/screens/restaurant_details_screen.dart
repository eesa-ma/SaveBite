import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:save_bite/models/food_item.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  RestaurantDetailsScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  final String restaurantId;
  final String restaurantName;
  final ValueNotifier<Set<String>> _reservingIds = ValueNotifier<Set<String>>(
    {},
  );

  static const Color _primaryColor = Color(0xFF2E7D32);

  Future<void> reserveFood(
    BuildContext context,
    FoodItem item,
    int quantity,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to reserve.')),
      );
      return;
    }

    if (_reservingIds.value.contains(item.id)) {
      return;
    }

    if (quantity <= 0) {
      return;
    }

    _setReserving(item.id, true);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final itemRef = FirebaseFirestore.instance
            .collection('foodItems')
            .doc(item.id);
        final snapshot = await transaction.get(itemRef);

        if (!snapshot.exists) {
          throw StateError('Item no longer exists.');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final quantityValue = data['quantityAvailable'];
        final currentQty = (quantityValue is num) ? quantityValue.toInt() : 0;

        if (currentQty <= 0) {
          throw StateError('Sold out.');
        }

        if (quantity > currentQty) {
          throw StateError('Only $currentQty left.');
        }

        final newQty = currentQty - quantity;
        transaction.update(itemRef, {
          'quantityAvailable': newQty,
          'isAvailable': newQty > 0,
        });

        final orderRef = FirebaseFirestore.instance.collection('orders').doc();
        transaction.set(orderRef, {
          'restaurantId': restaurantId,
          'foodItemId': item.id,
          'foodName': item.name,
          'quantity': quantity,
          'userId': user.uid,
          'status': 'new',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reserved $quantity x ${item.name}')),
      );
    } on StateError catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reservation failed: $e')));
    } finally {
      _setReserving(item.id, false);
    }
  }

  void _setReserving(String id, bool isReserving) {
    final updated = Set<String>.from(_reservingIds.value);
    if (isReserving) {
      updated.add(id);
    } else {
      updated.remove(id);
    }
    _reservingIds.value = updated;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final itemsStream = FirebaseFirestore.instance
        .collection('foodItems')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isAvailable', isEqualTo: true)
        .where('quantityAvailable', isGreaterThan: 0)
        .orderBy('quantityAvailable')
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(restaurantName),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: itemsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildMessage('Unable to load items. ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final items = docs.map(FoodItem.fromDoc).toList();

          if (items.isEmpty) {
            return _buildMessage('No available items right now.');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildFoodCard(context, items[index], user);
            },
          );
        },
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, FoodItem item, User? user) {
    final isSoldOut = item.quantityAvailable <= 0 || !item.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.description, style: TextStyle(color: Colors.grey[700])),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Only ${item.quantityAvailable} left',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                ValueListenableBuilder<Set<String>>(
                  valueListenable: _reservingIds,
                  builder: (context, reservingIds, _) {
                    final isReserving = reservingIds.contains(item.id);

                    if (user == null) {
                      return ElevatedButton(
                        onPressed: isSoldOut
                            ? null
                            : () async {
                                final quantity = await _showQuantityDialog(
                                  context,
                                  item,
                                );
                                if (quantity == null) {
                                  return;
                                }
                                await reserveFood(context, item, quantity);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isSoldOut ? 'Sold Out' : 'Reserve',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('userId', isEqualTo: user.uid)
                          .where('foodItemId', isEqualTo: item.id)
                          .where(
                            'status',
                            whereIn: ['new', 'preparing', 'ready'],
                          )
                          .snapshots(),
                      builder: (context, orderSnapshot) {
                        final hasActiveOrder =
                            orderSnapshot.hasData &&
                            (orderSnapshot.data?.docs.isNotEmpty ?? false);
                        return ElevatedButton(
                          onPressed:
                              (isSoldOut || isReserving || hasActiveOrder)
                              ? null
                              : () async {
                                  final quantity = await _showQuantityDialog(
                                    context,
                                    item,
                                  );
                                  if (quantity == null) {
                                    return;
                                  }
                                  await reserveFood(context, item, quantity);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isReserving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isSoldOut
                                      ? 'Sold Out'
                                      : (hasActiveOrder
                                            ? 'Reserved'
                                            : 'Reserve'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Future<int?> _showQuantityDialog(BuildContext context, FoodItem item) {
    return showDialog<int>(
      context: context,
      builder: (context) {
        var quantity = 1;
        final maxQty = item.quantityAvailable;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Reserve ${item.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available: $maxQty'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: quantity < maxQty
                            ? () => setState(() => quantity++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: maxQty > 0
                      ? () => Navigator.pop(context, quantity)
                      : null,
                  style: FilledButton.styleFrom(backgroundColor: _primaryColor),
                  child: Text('Reserve $quantity'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
