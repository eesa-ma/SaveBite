import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OrderEmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> queueOrderConfirmation({
    required String orderId,
    required String userId,
    required String foodName,
    required int quantity,
    required num price,
    required String restaurantName,
  }) async {
    final email = await _getUserEmail(userId);
    if (email == null) {
      debugPrint('Order confirmation email skipped: missing email for user $userId');
      return;
    }

    final customerName = await _getUserName(userId);
    final total = price * quantity;

    await _queueEmail(
      to: email,
      subject: 'Order Confirmed • SaveBite',
      text: [
        'Hi $customerName,',
        '',
        'Your order has been placed successfully.',
        'Order ID: $orderId',
        'Restaurant: $restaurantName',
        'Item: $foodName',
        'Quantity: $quantity',
        'Total: ₹$total',
        '',
        'We will notify you again when your order is picked up.',
        '',
        'Thanks,',
        'SaveBite',
      ].join('\n'),
    );
  }

  Future<void> queuePickedUpEmail({
    required String orderId,
    required String userId,
    required String foodName,
    required int quantity,
    required num price,
    required String restaurantName,
  }) async {
    final email = await _getUserEmail(userId);
    if (email == null) {
      debugPrint('Picked up email skipped: missing email for user $userId');
      return;
    }

    final customerName = await _getUserName(userId);
    final total = price * quantity;

    await _queueEmail(
      to: email,
      subject: 'Order Picked Up • SaveBite',
      text: [
        'Hi $customerName,',
        '',
        'Your order has been marked as picked up by the restaurant.',
        'Order ID: $orderId',
        'Restaurant: $restaurantName',
        'Item: $foodName',
        'Quantity: $quantity',
        'Total: ₹$total',
        '',
        'Enjoy your meal!',
        '',
        'Thanks,',
        'SaveBite',
      ].join('\n'),
    );
  }

  Future<void> _queueEmail({
    required String to,
    required String subject,
    required String text,
  }) {
    return _firestore.collection('mail').add({
      'to': [to],
      'message': {
        'subject': subject,
        'text': text,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> _getUserEmail(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final email = userDoc.data()?['email']?.toString().trim();
    if (email == null || email.isEmpty) {
      return null;
    }
    return email;
  }

  Future<String> _getUserName(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final name = userDoc.data()?['name']?.toString().trim();
    if (name == null || name.isEmpty) {
      return 'Customer';
    }
    return name;
  }
}
