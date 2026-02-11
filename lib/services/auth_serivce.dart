import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  Future<User?> signUp(String email, String password, String name, String role) async {
    UserCredential? credential;
    
    try {
      // Create user in Firebase Authentication
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save user profile to Firestore
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'name': name,
          'email': email,
          'role': role,
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
          print('Failed to delete user after Firestore error: $deleteError');
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
    return credential.user;
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
