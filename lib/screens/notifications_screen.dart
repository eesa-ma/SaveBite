import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:save_bite/screens/restaurant_details_screen.dart';
import 'package:save_bite/services/notification_center_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationCenterService _notificationCenterService =
      NotificationCenterService();

  bool _orderUpdatesEnabled = true;
  bool _stockAlertsEnabled = true;
  bool _preferencesLoaded = false;

  int _orderQueryLimit = 50;
  int _stockDisplayLimit = 50;
  DateTime _lastUpdatedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _preferencesLoaded = true;
        _lastUpdatedAt = DateTime.now();
      });
      return;
    }

    try {
      final data = await _notificationCenterService.getUserNotificationData(
        user.uid,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _orderUpdatesEnabled =
            (data[NotificationCenterService.orderUpdatesEnabledField]
                as bool?) ??
            true;
        _stockAlertsEnabled =
            (data[NotificationCenterService.stockAlertsEnabledField]
                as bool?) ??
            true;
        _preferencesLoaded = true;
        _lastUpdatedAt = DateTime.now();
      });
      await _markCurrentNotificationsSeen();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _preferencesLoaded = true;
        _lastUpdatedAt = DateTime.now();
      });
    }
  }

  Future<void> _updatePreferences({
    required bool orderUpdatesEnabled,
    required bool stockAlertsEnabled,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    await _firestore.collection('users').doc(user.uid).set({
      NotificationCenterService.orderUpdatesEnabledField: orderUpdatesEnabled,
      NotificationCenterService.stockAlertsEnabledField: stockAlertsEnabled,
    }, SetOptions(merge: true));
  }

  Future<bool> _setOrderUpdatesEnabled(bool value) async {
    final previous = _orderUpdatesEnabled;
    setState(() {
      _orderUpdatesEnabled = value;
    });

    try {
      await _updatePreferences(
        orderUpdatesEnabled: value,
        stockAlertsEnabled: _stockAlertsEnabled,
      );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _orderUpdatesEnabled = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update preference: $error')),
      );
      return false;
    }
  }

  Future<bool> _setStockAlertsEnabled(bool value) async {
    final previous = _stockAlertsEnabled;
    setState(() {
      _stockAlertsEnabled = value;
    });

    try {
      await _updatePreferences(
        orderUpdatesEnabled: _orderUpdatesEnabled,
        stockAlertsEnabled: value,
      );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _stockAlertsEnabled = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update preference: $error')),
      );
      return false;
    }
  }

  Future<void> _markCurrentNotificationsSeen() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _notificationCenterService.markCurrentAsSeen(user.uid);
    } catch (_) {
      // Best-effort update only.
    }
  }

  Future<void> _openNotificationSettings() async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        var modalOrderUpdatesEnabled = _orderUpdatesEnabled;
        var modalStockAlertsEnabled = _stockAlertsEnabled;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.receipt_long_outlined),
                      title: const Text('Order status updates'),
                      subtitle: const Text(
                        'New, preparing, ready, completed updates',
                      ),
                      value: modalOrderUpdatesEnabled,
                      onChanged: (value) async {
                        setModalState(() {
                          modalOrderUpdatesEnabled = value;
                        });
                        final success = await _setOrderUpdatesEnabled(value);
                        if (!success && mounted) {
                          setModalState(() {
                            modalOrderUpdatesEnabled = _orderUpdatesEnabled;
                          });
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.inventory_2_outlined),
                      title: const Text('Favorite item restock alerts'),
                      subtitle: const Text(
                        'Back-in-stock updates for favorites',
                      ),
                      value: modalStockAlertsEnabled,
                      onChanged: (value) async {
                        setModalState(() {
                          modalStockAlertsEnabled = value;
                        });
                        final success = await _setStockAlertsEnabled(value);
                        if (!success && mounted) {
                          setModalState(() {
                            modalStockAlertsEnabled = _stockAlertsEnabled;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream(String uid) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .limit(_orderQueryLimit * 3)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _favoriteItemsStream(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc('items')
        .snapshots();
  }

  Future<List<_StockAlert>> _buildStockAlerts(
    Map<String, dynamic> favoriteItemsData,
  ) async {
    final favoriteItemIds = favoriteItemsData.keys.toList();
    if (favoriteItemIds.isEmpty) {
      return const <_StockAlert>[];
    }

    final foodDocs = await _fetchByIds(
      collection: 'foodItems',
      ids: favoriteItemIds,
      chunkSize: 10,
    );

    final restaurantIds = <String>{};
    for (final doc in foodDocs) {
      final id = (doc.data()['restaurantId'] ?? '').toString();
      if (id.isNotEmpty) {
        restaurantIds.add(id);
      }
    }

    final restaurantDocs = await _fetchByIds(
      collection: 'restaurants',
      ids: restaurantIds.toList(),
      chunkSize: 10,
    );

    final restaurantNameById = <String, String>{
      for (final doc in restaurantDocs)
        doc.id: (doc.data()['name'] ?? 'Restaurant').toString(),
    };
    final openRestaurantIds = restaurantDocs
        .where((doc) => doc.data()['isOpen'] == true)
        .map((doc) => doc.id)
        .toSet();

    final alerts = <_StockAlert>[];
    for (final doc in foodDocs) {
      final data = doc.data();
      final isAvailable = data['isAvailable'] == true;
      final quantity = (data['quantityAvailable'] is num)
          ? (data['quantityAvailable'] as num).toInt()
          : 0;
      final restaurantId = (data['restaurantId'] ?? '').toString();

      if (!isAvailable || quantity <= 0) {
        continue;
      }
      if (!openRestaurantIds.contains(restaurantId)) {
        continue;
      }

      final fallbackMeta = favoriteItemsData[doc.id];
      final fallbackName = fallbackMeta is Map<String, dynamic>
          ? (fallbackMeta['name'] ?? '').toString()
          : '';
      final fallbackImage = fallbackMeta is Map<String, dynamic>
          ? (fallbackMeta['imageUrl'] ?? '').toString()
          : '';

      final itemName = (data['name'] ?? fallbackName).toString();
      final imageUrl = (data['imageUrl'] ?? fallbackImage).toString();

      alerts.add(
        _StockAlert(
          itemId: doc.id,
          itemName: itemName.isEmpty ? 'Food item' : itemName,
          restaurantId: restaurantId,
          restaurantName: restaurantNameById[restaurantId] ?? 'Restaurant',
          imageUrl: imageUrl,
          quantityAvailable: quantity,
        ),
      );
    }

    alerts.sort(
      (a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
    );
    return alerts;
  }

  List<_OrderTimeline> _buildOrderTimelines(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final allowedStatuses = <String>{
      'new',
      'preparing',
      'ready',
      'pickedUp',
      'cancelled',
    };

    final grouped = <String, _OrderTimeline>{};
    for (final doc in docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString();
      if (!allowedStatuses.contains(status)) {
        continue;
      }

      final createdAtValue = data['createdAt'];
      final updatedAt = createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime(1970);
      final orderGroupId = (data['orderGroupId'] ?? doc.id).toString();

      final previous = grouped[orderGroupId];
      if (previous == null || updatedAt.isAfter(previous.updatedAt)) {
        grouped[orderGroupId] = _OrderTimeline(
          orderGroupId: orderGroupId,
          restaurantName: (data['restaurantName'] ?? 'Restaurant').toString(),
          foodName: (data['foodName'] ?? 'Order item').toString(),
          currentStatus: status,
          updatedAt: updatedAt,
        );
      }
    }

    final timelines = grouped.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return timelines;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchByIds({
    required String collection,
    required List<String> ids,
    int chunkSize = 10,
  }) async {
    if (ids.isEmpty) {
      return const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    }

    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
      final chunk = ids.sublist(i, end);
      final snapshot = await _firestore
          .collection(collection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      docs.addAll(snapshot.docs);
    }

    return docs;
  }

  IconData _orderIcon(String status) {
    switch (status) {
      case 'ready':
        return Icons.notifications_active;
      case 'preparing':
        return Icons.soup_kitchen_outlined;
      case 'pickedUp':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color _orderColor(String status) {
    switch (status) {
      case 'ready':
        return const Color(0xFF2E7D32);
      case 'preparing':
        return const Color(0xFFEF6C00);
      case 'pickedUp':
        return const Color(0xFF1565C0);
      case 'cancelled':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF455A64);
    }
  }

  String _orderTitle(String status) {
    switch (status) {
      case 'ready':
        return 'Order Ready';
      case 'preparing':
        return 'Preparing Your Order';
      case 'pickedUp':
        return 'Order Completed';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return 'Order Update';
    }
  }

  String _orderMessage(_OrderTimeline order) {
    switch (order.currentStatus) {
      case 'ready':
        return '${order.restaurantName} marked ${order.foodName} as ready.';
      case 'preparing':
        return '${order.restaurantName} is preparing ${order.foodName}.';
      case 'pickedUp':
        return 'Order from ${order.restaurantName} has been completed.';
      case 'cancelled':
        return 'Order from ${order.restaurantName} was cancelled.';
      default:
        return 'Order received by ${order.restaurantName}.';
    }
  }

  List<String> _timelineStepsForStatus(String status) {
    switch (status) {
      case 'preparing':
        return const ['new', 'preparing'];
      case 'ready':
        return const ['new', 'preparing', 'ready'];
      case 'pickedUp':
        return const ['new', 'preparing', 'ready', 'pickedUp'];
      case 'cancelled':
        return const ['new', 'cancelled'];
      default:
        return const ['new'];
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'new':
        return 'New';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'pickedUp':
        return 'Picked Up';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'New';
    }
  }

  Widget _buildTimeline(String currentStatus) {
    final steps = currentStatus == 'cancelled'
        ? const ['new', 'preparing', 'ready', 'cancelled']
        : const ['new', 'preparing', 'ready', 'pickedUp'];
    final reached = _timelineStepsForStatus(currentStatus).toSet();

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: reached.contains(steps[i])
                  ? const Color(0x1A2E7D32)
                  : const Color(0xFFECEFF1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _statusLabel(steps[i]),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: reached.contains(steps[i])
                    ? const Color(0xFF2E7D32)
                    : Colors.grey.shade600,
              ),
            ),
          ),
          if (i != steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: reached.contains(steps[i + 1])
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE0E0E0),
              ),
            ),
        ],
      ],
    );
  }

  String _timeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _lastUpdatedLabel() {
    final diff = DateTime.now().difference(_lastUpdatedAt);
    if (diff.inSeconds < 5) {
      return 'Last updated: just now';
    }
    if (diff.inMinutes < 1) {
      return 'Last updated: ${diff.inSeconds}s ago';
    }
    if (diff.inMinutes < 60) {
      return 'Last updated: ${diff.inMinutes}m ago';
    }
    return 'Last updated: ${diff.inHours}h ago';
  }

  Future<void> _handleManualRefresh() async {
    await _markCurrentNotificationsSeen();
    if (!mounted) {
      return;
    }
    setState(() {
      _lastUpdatedAt = DateTime.now();
    });
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332E7D32),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(0x22FFFFFF),
            child: Icon(Icons.notifications_active, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Live updates for your orders and favourite items',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(_OrderTimeline order) {
    final color = _orderColor(order.currentStatus);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(_orderIcon(order.currentStatus), color: color),
        ),
        title: Text(
          _orderTitle(order.currentStatus),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _orderMessage(order),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            _buildTimeline(order.currentStatus),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.currentStatus.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _timeAgo(order.updatedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockTile(_StockAlert alert) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x332E7D32)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: () => _openRestaurantFromStockAlert(alert),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 50,
            height: 50,
            color: colors.primaryContainer,
            child: alert.imageUrl.isNotEmpty
                ? Image.network(
                    alert.imageUrl,
                    fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                        Icon(Icons.fastfood, color: colors.onPrimaryContainer),
                  )
                : Icon(Icons.fastfood, color: colors.onPrimaryContainer),
          ),
        ),
        title: Text(
          alert.itemName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'In stock at ${alert.restaurantName} (${alert.quantityAvailable} available)',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x1A2E7D32),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRestaurantFromStockAlert(_StockAlert alert) async {
    if (alert.restaurantId.isEmpty || !mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantDetailsScreen(
          restaurantId: alert.restaurantId,
          restaurantName: alert.restaurantName,
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String text}) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceOffState({
    required IconData icon,
    required String text,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            const Text(
              'You can enable it from the settings icon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _ordersStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load order notifications: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? const [];
        final timelines = _buildOrderTimelines(docs);
        if (timelines.isEmpty) {
          return _buildEmptyState(
            icon: Icons.receipt_long_outlined,
            text:
                'No order updates yet.\nYou will see preparing, ready, and completion updates here.',
          );
        }

        final canLoadMore = docs.length >= _orderQueryLimit;

        return RefreshIndicator(
          onRefresh: _handleManualRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              for (final timeline in timelines) _buildOrderTile(timeline),
              if (canLoadMore)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _orderQueryLimit += 50;
                      });
                    },
                    icon: const Icon(Icons.expand_more),
                    label: const Text('Load more'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStockTab(String uid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _favoriteItemsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load stock notifications: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final favoriteItemsData = snapshot.data?.data() ?? {};
        return FutureBuilder<List<_StockAlert>>(
          future: _buildStockAlerts(favoriteItemsData),
          builder: (context, alertsSnapshot) {
            if (alertsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (alertsSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load alerts: ${alertsSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final alerts = alertsSnapshot.data ?? const <_StockAlert>[];
            if (alerts.isEmpty) {
              return _buildEmptyState(
                icon: Icons.notifications_off_outlined,
                text:
                    'No stock alerts yet.\nWhen a favourite item is back in stock, it will appear here.',
              );
            }

            final visibleAlerts = alerts.take(_stockDisplayLimit).toList();
            final canLoadMore = alerts.length > _stockDisplayLimit;

            return RefreshIndicator(
              onRefresh: _handleManualRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                itemCount: visibleAlerts.length + (canLoadMore ? 1 : 0),
                itemBuilder: (_, index) {
                  if (index < visibleAlerts.length) {
                    return _buildStockTile(visibleAlerts[index]);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _stockDisplayLimit += 50;
                        });
                      },
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Load more'),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to view notifications.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: _openNotificationSettings,
            icon: const Icon(Icons.tune),
            tooltip: 'Notification preferences',
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _buildHeaderCard(),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _lastUpdatedLabel(),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x22333333)),
              ),
              child: const TabBar(
                dividerColor: Colors.transparent,
                labelColor: Color(0xFF2E7D32),
                unselectedLabelColor: Colors.black54,
                indicatorColor: Color(0xFF2E7D32),
                tabs: [
                  Tab(text: 'Order Updates'),
                  Tab(text: 'Stock Alerts'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: !_preferencesLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _orderUpdatesEnabled
                            ? _buildOrdersTab(user.uid)
                            : _buildPreferenceOffState(
                                icon: Icons.receipt_long_outlined,
                                text:
                                    'Order status updates are currently turned off.',
                              ),
                        _stockAlertsEnabled
                            ? _buildStockTab(user.uid)
                            : _buildPreferenceOffState(
                                icon: Icons.inventory_2_outlined,
                                text:
                                    'Favorite item restock alerts are currently turned off.',
                              ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockAlert {
  const _StockAlert({
    required this.itemId,
    required this.itemName,
    required this.restaurantId,
    required this.restaurantName,
    required this.imageUrl,
    required this.quantityAvailable,
  });

  final String itemId;
  final String itemName;
  final String restaurantId;
  final String restaurantName;
  final String imageUrl;
  final int quantityAvailable;
}

class _OrderTimeline {
  const _OrderTimeline({
    required this.orderGroupId,
    required this.restaurantName,
    required this.foodName,
    required this.currentStatus,
    required this.updatedAt,
  });

  final String orderGroupId;
  final String restaurantName;
  final String foodName;
  final String currentStatus;
  final DateTime updatedAt;
}
