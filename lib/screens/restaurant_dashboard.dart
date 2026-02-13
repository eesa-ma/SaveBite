import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  late final FirebaseAuth _auth;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/entry', (route) => false);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text('User not authenticated'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats Section
                _StatsSection(restaurantId: currentUser.uid),
                const SizedBox(height: 20),

                // Live Orders Section
                const Text(
                  'Live Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const SizedBox(height: 12),
                _LiveOrdersSection(restaurantId: currentUser.uid),
                const SizedBox(height: 20),

                // My Food Items Section
                const Text(
                  'My Food Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const SizedBox(height: 12),
                _FoodItemsSection(restaurantId: currentUser.uid),
                const SizedBox(height: 20),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to AddFoodScreen (placeholder)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Food feature coming soon')),
          );
        },
        backgroundColor: const Color(0xFF2E7D32),
        label: const Text('Add Food'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// Stats Section
class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today at a glance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B1B1B),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              title: 'Total Items',
              icon: Icons.restaurant_menu,
              color: const Color(0xFF2E7D32),
              future: _fetchTotalItems(),
            ),
            _StatCard(
              title: 'Active Orders',
              icon: Icons.receipt_long,
              color: const Color(0xFFF57C00),
              future: _fetchActiveReservations(),
            ),
            _StatCard(
              title: 'Completed Orders',
              icon: Icons.check_circle,
              color: const Color(0xFF00796B),
              future: _fetchCompletedOrders(),
            ),
            _StatCard(
              title: 'Reserved Items',
              icon: Icons.local_offer,
              color: const Color(0xFF6A1B9A),
              future: _fetchReservedItems(),
            ),
          ],
        ),
      ],
    );
  }

  Future<int> _fetchTotalItems() async {
    final query = await FirebaseFirestore.instance
        .collection('foodItems')
        .where('restaurantId', isEqualTo: restaurantId)
        .count()
        .get();
    return query.count ?? 0;
  }

  Future<int> _fetchActiveReservations() async {
    final query = await FirebaseFirestore.instance
        .collection('reservations')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isNotEqualTo: 'picked_up')
        .count()
        .get();
    return query.count ?? 0;
  }

  Future<int> _fetchCompletedOrders() async {
    final query = await FirebaseFirestore.instance
        .collection('reservations')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: 'picked_up')
        .count()
        .get();
    return query.count ?? 0;
  }

  Future<int> _fetchReservedItems() async {
    final query = await FirebaseFirestore.instance
        .collection('foodItems')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: 'reserved')
        .count()
        .get();
    return query.count ?? 0;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.future,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Future<int> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, size: 18, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Live Orders Section
class _LiveOrdersSection extends StatelessWidget {
  const _LiveOrdersSection({required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isNotEqualTo: 'picked_up')
          .orderBy('status')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No active orders',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          );
        }

        return Column(
          children: orders.map((doc) {
            return _OrderCard(reservationDoc: doc, restaurantId: restaurantId);
          }).toList(),
        );
      },
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.reservationDoc, required this.restaurantId});

  final QueryDocumentSnapshot reservationDoc;
  final String restaurantId;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.reservationDoc['status'] ?? 'preparing';
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationDoc.id)
          .update({'status': newStatus});

      setState(() {
        _currentStatus = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'ready':
        return const Color(0xFF2E7D32);
      case 'preparing':
        return const Color(0xFFF57C00);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.reservationDoc.data() as Map<String, dynamic>;
    final foodId = data['foodId'] ?? 'N/A';
    final userId = data['userId'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_dining, color: _getStatusColor()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food ID: $foodId',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'User: $userId',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentStatus.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_currentStatus == 'preparing')
                    ElevatedButton.icon(
                      onPressed: () => _updateStatus('ready'),
                      icon: const Icon(Icons.check),
                      label: const Text('Mark Ready'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    ),
                  if (_currentStatus == 'ready')
                    ElevatedButton.icon(
                      onPressed: () => _updateStatus('picked_up'),
                      icon: const Icon(Icons.done_all),
                      label: const Text('Picked Up'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                      ),
                    ),
                  if (_currentStatus != 'preparing' &&
                      _currentStatus != 'ready')
                    const Text('Order completed'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Food Items Section
class _FoodItemsSection extends StatelessWidget {
  const _FoodItemsSection({required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('foodItems')
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final foodItems = snapshot.data?.docs ?? [];

        if (foodItems.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No food items yet. Add one to get started!',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          );
        }

        return Column(
          children: foodItems.map((doc) {
            return _FoodItemCard(foodDoc: doc, restaurantId: restaurantId);
          }).toList(),
        );
      },
    );
  }
}

class _FoodItemCard extends StatefulWidget {
  const _FoodItemCard({required this.foodDoc, required this.restaurantId});

  final QueryDocumentSnapshot foodDoc;
  final String restaurantId;

  @override
  State<_FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<_FoodItemCard> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.foodDoc['status'] ?? 'available';
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'available':
        return const Color(0xFF2E7D32);
      case 'reserved':
        return const Color(0xFFF57C00);
      case 'completed':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  Future<void> _toggleAvailability() async {
    final newStatus = _currentStatus == 'available'
        ? 'unavailable'
        : 'available';
    try {
      await FirebaseFirestore.instance
          .collection('foodItems')
          .doc(widget.foodDoc.id)
          .update({'status': newStatus});

      setState(() {
        _currentStatus = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Item marked as $newStatus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteFoodItem() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('foodItems')
                    .doc(widget.foodDoc.id)
                    .delete();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Item deleted')));
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.foodDoc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown Item';
    final price = data['price'] ?? 0.0;
    final quantity = data['quantity'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: _getStatusColor(),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: $quantity | Price: \$${price.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _currentStatus.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: _toggleAvailability,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: Color(0xFF2E7D32),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _deleteFoodItem,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 18,
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
