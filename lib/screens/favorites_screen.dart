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
  String? _error;
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
      _error = null;
    });

    try {
      final restaurants = await _favoritesService.getFavoriteRestaurants();
      final items = await _favoritesService.getFavoriteFoodItems();
      if (!mounted) return;
      setState(() {
        _favoriteRestaurants = restaurants;
        _favoriteItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
        const SnackBar(
          content: Text('Removed from favorites.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to remove favorite: $e'),
          duration: const Duration(seconds: 3),
        ),
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
        const SnackBar(
          content: Text('Removed from favorites.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to remove favorite: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _openRestaurant({
    required String restaurantId,
    required String fallbackName,
  }) async {
    if (restaurantId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text('Restaurant not found.'),
          duration: Duration(seconds: 3),
        ),
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
    final imageUrl = (restaurant['imageUrl'] ?? '').toString();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () => _openRestaurant(
          restaurantId: restaurantId,
          fallbackName: restaurantName,
        ),
        leading: _buildFavoriteImage(
          imageUrl: imageUrl,
          backgroundColor: colors.primaryContainer,
          fallbackIcon: Icons.storefront,
          fallbackIconColor: colors.onPrimaryContainer,
        ),
        title: Text(
          restaurantName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
    final imageUrl = (item['imageUrl'] ?? '').toString();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () => _openRestaurant(
          restaurantId: restaurantId,
          fallbackName: 'Restaurant',
        ),
        leading: _buildFavoriteImage(
          imageUrl: imageUrl,
          backgroundColor: colors.secondaryContainer,
          fallbackIcon: Icons.fastfood,
          fallbackIconColor: colors.onSecondaryContainer,
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

  Widget _buildFavoriteImage({
    required String imageUrl,
    required Color backgroundColor,
    required IconData fallbackIcon,
    required Color fallbackIconColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 48,
        color: backgroundColor,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(fallbackIcon, color: fallbackIconColor);
                },
              )
            : Icon(fallbackIcon, color: fallbackIconColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not load favourites',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadFavorites,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
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
    );
  }
}
