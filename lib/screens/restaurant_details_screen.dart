import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:save_bite/models/food_item.dart';
import 'package:save_bite/screens/checkout_screen.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  const RestaurantDetailsScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  final String restaurantId;
  final String restaurantName;

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  final ValueNotifier<Set<String>> _reservingIds = ValueNotifier<Set<String>>(
    {},
  );
  final ValueNotifier<Map<String, int>> _cartItems =
      ValueNotifier<Map<String, int>>({});
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _lightGrey = Color(0xFFF5F5F5);
  static const Color _mediumGrey = Color(0xFFBDBDBD);

  void _addToCart(FoodItem item) {
    final updated = Map<String, int>.from(_cartItems.value);
    updated[item.id] = (updated[item.id] ?? 0) + 1;
    _cartItems.value = updated;
  }

  void _removeFromCart(String itemId) {
    final updated = Map<String, int>.from(_cartItems.value);
    if (updated.containsKey(itemId)) {
      if (updated[itemId]! > 1) {
        updated[itemId] = updated[itemId]! - 1;
      } else {
        updated.remove(itemId);
      }
    }
    _cartItems.value = updated;
  }

  int _getCartCount() =>
      _cartItems.value.values.fold(0, (sum, qty) => sum + qty);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final itemsStream = FirebaseFirestore.instance
        .collection('foodItems')
        .where('restaurantId', isEqualTo: widget.restaurantId)
        .where('isAvailable', isEqualTo: true)
        .where('quantityAvailable', isGreaterThan: 0)
        .orderBy('quantityAvailable')
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: itemsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final items = docs.map(FoodItem.fromDoc).toList();

          if (items.isEmpty) {
            return _buildEmptyState();
          }

          // Filter items
          final filteredItems = items
              .where((item) =>
                  item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

          final categories = ['All', ...items.map((i) => i.description).toSet()];

          return Column(
            children: [
              // Header with restaurant details
              _buildHeader(),
              // Search bar
              _buildSearchBar(),
              // Main content
              Expanded(
                child: ListView(
                  children: [
                    // Restaurant info card
                    _buildRestaurantInfo(),
                    // Category filter
                    _buildCategoryFilter(categories),
                    // Food items
                    _buildFoodsList(filteredItems, user),
                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<Map<String, int>>(
        valueListenable: _cartItems,
        builder: (context, cartItems, _) {
          final count = _getCartCount();
          return count == 0
              ? const SizedBox.shrink()
              : _buildCartFAB(count, itemsStream);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _primaryColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.restaurantName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Serves fresh food daily',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: 'Search for items...',
          prefixIcon: const Icon(Icons.search, color: _mediumGrey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _lightGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _lightGrey),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          filled: true,
          fillColor: _lightGrey,
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoItem('⭐', '4.5', 'Rating'),
            _buildInfoItem('🚚', '30 min', 'Delivery'),
            _buildInfoItem('💵', '\$50', 'Min Order'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedCategory = category);
                },
                backgroundColor: Colors.white,
                selectedColor: _primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected ? _primaryColor : _lightGrey,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFoodsList(List<FoodItem> items, User? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: items
            .map((item) => _buildFoodItemCard(context, item, user))
            .toList(),
      ),
    );
  }

  Widget _buildFoodItemCard(
    BuildContext context,
    FoodItem item,
    User? user,
  ) {
    final isSoldOut = item.quantityAvailable <= 0 || !item.isAvailable;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _lightGrey)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food icon/image placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fastfood_outlined,
                color: _mediumGrey,
                size: 40,
              ),
            ),
            const SizedBox(width: 12),
            // Food details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.quantityAvailable < 5)
                    Text(
                      'Only ${item.quantityAvailable} left!',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            // Add/Remove buttons
            ValueListenableBuilder<Map<String, int>>(
              valueListenable: _cartItems,
              builder: (context, cartItems, _) {
                final quantity = cartItems[item.id] ?? 0;
                return quantity == 0
                    ? _buildAddButton(item, isSoldOut)
                    : _buildQuantityCounter(item, quantity, isSoldOut);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(FoodItem item, bool isSoldOut) {
    return ElevatedButton.icon(
      onPressed: isSoldOut ? null : () => _startCheckout(context, item),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Reserve'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildQuantityCounter(
    FoodItem item,
    int quantity,
    bool isSoldOut,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _primaryColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _removeFromCart(item.id),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.remove, size: 16, color: _primaryColor),
            ),
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: _primaryColor,
            ),
          ),
          InkWell(
            onTap: quantity < item.quantityAvailable
                ? () => _addToCart(item)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                Icons.add,
                size: 16,
                color: quantity < item.quantityAvailable
                    ? _primaryColor
                    : Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartFAB(
    int count,
    Stream<QuerySnapshot<Map<String, dynamic>>> itemsStream,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: itemsStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final items = docs.map(FoodItem.fromDoc).toList();

        double totalPrice = 0;
        _cartItems.value.forEach((itemId, quantity) {
          final item = items.firstWhere(
            (i) => i.id == itemId,
            orElse: () => FoodItem(
              id: '',
              restaurantId: '',
              name: '',
              description: '',
              price: 0,
              quantityAvailable: 0,
              isAvailable: false,
              createdAt: null,
            ),
          );
          totalPrice += item.price * quantity;
        });

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ElevatedButton(
            onPressed: () => _checkoutCart(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$count item${count > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Checkout • ₹${totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkoutCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to checkout.')),
      );
      return;
    }

    if (_cartItems.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    _setReserving('all', true);

    try {
      // Get all food items
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('foodItems')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .get();

      final items = itemsSnapshot.docs.map(FoodItem.fromDoc).toList();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        for (final entry in _cartItems.value.entries) {
          final itemId = entry.key;
          final quantity = entry.value;

          final item = items.firstWhere(
            (i) => i.id == itemId,
            orElse: () => FoodItem(
              id: '',
              restaurantId: '',
              name: '',
              description: '',
              price: 0,
              quantityAvailable: 0,
              isAvailable: false,
              createdAt: null,
            ),
          );

          final itemRef = FirebaseFirestore.instance
              .collection('foodItems')
              .doc(itemId);
          final snapshot = await transaction.get(itemRef);

          if (!snapshot.exists) {
            throw StateError('${item.name} no longer exists.');
          }

          final data = snapshot.data() as Map<String, dynamic>;
          final currentQty = (data['quantityAvailable'] as num).toInt();

          if (currentQty < quantity) {
            throw StateError('Only $currentQty ${item.name} left.');
          }

          final newQty = currentQty - quantity;
          transaction.update(itemRef, {
            'quantityAvailable': newQty,
            'isAvailable': newQty > 0,
          });

          final orderRef = FirebaseFirestore.instance.collection('orders').doc();
          transaction.set(orderRef, {
            'restaurantId': widget.restaurantId,
            'foodItemId': itemId,
            'foodName': item.name,
            'price': item.price,
            'quantity': quantity,
            'userId': user.uid,
            'status': 'new',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      _cartItems.value = {};

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Order placed successfully!'),
            backgroundColor: _primaryColor,
          ),
        );
        Navigator.pop(context);
      }
    } on StateError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _setReserving('all', false);
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

  Future<void> _startCheckout(BuildContext context, FoodItem item) async {
    final result = await Navigator.push<CheckoutResult>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          item: item,
          restaurantName: widget.restaurantName,
          initialQuantity: 1,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    await _reserveFood(context, item, result.quantity, notes: result.notes);
  }

  Future<void> _reserveFood(
    BuildContext context,
    FoodItem item,
    int quantity, {
    String? notes,
  }) async {
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
        final itemRef =
            FirebaseFirestore.instance.collection('foodItems').doc(item.id);
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

        final orderRef =
            FirebaseFirestore.instance.collection('orders').doc();
        transaction.set(orderRef, {
          'restaurantId': widget.restaurantId,
          'foodItemId': item.id,
          'foodName': item.name,
          'quantity': quantity,
          'userId': user.uid,
          'notes': notes,
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

  Widget _buildErrorState() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Unable to load items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No items available right now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon!',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
