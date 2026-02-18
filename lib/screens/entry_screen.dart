import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:save_bite/services/auth_serivce.dart';
import 'package:save_bite/screens/restaurant_details_screen.dart';

class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final double rating;
  final int reviews;
  final String distance;
  final String imageUrl;
  final bool isOpen;
  final String deliveryTime;

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.imageUrl,
    required this.isOpen,
    required this.deliveryTime,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? 'Unknown Restaurant',
      cuisine: data['cuisine'] ?? 'General',
      rating: (data['rating'] ?? 0).toDouble(),
      reviews: data['reviews'] ?? 0,
      distance: data['distance'] ?? 'N/A',
      imageUrl:
          data['imageUrl'] ??
          'https://via.placeholder.com/300x200?text=Restaurant',
      isOpen: data['isOpen'] ?? true,
      deliveryTime: data['deliveryTime'] ?? 'N/A',
    );
  }
}

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  List<Restaurant> restaurants = [];
  bool isLoadingRestaurants = true;
  int _selectedTab = 0; // 0: Restaurants, 1: Dishes
  bool _isVegetarian = false;
  bool _only99Store = false;
  bool _onlyOffers = false;

  // Filter options
  String selectedFoodType = 'All';
  String selectedAvailability = 'All';
  String sortBy = 'Relevance';

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      final snapshot = await _firestore.collection('restaurants').get();
      setState(() {
        restaurants = snapshot.docs
            .map((doc) => Restaurant.fromFirestore(doc))
            .toList();
        isLoadingRestaurants = false;
      });
    } catch (e) {
      setState(() {
        isLoadingRestaurants = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading restaurants: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Restaurant> getFilteredRestaurants() {
    List<Restaurant> filtered = restaurants;

    // Filter by food type if selected
    if (selectedFoodType != 'All') {
      filtered = filtered.where((r) => r.cuisine == selectedFoodType).toList();
    }

    // Filter by availability
    if (selectedAvailability == 'Open') {
      filtered = filtered.where((r) => r.isOpen).toList();
    }

    // Filter by vegetarian if toggled
    if (_isVegetarian) {
      // This would filter based on restaurant's veg-only flag
      // For now, just filter by name containing 'veg'
      filtered = filtered.where((r) => r.cuisine.toLowerCase().contains('veg')).toList();
    }

    // Filter by $99 store
    if (_only99Store) {
      // This would need a field in Restaurant model
      // filtered = filtered.where((r) => r.priceCategory == '99').toList();
    }

    // Filter by offers
    if (_onlyOffers) {
      // This would need an offers field in Restaurant model
      // filtered = filtered.where((r) => r.hasOffers == true).toList();
    }

    // Search filter
    if (searchController.text.isNotEmpty) {
      filtered = filtered
          .where(
            (r) => r.name.toLowerCase().contains(
              searchController.text.toLowerCase(),
            ),
          )
          .toList();
    }

    // Sort results
    switch (sortBy) {
      case 'Rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Delivery Time':
        // Would need to parse deliveryTime properly
        break;
      case 'Distance':
        // Would need to parse distance properly
        break;
      case 'Relevance':
      default:
        // Keep original order
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Bar with Back Button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(
                left: 16.0,
                top: 40.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Search for dishes & restaurants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar with VEG Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      onChanged: (value) {
                        setState(() {});
                      },
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      cursorColor: const Color(0xFF2E7D32),
                      decoration: InputDecoration(
                        hintText: "Search here...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey),
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {});
                                },
                              )
                            : IconButton(
                                icon: Icon(Icons.mic, color: Colors.red[600]),
                                onPressed: () {},
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _isVegetarian = !_isVegetarian),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _isVegetarian
                            ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isVegetarian
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'VEG',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isVegetarian
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey,
                            ),
                          ),
                          Icon(
                            Icons.toggle_off,
                            size: 20,
                            color: _isVegetarian
                                ? const Color(0xFF2E7D32)
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tabs: Restaurants and Dishes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 0
                                  ? const Color(0xFF2E7D32)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          'Restaurants',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 0
                                ? const Color(0xFF2E7D32)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 1
                                  ? const Color(0xFF2E7D32)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          'Dishes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 1
                                ? const Color(0xFF2E7D32)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            const SizedBox(height: 12),

            // Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterButton('Food Type', () {
                      _showFoodTypeOptions();
                    }, isActive: selectedFoodType != 'All'),
                    const SizedBox(width: 12),
                    _buildFilterButton('Availability', () {
                      _showAvailabilityOptions();
                    }, isActive: selectedAvailability != 'All'),
                    const SizedBox(width: 12),
                    _buildFilterButton('Sort by', () {
                      _showSortOptions();
                    }),
                    const SizedBox(width: 12),
                    _buildFilterButton('$99 store', () {
                      setState(() => _only99Store = !_only99Store);
                    }, isActive: _only99Store),
                    const SizedBox(width: 12),
                    _buildFilterButton('Offers', () {
                      setState(() => _onlyOffers = !_onlyOffers);
                    }, isActive: _onlyOffers),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content based on selected tab
            _selectedTab == 0
                ? _buildRestaurantsTab()
                : _buildDishesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    String label,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2E7D32).withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isActive ? const Color(0xFF2E7D32) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label == 'Sort by'
                  ? Icons.unfold_more
                  : Icons.check_circle_outline,
              size: 16,
              color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF2E7D32) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsTab() {
    final filtered = getFilteredRestaurants();

    if (isLoadingRestaurants) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No restaurants found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildRestaurantCard(filtered[index]),
      ),
    );
  }

  Widget _buildDishesTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.fastfood, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Search for dishes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon!',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RestaurantDetailsScreen(
              restaurantId: restaurant.id,
              restaurantName: restaurant.name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    restaurant.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 64),
                      );
                    },
                  ),
                ),
                // Offer Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'GET 60% OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Restaurant Info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.rating} • ${restaurant.deliveryTime}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        restaurant.distance,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.cuisine,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort by'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Relevance', 'Rating', 'Delivery Time', 'Distance']
              .map((option) => ListTile(
                    title: Text(option),
                    trailing: sortBy == option
                        ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                        : null,
                    onTap: () {
                      setState(() => sortBy = option);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showFoodTypeOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Food Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['All', 'Continental', 'Indian', 'Chinese', 'Fast Food', 'Bakery']
              .map((option) => ListTile(
                    title: Text(option),
                    trailing: selectedFoodType == option
                        ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                        : null,
                    onTap: () {
                      setState(() => selectedFoodType = option);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showAvailabilityOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Availability'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['All', 'Open', 'Coming Soon']
              .map((option) => ListTile(
                    title: Text(option),
                    trailing: selectedAvailability == option
                        ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                        : null,
                    onTap: () {
                      setState(() => selectedAvailability = option);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }
}

