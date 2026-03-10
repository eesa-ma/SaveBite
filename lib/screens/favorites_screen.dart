import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:save_bite/screens/restaurant_details_screen.dart';
import 'package:save_bite/services/favorites_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  late final TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _favoriteRestaurants = [];
  List<Map<String, dynamic>> _favoriteItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    final restaurants = await _favoritesService.getFavoriteRestaurants();
    final items = await _favoritesService.getFavoriteFoodItems();

    if (!mounted) {
      return;
    }

    setState(() {
      _favoriteRestaurants = restaurants;
      _favoriteItems = items;
      _isLoading = false;
    });
  }

  Future<void> _removeRestaurantFavorite(String restaurantId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _favoritesService.removeRestaurantFavorite(restaurantId);
      if (!mounted) {
        return;
      }
      await _loadFavorites();
      messenger.showSnackBar(
        const SnackBar(content: Text('Removed from favorites.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to remove favorite: $e')),
      );
    }
  }

  Future<void> _removeFoodFavorite(String itemId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _favoritesService.removeFoodItemFavorite(itemId);
      if (!mounted) {
        return;
      }
      await _loadFavorites();
      messenger.showSnackBar(
        const SnackBar(content: Text('Removed from favorites.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to remove favorite: $e')),
      );
    }
  }

  Future<void> _openRestaurant({
    required String restaurantId,
    required String fallbackName,
  }) async {
    if (restaurantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant not found.')),
      );
      return;
    }

    String restaurantName = fallbackName;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        restaurantName = (data?['name'] ?? fallbackName).toString();
      }
    } catch (_) {
      // Use fallback name.
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantDetailsScreen(
          restaurantId: restaurantId,
          restaurantName: restaurantName,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 72, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantTile(Map<String, dynamic> restaurant) {
    final colors = Theme.of(context).colorScheme;
    final restaurantId = (restaurant['id'] ?? '').toString();
    final restaurantName = (restaurant['name'] ?? 'Restaurant').toString();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () => _openRestaurant(
          restaurantId: restaurantId,
          fallbackName: restaurantName,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.storefront, color: colors.onPrimaryContainer),
        ),
        title: Text(restaurantName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: const Text('Tap to open restaurant'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _removeRestaurantFavorite(restaurantId),
        ),
      ),
    );
  }

  Widget _buildFoodTile(Map<String, dynamic> item) {
    final colors = Theme.of(context).colorScheme;
    final itemId = (item['id'] ?? '').toString();
    final itemName = (item['name'] ?? 'Item').toString();
    final restaurantId = (item['restaurantId'] ?? '').toString();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () => _openRestaurant(
          restaurantId: restaurantId,
          fallbackName: 'Restaurant',
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.fastfood, color: colors.onSecondaryContainer),
        ),
        title: Text(itemName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: const Text('Tap to open restaurant'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _removeFoodFavorite(itemId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Restaurants'),
            Tab(text: 'Food Items'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _favoriteRestaurants.isEmpty
                    ? _buildEmptyState('No favorite restaurants yet.')
                    : RefreshIndicator(
                        onRefresh: _loadFavorites,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _favoriteRestaurants.length,
                          itemBuilder: (_, index) =>
                              _buildRestaurantTile(_favoriteRestaurants[index]),
                        ),
                      ),
                _favoriteItems.isEmpty
                    ? _buildEmptyState('No favorite food items yet.')
                    : RefreshIndicator(
                        onRefresh: _loadFavorites,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _favoriteItems.length,
                          itemBuilder: (_, index) =>
                              _buildFoodTile(_favoriteItems[index]),
                        ),
                      ),
              ],
            ),
      bottomNavigationBar: Container(
        color: colors.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          'Tip: Tap any card to open its restaurant',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
      ),
    );
  }
}
