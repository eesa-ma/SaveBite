import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class _OrderHistoryGroup {
  const _OrderHistoryGroup({required this.key, required this.orders});

  final String key;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> orders;

  Map<String, dynamic> get primaryData => orders.first.data();
  String get primaryOrderId => orders.first.id;
}

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _lightGrey = Color(0xFFF5F5F5);

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  int _selectedTab = 0; // 0: Active, 1: History

  Future<String?> _resolveFoodImageUrl(Map<String, dynamic> orderData) async {
    final directUrl = (orderData['imageUrl'] ?? '').toString().trim();
    if (directUrl.isNotEmpty) {
      return directUrl;
    }

    final foodItemId = (orderData['foodItemId'] ?? '').toString().trim();
    if (foodItemId.isEmpty) {
      return null;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('foodItems')
          .doc(foodItemId)
          .get();
      if (!doc.exists) {
        return null;
      }
      final data = doc.data();
      final imageUrl = (data?['imageUrl'] ?? '').toString().trim();
      return imageUrl.isEmpty ? null : imageUrl;
    } catch (_) {
      return null;
    }
  }

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
        body: const Center(child: Text('Please log in to view orders.')),
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
    final ordersStream = _ordersStream(userId);

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

        final allDocs = snapshot.data?.docs ?? [];
        final docs = _sortOrders(
          allDocs.where((doc) {
            final status = (doc.data()['status'] ?? 'new').toString();
            return _isActiveStatus(status);
          }),
        );

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
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
            return _buildOrderCard(data, context, orderId: order.id);
          },
        );
      },
    );
  }

  Widget _buildOrderHistory(String userId) {
    final ordersStream = _ordersStream(userId);

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

        final allDocs = snapshot.data?.docs ?? [];
        final docs = _sortOrders(
          allDocs.where((doc) {
            final status = (doc.data()['status'] ?? 'new').toString();
            return _isHistoryStatus(status);
          }),
        );

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

        final groups = _groupHistoryOrders(docs);

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            return _buildHistoryCard(groups[index], context);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(_OrderHistoryGroup group, BuildContext context) {
    final data = group.primaryData;
    final primaryOrderId = group.primaryOrderId;
    final restaurantName = (data['restaurantName'] ?? 'Restaurant').toString();
    final status = (data['status'] ?? 'pickedUp').toString();
    final hasReview = data['reviewed'] == true;
    final savedRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final timestamp = _createdAtFromData(data);
    final total = _groupBillTotal(group);

    final statusText = status == 'cancelled' ? 'Cancelled' : 'Completed';
    final statusColor = status == 'cancelled' ? Colors.red : Colors.green;
    final visibleItems = group.orders.take(2).toList();
    final hiddenCount = group.orders.length - visibleItems.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String?>(
                  future: _resolveOrderCardImage(data),
                  builder: (context, snapshot) {
                    final imageUrl = snapshot.data;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 52,
                        height: 52,
                        color: MyReservationsScreen._lightGrey,
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.storefront,
                                    color: Colors.grey,
                                  );
                                },
                              )
                            : const Icon(Icons.storefront, color: Colors.grey),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<Map<String, String>>(
                    future: _resolveRestaurantDetails(data),
                    builder: (context, snapshot) {
                      final restaurant =
                          snapshot.data ??
                          {
                            'name': restaurantName,
                            'address': (data['restaurantAddress'] ?? '')
                                .toString(),
                            'status': 'Loading...',
                          };

                      final subtitle =
                          (restaurant['status'] == 'Closed permanently' ||
                              (restaurant['address'] ?? '').trim().isEmpty)
                          ? (restaurant['status'] ?? '')
                          : (restaurant['address'] ?? '');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant['name'] ?? restaurantName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.check_circle, size: 18, color: statusColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...visibleItems.map((order) {
              final item = order.data();
              final quantity = (item['quantity'] is num)
                  ? (item['quantity'] as num).toInt()
                  : 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: MyReservationsScreen._lightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${quantity}x',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (item['foodName'] ?? 'Item').toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '& $hiddenCount more',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            Divider(color: Colors.grey[300], height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showHistoryGroupDetails(context, group),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE36B2C),
                  side: const BorderSide(color: Color(0xFFFFE4D6)),
                  backgroundColor: const Color(0xFFFFF2EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'DETAILS',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (status == 'pickedUp') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: hasReview
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.star, size: 16),
                        label: Text(
                          savedRating > 0
                              ? 'Reviewed • ${savedRating.toStringAsFixed(1)}'
                              : 'Reviewed',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[700],
                          side: BorderSide(color: Colors.amber[300]!),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () =>
                            _showReviewDialog(context, primaryOrderId, data),
                        icon: const Icon(Icons.star_border, size: 16),
                        label: const Text('Write a Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyReservationsScreen._primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Ordered: ${_formatOrderDate(timestamp)} • Bill Total: ₹${total.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> data,
    BuildContext context, {
    bool isHistory = false,
    String orderId = '',
  }) {
    final hasReview = data['reviewed'] == true;
    final foodName = data['foodName'] ?? 'Item';
    final quantity = (data['quantity'] is num)
        ? (data['quantity'] as num).toInt()
        : 1;
    final status = data['status'] ?? 'new';
    final createdAt = data['createdAt'];
    final price = (data['price'] is num) ? (data['price'] as num) : 0.0;

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
              color: statusColor.withValues(alpha: 0.1),
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
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String?>(
                      future: _resolveFoodImageUrl(data),
                      builder: (context, snapshot) {
                        final imageUrl = snapshot.data;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 56,
                            height: 56,
                            color: MyReservationsScreen._lightGrey,
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.fastfood_outlined,
                                        color: Colors.grey,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.fastfood_outlined,
                                    color: Colors.grey,
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
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
                            '$quantity item${quantity > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _resolveRestaurantName(data),
                        builder: (context, snapshot) {
                          final restaurantName =
                              snapshot.data ??
                              (data['restaurantName'] ?? 'Restaurant')
                                  .toString();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurantName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
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
                                '$quantity item${quantity > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
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
                            status == 'ready' ? Colors.green : Colors.orange,
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
                            foregroundColor: MyReservationsScreen._primaryColor,
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
                // Review button for picked-up orders
                if (isHistory && status == 'pickedUp')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: hasReview
                          ? OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.star, size: 16),
                              label: const Text('Reviewed'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.amber[700],
                                side: BorderSide(color: Colors.amber[300]!),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () =>
                                  _showReviewDialog(context, orderId, data),
                              icon: const Icon(Icons.star_border, size: 16),
                              label: const Text('Write a Review'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    MyReservationsScreen._primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream(String userId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortOrders(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final list = docs.toList();
    list.sort((a, b) {
      final aDate = _createdAtFromData(a.data());
      final bDate = _createdAtFromData(b.data());
      return bDate.compareTo(aDate);
    });
    return list;
  }

  bool _isActiveStatus(String status) {
    return status == 'new' || status == 'preparing' || status == 'ready';
  }

  bool _isHistoryStatus(String status) {
    return status == 'pickedUp' || status == 'cancelled';
  }

  List<_OrderHistoryGroup> _groupHistoryOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> byKey =
        {};

    for (final doc in docs) {
      final data = doc.data();
      final orderGroupId =
          (data['orderGroupId'] ?? data['orderId'] ?? doc.id).toString();
      final key = orderGroupId.isEmpty ? doc.id : orderGroupId;
      byKey.putIfAbsent(key, () => []).add(doc);
    }

    final groups = byKey.entries
        .map((entry) => _OrderHistoryGroup(key: entry.key, orders: entry.value))
        .toList();

    groups.sort((a, b) {
      final aDate = _createdAtFromData(a.primaryData);
      final bDate = _createdAtFromData(b.primaryData);
      return bDate.compareTo(aDate);
    });

    return groups;
  }

  DateTime _createdAtFromData(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }
    return DateTime.now();
  }

  double _groupBillTotal(_OrderHistoryGroup group) {
    return group.orders.fold<double>(0, (total, doc) {
      final item = doc.data();
      final price = (item['price'] is num)
          ? (item['price'] as num).toDouble()
          : 0;
      final quantity = (item['quantity'] is num)
          ? (item['quantity'] as num).toInt()
          : 1;
      return total + (price * quantity);
    });
  }

  Future<String?> _resolveOrderCardImage(Map<String, dynamic> data) async {
    return _resolveFoodImageUrl(data);
  }

  Future<Map<String, String>> _resolveRestaurantDetails(
    Map<String, dynamic> data,
  ) async {
    final fallbackName = (data['restaurantName'] ?? 'Restaurant').toString();
    final fallbackAddress = (data['restaurantAddress'] ?? '').toString();
    final restaurantId = (data['restaurantId'] ?? '').toString();

    if (restaurantId.isEmpty) {
      return {
        'name': fallbackName,
        'address': fallbackAddress,
        'status': fallbackAddress.isEmpty
            ? 'Address unavailable'
            : fallbackAddress,
      };
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();
      if (!doc.exists) {
        return {
          'name': fallbackName,
          'address': fallbackAddress,
          'status': 'Restaurant unavailable',
        };
      }

      final restaurant = doc.data() ?? {};
      final isOpen = restaurant['isOpen'] == true;
      return {
        'name': (restaurant['name'] ?? fallbackName).toString(),
        'address': (restaurant['address'] ?? fallbackAddress).toString(),
        'status': isOpen ? 'Open now' : 'Closed',
      };
    } catch (_) {
      return {
        'name': fallbackName,
        'address': fallbackAddress,
        'status': 'Unavailable',
      };
    }
  }

  Future<String> _resolveRestaurantName(Map<String, dynamic> data) async {
    final details = await _resolveRestaurantDetails(data);
    return details['name'] ?? 'Restaurant';
  }

  String _formatOrderDate(DateTime date) {
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
      'Dec',
    ];
    final month = months[date.month - 1];
    final hour24 = date.hour;
    final hour = (hour24 % 12) == 0 ? 12 : (hour24 % 12);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} $month ${date.year}, $hour:$minute $period';
  }

  void _showHistoryGroupDetails(
    BuildContext context,
    _OrderHistoryGroup group,
  ) {
    final timestamp = _createdAtFromData(group.primaryData);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order details',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...group.orders.map((doc) {
                final item = doc.data();
                final quantity = (item['quantity'] is num)
                    ? (item['quantity'] as num).toInt()
                    : 1;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text((item['foodName'] ?? 'Item').toString()),
                  subtitle: Text('Qty: $quantity'),
                  trailing: Text(
                    '₹${(((item['price'] is num) ? item['price'] as num : 0) * quantity).toStringAsFixed(0)}',
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text('Ordered: ${_formatOrderDate(timestamp)}'),
              Text('Total: ₹${_groupBillTotal(group).toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReviewDialog(
    BuildContext context,
    String orderId,
    Map<String, dynamic> orderData,
  ) {
    int selectedRating = 0;
    final commentController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How was your order?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    orderData['foodName'] ?? 'Item',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  // Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedRating = star),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            star <= selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      selectedRating == 0
                          ? 'Tap a star to rate'
                          : [
                              '',
                              'Poor',
                              'Fair',
                              'Good',
                              'Very Good',
                              'Excellent',
                            ][selectedRating],
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedRating == 0
                            ? Colors.grey
                            : Colors.amber[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Comment field
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Tell us what you thought (optional)...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFF5F5F5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFF5F5F5)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting || selectedRating == 0
                          ? null
                          : () async {
                              setSheetState(() => submitting = true);
                              final success = await _submitReview(
                                orderId: orderId,
                                orderData: orderData,
                                rating: selectedRating,
                                comment: commentController.text.trim(),
                              );
                              if (!sheetContext.mounted) return;
                              Navigator.pop(sheetContext);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Thanks for your review!'
                                          : 'Could not submit review. Try again.',
                                    ),
                                    backgroundColor: success
                                        ? MyReservationsScreen._primaryColor
                                        : Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyReservationsScreen._primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Review',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _submitReview({
    required String orderId,
    required Map<String, dynamic> orderData,
    required int rating,
    required String comment,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final batch = FirebaseFirestore.instance.batch();

      // Save review document
      final reviewRef = FirebaseFirestore.instance.collection('reviews').doc();
      batch.set(reviewRef, {
        'orderId': orderId,
        'restaurantId': orderData['restaurantId'] ?? '',
        'foodItemId': orderData['foodItemId'] ?? '',
        'userId': user.uid,
        'foodName': orderData['foodName'] ?? '',
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mark the order as reviewed
      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId);
      batch.update(orderRef, {
        'reviewed': true,
        'rating': rating,
        'reviewComment': comment,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Update the restaurant's average rating atomically
      final restaurantId = (orderData['restaurantId'] ?? '') as String;
      if (restaurantId.isNotEmpty) {
        final restaurantRef = FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId);
        await FirebaseFirestore.instance.runTransaction((txn) async {
          final snap = await txn.get(restaurantRef);
          if (!snap.exists) {
            return;
          }
          final d = snap.data() ?? {};
          final oldCount =
              (d['reviewCount'] as num?)?.toInt() ??
              (d['reviews'] as num?)?.toInt() ??
              0;
          final oldAvg = (d['rating'] as num?)?.toDouble() ?? 0.0;
          final oldSum = oldAvg * oldCount;
          final newCount = oldCount + 1;
          final newAvg = double.parse(
            ((oldSum + rating) / newCount).toStringAsFixed(1),
          );
          txn.update(restaurantRef, {
            'reviewCount': newCount,
            'reviews': newCount,
            'rating': newAvg,
          });
        });
      }

      return true;
    } catch (_) {
      return false;
    }
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
        return FutureBuilder<Map<String, String>>(
          future: _resolveRestaurantDetails(order),
          builder: (context, snapshot) {
            final restaurant =
                snapshot.data ??
                {
                  'name': (order['restaurantName'] ?? 'Restaurant').toString(),
                  'address': (order['restaurantAddress'] ?? '').toString(),
                  'status': 'Loading...',
                };

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
                  _buildDetailRow('Restaurant', restaurant['name'] ?? '-'),
                  _buildDetailRow(
                    'Restaurant Status',
                    restaurant['status'] ?? '-',
                  ),
                  if ((restaurant['address'] ?? '').trim().isNotEmpty)
                    _buildDetailRow('Address', restaurant['address'] ?? '-'),
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
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
            const Text('Are you sure you want to cancel this order?'),
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
          duration: Duration(seconds: 3),
        ),
      );

      // Get the order ID (we need to find it from Firestore)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final foodItemId = orderData['foodItemId'] as String?;
      final orderedQuantity =
          orderData['quantity'] as int? ??
          (orderData['quantity'] is num
              ? (orderData['quantity'] as num).toInt()
              : 1);
      final foodName = orderData['foodName'] as String? ?? 'Unknown Item';

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

        final foodRef = FirebaseFirestore.instance
            .collection('foodItems')
            .doc(foodItemId);
        final foodSnapshot = await transaction.get(foodRef);

        if (!foodSnapshot.exists) {
          throw Exception('Food item no longer exists');
        }

        final currentQuantity =
            (foodSnapshot.get('quantityAvailable') as num?)?.toInt() ?? 0;

        // 3. Calculate restored quantity (prevent negative)
        final restoredQuantity = (currentQuantity + orderedQuantity)
            .clamp(0, double.infinity)
            .toInt();

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
      if (context.mounted) {
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
                      style: TextStyle(fontWeight: FontWeight.bold),
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
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
            duration: const Duration(seconds: 3),
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
}
