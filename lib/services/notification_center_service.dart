import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationUnreadCounts {
  const NotificationUnreadCounts({
    required this.orderUpdates,
    required this.stockAlerts,
  });

  final int orderUpdates;
  final int stockAlerts;

  int get total => orderUpdates + stockAlerts;
}

class NotificationCenterService {
  NotificationCenterService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String orderUpdatesEnabledField =
      'notificationsOrderUpdatesEnabled';
  static const String stockAlertsEnabledField =
      'notificationsStockAlertsEnabled';
  static const String seenOrderKeysField = 'notificationsSeenOrderKeys';
  static const String seenStockIdsField = 'notificationsSeenStockItemIds';
  static const String lastSeenAtField = 'notificationsLastSeenAt';

  Future<Map<String, dynamic>> getUserNotificationData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() ?? const <String, dynamic>{};
  }

  Future<NotificationUnreadCounts> getUnreadCounts(String uid) async {
    final userData = await getUserNotificationData(uid);
    final orderEnabled = (userData[orderUpdatesEnabledField] as bool?) ?? true;
    final stockEnabled = (userData[stockAlertsEnabledField] as bool?) ?? true;

    final seenOrderKeys =
        ((userData[seenOrderKeysField] as List<dynamic>?) ?? const <dynamic>[])
            .map((e) => e.toString())
            .toSet();
    final seenStockIds =
        ((userData[seenStockIdsField] as List<dynamic>?) ?? const <dynamic>[])
            .map((e) => e.toString())
            .toSet();

    int unreadOrderCount = 0;
    int unreadStockCount = 0;

    if (orderEnabled) {
      final orderKeys = await _fetchCurrentOrderKeys(uid, limit: 200);
      unreadOrderCount = orderKeys
          .where((k) => !seenOrderKeys.contains(k))
          .length;
    }

    if (stockEnabled) {
      final stockIds = await _fetchCurrentInStockFavoriteItemIds(uid);
      unreadStockCount = stockIds
          .where((id) => !seenStockIds.contains(id))
          .length;
    }

    return NotificationUnreadCounts(
      orderUpdates: unreadOrderCount,
      stockAlerts: unreadStockCount,
    );
  }

  Future<void> markCurrentAsSeen(String uid) async {
    final userData = await getUserNotificationData(uid);

    final existingOrderKeys =
        ((userData[seenOrderKeysField] as List<dynamic>?) ?? const <dynamic>[])
            .map((e) => e.toString())
            .toList();
    final existingStockIds =
        ((userData[seenStockIdsField] as List<dynamic>?) ?? const <dynamic>[])
            .map((e) => e.toString())
            .toList();

    final currentOrderKeys = await _fetchCurrentOrderKeys(uid, limit: 300);
    final currentStockIds = await _fetchCurrentInStockFavoriteItemIds(uid);

    final mergedOrderKeys = <String>[];
    for (final key in [...currentOrderKeys, ...existingOrderKeys]) {
      if (!mergedOrderKeys.contains(key)) {
        mergedOrderKeys.add(key);
      }
      if (mergedOrderKeys.length >= 300) {
        break;
      }
    }

    final mergedStockIds = <String>[];
    for (final id in [...currentStockIds, ...existingStockIds]) {
      if (!mergedStockIds.contains(id)) {
        mergedStockIds.add(id);
      }
      if (mergedStockIds.length >= 300) {
        break;
      }
    }

    await _firestore.collection('users').doc(uid).set({
      seenOrderKeysField: mergedOrderKeys,
      seenStockIdsField: mergedStockIds,
      lastSeenAtField: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<String>> _fetchCurrentOrderKeys(
    String uid, {
    int limit = 200,
  }) async {
    final allowedStatuses = <String>{
      'new',
      'preparing',
      'ready',
      'pickedUp',
      'cancelled',
    };

    final snapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .limit(limit * 3)
        .get();

    final keys = <String>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString();
      if (!allowedStatuses.contains(status)) {
        continue;
      }

      final groupId = (data['orderGroupId'] ?? doc.id).toString();
      final key = '$groupId|$status';
      if (!keys.contains(key)) {
        keys.add(key);
      }
    }

    return keys;
  }

  Future<List<String>> _fetchCurrentInStockFavoriteItemIds(String uid) async {
    final favoriteDoc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc('items')
        .get();

    final favoriteData = favoriteDoc.data() ?? const <String, dynamic>{};
    final itemIds = favoriteData.keys.toList();
    if (itemIds.isEmpty) {
      return const <String>[];
    }

    final foodDocs = await _fetchByIds(collection: 'foodItems', ids: itemIds);

    final restaurantIds = <String>{};
    for (final doc in foodDocs) {
      final restaurantId = (doc.data()['restaurantId'] ?? '').toString();
      if (restaurantId.isNotEmpty) {
        restaurantIds.add(restaurantId);
      }
    }

    final restaurantDocs = await _fetchByIds(
      collection: 'restaurants',
      ids: restaurantIds.toList(),
    );

    final openRestaurantIds = restaurantDocs
        .where((doc) => doc.data()['isOpen'] == true)
        .map((doc) => doc.id)
        .toSet();

    final inStockIds = <String>[];
    for (final doc in foodDocs) {
      final data = doc.data();
      final isAvailable = data['isAvailable'] == true;
      final quantity = (data['quantityAvailable'] is num)
          ? (data['quantityAvailable'] as num).toInt()
          : 0;
      final restaurantId = (data['restaurantId'] ?? '').toString();

      if (isAvailable &&
          quantity > 0 &&
          openRestaurantIds.contains(restaurantId)) {
        inStockIds.add(doc.id);
      }
    }

    return inStockIds;
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
}
