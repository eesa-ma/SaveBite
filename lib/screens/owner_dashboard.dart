import 'package:flutter/material.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _DashboardStat(
        title: 'Today Orders',
        value: '32',
        icon: Icons.receipt_long,
        color: const Color(0xFF2E7D32),
      ),
      _DashboardStat(
        title: 'Revenue',
        value: '\$1,248',
        icon: Icons.payments_outlined,
        color: const Color(0xFF00796B),
      ),
      _DashboardStat(
        title: 'Active Deals',
        value: '7',
        icon: Icons.local_offer_outlined,
        color: const Color(0xFF6A1B9A),
      ),
      _DashboardStat(
        title: 'Rating',
        value: '4.6',
        icon: Icons.star_outline,
        color: const Color(0xFFF57C00),
      ),
    ];

    final orders = [
      _OrderItem(
        id: 'SB-1021',
        name: 'Sunset Diner',
        itemCount: 4,
        total: 28.50,
        status: 'Preparing',
      ),
      _OrderItem(
        id: 'SB-1017',
        name: 'Campus Cafe',
        itemCount: 2,
        total: 14.00,
        status: 'Ready',
      ),
      _OrderItem(
        id: 'SB-1012',
        name: 'City Bites',
        itemCount: 5,
        total: 36.25,
        status: 'Picked Up',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DashboardHeader(
            name: 'Green Bowl Kitchen',
            address: 'Sector 21, Chandigarh',
            isOpen: true,
          ),
          const SizedBox(height: 16),
          _QuickActions(
            onCreateDeal: () {},
            onAddItem: () {},
            onViewMenu: () {},
            onViewReports: () {},
          ),
          const SizedBox(height: 20),
          const Text(
            'Today at a glance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1B1B),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (context, index) {
              return _StatCard(stat: stats[index]);
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Live orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1B1B),
            ),
          ),
          const SizedBox(height: 12),
          ...orders.map((order) => _OrderCard(order: order)).toList(),
          const SizedBox(height: 20),
          const Text(
            'Your Food Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1B1B),
            ),
          ),
          const SizedBox(height: 12),
          _FoodItemsList(onAddFood: () {}),
          const SizedBox(height: 20),
          const Text(
            'Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1B1B),
            ),
          ),
          const SizedBox(height: 12),
          const _PerformanceCard(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF2E7D32),
        label: const Text('Add Food'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.name,
    required this.address,
    required this.isOpen,
  });

  final String name;
  final String address;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final statusColor = isOpen ? const Color(0xFF2E7D32) : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront,
              color: Color(0xFF2E7D32),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(address, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOpen ? 'Open' : 'Closed',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCreateDeal,
    required this.onAddItem,
    required this.onViewMenu,
    required this.onViewReports,
  });

  final VoidCallback onCreateDeal;
  final VoidCallback onAddItem;
  final VoidCallback onViewMenu;
  final VoidCallback onViewReports;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Create Deal',
            icon: Icons.add_circle_outline,
            color: const Color(0xFF2E7D32),
            onTap: onCreateDeal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            title: 'Add Item',
            icon: Icons.playlist_add,
            color: const Color(0xFF1E88E5),
            onTap: onAddItem,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            title: 'Menu',
            icon: Icons.menu_book,
            color: const Color(0xFFF57C00),
            onTap: onViewMenu,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            title: 'Reports',
            icon: Icons.assessment_outlined,
            color: const Color(0xFF6A1B9A),
            onTap: onViewReports,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _DashboardStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: stat.color.withOpacity(0.12),
            child: Icon(stat.icon, size: 18, color: stat.color),
          ),
          const Spacer(),
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1B1B),
            ),
          ),
          const SizedBox(height: 4),
          Text(stat.title, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final _OrderItem order;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (order.status) {
      case 'Ready':
        statusColor = const Color(0xFF2E7D32);
        break;
      case 'Preparing':
        statusColor = const Color(0xFFF57C00);
        break;
      default:
        statusColor = const Color(0xFF455A64);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_dining, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.itemCount} items • \$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(order.id, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Weekly summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          _PerformanceRow(label: 'Completion rate', value: '92%'),
          SizedBox(height: 8),
          _PerformanceRow(label: 'Avg. prep time', value: '18 min'),
          SizedBox(height: 8),
          _PerformanceRow(label: 'Cancellation rate', value: '3%'),
          SizedBox(height: 8),
          _PerformanceRow(label: 'New customers', value: '+24'),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DashboardStat {
  const _DashboardStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _OrderItem {
  const _OrderItem({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.total,
    required this.status,
  });

  final String id;
  final String name;
  final int itemCount;
  final double total;
  final String status;
}

class _FoodItemsList extends StatefulWidget {
  const _FoodItemsList({required this.onAddFood});

  final VoidCallback onAddFood;

  @override
  State<_FoodItemsList> createState() => _FoodItemsListState();
}

class _FoodItemsListState extends State<_FoodItemsList> {
  final List<_FoodItem> foodItems = [
    _FoodItem(
      id: '1',
      name: 'Grilled Veggie Burger',
      price: 8.99,
      isAvailable: true,
      category: 'Main Course',
      image: Icons.fastfood,
    ),
    _FoodItem(
      id: '2',
      name: 'Caesar Salad',
      price: 6.50,
      isAvailable: true,
      category: 'Salad',
      image: Icons.restaurant,
    ),
    _FoodItem(
      id: '3',
      name: 'Chocolate Brownie',
      price: 4.99,
      isAvailable: false,
      category: 'Dessert',
      image: Icons.cake,
    ),
    _FoodItem(
      id: '4',
      name: 'Fresh Juice Combo',
      price: 5.99,
      isAvailable: true,
      category: 'Beverage',
      image: Icons.local_drink,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: foodItems.length,
      itemBuilder: (context, index) {
        final food = foodItems[index];
        return _FoodItemCard(
          food: food,
          onEdit: () => _showEditFoodDialog(context, food),
          onDelete: () => _removeFoodItem(index),
        );
      },
    );
  }

  void _removeFoodItem(int index) {
    setState(() {
      foodItems.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Food item removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEditFoodDialog(BuildContext context, _FoodItem food) {
    final nameController = TextEditingController(text: food.name);
    final priceController = TextEditingController(text: food.price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Food Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Available'),
              value: food.isAvailable,
              onChanged: (value) {
                setState(() {
                  food.isAvailable = value ?? false;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                food.name = nameController.text;
                food.price =
                    double.tryParse(priceController.text) ?? food.price;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Food item updated'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  const _FoodItemCard({
    required this.food,
    required this.onEdit,
    required this.onDelete,
  });

  final _FoodItem food;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(food.image, color: const Color(0xFF2E7D32), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  food.category,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: food.isAvailable
                        ? const Color(0xFF2E7D32).withOpacity(0.12)
                        : Colors.grey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    food.isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: food.isAvailable
                          ? const Color(0xFF2E7D32)
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${food.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  InkWell(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Color(0xFF2E7D32),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodItem {
  _FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.category,
    required this.image,
  });

  final String id;
  String name;
  double price;
  bool isAvailable;
  final String category;
  final IconData image;
}
