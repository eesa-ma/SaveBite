import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_serivce.dart';
import '../services/restaurant_service.dart';
import '../utils/theme_manager.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final RestaurantService _restaurantService = RestaurantService();
  late final List<_RestaurantSummary> _restaurants;
  late final Map<String, List<_MenuItem>> _menuByRestaurant;
  late final Map<String, List<_LiveOrder>> _ordersByRestaurant;
  late String _selectedRestaurantId;
  _RestaurantSummary? _selectedRestaurantCache;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _restaurants = [
      _RestaurantSummary(
        id: 'r1',
        name: 'Green Bowl Kitchen',
        address: 'Sector 21, Chandigarh',
        isOpen: true,
      ),
      _RestaurantSummary(
        id: 'r2',
        name: 'Spice Route Bistro',
        address: 'Phase 5, Mohali',
        isOpen: true,
      ),
      _RestaurantSummary(
        id: 'r3',
        name: 'Urban Tandoor',
        address: 'Sector 34, Chandigarh',
        isOpen: false,
      ),
    ];

    _menuByRestaurant = {
      'r1': [
        _MenuItem(
          id: '1',
          name: 'Grilled Veggie Burger',
          description: 'Toasted bun, veggie patty, house sauce',
          price: 8.99,
          isAvailable: true,
          category: 'Main Course',
          emoji: '🍔',
          quantity: 18,
        ),
        _MenuItem(
          id: '2',
          name: 'Caesar Salad Bowl',
          description: 'Romaine, parmesan, garlic croutons',
          price: 6.50,
          isAvailable: true,
          category: 'Salads',
          emoji: '🥗',
          quantity: 24,
        ),
        _MenuItem(
          id: '3',
          name: 'Margherita Pizza',
          description: 'Tomato, mozzarella, fresh basil',
          price: 12.99,
          isAvailable: false,
          category: 'Pizza',
          emoji: '🍕',
          quantity: 6,
        ),
        _MenuItem(
          id: '4',
          name: 'Chocolate Brownie',
          description: 'Fudgy brownie with cocoa drizzle',
          price: 4.99,
          isAvailable: true,
          category: 'Desserts',
          emoji: '🍰',
          quantity: 32,
        ),
        _MenuItem(
          id: '5',
          name: 'Fresh Orange Juice',
          description: 'Cold-pressed Valencia oranges',
          price: 3.99,
          isAvailable: true,
          category: 'Beverages',
          emoji: '🧃',
          quantity: 40,
        ),
        _MenuItem(
          id: '6',
          name: 'Pasta Alfredo',
          description: 'Creamy alfredo sauce, herbs',
          price: 10.99,
          isAvailable: true,
          category: 'Pasta',
          emoji: '🍝',
          quantity: 14,
        ),
        _MenuItem(
          id: '7',
          name: 'BBQ Chicken Wings',
          description: 'Smoky BBQ glaze, house dip',
          price: 9.99,
          isAvailable: false,
          category: 'Appetizers',
          emoji: '🍗',
          quantity: 9,
        ),
        _MenuItem(
          id: '8',
          name: 'Iced Coffee',
          description: 'Chilled brew with oat milk',
          price: 4.50,
          isAvailable: true,
          category: 'Beverages',
          emoji: '☕',
          quantity: 22,
        ),
      ],
      'r2': [
        _MenuItem(
          id: '21',
          name: 'Butter Chicken Bowl',
          description: 'Creamy tomato gravy, basmati rice',
          price: 11.50,
          isAvailable: true,
          category: 'Signature',
          emoji: '🍛',
          quantity: 16,
        ),
        _MenuItem(
          id: '22',
          name: 'Paneer Tikka Wrap',
          description: 'Grilled paneer, mint chutney',
          price: 7.25,
          isAvailable: true,
          category: 'Wraps',
          emoji: '🌯',
          quantity: 28,
        ),
        _MenuItem(
          id: '23',
          name: 'Masala Lemonade',
          description: 'Spiced lemonade with mint',
          price: 3.25,
          isAvailable: true,
          category: 'Beverages',
          emoji: '🍋',
          quantity: 35,
        ),
      ],
      'r3': [
        _MenuItem(
          id: '31',
          name: 'Tandoori Platter',
          description: 'Smoky grill mix, onion salad',
          price: 14.75,
          isAvailable: false,
          category: 'Grill',
          emoji: '🍢',
          quantity: 8,
        ),
        _MenuItem(
          id: '32',
          name: 'Garlic Naan',
          description: 'Stone-baked naan, garlic butter',
          price: 2.50,
          isAvailable: true,
          category: 'Breads',
          emoji: '🫓',
          quantity: 50,
        ),
      ],
    };

    _ordersByRestaurant = {
      'r1': [
        _LiveOrder(
          id: '#1021',
          items: 4,
          status: _LiveOrderStatus.newOrder,
          customerName: 'Aman Singh',
          customerPhone: '+91 98111 22334',
          deliveryAddress: 'Sector 21, Chandigarh',
          placedAt: now.subtract(const Duration(minutes: 6)),
          lines: [
            _OrderLine(name: 'Grilled Veggie Burger', quantity: 2, price: 8.99),
            _OrderLine(name: 'Fresh Orange Juice', quantity: 1, price: 3.99),
            _OrderLine(name: 'Chocolate Brownie', quantity: 1, price: 4.99),
          ],
        ),
        _LiveOrder(
          id: '#1020',
          items: 2,
          status: _LiveOrderStatus.preparing,
          customerName: 'Ria Kapoor',
          customerPhone: '+91 98765 33210',
          deliveryAddress: 'Phase 3, Mohali',
          placedAt: now.subtract(const Duration(minutes: 18)),
          lines: [
            _OrderLine(name: 'Pasta Alfredo', quantity: 1, price: 10.99),
            _OrderLine(name: 'Iced Coffee', quantity: 1, price: 4.50),
          ],
        ),
        _LiveOrder(
          id: '#1019',
          items: 5,
          status: _LiveOrderStatus.ready,
          customerName: 'Kabir Malik',
          customerPhone: '+91 90012 45555',
          deliveryAddress: 'Sector 34, Chandigarh',
          placedAt: now.subtract(const Duration(minutes: 28)),
          lines: [
            _OrderLine(name: 'Margherita Pizza', quantity: 1, price: 12.99),
            _OrderLine(name: 'Caesar Salad Bowl', quantity: 2, price: 6.50),
            _OrderLine(name: 'Fresh Orange Juice', quantity: 2, price: 3.99),
          ],
        ),
      ],
      'r2': [
        _LiveOrder(
          id: '#2025',
          items: 3,
          status: _LiveOrderStatus.preparing,
          customerName: 'Simran Kaur',
          customerPhone: '+91 99888 33221',
          deliveryAddress: 'Phase 5, Mohali',
          placedAt: now.subtract(const Duration(minutes: 12)),
          lines: [
            _OrderLine(name: 'Butter Chicken Bowl', quantity: 1, price: 11.50),
            _OrderLine(name: 'Paneer Tikka Wrap', quantity: 2, price: 7.25),
          ],
        ),
        _LiveOrder(
          id: '#2024',
          items: 1,
          status: _LiveOrderStatus.newOrder,
          customerName: 'Neha Jain',
          customerPhone: '+91 99100 10101',
          deliveryAddress: 'Sector 44, Chandigarh',
          placedAt: now.subtract(const Duration(minutes: 3)),
          lines: [
            _OrderLine(name: 'Masala Lemonade', quantity: 1, price: 3.25),
          ],
        ),
      ],
      'r3': [],
    };

    _selectedRestaurantId = _restaurants.first.id;
  }

  _RestaurantSummary get _selectedRestaurant => _restaurants.firstWhere(
    (restaurant) => restaurant.id == _selectedRestaurantId,
  );

  List<_MenuItem> get _selectedMenuItems =>
      _menuByRestaurant[_selectedRestaurantId] ?? [];

  List<_LiveOrder> get _selectedOrders =>
      (_ordersByRestaurant[_selectedRestaurantId] ?? [])
          .where((order) => order.status != _LiveOrderStatus.pickedUp)
          .toList();

  _LiveOrderStatus _statusFromString(String? value) {
    switch (value) {
      case 'new':
        return _LiveOrderStatus.newOrder;
      case 'preparing':
        return _LiveOrderStatus.preparing;
      case 'ready':
        return _LiveOrderStatus.ready;
      case 'pickedUp':
        return _LiveOrderStatus.pickedUp;
      default:
        return _LiveOrderStatus.newOrder;
    }
  }

  String _statusToString(_LiveOrderStatus status) {
    switch (status) {
      case _LiveOrderStatus.newOrder:
        return 'new';
      case _LiveOrderStatus.preparing:
        return 'preparing';
      case _LiveOrderStatus.ready:
        return 'ready';
      case _LiveOrderStatus.pickedUp:
        return 'pickedUp';
    }
  }

  _RestaurantSummary _restaurantFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return _RestaurantSummary(
      id: doc.id,
      name: data['name'] ?? 'Restaurant',
      address: data['address'] ?? 'Address not set',
      isOpen: data['isOpen'] ?? false,
    );
  }

  _MenuItem _menuItemFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final priceValue = data['price'];
    final quantityValue = data['quantityAvailable'];

    return _MenuItem(
      id: doc.id,
      name: data['name'] ?? 'Item',
      description: data['description'] ?? '',
      price: (priceValue is num) ? priceValue.toDouble() : 0.0,
      isAvailable: data['isAvailable'] ?? true,
      category: data['category'] ?? 'Menu',
      emoji: data['emoji'] ?? '🍽️',
      quantity: (quantityValue is num) ? quantityValue.toInt() : 0,
    );
  }

  _LiveOrder _orderFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final itemsData = (data['items'] as List<dynamic>?) ?? [];
    final createdAt = data['createdAt'];
    final placedAt = createdAt is Timestamp
        ? createdAt.toDate()
        : DateTime.now();
    final lines = itemsData
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => _OrderLine(
            name: item['name'] ?? 'Item',
            quantity: (item['quantity'] is num)
                ? (item['quantity'] as num).toInt()
                : 1,
            price: (item['price'] is num)
                ? (item['price'] as num).toDouble()
                : 0.0,
          ),
        )
        .toList();
    final totalItems = lines.fold<int>(
      0,
      (total, line) => total + line.quantity,
    );

    return _LiveOrder(
      id: doc.id,
      items: totalItems,
      status: _statusFromString(data['status'] as String?),
      customerName: data['customerName'] ?? 'Customer',
      customerPhone: data['customerPhone'] ?? 'N/A',
      deliveryAddress: data['deliveryAddress'] ?? 'Address not set',
      placedAt: placedAt,
      lines: lines,
    );
  }

  void _onRestaurantChanged(String? id) {
    if (id == null) {
      return;
    }
    setState(() {
      _selectedRestaurantId = id;
    });
  }

  void _updateOrderStatus(String orderId, _LiveOrderStatus status) {
    _restaurantService
        .updateOrderStatus(orderId, _statusToString(status))
        .catchError((_) {
          final orders = _ordersByRestaurant[_selectedRestaurantId];
          if (orders == null) {
            return;
          }

          final index = orders.indexWhere((order) => order.id == orderId);
          if (index == -1) {
            return;
          }

          setState(() {
            orders[index].status = status;
          });
        });
  }

  void _openOrderDetails(_LiveOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _OrderDetailsSheet(
        order: order,
        onMarkReady: order.status == _LiveOrderStatus.ready
            ? null
            : () {
                _updateOrderStatus(order.id, _LiveOrderStatus.ready);
                Navigator.pop(context);
              },
        onMarkPickedUp: order.status == _LiveOrderStatus.ready
            ? () {
                _updateOrderStatus(order.id, _LiveOrderStatus.pickedUp);
                Navigator.pop(context);
              }
            : null,
      ),
    );
  }

  void _openAddItemDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add items.')),
      );
      return;
    }

    final restaurantId = _selectedRestaurantId;
    if (restaurantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a restaurant first.')),
      );
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Food Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0.0;
              final quantity = int.tryParse(quantityController.text) ?? 0;

              if (name.isEmpty || price <= 0 || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a name, price, and quantity.'),
                  ),
                );
                return;
              }

              try {
                await _restaurantService.addMenuItem(
                  restaurantId: restaurantId,
                  name: name,
                  description: description,
                  price: price,
                  quantityAvailable: quantity,
                );
                if (!mounted) {
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item added successfully!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (error) {
                final newItem = _MenuItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  description: description,
                  price: price,
                  isAvailable: true,
                  category: 'New',
                  emoji: '🍽️',
                  quantity: quantity,
                );

                setState(() {
                  _menuByRestaurant[restaurantId]?.insert(0, newItem);
                });

                if (!mounted) {
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added locally (offline): $error')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  void _openAddRestaurantDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add restaurants.')),
      );
      return;
    }

    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final hoursController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Restaurant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hoursController,
              decoration: const InputDecoration(
                labelText: 'Operating Hours',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final address = addressController.text.trim();
              final phone = phoneController.text.trim();
              final email = emailController.text.trim();
              final hours = hoursController.text.trim();

              if (name.isEmpty ||
                  address.isEmpty ||
                  phone.isEmpty ||
                  email.isEmpty ||
                  hours.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter name, address, phone, email, and hours.',
                    ),
                  ),
                );
                return;
              }

              try {
                final doc = await _restaurantService.addRestaurant(
                  ownerId: user.uid,
                  name: name,
                  address: address,
                  phone: phone,
                  email: email,
                  hours: hours,
                  isOpen: true,
                );
                if (!mounted) {
                  return;
                }
                setState(() {
                  _selectedRestaurantId = doc.id;
                  _selectedRestaurantCache = null;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restaurant added.')),
                );
              } catch (error) {
                final newRestaurant = _RestaurantSummary(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  address: address,
                  isOpen: true,
                );

                setState(() {
                  _restaurants.insert(0, newRestaurant);
                  _selectedRestaurantId = newRestaurant.id;
                });

                if (!mounted) {
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added locally (offline): $error')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Add Restaurant'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fallbackRestaurant = _selectedRestaurantCache ?? _selectedRestaurant;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Restaurant Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _showNotifications(context);
            },
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              _handleMenuSelection(
                context,
                value,
                restaurant: fallbackRestaurant,
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'details',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.store, color: Color(0xFF4CAF50)),
                  title: Text('Restaurant Details'),
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person, color: Color(0xFF4CAF50)),
                  title: Text('My Profile'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.settings, color: Color(0xFF4CAF50)),
                  title: Text('Settings'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: user == null
          ? _buildCenteredMessage('Please sign in to view your dashboard.')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _restaurantService.streamRestaurants(user.uid),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final hasFirestoreData = docs.isNotEmpty;

                if (snapshot.hasError && !hasFirestoreData) {
                  return _buildCenteredMessage(
                    'Unable to load restaurants. ${snapshot.error}',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !hasFirestoreData) {
                  return _buildCenteredLoading();
                }

                final restaurants = hasFirestoreData
                    ? docs.map(_restaurantFromDoc).toList()
                    : _restaurants;

                var selectedId = _selectedRestaurantId;
                final hasSelection =
                    selectedId.isNotEmpty &&
                    restaurants.any((r) => r.id == selectedId);
                if (!hasSelection) {
                  selectedId = restaurants.first.id;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedRestaurantId = selectedId;
                      });
                    }
                  });
                }

                final selected = restaurants.firstWhere(
                  (r) => r.id == selectedId,
                );
                if (_selectedRestaurantCache?.id != selected.id) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedRestaurantCache = selected;
                        _selectedRestaurantId = selected.id;
                      });
                    }
                  });
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      _RestaurantSwitcher(
                        restaurants: restaurants,
                        selectedId: selected.id,
                        onChanged: _onRestaurantChanged,
                        onAddRestaurant: _openAddRestaurantDialog,
                      ),
                      _RestaurantHeader(
                        restaurantId: selected.id,
                        name: selected.name,
                        address: selected.address,
                        isOpen: selected.isOpen,
                        onToggleStatus: (isOpen) async {
                          try {
                            await _restaurantService.updateRestaurantStatus(
                              selected.id,
                              isOpen,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Restaurant is now ${isOpen ? "Open" : "Closed"}',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating status: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _buildOrdersSection(
                        selected.id,
                        fallback: !hasFirestoreData,
                      ),
                      _buildMenuSection(
                        selected.id,
                        fallback: !hasFirestoreData,
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddItemDialog,
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 4,
        label: const Text(
          'Add Item',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        icon: const Icon(Icons.add, size: 22),
      ),
    );
  }

  Widget _buildCenteredLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
    );
  }

  Widget _buildCenteredMessage(String message) {
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

  Widget _buildOrdersSection(String restaurantId, {required bool fallback}) {
    if (fallback) {
      return _LiveOrdersBar(
        orders: _selectedOrders,
        onOrderTap: _openOrderDetails,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _restaurantService.streamOrders(restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LiveOrdersBar(
            orders: const [],
            onOrderTap: _openOrderDetails,
            isLoading: true,
          );
        }

        // Even if there's an error, show the UI with empty orders
        final orders = snapshot.hasError
            ? <_LiveOrder>[]
            : (snapshot.data?.docs ?? []).map(_orderFromDoc).toList();

        return _LiveOrdersBar(orders: orders, onOrderTap: _openOrderDetails);
      },
    );
  }

  Widget _buildMenuSection(String restaurantId, {required bool fallback}) {
    if (fallback) {
      return _FoodMenuManager(
        menuItems: _selectedMenuItems,
        onToggleAvailability: (item) async {
          setState(() {
            item.isAvailable = !item.isAvailable;
          });
        },
        onUpdateItem: (item, name, description, price, quantity) async {
          setState(() {
            item.name = name;
            item.description = description;
            item.price = price;
            item.quantity = quantity;
            item.isAvailable = quantity > 0;
          });
        },
        onDeleteItem: (item) async {
          setState(() {
            _menuByRestaurant[restaurantId]?.removeWhere(
              (entry) => entry.id == item.id,
            );
          });
        },
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _restaurantService.streamMenuItems(restaurantId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _FoodMenuManager(
            menuItems: const [],
            onToggleAvailability: (_) async {},
            onUpdateItem: (item, name, description, price, quantity) async {},
            onDeleteItem: (_) async {},
            errorText: 'Unable to load menu items.',
          );
        }

        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final menuItems = (snapshot.data?.docs ?? [])
            .map(_menuItemFromDoc)
            .toList();

        return _FoodMenuManager(
          menuItems: menuItems,
          isLoading: isLoading,
          onToggleAvailability: (item) {
            return _restaurantService.updateMenuItem(item.id, {
              'isAvailable': !item.isAvailable,
            });
          },
          onUpdateItem: (item, name, description, price, quantity) {
            return _restaurantService.updateMenuItem(item.id, {
              'name': name,
              'description': description,
              'price': price,
              'quantityAvailable': quantity,
              'isAvailable': quantity > 0,
            });
          },
          onDeleteItem: (item) {
            return _restaurantService.deleteMenuItem(item.id);
          },
        );
      },
    );
  }

  Widget _buildSectionMessage(String message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(message, style: TextStyle(color: Colors.grey[600])),
    );
  }
}

// Restaurant Header Widget
// class _RestaurantHeader extends StatelessWidget {
//   const _RestaurantHeader({
//     required this.restaurantId,
//     required this.name,
//     required this.address,
//     required this.isOpen,
//     required this.onToggleStatus,
//   });

//   final String restaurantId;
//   final String name;
//   final String address;
//   final bool isOpen;
//   final Function(bool) onToggleStatus;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF2E7D32),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.2),
//             blurRadius: 10,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//          Container(
//             width: 64,
//             height: 64,
//             decoration: const BoxDecoration(
//               color: Color(0xFF3E8E41),
//               borderRadius: BorderRadius.all(Radius.circular(18)),
//             ),
//             child: const Icon(
//               Icons.restaurant_menu,
//               color: Colors.white,
//               size: 32,
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   name,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   address,
//                   style: const TextStyle(
//                     color: Color(0xFFE7F3E7),
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 10),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 8,
//                   height: 8,
//                   decoration: BoxDecoration(
//                     color: isOpen ? const Color(0xFF2E7D32) : Colors.grey,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   isOpen ? 'Open' : 'Closed',
//                   style: const TextStyle(
//                     color: Color(0xFF2E7D32),
//                     fontWeight: FontWeight.w600,
//                     fontSize: 13,
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 SizedBox(
//                   height: 22,
//                   child: Switch(
//                     value: isOpen,
//                     onChanged: (value) => onToggleStatus(value),
//                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     activeThumbColor: const Color(0xFF2E7D32),
//                     activeTrackColor: const Color(0xFFB7D7B8),
//                     inactiveThumbColor: Colors.grey,
//                     inactiveTrackColor: const Color(0xFFE0E0E0),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


//test code

// Restaurant Header Widget (Image 1 Style)
class _RestaurantHeader extends StatelessWidget {
  const _RestaurantHeader({
    required this.restaurantId,
    required this.name,
    required this.address,
    required this.isOpen,
    required this.onToggleStatus,
  });

  final String restaurantId;
  final String name;
  final String address;
  final bool isOpen;
  final Function(bool) onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50), 
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // White Circle Icon
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant, 
              color: Color(0xFF4CAF50),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          
          // Restaurant Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),

          // Toggle Section (Label + Switch)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOpen ? 'Open' : 'Closed',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 30,
                child: Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: isOpen,
                    onChanged: onToggleStatus,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white.withOpacity(0.4),
                    inactiveThumbColor: Colors.white60,
                    inactiveTrackColor: Colors.black12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}







class _RestaurantSwitcher extends StatelessWidget {
  const _RestaurantSwitcher({
    required this.restaurants,
    required this.selectedId,
    required this.onChanged,
    required this.onAddRestaurant,
  });

  final List<_RestaurantSummary> restaurants;
  final String selectedId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onAddRestaurant;

  @override
  Widget build(BuildContext context) {
    final selected = restaurants.firstWhere(
      (restaurant) => restaurant.id == selectedId,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E5E5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F1E6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: Color(0xFF2E7D32),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selected.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => onChanged(selectedId),
                    borderRadius: BorderRadius.circular(16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedId,
                        onChanged: onChanged,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 24),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        selectedItemBuilder: (context) => restaurants
                            .map((_) => const SizedBox.shrink())
                            .toList(),
                        items: restaurants
                            .map(
                              (restaurant) => DropdownMenuItem<String>(
                                value: restaurant.id,
                                child: Text(restaurant.name),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onAddRestaurant,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.storefront, size: 24, color: Colors.white),
                  Positioned(
                    right: 10,
                    bottom: 12,
                    child: Icon(
                      Icons.add_circle,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveOrdersBar extends StatefulWidget {
  const _LiveOrdersBar({
    required this.orders,
    required this.onOrderTap,
    this.isLoading = false,
  });

  final List<_LiveOrder> orders;
  final ValueChanged<_LiveOrder> onOrderTap;
  final bool isLoading;

  @override
  State<_LiveOrdersBar> createState() => _LiveOrdersBarState();
}

class _LiveOrdersBarState extends State<_LiveOrdersBar> {
  String _selectedFilter = 'All'; // All, Preparing, Ready, Completed

  @override
  Widget build(BuildContext context) {
    final total = widget.orders.length;
    final preparingCount = widget.orders
        .where(
          (order) =>
              order.status == _LiveOrderStatus.preparing ||
              order.status == _LiveOrderStatus.newOrder,
        )
        .length;
    final readyCount = widget.orders
        .where((order) => order.status == _LiveOrderStatus.ready)
        .length;
    final completedCount = widget.orders
        .where((order) => order.status == _LiveOrderStatus.pickedUp)
        .length;

    // Filter orders based on selection
    final filteredOrders = _selectedFilter == 'All'
        ? widget.orders
        : widget.orders.where((order) {
            switch (_selectedFilter) {
              case 'Preparing':
                return order.status == _LiveOrderStatus.preparing ||
                    order.status == _LiveOrderStatus.newOrder;
              case 'Ready':
                return order.status == _LiveOrderStatus.ready;
              case 'Completed':
                return order.status == _LiveOrderStatus.pickedUp;
              default:
                return true;
            }
          }).toList();

    final shouldScroll = filteredOrders.length > 3;

    Color statusColor(_LiveOrderStatus status) {
      switch (status) {
        case _LiveOrderStatus.newOrder:
          return const Color(0xFF1565C0);
        case _LiveOrderStatus.preparing:
          return const Color(0xFFEF6C00);
        case _LiveOrderStatus.ready:
          return const Color(0xFF2E7D32);
        case _LiveOrderStatus.pickedUp:
          return Colors.grey;
      }
    }

    String statusLabel(_LiveOrderStatus status) {
      switch (status) {
        case _LiveOrderStatus.newOrder:
          return 'New';
        case _LiveOrderStatus.preparing:
          return 'Preparing';
        case _LiveOrderStatus.ready:
          return 'Ready';
        case _LiveOrderStatus.pickedUp:
          return 'Picked Up';
      }
    }

    Widget buildOrderTile(_LiveOrder order) {
      return InkWell(
        onTap: () => widget.onOrderTap(order),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: shouldScroll
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor(order.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel(order.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor(order.status),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.items} items • ${order.customerName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Live Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                '$total active',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              ),
            )
          else ...[
            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All $total',
                    isSelected: _selectedFilter == 'All',
                    onTap: () => setState(() => _selectedFilter = 'All'),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Preparing $preparingCount',
                    isSelected: _selectedFilter == 'Preparing',
                    onTap: () => setState(() => _selectedFilter = 'Preparing'),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Ready $readyCount',
                    isSelected: _selectedFilter == 'Ready',
                    onTap: () => setState(() => _selectedFilter = 'Ready'),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Comp',
                    isSelected: _selectedFilter == 'Completed',
                    onTap: () => setState(() => _selectedFilter = 'Completed'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Orders List
            if (filteredOrders.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No orders yet',
                    style: TextStyle(color: Colors.grey[400], fontSize: 15),
                  ),
                ),
              )
            else if (shouldScroll)
              SizedBox(
                height: 220,
                child: ListView.separated(
                  itemCount: filteredOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      buildOrderTile(filteredOrders[index]),
                ),
              )
            else
              Column(children: filteredOrders.map(buildOrderTile).toList()),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF757575),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  const _OrderDetailsSheet({
    required this.order,
    required this.onMarkReady,
    required this.onMarkPickedUp,
  });

  final _LiveOrder order;
  final VoidCallback? onMarkReady;
  final VoidCallback? onMarkPickedUp;

  String _formatElapsed(DateTime placedAt) {
    final diff = DateTime.now().difference(placedAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    }
    return '${diff.inDays} day ago';
  }

  Color _statusColor(_LiveOrderStatus status) {
    switch (status) {
      case _LiveOrderStatus.newOrder:
        return const Color(0xFF1565C0);
      case _LiveOrderStatus.preparing:
        return const Color(0xFFEF6C00);
      case _LiveOrderStatus.ready:
        return const Color(0xFF2E7D32);
      case _LiveOrderStatus.pickedUp:
        return Colors.grey;
    }
  }

  String _statusLabel(_LiveOrderStatus status) {
    switch (status) {
      case _LiveOrderStatus.newOrder:
        return 'New Order';
      case _LiveOrderStatus.preparing:
        return 'Preparing';
      case _LiveOrderStatus.ready:
        return 'Ready';
      case _LiveOrderStatus.pickedUp:
        return 'Picked Up';
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = order.subtotal;
    final tax = subtotal * 0.05;
    final total = subtotal + tax;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          top: 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Order ${order.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(order.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(order.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(order.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Placed ${_formatElapsed(order.placedAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.customerName,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.customerPhone,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.deliveryAddress,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Items',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...order.lines.map(
                (line) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${line.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          line.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '₹${(line.price * line.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Subtotal',
                      value: '₹${subtotal.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 6),
                    _SummaryRow(
                      label: 'Tax (5%)',
                      value: '₹${tax.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Total',
                      value: '₹${total.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (onMarkReady != null || onMarkPickedUp != null)
                Row(
                  children: [
                    if (onMarkReady != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onMarkReady,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF4CAF50)),
                          ),
                          child: const Text('Mark Ready'),
                        ),
                      ),
                    if (onMarkReady != null && onMarkPickedUp != null)
                      const SizedBox(width: 12),
                    if (onMarkPickedUp != null)
                      Expanded(
                        child: FilledButton(
                          onPressed: onMarkPickedUp,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Mark Picked Up'),
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
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      fontSize: isBold ? 16 : 14,
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}

// Food Menu Manager Widget
class _FoodMenuManager extends StatefulWidget {
  const _FoodMenuManager({
    required this.menuItems,
    required this.onToggleAvailability,
    required this.onUpdateItem,
    required this.onDeleteItem,
    this.isLoading = false,
    this.errorText,
  });

  final List<_MenuItem> menuItems;
  final Future<void> Function(_MenuItem item) onToggleAvailability;
  final Future<void> Function(
    _MenuItem item,
    String name,
    String description,
    double price,
    int quantity,
  )
  onUpdateItem;
  final Future<void> Function(_MenuItem item) onDeleteItem;
  final bool isLoading;
  final String? errorText;

  @override
  State<_FoodMenuManager> createState() => _FoodMenuManagerState();
}

class _FoodMenuManagerState extends State<_FoodMenuManager> {
  void _toggleAvailability(int index) {
    final item = widget.menuItems[index];
    final newAvailability = !item.isAvailable;
    widget
        .onToggleAvailability(item)
        .then((_) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${item.name} marked as ${newAvailability ? 'Available' : 'Unavailable'}',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: newAvailability
                  ? const Color(0xFF4CAF50)
                  : Colors.grey[700],
            ),
          );
        })
        .catchError((error) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating item: $error')),
          );
        });
  }

  void _confirmDelete(int index) {
    final item = widget.menuItems[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" from the menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget
                  .onDeleteItem(item)
                  .then((_) {
                    if (!mounted) {
                      return;
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item deleted.')),
                    );
                  })
                  .catchError((error) {
                    if (!mounted) {
                      return;
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting item: $error')),
                    );
                  });
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCount = widget.menuItems
        .where((item) => item.isAvailable)
        .length;

    return Column(
      children: [
        // Menu Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Menu Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.menuItems.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '$availableCount Available • ${widget.menuItems.length - availableCount} Unavailable',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Text(
              widget.errorText!,
              style: TextStyle(color: Colors.grey[400], fontSize: 15),
            ),
          )
        else if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          )
        else if (widget.menuItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No menu items yet.',
                style: TextStyle(color: Colors.grey[400], fontSize: 15),
              ),
            ),
          )
        else
          // Menu Items List
          ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.menuItems.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return _MenuItemCard(
                item: widget.menuItems[index],
                onToggle: () => _toggleAvailability(index),
                onEdit: () => _showEditDialog(index),
                onDelete: () => _confirmDelete(index),
              );
            },
          ),
      ],
    );
  }

  void _showEditDialog(int index) {
    final item = widget.menuItems[index];
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description);
    final priceController = TextEditingController(text: item.price.toString());
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              final price = double.tryParse(priceController.text) ?? item.price;
              final quantity =
                  int.tryParse(quantityController.text) ?? item.quantity;

              widget
                  .onUpdateItem(item, name, description, price, quantity)
                  .then((_) {
                    if (!mounted) {
                      return;
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item updated successfully!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  })
                  .catchError((error) {
                    if (!mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating item: $error')),
                    );
                  });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Menu Item Card Widget
class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final _MenuItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isAvailable
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Food Emoji/Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: item.isAvailable
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 12),
            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: item.isAvailable
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: item.isAvailable
                              ? const Color(0xFF4CAF50)
                              : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Qty: ${item.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action Buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Availability Switch
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: item.isAvailable,
                    onChanged: (_) => onToggle(),
                    activeThumbColor: const Color(0xFF4CAF50),
                    activeTrackColor: const Color(
                      0xFF4CAF50,
                    ).withValues(alpha: 0.4),
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[300],
                  ),
                ),
                // Edit & Delete Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Restaurant and Order Models
class _RestaurantSummary {
  _RestaurantSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.isOpen,
  });

  final String id;
  final String name;
  final String address;
  final bool isOpen;
}

enum _LiveOrderStatus { newOrder, preparing, ready, pickedUp }

class _LiveOrder {
  _LiveOrder({
    required this.id,
    required this.items,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.placedAt,
    required this.lines,
  });

  final String id;
  final int items;
  _LiveOrderStatus status;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final DateTime placedAt;
  final List<_OrderLine> lines;

  double get subtotal =>
      lines.fold(0.0, (sum, line) => sum + (line.price * line.quantity));
}

class _OrderLine {
  _OrderLine({required this.name, required this.quantity, required this.price});

  final String name;
  final int quantity;
  final double price;
}

// Menu Item Model
class _MenuItem {
  _MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isAvailable,
    required this.category,
    required this.emoji,
    required this.quantity,
  });

  final String id;
  String name;
  String description;
  double price;
  bool isAvailable;
  final String category;
  final String emoji;
  int quantity;
}

// Helper Functions
void _handleMenuSelection(
  BuildContext context,
  String value, {
  _RestaurantSummary? restaurant,
}) async {
  switch (value) {
    case 'details':
      _showRestaurantDetails(context, restaurant);
      break;
    case 'profile':
      _showProfile(context);
      break;
    case 'settings':
      _showSettings(context);
      break;
    case 'logout':
      _handleLogout(context);
      break;
  }
}

void _showNotifications(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.notifications, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text('Notifications'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            _NotificationTile(
              icon: Icons.shopping_bag,
              title: 'New Order #1021',
              subtitle: '4 items • ₹28.50',
              time: '2 min ago',
              color: const Color(0xFF2E7D32),
            ),
            _NotificationTile(
              icon: Icons.star,
              title: 'New Review',
              subtitle: 'Great food and service!',
              time: '15 min ago',
              color: const Color(0xFFF57C00),
            ),
            _NotificationTile(
              icon: Icons.local_offer,
              title: 'Deal Expiring Soon',
              subtitle: 'Lunch Special ends in 2 hours',
              time: '1 hour ago',
              color: const Color(0xFF6A1B9A),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
          ),
          child: const Text('View All'),
        ),
      ],
    ),
  );
}

void _showRestaurantDetails(
  BuildContext context,
  _RestaurantSummary? restaurant,
) {
  showDialog(
    context: context,
    builder: (context) => _RestaurantDetailsDialog(restaurant: restaurant),
  );
}

void _showProfile(BuildContext context) async {
  showDialog(context: context, builder: (context) => _ProfileEditDialog());
}

void _showSettings(BuildContext context) {
  showDialog(context: context, builder: (context) => _SettingsDialog());
}

void _handleLogout(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 8),
          Text('Logout'),
        ],
      ),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final authService = AuthService();
            try {
              await authService.logout();
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, '/entry');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Color(0xFF2E7D32),
                ),
              );
            } catch (e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error logging out: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}

// UI Helper Widgets
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(subtitle),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
      isThreeLine: true,
    );
  }
}

// Restaurant Details Dialog
class _RestaurantDetailsDialog extends StatefulWidget {
  const _RestaurantDetailsDialog({this.restaurant});

  final _RestaurantSummary? restaurant;

  @override
  State<_RestaurantDetailsDialog> createState() =>
      _RestaurantDetailsDialogState();
}

class _RestaurantDetailsDialogState extends State<_RestaurantDetailsDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _hoursController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final restaurant = widget.restaurant;
    _nameController = TextEditingController(
      text: restaurant?.name ?? 'Green Bowl Kitchen',
    );
    _addressController = TextEditingController(
      text: restaurant?.address ?? 'Sector 21, Chandigarh',
    );
    _phoneController = TextEditingController(text: '+91 98765 43210');
    _emailController = TextEditingController(text: 'contact@greenbowl.com');
    _hoursController = TextEditingController(text: '9:00 AM - 10:00 PM');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Here you would save to Firestore
      // For now, just simulate a save
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant details updated'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.store, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text('Restaurant Details'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Restaurant Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.restaurant),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hoursController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Operating Hours',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.access_time),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_isEditing)
          FilledButton(
            onPressed: _isSaving ? null : _saveDetails,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          )
        else
          FilledButton(
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Edit Details'),
          ),
      ],
    );
  }
}

// Profile Edit Dialog
class _ProfileEditDialog extends StatefulWidget {
  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      setState(() {
        _userData = userData;
        _nameController.text = userData?['name'] ?? '';
        _phoneController.text = userData?['phone'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text('My Profile'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(
                        0xFF2E7D32,
                      ).withValues(alpha: 0.1),
                      child: Text(
                        (_nameController.text.isNotEmpty
                                ? _nameController.text[0]
                                : 'U')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: TextEditingController(
                      text: user?.email ?? 'N/A',
                    ),
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: TextEditingController(
                      text: _userData?['role'] ?? 'N/A',
                    ),
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.badge),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_isEditing)
          FilledButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          )
        else
          FilledButton(
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Edit Profile'),
          ),
      ],
    );
  }
}

// Settings Dialog
class _SettingsDialog extends StatefulWidget {
  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  bool _notificationsEnabled = true;
  late bool _darkModeEnabled;

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = ThemeManager.isDarkMode;
  }

  void _showHelpSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.help, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Help & Support'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need assistance? Contact us:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.email, color: Color(0xFF2E7D32)),
                title: const Text('Email'),
                subtitle: const Text('contact@greenbowl.com'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening email app...')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFF2E7D32)),
                title: const Text('Phone'),
                subtitle: const Text('+91 98765 43210'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening phone dialer...')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFF2E7D32)),
                title: const Text('Live Chat'),
                subtitle: const Text('Available 9 AM - 6 PM'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening live chat...')),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text('Settings'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            secondary: const Icon(
              Icons.notifications,
              color: Color(0xFF2E7D32),
            ),
            title: const Text('Notifications'),
            subtitle: const Text('Receive order and review alerts'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Notifications enabled' : 'Notifications disabled',
                  ),
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              );
            },
            activeThumbColor: const Color(0xFF2E7D32),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode, color: Color(0xFF2E7D32)),
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch to dark theme'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
              ThemeManager.toggleTheme(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Dark mode enabled' : 'Dark mode disabled',
                  ),
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              );
            },
            activeThumbColor: const Color(0xFF2E7D32),
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Color(0xFF2E7D32)),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and contact us'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHelpSupport(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
