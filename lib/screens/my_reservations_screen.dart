import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _lightGrey = Color(0xFFF5F5F5);

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  int _selectedTab = 0; // 0: Active, 1: History

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          backgroundColor: MyReservationsScreen._primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please sign in to view orders.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: MyReservationsScreen._primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab buttons
          Container(
            padding: const EdgeInsets.all(12),
            color: MyReservationsScreen._lightGrey,
            child: Row(
              children: [
                _buildTabButton('Active Orders', 0),
                const SizedBox(width: 12),
                _buildTabButton('Order History', 1),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedTab == 0
                ? _buildActiveOrders(user.uid)
                : _buildOrderHistory(user.uid),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : MyReservationsScreen._lightGrey,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: MyReservationsScreen._primaryColor,
                    width: 2,
                  )
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? MyReservationsScreen._primaryColor
                  : Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveOrders(String userId) {
    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['new', 'preparing', 'ready'])
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: MyReservationsScreen._primaryColor,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No active orders',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Place an order from your favorite restaurant',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final order = docs[index];
            final data = order.data();
            return _buildOrderCard(data, context);
          },
        );
      },
    );
  }

  Widget _buildOrderHistory(String userId) {
    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['ready', 'pickedUp', 'cancelled'])
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: MyReservationsScreen._primaryColor,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No order history',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final order = docs[index];
            final data = order.data();
            return _buildOrderCard(data, context, isHistory: true);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> data, BuildContext context,
      {bool isHistory = false}) {
    final foodName = data['foodName'] ?? 'Item';
    final quantity = (data['quantity'] is num)
        ? (data['quantity'] as num).toInt()
        : 1;
    final status = data['status'] ?? 'new';
    final createdAt = data['createdAt'];
    final price = (data['price'] is num) ? (data['price'] as num) : 0.0;
    final restaurantName = data['restaurantName'] ?? 'Restaurant';

    final timestamp = createdAt is Timestamp
        ? createdAt.toDate()
        : DateTime.now();

    String statusText;
    IconData statusIcon;
    Color statusColor;

    switch (status) {
      case 'preparing':
        statusText = 'Preparing';
        statusIcon = Icons.local_fire_department;
        statusColor = Colors.orange;
        break;
      case 'ready':
        statusText = 'Ready for Pickup';
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'pickedUp':
        statusText = 'Picked Up ✓';
        statusIcon = Icons.done_all;
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusText = 'Cancelled';
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      default:
        statusText = 'Confirmed';
        statusIcon = Icons.info;
        statusColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: MyReservationsScreen._lightGrey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatTime(timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Order details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            foodName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            restaurantName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$quantity item${quantity > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${(price * quantity).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: MyReservationsScreen._primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Order date
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: MyReservationsScreen._lightGrey,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order Date',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatFullDate(timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Timeline indicator
                if (status == 'preparing' || status == 'ready')
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: status == 'ready' ? 1.0 : 0.5,
                          minHeight: 4,
                          backgroundColor: MyReservationsScreen._lightGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            status == 'ready'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                // Action buttons (for active orders)
                if (!isHistory && status != 'cancelled')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showOrderDetails(context, data),
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                MyReservationsScreen._primaryColor,
                            side: const BorderSide(
                              color: MyReservationsScreen._primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (status == 'new')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showCancelDialog(context, data),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Item', order['foodName'] ?? '-'),
              _buildDetailRow('Quantity', '${order['quantity']} x'),
              _buildDetailRow('Price', '₹${order['price']}'),
              _buildDetailRow('Status', order['status'] ?? '-'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyReservationsScreen._primaryColor,
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this order?',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MyReservationsScreen._lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['foodName'] ?? 'Item',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: ${order['quantity']} × ₹${order['price']}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '✓ Your food quantity will be restored',
              style: TextStyle(
                fontSize: 11,
                color: MyReservationsScreen._primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(context, order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(
    BuildContext context,
    Map<String, dynamic> orderData,
  ) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Cancelling order...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Get the order ID (we need to find it from Firestore)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final foodItemId = orderData['foodItemId'] as String?;
      final orderedQuantity = orderData['quantity'] as int?
          ?? (orderData['quantity'] is num ? (orderData['quantity'] as num).toInt() : 1);
      final foodName = orderData['foodName'] as String? ?? 'Item';

      if (foodItemId == null || foodItemId.isEmpty) {
        throw Exception('Invalid order data');
      }

      // Find the order document ID
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('foodItemId', isEqualTo: foodItemId)
          .where('status', isEqualTo: 'new')
          .limit(1)
          .get();

      if (ordersQuery.docs.isEmpty) {
        throw Exception('Order not found or already cancelled');
      }

      final orderId = ordersQuery.docs.first.id;

      // Run atomic transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Get the order document
        final orderRef = FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId);
        final orderSnapshot = await transaction.get(orderRef);

        if (!orderSnapshot.exists) {
          throw Exception('Order no longer exists');
        }

        final orderStatus = orderSnapshot.get('status') as String?;
        if (orderStatus != 'new') {
          throw Exception(
            'Cannot cancel order with status: $orderStatus. Only new orders can be cancelled.',
          );
        }

        // 2. Get the food item document
        final foodRef =
            FirebaseFirestore.instance.collection('foodItems').doc(foodItemId);
        final foodSnapshot = await transaction.get(foodRef);

        if (!foodSnapshot.exists) {
          throw Exception('Food item no longer exists');
        }

        final currentQuantity =
            (foodSnapshot.get('quantityAvailable') as num?)
                ?.toInt() ??
            0;

        // 3. Calculate restored quantity (prevent negative)
        final restoredQuantity =
            (currentQuantity + orderedQuantity).clamp(0, double.infinity).toInt();

        // 4. Update order status to cancelled
        transaction.update(orderRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        // 5. Restore food quantity and update availability
        transaction.update(foodRef, {
          'quantityAvailable': restoredQuantity,
          'isAvailable': restoredQuantity > 0,
        });
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Order cancelled successfully',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '✓ $foodName (Qty: $orderedQuantity) quantity restored',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to cancel: ${e.toString().replaceFirst('Exception: ', '')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String _formatFullDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
