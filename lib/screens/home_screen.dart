import 'package:flutter/material.dart';

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
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Restaurant> restaurants = [
    Restaurant(
      id: '1',
      name: 'The Gourmet Burger',
      cuisine: 'American',
      rating: 4.8,
      reviews: 342,
      distance: '0.5 km',
      imageUrl: 'https://via.placeholder.com/300x200?text=Burger+Restaurant',
      isOpen: true,
      deliveryTime: '20-30 min',
    ),
    Restaurant(
      id: '2',
      name: 'Pizza Palace',
      cuisine: 'Italian',
      rating: 4.6,
      reviews: 521,
      distance: '1.2 km',
      imageUrl: 'https://via.placeholder.com/300x200?text=Pizza+Restaurant',
      isOpen: true,
      deliveryTime: '25-35 min',
    ),
    Restaurant(
      id: '3',
      name: 'Spice Garden',
      cuisine: 'Indian',
      rating: 4.7,
      reviews: 289,
      distance: '2.1 km',
      imageUrl: 'https://via.placeholder.com/300x200?text=Indian+Restaurant',
      isOpen: true,
      deliveryTime: '30-40 min',
    ),
    Restaurant(
      id: '4',
      name: 'Sushi Paradise',
      cuisine: 'Japanese',
      rating: 4.9,
      reviews: 456,
      distance: '1.8 km',
      imageUrl: 'https://via.placeholder.com/300x200?text=Sushi+Restaurant',
      isOpen: true,
      deliveryTime: '35-45 min',
    ),
    Restaurant(
      id: '5',
      name: 'Taco Fiesta',
      cuisine: 'Mexican',
      rating: 4.5,
      reviews: 198,
      distance: '0.8 km',
      imageUrl: 'https://via.placeholder.com/300x200?text=Taco+Restaurant',
      isOpen: true,
      deliveryTime: '15-25 min',
    ),
    Restaurant(
      id: '6',
      name: 'Wok Express',
      cuisine: 'Chinese',
      rating: 4.4,
      reviews: 267,
      distance: '1.5 km',
      imageUrl: 'https://via.placeholder.com/300x200?text=Chinese+Restaurant',
      isOpen: false,
      deliveryTime: '40-50 min',
    ),
  ];

  String selectedFilter = 'All';
  final TextEditingController searchController = TextEditingController();

  List<Restaurant> getFilteredRestaurants() {
    List<Restaurant> filtered = restaurants;

    if (selectedFilter != 'All') {
      filtered = filtered
          .where((r) => r.cuisine == selectedFilter)
          .toList();
    }

    if (searchController.text.isNotEmpty) {
      filtered = filtered
          .where((r) =>
              r.name.toLowerCase().contains(searchController.text.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredRestaurants = getFilteredRestaurants();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          'SaveBite',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: const Color(0xFF2E7D32)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search restaurants...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('American'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Italian'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Indian'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Japanese'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Mexican'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Chinese'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Restaurants List
            if (filteredRestaurants.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No restaurants found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredRestaurants.length,
                  itemBuilder: (context, index) {
                    return _buildRestaurantCard(filteredRestaurants[index]);
                  },
                ),
              ),

            const SizedBox(height: 16),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening ${restaurant.name}...')),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          Text(
                            restaurant.cuisine,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.favorite_border,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${restaurant.reviews} reviews',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.distance,
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
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.deliveryTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: restaurant.isOpen ? () {} : null,
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
    searchController.dispose();
    super.dispose();
  }
}
