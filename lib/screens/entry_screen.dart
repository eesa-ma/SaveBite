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

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  String selectedFilter = 'All';

  // User profile data
  String userName = 'John Doe';
  String userPhone = '+91 9876543210';
  String userEmail = 'johndoe@example.com';

  final List<Map<String, String>> categories = [
    {'name': 'Pizzas', 'image': 'https://via.placeholder.com/80x80?text=Pizzas'},
    {'name': 'Dosa', 'image': 'https://via.placeholder.com/80x80?text=Dosa'},
    {'name': 'Shawarma', 'image': 'https://via.placeholder.com/80x80?text=Shawarma'},
    {'name': 'Cakes', 'image': 'https://via.placeholder.com/80x80?text=Cakes'},
    {'name': 'Idli', 'image': 'https://via.placeholder.com/80x80?text=Idli'},
  ];

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with App Name and Profile Button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  GestureDetector(
                    onTap: _showRoleSelection,
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
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.mic, color: Colors.red.shade600, size: 20),
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
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

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
                  return Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            categories[index]['image']!,
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        categories[index]['name']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Filter, Sort, Store, Offers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(Icons.tune, 'Filter'),
                  ),
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
            ),

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (context) {
                  final filteredRestaurants = getFilteredRestaurants();
                  if (filteredRestaurants.isEmpty) {
                    return Column(
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
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredRestaurants.length,
                    itemBuilder: (context, index) {
                      return _buildRestaurantCard(filteredRestaurants[index]);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label tapped')),
        );
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

  void _showRoleSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              _buildRoleCard(
                role: 'customer',
                title: 'Customer',
                description: 'Order discounted food',
                icon: Icons.shopping_cart,
              ),
              const SizedBox(height: 12),
              _buildRoleCard(
                role: 'restaurant',
                title: 'Restaurant Owner',
                description: 'Manage listings and offers',
                icon: Icons.restaurant,
              ),
              const SizedBox(height: 12),
              _buildRoleCard(
                role: 'admin',
                title: 'Admin',
                description: 'Manage platform',
                icon: Icons.admin_panel_settings,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.of(context).pushNamed(
          '/login',
          arguments: {'role': role},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2E7D32), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF2E7D32), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
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
