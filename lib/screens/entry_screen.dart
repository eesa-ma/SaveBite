import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:save_bite/services/auth_serivce.dart';
import 'package:save_bite/services/favorites_service.dart';
import 'package:save_bite/screens/restaurant_details_screen.dart';
import '../services/location_service.dart';

class Restaurant {
  final String id;
  final String name;
  final double rating;
  final int reviews;
  final String imageUrl;
  final bool isOpen;
  final double? latitude;
  final double? longitude;

  Restaurant({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.isOpen,
    required this.latitude,
    required this.longitude,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final latitudeValue = data['latitude'];
    final longitudeValue = data['longitude'];
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? 'Unknown Restaurant',
      rating: (data['rating'] ?? 0).toDouble(),
      reviews: data['reviews'] ?? 0,
      imageUrl:
          data['imageUrl'] ??
          'https://via.placeholder.com/300x200?text=Restaurant',
      isOpen: data['isOpen'] ?? true,
      latitude: latitudeValue is num ? latitudeValue.toDouble() : null,
      longitude: longitudeValue is num ? longitudeValue.toDouble() : null,
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
  final FavoritesService _favoritesService = FavoritesService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  String selectedFilter = 'All';
  List<Restaurant> restaurants = [];
  bool isLoadingRestaurants = true;
  double? _userLatitude;
  double? _userLongitude;
  bool _locationLoading = true;
  String? _locationError;
  Set<String> _favoriteRestaurantIds = <String>{};
  Set<String>? _categoryRestaurantIds;
  bool _categoryLoading = false;
  String? _selectedMindCategory;
  final Map<String, String> _distanceCache = {};
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    final results = await Future.wait([
      _fetchLocation(),
      _fetchRestaurants(),
      _fetchFavoriteRestaurants(),
    ]);
    if (!mounted) return;
    final loc = results[0] as Map<String, dynamic>;
    final rest = results[1] as List<Restaurant>;
    final favs = results[2] as Set<String>;
    setState(() {
      _userLatitude = loc['lat'] as double?;
      _userLongitude = loc['lng'] as double?;
      _locationLoading = false;
      _locationError = loc['error'] as String?;
      restaurants = rest;
      isLoadingRestaurants = false;
      _favoriteRestaurantIds = favs;
    });
  }

  Future<Map<String, dynamic>> _fetchLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      return {
        'lat': location['latitude'] as double?,
        'lng': location['longitude'] as double?,
        'error': null,
      };
    } catch (_) {
      return {'lat': null, 'lng': null, 'error': 'Location unavailable'};
    }
  }

  Future<List<Restaurant>> _fetchRestaurants() async {
    try {
      final snapshot = await _firestore.collection('restaurants').get();
      return snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading restaurants: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  Future<Set<String>> _fetchFavoriteRestaurants() async {
    try {
      final favorites = await _favoritesService.getFavoriteRestaurants();
      return favorites
          .map((f) => (f['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _toggleRestaurantFavorite(Restaurant restaurant) async {
    final user = _authService.getCurrentUser();
    if (user == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save favorites.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final isFavorite = _favoriteRestaurantIds.contains(restaurant.id);
    try {
      if (isFavorite) {
        await _favoritesService.removeRestaurantFavorite(restaurant.id);
        if (!mounted) {
          return;
        }
        setState(() {
          _favoriteRestaurantIds.remove(restaurant.id);
        });
      } else {
        await _favoritesService.addRestaurantFavorite(
          restaurant.id,
          restaurant.name,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _favoriteRestaurantIds.add(restaurant.id);
        });
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isFavorite ? 'Removed from favorites.' : 'Added to favorites.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to update favorite: $e')),
      );
    }
  }

  String _getDistanceLabel(Restaurant restaurant) {
    if (_locationLoading) return 'Detecting location...';
    final cached = _distanceCache[restaurant.id];
    if (cached != null) return cached;
    String result;
    if (_locationError != null ||
        _userLatitude == null ||
        _userLongitude == null ||
        restaurant.latitude == null ||
        restaurant.longitude == null) {
      result = 'Location unavailable';
    } else {
      final distanceKm = _locationService.calculateDistance(
        _userLatitude!,
        _userLongitude!,
        restaurant.latitude!,
        restaurant.longitude!,
      );
      result = _locationService.formatDistance(distanceKm);
    }
    _distanceCache[restaurant.id] = result;
    return result;
  }

  final List<Map<String, String>> categories = [
    {
      'name': 'Pizza',
      'cuisine': 'Italian',
      'keyword': 'pizza',
      'image': 'https://via.placeholder.com/80x80?text=Pizza',
    },
    {
      'name': 'Burger',
      'cuisine': 'American',
      'keyword': 'burger',
      'image': 'https://via.placeholder.com/80x80?text=Burger',
    },
    {
      'name': 'Dosa',
      'cuisine': 'Indian',
      'keyword': 'dosa',
      'image': 'https://via.placeholder.com/80x80?text=Dosa',
    },
    {
      'name': 'Biryani',
      'cuisine': 'Indian',
      'keyword': 'biryani',
      'image': 'https://via.placeholder.com/80x80?text=Biryani',
    },
    {
      'name': 'Shawarma',
      'cuisine': 'All',
      'keyword': 'shawarma',
      'image': 'https://via.placeholder.com/80x80?text=Shawarma',
    },
    {
      'name': 'Idli',
      'cuisine': 'Indian',
      'keyword': 'idli',
      'image': 'https://via.placeholder.com/80x80?text=Idli',
    },
    {
      'name': 'Cake',
      'cuisine': 'All',
      'keyword': 'cake',
      'image': 'https://via.placeholder.com/80x80?text=Cake',
    },
    {
      'name': 'Parotta',
      'cuisine': 'Indian',
      'keyword': 'parotta',
      'image': 'https://via.placeholder.com/80x80?text=Parotta',
    },
  ];

  void _applyMindCategory(Map<String, String> category) async {
    final keyword = category['keyword'] ?? '';
    if (keyword.isEmpty) return;

    // Deselect if already active
    if (_selectedMindCategory == category['name']) {
      setState(() {
        _selectedMindCategory = null;
        _categoryRestaurantIds = null;
      });
      return;
    }

    setState(() {
      _categoryLoading = true;
      _categoryRestaurantIds = null;
      _selectedMindCategory = category['name'];
      selectedFilter = 'All';
      searchController.clear();
    });
    try {
      final snapshot = await _firestore.collection('foodItems').get();
      final ids = snapshot.docs
          .where((doc) {
            final name = (doc.data()['name'] ?? '').toString().toLowerCase();
            return name.contains(keyword.toLowerCase());
          })
          .map((doc) => (doc.data()['restaurantId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
      if (!mounted) return;
      setState(() {
        _categoryRestaurantIds = ids;
        _categoryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoryLoading = false;
      });
    }
  }

  List<Restaurant> getFilteredRestaurants() {
    List<Restaurant> filtered = restaurants;

    if (_categoryRestaurantIds != null) {
      filtered = filtered
          .where((r) => _categoryRestaurantIds!.contains(r.id))
          .toList();
    }

    if (searchController.text.isNotEmpty) {
      filtered = filtered
          .where(
            (r) => r.name.toLowerCase().contains(
              searchController.text.toLowerCase(),
            ),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with App Name and Profile Button
            Container(
              color: Colors.white,
              //padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.only(
                left: 16.0, // horizontal start
                top: 40.0, // vertical start
                right: 20.0, // custom right padding
                bottom: 8.0, // custom bottom padding
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SaveBite',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/reservations');
                        },
                        icon: const Icon(
                          Icons.receipt_long,
                          color: Color(0xFF2E7D32),
                          size: 26,
                        ),
                        tooltip: 'My Reservations',
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final user = _authService.getCurrentUser();
                          if (user != null) {
                            Navigator.of(context).pushNamed('/profile');
                          } else {
                            Navigator.of(context).pushNamed('/login');
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2E7D32),
                              width: 2,
                            ),
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Color(0xFF2E7D32),
                            radius: 24,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                onTap: () {
                  if (!searchFocusNode.hasFocus) {
                    searchFocusNode.requestFocus();
                  }
                },
                onChanged: (value) {
                  _searchDebounce?.cancel();
                  if (value.isEmpty) {
                    setState(() {
                      _categoryRestaurantIds = null;
                      _selectedMindCategory = null;
                    });
                  } else {
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 250),
                      () => setState(() {
                        _categoryRestaurantIds = null;
                        _selectedMindCategory = null;
                      }),
                    );
                  }
                },
                decoration: InputDecoration(
                  hintText: "Search for 'Restaurant'",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            /* 
            // Scan a Heart Promotional Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '.Scan a Heart',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Spot a heart, scan it &\nwin exciting rewards!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PLAY & WIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.pink.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.favorite,
                          size: 50,
                          color: Colors.pink.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Free Cash Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use your ₹40 free cash',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'auto applied at checkout',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 3),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹40',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
*/
            // What's on your mind section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "What's on your mind?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Food Categories
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedMindCategory == category['name'];
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () => _applyMindCategory(category),
                        child: Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFF2E7D32),
                                    width: 3,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(
                                        0xFF2E7D32,
                                      ).withValues(alpha: 0.35)
                                    : Colors.grey.withValues(alpha: 0.2),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              isSelected ? 9 : 12,
                            ),
                            child: Stack(
                              children: [
                                Image.network(
                                  category['image']!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.restaurant_menu,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                ),
                                if (isSelected)
                                  Container(
                                    width: 80,
                                    height: 80,
                                    color: const Color(
                                      0xFF2E7D32,
                                    ).withValues(alpha: 0.25),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF2E7D32)
                              : Colors.black,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            /* // Filter, Sort, Store, Offers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildActionButton(Icons.tune, 'Filter')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(Icons.arrow_downward, 'Sort by'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(Icons.storefront, '99 Store'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(Icons.local_offer, 'Offers'),
                  ),
                ],
              ),
            ),*/
            const SizedBox(height: 24),

            // Restaurants to explore section with filter chips and list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    /*_buildFilterChip('American'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Italian'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Indian'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Japanese'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Mexican'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Chinese'),*/
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Restaurants List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: (isLoadingRestaurants || _categoryLoading)
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final filteredRestaurants = getFilteredRestaurants();
                        if (filteredRestaurants.isEmpty) {
                          return Column(
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                restaurants.isEmpty
                                    ? 'No restaurants available'
                                    : 'No restaurants found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredRestaurants.length,
                          itemBuilder: (context, index) {
                            return _buildRestaurantCard(
                              filteredRestaurants[index],
                            );
                          },
                        );
                      },
                    ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (value) {
        setState(() {
          selectedFilter = label;
          _categoryRestaurantIds = null;
          _selectedMindCategory = null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF2E7D32),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    final isFavorite = _favoriteRestaurantIds.contains(restaurant.id);
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
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    restaurant.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 64),
                      );
                    },
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: restaurant.isOpen ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      restaurant.isOpen ? 'Open' : 'Closed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Rating Badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant.rating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Restaurant Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (restaurant.rating > 0)
                            Row(
                              children: List.generate(5, (i) {
                                final full = i < restaurant.rating.floor();
                                final half =
                                    !full &&
                                    i < restaurant.rating &&
                                    (restaurant.rating - i) >= 0.5;
                                return Icon(
                                  full
                                      ? Icons.star
                                      : half
                                      ? Icons.star_half
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 14,
                                );
                              }),
                            ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _toggleRestaurantFavorite(restaurant),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey[400],
                        ),
                        tooltip: isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getDistanceLabel(restaurant),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox.shrink(),
                      ElevatedButton(
                        onPressed: restaurant.isOpen
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RestaurantDetailsScreen(
                                      restaurantId: restaurant.id,
                                      restaurantName: restaurant.name,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }
}
