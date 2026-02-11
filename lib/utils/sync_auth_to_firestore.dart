import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:save_bite/services/auth_serivce.dart';

/// Utility to sync existing Firebase Authentication users to Firestore
/// This is useful for fixing accounts that were created in Auth but not saved to Firestore
class SyncAuthToFirestore {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Sync current authenticated user to Firestore
  /// This will create a Firestore document for the user if it doesn't exist
  /// Note: Since we don't have the original name and role, we'll use defaults
  Future<void> syncCurrentUserToFirestore({
    String? name,
    String? role,
  }) async {
    final user = _auth.currentUser;
    
    if (user == null) {
      throw Exception('No user is currently logged in');
    }

    // Check if user already exists in Firestore using AuthService
    final exists = await _authService.userExistsInFirestore(user.uid);
    
    if (exists) {
      debugPrint('User ${user.email} already exists in Firestore');
      return;
    }

    // Create user document in Firestore
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name ?? user.displayName ?? 'Unknown User',
        'email': user.email ?? '',
        'role': role ?? 'User', // Default to 'User' if not specified
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'syncedFromAuth': true, // Flag to indicate this was synced
      });
      
      debugPrint('Successfully synced user ${user.email} to Firestore');
    } catch (e) {
      debugPrint('Failed to sync user to Firestore: $e');
      rethrow;
    }
  }

  /// Prompt user to provide their details for syncing
  /// This can be called from a screen if the user is logged in but not in Firestore
  Future<void> promptUserDetailsAndSync({
    required String name,
    required String role,
  }) async {
    await syncCurrentUserToFirestore(name: name, role: role);
  }
}
