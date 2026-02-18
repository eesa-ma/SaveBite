import 'package:flutter/material.dart';
import 'package:save_bite/models/food_item.dart';

class CheckoutResult {
  CheckoutResult({required this.quantity, this.notes});

  final int quantity;
  final String? notes;
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.item,
    required this.restaurantName,
    required this.initialQuantity,
  });

  final FoodItem item;
  final String restaurantName;
  final int initialQuantity;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color _primaryColor = Color(0xFF2E7D32);

  final TextEditingController _notesController = TextEditingController();

  late int _quantity;

  @override
  void initState() {
    super.initState();
    final maxQty = widget.item.quantityAvailable;
    _quantity = maxQty > 0
        ? widget.initialQuantity.clamp(1, maxQty)
        : widget.initialQuantity;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal => widget.item.price * _quantity;

  double get _total => _subtotal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Restaurant',
            child: Text(
              widget.restaurantName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Your Order',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${widget.item.price.toStringAsFixed(2)} each',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    _buildQuantityStepper(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Instructions (optional)',
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any special requests for the restaurant',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Bill Details',
            child: Column(
              children: [
                _buildBillRow('Subtotal', _subtotal),
                const Divider(height: 24),
                _buildBillRow('Total', _total, isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: widget.item.quantityAvailable <= 0
                ? null
                : () {
                    Navigator.pop(
                      context,
                      CheckoutResult(
                        quantity: _quantity,
                        notes: _notesController.text.trim().isEmpty
                            ? null
                            : _notesController.text.trim(),
                      ),
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Place reservation ₹${_total.toStringAsFixed(2)}'),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildQuantityStepper() {
    final maxQty = widget.item.quantityAvailable;
    return Row(
      children: [
        IconButton(
          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '$_quantity',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: _quantity < maxQty
              ? () => setState(() => _quantity++)
              : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _buildBillRow(String label, double amount, {bool isTotal = false}) {
    final textStyle = TextStyle(
      fontSize: isTotal ? 16 : 14,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
      color: isTotal ? Colors.black : Colors.grey[700],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Text('₹${amount.toStringAsFixed(2)}', style: textStyle),
      ],
    );
  }
}
