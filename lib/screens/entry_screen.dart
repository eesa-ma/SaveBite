import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:save_bite/services/auth_serivce.dart';
import 'package:save_bite/screens/restaurant_details_screen.dart';
import '../services/location_service.dart';

class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final double rating;
  final int reviews;
  final String imageUrl;
  final bool isOpen;
  final String deliveryTime;
  final double? latitude;
  final double? longitude;

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.isOpen,
    required this.deliveryTime,
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
      cuisine: data['cuisine'] ?? 'General',
      rating: (data['rating'] ?? 0).toDouble(),
      reviews: data['reviews'] ?? 0,
      imageUrl:
          data['imageUrl'] ??
          'https://via.placeholder.com/300x200?text=Restaurant',
      isOpen: data['isOpen'] ?? true,
      deliveryTime: data['deliveryTime'] ?? 'N/A',
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

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadRestaurants();
  }

  Future<void> _loadUserLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) {
        return;
      }
      setState(() {
        _userLatitude = location['latitude'] as double?;
        _userLongitude = location['longitude'] as double?;
        _locationLoading = false;
        _locationError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _locationLoading = false;
        _locationError = 'Location unavailable';
      });
    }
  }

  String _getDistanceLabel(Restaurant restaurant) {
    if (_locationLoading) {
      return 'Detecting location...';
    }
    if (_locationError != null ||
        _userLatitude == null ||
        _userLongitude == null ||
        restaurant.latitude == null ||
        restaurant.longitude == null) {
      return 'Location unavailable';
    }

    final distanceKm = _locationService.calculateDistance(
      _userLatitude!,
      _userLongitude!,
      restaurant.latitude!,
      restaurant.longitude!,
    );
    return _locationService.formatDistance(distanceKm);
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

  final List<Map<String, String>> categories = [
    {
      'name': 'Pizzas',
      'image': 'https://via.placeholder.com/80x80?text=Pizzas',
    },
    {'name': 'Dosa', 'image': 'https://via.placeholder.com/80x80?text=Dosa'},
    {
      'name': 'Shawarma',
      'image': 'https://via.placeholder.com/80x80?text=Shawarma',
    },
    {'name': 'Cakes', 'image': 'https://via.placeholder.com/80x80?text=Cakes'},
    {'name': 'Idli', 'image': 'https://via.placeholder.com/80x80?text=Idli'},
  ];

  List<Restaurant> getFilteredRestaurants() {
    List<Restaurant> filtered = restaurants;

    if (selectedFilter != 'All') {
      filtered = filtered.where((r) => r.cuisine == selectedFilter).toList();
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
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: "Search for 'Cake'",
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

            // Restaurants List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isLoadingRestaurants
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

  Widget _buildActionButton(IconData icon, String label) {
    return OutlinedButton(
      onPressed: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label tapped')));
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
                        ],
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }
}
