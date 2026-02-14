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
  String _selectedRestaurantId = '';
  _RestaurantSummary? _selectedRestaurantCache;

  // Cache snapshots to prevent flicker on rebuild
  final Map<String, QuerySnapshot<Map<String, dynamic>>> _ordersSnapshotCache =
      {};
  final Map<String, QuerySnapshot<Map<String, dynamic>>> _menuSnapshotCache =
      {};

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
    final createdAt = data['createdAt'];
    final placedAt = createdAt is Timestamp
        ? createdAt.toDate()
        : DateTime.now();

    // Handle both old format (items array) and new format (single food item)
    List<_OrderLine> lines = [];
    final itemsData = (data['items'] as List<dynamic>?) ?? [];

    if (itemsData.isNotEmpty) {
      // Old format with nested items
      lines = itemsData
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
    } else {
      // New format from checkout (single food item order)
      final foodName = data['foodName'] ?? 'Item';
      final quantity = (data['quantity'] is num)
          ? (data['quantity'] as num).toInt()
          : 1;
      final price = (data['price'] is num)
          ? (data['price'] as num).toDouble()
          : 0.0;

      if (foodName.isNotEmpty) {
        lines = [_OrderLine(name: foodName, quantity: quantity, price: price)];
      }
    }

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
      // Clear caches when switching restaurants
      _ordersSnapshotCache.clear();
      _menuSnapshotCache.clear();
    });
  }

  void _updateOrderStatus(String orderId, _LiveOrderStatus status) {
    _restaurantService
        .updateOrderStatus(orderId, _statusToString(status))
        .catchError((_) {
          // Error will be shown in UI via StreamBuilder
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
                if (!mounted) {
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add item: $error')),
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
                if (!mounted) {
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add restaurant: $error')),
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('restaurantId', isEqualTo: _selectedRestaurantId)
                .where('status', isEqualTo: 'new')
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      _showNotifications(context, _selectedRestaurantId);
                    },
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
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
                restaurant: _selectedRestaurantCache,
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

                if (snapshot.hasError) {
                  return _buildCenteredMessage(
                    'Unable to load restaurants. ${snapshot.error}',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    docs.isEmpty) {
                  return _buildCenteredLoading();
                }

                if (docs.isEmpty) {
                  return _buildCenteredMessage(
                    'No restaurants yet.\nTap + to add your first restaurant.',
                  );
                }

                final restaurants = docs.map(_restaurantFromDoc).toList();

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
                      _buildOrdersSection(selected.id),
                      _buildMenuSection(selected.id),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedRestaurantId.isEmpty
            ? _openAddRestaurantDialog
            : _openAddItemDialog,
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 4,
        label: Text(
          _selectedRestaurantId.isEmpty ? 'Add Restaurant' : 'Add Item',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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

  Widget _buildOrdersSection(String restaurantId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      initialData: _ordersSnapshotCache[restaurantId],
      stream: _restaurantService.streamOrders(restaurantId),
      builder: (context, snapshot) {
        // Cache the snapshot for future rebuilds
        if (snapshot.hasData) {
          _ordersSnapshotCache[restaurantId] = snapshot.data!;
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _LiveOrdersBar(
            orders: const [],
            onOrderTap: _openOrderDetails,
            isLoading: true,
          );
        }

        if (snapshot.hasError) {
          debugPrint('Orders stream error: ${snapshot.error}');
        }

        // Filter and sort orders client-side
        List<_LiveOrder> orders = [];
        if (snapshot.hasData && snapshot.data != null) {
          orders = (snapshot.data!.docs)
              .map(_orderFromDoc)
              .where(
                (order) =>
                    order.status != _LiveOrderStatus.pickedUp &&
                    order.lines.isNotEmpty,
              ) // Only show orders with items
              .toList();

          // Sort by recency
          orders.sort((a, b) => b.placedAt.compareTo(a.placedAt));
        }

        return _LiveOrdersBar(orders: orders, onOrderTap: _openOrderDetails);
      },
    );
  }

  Widget _buildMenuSection(String restaurantId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      initialData: _menuSnapshotCache[restaurantId],
      stream: _restaurantService.streamMenuItems(restaurantId),
      builder: (context, snapshot) {
        // Cache the snapshot for future rebuilds
        if (snapshot.hasData) {
          _menuSnapshotCache[restaurantId] = snapshot.data!;
        }

        if (snapshot.hasError && !snapshot.hasData) {
          return _FoodMenuManager(
            menuItems: const [],
            onToggleAvailability: (_) async {},
            onUpdateItem: (item, name, description, price, quantity) async {},
            onDeleteItem: (_) async {},
            errorText: 'Unable to load menu items.',
          );
        }

        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
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
}

// Restaurant Header Widget
class _RestaurantHeader extends StatefulWidget {
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
  State<_RestaurantHeader> createState() => _RestaurantHeaderState();
}

class _RestaurantHeaderState extends State<_RestaurantHeader> {
  Stream<Map<String, dynamic>> _getRevenueStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('restaurantId', isEqualTo: widget.restaurantId)
        .where('status', whereIn: ['pickedUp', 'cancelled'])
        .snapshots()
        .map((snapshot) {
      double totalRevenue = 0;
      int totalOrders = 0;

      for (final doc in snapshot.docs) {
        if (doc['status'] == 'pickedUp') {
          final price = (doc['price'] as num?)?.toDouble() ?? 0;
          final quantity = (doc['quantity'] as num?)?.toInt() ?? 1;
          totalRevenue += price * quantity;
          totalOrders++;
        }
      }

      return {'revenue': totalRevenue, 'orders': totalOrders};
    });
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      widget.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.address,
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
                    widget.isOpen ? 'Open' : 'Closed',
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
                        value: widget.isOpen,
                        onChanged: widget.onToggleStatus,
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
          const SizedBox(height: 16),
          // Revenue stats row
          StreamBuilder<Map<String, dynamic>>(
            stream: _getRevenueStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final revenue = snapshot.data?['revenue'] as double? ?? 0;
              final orders = snapshot.data?['orders'] as int? ?? 0;

              return Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _showOrderHistory(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Revenue',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${revenue.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _showOrderHistory(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Orders (Tap History)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$orders completed',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showOrderHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          _OrderHistorySheet(restaurantId: widget.restaurantId),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          selected.name.isNotEmpty
                              ? selected.name
                              : 'Restaurant',
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
                          selected.address.isNotEmpty
                              ? selected.address
                              : 'Address',
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
                  PopupMenuButton<String>(
                    onSelected: (value) => onChanged(value),
                    tooltip: 'Select restaurant',
                    constraints: const BoxConstraints(
                      minWidth: 220,
                      maxWidth: 280,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => restaurants
                        .map(
                          (restaurant) => PopupMenuItem<String>(
                            value: restaurant.id,
                            child: Text(
                              restaurant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 24,
                        color: Colors.black87,
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
  String _selectedFilter = 'All'; // All, Preparing, Ready

  @override
  Widget build(BuildContext context) {
    // Only show active orders (exclude picked up)
    final activeOrders = widget.orders
        .where((order) => order.status != _LiveOrderStatus.pickedUp)
        .toList();

    final total = activeOrders.length;
    final preparingCount = activeOrders
        .where(
          (order) =>
              order.status == _LiveOrderStatus.preparing ||
              order.status == _LiveOrderStatus.newOrder,
        )
        .length;
    final readyCount = activeOrders
        .where((order) => order.status == _LiveOrderStatus.ready)
        .length;

    // Filter orders based on selection
    final filteredOrders = _selectedFilter == 'All'
        ? activeOrders
        : activeOrders.where((order) {
            switch (_selectedFilter) {
              case 'Preparing':
                return order.status == _LiveOrderStatus.preparing ||
                    order.status == _LiveOrderStatus.newOrder;
              case 'Ready':
                return order.status == _LiveOrderStatus.ready;
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
      // Format order ID for display
      final displayId = '#${order.id.substring(0, 8).toUpperCase()}';

      // Create food items preview
      final itemsPreview = order.lines
          .map(
            (line) =>
                '${line.name}${line.quantity > 1 ? ' (x${line.quantity})' : ''}',
          )
          .join(', ');

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
                      displayId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      itemsPreview.isEmpty ? 'No items' : itemsPreview,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.customerName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    final total = subtotal;

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
                      'Customer Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Name: ${order.customerName}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Phone: ${order.customerPhone}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pickup: ${order.deliveryAddress}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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

void _showNotifications(BuildContext context, String restaurantId) {
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('restaurantId', isEqualTo: restaurantId)
              .where('status', isEqualTo: 'new')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error: ${snapshot.error}'),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, 
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No new orders',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final foodName = data['foodName'] ?? 'Item';
                final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
                final price = (data['price'] as num?)?.toDouble() ?? 0;
                final total = price * quantity;
                final createdAt = data['createdAt'] as Timestamp?;
                final orderId = doc.id;

                String timeAgo = 'Just now';
                if (createdAt != null) {
                  final orderTime = createdAt.toDate();
                  final diff = DateTime.now().difference(orderTime);
                  if (diff.inMinutes < 1) {
                    timeAgo = 'Just now';
                  } else if (diff.inMinutes < 60) {
                    timeAgo = '${diff.inMinutes} min ago';
                  } else if (diff.inHours < 24) {
                    timeAgo = '${diff.inHours}h ago';
                  } else {
                    timeAgo = '${diff.inDays}d ago';
                  }
                }

                return _NotificationTile(
                  icon: Icons.shopping_bag,
                  title: 'New Order #${orderId.substring(0, 8).toUpperCase()}',
                  subtitle: '$foodName • $quantity item${quantity > 1 ? 's' : ''} • ₹${total.toStringAsFixed(0)}',
                  time: timeAgo,
                  color: const Color(0xFF2E7D32),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
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
    _nameController = TextEditingController(text: restaurant?.name ?? '');
    _addressController = TextEditingController(text: restaurant?.address ?? '');
    _phoneController = TextEditingController(text: '');
    _emailController = TextEditingController(text: '');
    _hoursController = TextEditingController(text: '');
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

// Order History Sheet
class _OrderHistorySheet extends StatefulWidget {
  const _OrderHistorySheet({required this.restaurantId});

  final String restaurantId;

  @override
  State<_OrderHistorySheet> createState() => _OrderHistorySheetState();
}

class _OrderHistorySheetState extends State<_OrderHistorySheet> {
  String _filterType = 'completed'; // completed, cancelled, all

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Order History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Filter tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterTab('Completed', 'completed'),
                          const SizedBox(width: 8),
                          _buildFilterTab('Cancelled', 'cancelled'),
                          const SizedBox(width: 8),
                          _buildFilterTab('All', 'all'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Orders list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getOrdersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4CAF50),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No orders found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'unknown';
                        final foodName = data['foodName'] ?? 'Item';
                        final quantity =
                            (data['quantity'] as num?)?.toInt() ?? 1;
                        final price = (data['price'] as num?)?.toDouble() ?? 0;
                        final createdAt = data['createdAt'] as Timestamp?;
                        final timestamp = createdAt?.toDate() ?? DateTime.now();

                        final statusColor = status == 'cancelled'
                            ? Colors.red
                            : Colors.green;
                        final statusLabel = status == 'cancelled'
                            ? 'Cancelled'
                            : 'Completed';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      foodName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Qty: $quantity × ₹${price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Total: ₹${(price * quantity).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDateTime(timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('orders')
        .where('restaurantId', isEqualTo: widget.restaurantId);

    // Apply filter
    if (_filterType == 'completed') {
      query = query.where('status', isEqualTo: 'pickedUp');
    } else if (_filterType == 'cancelled') {
      query = query.where('status', isEqualTo: 'cancelled');
    } else {
      // 'all' includes both completed and cancelled
      query = query.where('status', whereIn: ['pickedUp', 'cancelled']);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
