import 'package:flutter/material.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: Column(
        children: [
          _RestaurantHeader(
            name: 'Green Bowl Kitchen',
            address: 'Sector 21, Chandigarh',
            isOpen: true,
          ),
          Expanded(
            child: _FoodMenuManager(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF2E7D32),
        label: const Text('Add Item'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// Restaurant Header Widget
class _RestaurantHeader extends StatelessWidget {
  const _RestaurantHeader({
    required this.name,
    required this.address,
    required this.isOpen,
  });

  final String name;
  final String address;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7D32),
            const Color(0xFF388E3C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant,
              color: Color(0xFF2E7D32),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isOpen ? Colors.white : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOpen ? const Color(0xFF2E7D32) : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOpen ? 'Open' : 'Closed',
                  style: TextStyle(
                    color: isOpen ? const Color(0xFF2E7D32) : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Food Menu Manager Widget
class _FoodMenuManager extends StatefulWidget {
  @override
  State<_FoodMenuManager> createState() => _FoodMenuManagerState();
}

class _FoodMenuManagerState extends State<_FoodMenuManager> {
  final List<_MenuItem> menuItems = [
    _MenuItem(
      id: '1',
      name: 'Grilled Veggie Burger',
      price: 8.99,
      isAvailable: true,
      category: 'Main Course',
      emoji: '🍔',
    ),
    _MenuItem(
      id: '2',
      name: 'Caesar Salad Bowl',
      price: 6.50,
      isAvailable: true,
      category: 'Salads',
      emoji: '🥗',
    ),
    _MenuItem(
      id: '3',
      name: 'Margherita Pizza',
      price: 12.99,
      isAvailable: false,
      category: 'Pizza',
      emoji: '🍕',
    ),
    _MenuItem(
      id: '4',
      name: 'Chocolate Brownie',
      price: 4.99,
      isAvailable: true,
      category: 'Desserts',
      emoji: '🍰',
    ),
    _MenuItem(
      id: '5',
      name: 'Fresh Orange Juice',
      price: 3.99,
      isAvailable: true,
      category: 'Beverages',
      emoji: '🧃',
    ),
    _MenuItem(
      id: '6',
      name: 'Pasta Alfredo',
      price: 10.99,
      isAvailable: true,
      category: 'Pasta',
      emoji: '🍝',
    ),
    _MenuItem(
      id: '7',
      name: 'BBQ Chicken Wings',
      price: 9.99,
      isAvailable: false,
      category: 'Appetizers',
      emoji: '🍗',
    ),
    _MenuItem(
      id: '8',
      name: 'Iced Coffee',
      price: 4.50,
      isAvailable: true,
      category: 'Beverages',
      emoji: '☕',
    ),
  ];

  void _toggleAvailability(int index) {
    setState(() {
      menuItems[index].isAvailable = !menuItems[index].isAvailable;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${menuItems[index].name} marked as ${menuItems[index].isAvailable ? "Available" : "Unavailable"}',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: menuItems[index].isAvailable 
          ? const Color(0xFF2E7D32) 
          : Colors.grey[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCount = menuItems.where((item) => item.isAvailable).length;
    
    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Menu Items',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$availableCount available • ${menuItems.length - availableCount} unavailable',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${menuItems.length}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Menu Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              return _MenuItemCard(
                item: menuItems[index],
                onToggle: () => _toggleAvailability(index),
                onEdit: () => _showEditDialog(index),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditDialog(int index) {
    final item = menuItems[index];
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (\$)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                item.name = nameController.text;
                item.price = double.tryParse(priceController.text) ?? item.price;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item updated successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Menu Item Card Widget
class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.onToggle,
    required this.onEdit,
  });

  final _MenuItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isAvailable 
            ? const Color(0xFF2E7D32).withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Food Emoji/Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: item.isAvailable 
                  ? const Color(0xFF2E7D32).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  item.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: item.isAvailable 
                        ? const Color(0xFF1B1B1B)
                        : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: item.isAvailable 
                        ? const Color(0xFF2E7D32)
                        : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            Column(
              children: [
                // Availability Switch
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: item.isAvailable,
                    onChanged: (_) => onToggle(),
                    activeColor: const Color(0xFF2E7D32),
                    activeTrackColor: const Color(0xFF2E7D32).withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: item.isAvailable 
                      ? const Color(0xFF2E7D32)
                      : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // Edit Button
                InkWell(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Menu Item Model
class _MenuItem {
  _MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.category,
    required this.emoji,
  });

  final String id;
  String name;
  double price;
  bool isAvailable;
  final String category;
  final String emoji;
}
