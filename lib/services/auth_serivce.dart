import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  Future<User?> signUp(
    String email,
    String password,
    String name,
    String role, {
    String? phone,
  }) async {
    UserCredential? credential;

    try {
      // Create user in Firebase Authentication
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user profile to Firestore
      if (credential.user != null) {
        // Set display name on Fire base User object
        await credential.user!.updateDisplayName(name);

        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'name': name,
          'email': email,
          'phone': phone ?? '',
          'role': role,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return credential.user;
    } catch (e) {
      // If Firestore write failed but auth user was created, delete the auth user
      // to keep Authentication and Firestore in sync
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (deleteError) {
          // Log delete error but throw the original error
          debugPrint(
            'Failed to delete user after Firestore error: $deleteError',
          );
        }
      }
      // Re-throw the original error
      rethrow;
    }
  }

  // Login
  Future<User?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      return null;
    }

    final userData = await getUserData(user.uid);
    final status = (userData?['status'] ?? 'active').toString().toLowerCase();
    if (status == 'suspended') {
      await _auth.signOut();
      throw Exception(
        'Your account has been suspended. Please contact support.',
      );
    }

    return credential.user;
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await resetPassword(email);
  }

  // Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  // Check if user exists in Firestore
  Future<bool> userExistsInFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking user in Firestore: $e');
      return false;
    }
  }

  // Update profile fields in both Auth and Firestore
  Future<void> updateProfile({required String name, String? phone}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final normalizedName = name.trim();
    final normalizedPhone = (phone ?? '').trim();

    await user.updateDisplayName(normalizedName);
    await _firestore.collection('users').doc(user.uid).set({
      'name': normalizedName,
      'phone': normalizedPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> isCurrentUserSuspended() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    final userData = await getUserData(user.uid);
    final status = (userData?['status'] ?? 'active').toString().toLowerCase();
    return status == 'suspended';
  }
}
