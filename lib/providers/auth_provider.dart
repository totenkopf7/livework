import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'normal',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
    };
  }

  bool get isAdmin => role == 'admin';
}

// Renamed to avoid conflict with Firebase's AuthProvider
class LiveWorkAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _user;
  bool _isLoading = true;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  LiveWorkAuthProvider() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await _fetchUserData(firebaseUser.uid);
      }
    } catch (e) {
      _error = 'Error checking authentication status: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        _user = AppUser.fromFirestore(userDoc.data() as Map<String, dynamic>, uid);
      } else {
          final currentUser = _auth.currentUser;
          _user = AppUser(
          uid: uid,
          email: _auth.currentUser?.email ?? '',
          name: _auth.currentUser?.displayName ?? 'User',
          role: 'normal',
        );
        await _firestore.collection('users').doc(uid).set(_user!.toMap());
      }
    } catch (e) {
      _error = 'Error fetching user data: $e';
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _fetchUserData(result.user!.uid);
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _user = null;
      _error = null;
    } catch (e) {
      _error = 'Error signing out: $e';
    } finally {
      notifyListeners();
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}