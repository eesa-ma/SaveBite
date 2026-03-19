import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:save_bite/models/food_item.dart';
import 'package:save_bite/screens/checkout_screen.dart';
import 'package:save_bite/services/favorites_service.dart';
import '../services/location_service.dart';

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
  final FavoritesService _favoritesService = FavoritesService();
  final ValueNotifier<Set<String>> _reservingIds = ValueNotifier<Set<String>>(
    {},
  );
  final ValueNotifier<Map<String, int>> _cartItems =
      ValueNotifier<Map<String, int>>({});
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedFoodType = 'All';
  Set<String> _favoriteFoodItemIds = <String>{};
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // Location data
  double? _userLatitude;
  double? _userLongitude;
  double? _restaurantLatitude;
  double? _restaurantLongitude;
  String? _restaurantAddress;
  String? _restaurantImageUrl;
  bool _restaurantIsOpen = true;

  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _lightGrey = Color(0xFFF5F5F5);
  static const Color _mediumGrey = Color(0xFFBDBDBD);

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _reservingIds.dispose();
    _cartItems.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLocationData();
    _loadFavoriteFoodItems();
  }

  Future<void> _loadFavoriteFoodItems() async {
    final favorites = await _favoritesService.getFavoriteFoodItems();
    if (!mounted) {
      return;
    }
    setState(() {
      _favoriteFoodItemIds = favorites
          .map((item) => (item['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    });
  }

  Future<void> _toggleFoodFavorite(FoodItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in to add favorites.');
      return;
    }

    final isFavorite = _favoriteFoodItemIds.contains(item.id);
    try {
      if (isFavorite) {
        await _favoritesService.removeFoodItemFavorite(item.id);
        if (!mounted) {
          return;
        }
        setState(() {
          _favoriteFoodItemIds.remove(item.id);
        });
        _showSnackBar('Removed from favorites.');
      } else {
        await _favoritesService.addFoodItemFavorite(
          widget.restaurantId,
          item.id,
          item.name,
          item.imageUrl,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _favoriteFoodItemIds.add(item.id);
        });
        _showSnackBar('Added to favorites.');
      }
    } catch (e) {
      _showSnackBar('Could not update favorite: $e');
    }
  }

  Future<void> _loadLocationData() async {
    // Load user location
    try {
      final locationService = LocationService();
      final userLocation = await locationService.getCurrentLocation();
      if (!mounted) {
        return;
      }
      setState(() {
        _userLatitude = _asDouble(userLocation['latitude']);
        _userLongitude = _asDouble(userLocation['longitude']);
      });
    } catch (e) {
      // Silently fail - will just not show distance
    }

    // Load restaurant location
    try {
      final restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();

      if (restaurantDoc.exists) {
        final data = restaurantDoc.data();
        if (!mounted) {
          return;
        }
        setState(() {
          _restaurantLatitude = _asDouble(data?['latitude']);
          _restaurantLongitude = _asDouble(data?['longitude']);
          _restaurantAddress = data?['address'];
          _restaurantImageUrl = data?['imageUrl'];
          _restaurantIsOpen = data?['isOpen'] == true;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<bool> _isRestaurantOpen() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();
      if (!doc.exists) {
        if (mounted) {
          setState(() {
            _restaurantIsOpen = false;
          });
        }
        return false;
      }

      final isOpen = doc.data()?['isOpen'] == true;
      if (mounted && isOpen != _restaurantIsOpen) {
        setState(() {
          _restaurantIsOpen = isOpen;
        });
      }
      return isOpen;
    } catch (_) {
      return _restaurantIsOpen;
    }
  }

  String _getDistanceText() {
    if (_userLatitude != null &&
        _userLongitude != null &&
        _restaurantLatitude != null &&
        _restaurantLongitude != null) {
      final locationService = LocationService();
      final distance = locationService.calculateDistance(
        _userLatitude!,
        _userLongitude!,
        _restaurantLatitude!,
        _restaurantLongitude!,
      );
      return locationService.formatDistance(distance);
    }
    return '';
  }

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
      _cartItems.value.values.fold(0, (total, qty) => total + qty);

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: backgroundColor,
      ),
    );
  }

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          final filteredItems = items.where((item) {
            final matchesSearch =
                _searchQuery.isEmpty ||
                item.name.toLowerCase().startsWith(_searchQuery.toLowerCase());
            final matchesCategory =
                _selectedCategory == 'All' ||
                item.description == _selectedCategory;
            final matchesFoodType =
                _selectedFoodType == 'All' ||
                (_selectedFoodType == 'Veg' && item.isVeg == true) ||
                (_selectedFoodType == 'Non-Veg' && item.isVeg == false);
            return matchesSearch && matchesCategory && matchesFoodType;
          }).toList();

          final categories = [
            'All',
            ...items.map((i) => i.description).toSet(),
          ];

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
                    // Category filter
                    _buildCategoryFilter(categories),
                    // Veg / Non-Veg filter
                    _buildFoodTypeFilter(),
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
    final distanceText = _getDistanceText();
    final addressText = _restaurantAddress ?? 'Serves fresh food daily';
    final subtitleText = distanceText.isNotEmpty
        ? '$distanceText • $addressText'
        : addressText;

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
              Expanded(
                child: Column(
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
                    Text(
                      subtitleText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _restaurantIsOpen ? 'Open now' : 'Closed',
                      style: TextStyle(
                        fontSize: 11,
                        color: _restaurantIsOpen
                            ? Colors.green[100]
                            : Colors.red[100],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputFill = isDark ? const Color(0xFF2A2A2A) : _lightGrey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          _searchDebounce?.cancel();
          if (value.isEmpty) {
            // Clear immediately — no delay needed
            setState(() => _searchQuery = '');
          } else {
            _searchDebounce = Timer(const Duration(milliseconds: 250), () {
              setState(() => _searchQuery = value);
            });
          }
        },
        decoration: InputDecoration(
          hintText: 'Search for items...',
          prefixIcon: Icon(Icons.search, color: theme.hintColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: theme.hintColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
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
          fillColor: inputFill,
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    final theme = Theme.of(context);

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
                backgroundColor: theme.cardColor,
                selectedColor: _primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
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
        children: items.map((item) => _buildFoodItemCard(item, user)).toList(),
      ),
    );
  }

  Widget _buildFoodTypeFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFoodTypePill(
              isVeg: true,
              isSelected: _selectedFoodType == 'Veg',
              onTap: () {
                setState(() {
                  _selectedFoodType = _selectedFoodType == 'Veg'
                      ? 'All'
                      : 'Veg';
                });
              },
            ),
            const SizedBox(width: 6),
            _buildFoodTypePill(
              isVeg: false,
              isSelected: _selectedFoodType == 'Non-Veg',
              onTap: () {
                setState(() {
                  _selectedFoodType = _selectedFoodType == 'Non-Veg'
                      ? 'All'
                      : 'Non-Veg';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodTypePill({
    required bool isVeg,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final accentColor = isVeg
        ? const Color(0xFF1B9E77)
        : const Color(0xFFD1495B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 82,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFD8D8D8),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accentColor, width: 1.5),
                color: isSelected
                    ? accentColor.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
              child: Icon(
                isVeg ? Icons.circle : Icons.change_history,
                size: 10,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E8EB),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Align(
                  alignment: isSelected
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 12,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.55)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemCard(FoodItem item, User? user) {
    final isSoldOut = item.quantityAvailable <= 0 || !item.isAvailable;
    final isFavorite = _favoriteFoodItemIds.contains(item.id);

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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: _lightGrey,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.fastfood_outlined,
                            color: _mediumGrey,
                            size: 40,
                          );
                        },
                      )
                    : const Icon(
                        Icons.fastfood_outlined,
                        color: _mediumGrey,
                        size: 40,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Food details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (item.isVeg != null)
                        _buildFoodTypeIndicator(item.isVeg!),
                      IconButton(
                        onPressed: () => _toggleFoodFavorite(item),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        tooltip: isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
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

  Widget _buildFoodTypeIndicator(bool isVeg) {
    final indicatorColor = isVeg
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Container(
      margin: const EdgeInsets.only(right: 6),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: indicatorColor, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: isVeg
          ? Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
            )
          : CustomPaint(
              size: const Size(10, 10),
              painter: _TriangleIndicatorPainter(color: Color(0xFFC62828)),
            ),
    );
  }

  Widget _buildAddButton(FoodItem item, bool isSoldOut) {
    return ElevatedButton.icon(
      onPressed: (isSoldOut || !_restaurantIsOpen)
          ? null
          : () => _startCheckout(item),
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

  Widget _buildQuantityCounter(FoodItem item, int quantity, bool isSoldOut) {
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
            onTap: _restaurantIsOpen && quantity < item.quantityAvailable
                ? () => _addToCart(item)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                Icons.add,
                size: 16,
                color: _restaurantIsOpen && quantity < item.quantityAvailable
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
              imageUrl: '',
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
            onPressed: _restaurantIsOpen ? _checkoutCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              disabledBackgroundColor: Colors.grey[300],
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
                    color: Colors.white.withValues(alpha: 0.3),
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
                  _restaurantIsOpen
                      ? 'Checkout • ₹${totalPrice.toStringAsFixed(0)}'
                      : 'Restaurant is closed',
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

  Future<void> _checkoutCart() async {
    final isOpen = await _isRestaurantOpen();
    if (!isOpen) {
      _showSnackBar('This restaurant is currently closed.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in to checkout.');
      return;
    }

    if (_cartItems.value.isEmpty) {
      _showSnackBar('Cart is empty');
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

      final locationService = LocationService();
      Map<String, dynamic> userLocation = {
        'latitude': 0.0,
        'longitude': 0.0,
        'address': 'Location not available',
      };
      try {
        userLocation = await locationService.getCurrentLocation();
      } catch (e) {
        debugPrint('Failed to get user location: $e');
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final orderGroupId = FirebaseFirestore.instance
            .collection('orders')
            .doc()
            .id;

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
              imageUrl: '',
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

          final orderRef = FirebaseFirestore.instance
              .collection('orders')
              .doc();
          transaction.set(orderRef, {
            'orderGroupId': orderGroupId,
            'restaurantId': widget.restaurantId,
            'restaurantName': widget.restaurantName,
            'restaurantAddress': _restaurantAddress ?? '',
            'restaurantImageUrl': _restaurantImageUrl ?? '',
            'foodItemId': itemId,
            'foodName': item.name,
            'imageUrl': item.imageUrl,
            'price': item.price,
            'quantity': quantity,
            'userId': user.uid,
            'ownerNotificationSeen': false,
            'status': 'new',
            'userLocation': {
              'latitude': userLocation['latitude'],
              'longitude': userLocation['longitude'],
              'address': userLocation['address'],
            },
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      _cartItems.value = {};

      _showSnackBar(
        '✓ Order placed successfully!',
        backgroundColor: _primaryColor,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on StateError catch (e) {
      _showSnackBar(e.toString(), backgroundColor: Colors.red);
    } catch (e) {
      _showSnackBar('Checkout failed: $e', backgroundColor: Colors.red);
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

  Future<void> _startCheckout(FoodItem item) async {
    final isOpen = await _isRestaurantOpen();
    if (!mounted) {
      return;
    }

    if (!isOpen) {
      _showSnackBar('This restaurant is currently closed.');
      return;
    }

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

    await _reserveFood(
      item,
      result.quantity,
      notes: result.notes,
      locationOverride: result.userLocation,
    );
  }

  Future<void> _reserveFood(
    FoodItem item,
    int quantity, {
    String? notes,
    Map<String, dynamic>? locationOverride,
  }) async {
    final isOpen = await _isRestaurantOpen();
    if (!isOpen) {
      _showSnackBar('This restaurant is currently closed.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in to reserve.');
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
      // Fetch customer name and phone from Firestore users collection
      String customerName = 'Customer';
      String customerPhone = 'N/A';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final name = userData?['name'];
          final phone = userData?['phone'];

          if (name != null && name.toString().isNotEmpty) {
            customerName = name.toString();
          } else {
            // If no name in Firestore, try displayName or email
            customerName = user.displayName ?? user.email ?? 'Customer';
          }

          if (phone != null && phone.toString().isNotEmpty) {
            customerPhone = phone.toString();
          }
        } else {
          // If user doc doesn't exist, use displayName or email
          customerName = user.displayName ?? user.email ?? 'Customer';
        }
      } catch (e) {
        // Fall back to displayName or email if Firestore fails
        customerName = user.displayName ?? user.email ?? 'Customer';
      }

      Map<String, dynamic> userLocation =
          locationOverride ??
          {
            'latitude': 0.0,
            'longitude': 0.0,
            'address': 'Location not available',
          };
      if (locationOverride == null) {
        final locationService = LocationService();
        try {
          userLocation = await locationService.getCurrentLocation();
        } catch (e) {
          debugPrint('Failed to get user location: $e');
        }
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final orderGroupId = FirebaseFirestore.instance
            .collection('orders')
            .doc()
            .id;
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
          'orderGroupId': orderGroupId,
          'restaurantId': widget.restaurantId,
          'restaurantName': widget.restaurantName,
          'restaurantAddress': _restaurantAddress ?? '',
          'restaurantImageUrl': _restaurantImageUrl ?? '',
          'foodItemId': item.id,
          'foodName': item.name,
          'imageUrl': item.imageUrl,
          'price': item.price,
          'quantity': quantity,
          'userId': user.uid,
          'customerName': customerName,
          'customerPhone': customerPhone,
          'deliveryAddress': 'Pickup',
          'notes': notes,
          'ownerNotificationSeen': false,
          'status': 'new',
          'userLocation': {
            'latitude': userLocation['latitude'],
            'longitude': userLocation['longitude'],
            'address': userLocation['address'],
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      _showSnackBar('Reserved $quantity x ${item.name}');
    } on StateError catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Reservation failed: $e');
    } finally {
      _setReserving(item.id, false);
    }
  }

  Widget _buildErrorState() {
    return Scaffold(
      appBar: AppBar(title: Text(widget.restaurantName)),
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
      appBar: AppBar(title: Text(widget.restaurantName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
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

class _TriangleIndicatorPainter extends CustomPainter {
  const _TriangleIndicatorPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleIndicatorPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
