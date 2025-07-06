import 'package:chat_app/services.dart/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  User? get user => _auth.currentUser;
  Stream<User?> get userStream => _auth.userChanges();
  bool get isLoading => _isLoading;

  Future<void> _setLanguageCode() async {
    try {
      await _auth.setLanguageCode("en");
    } catch (e) {
      if (kDebugMode) {
        print("Error setting language code: $e");
      }
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _setIsLoading(true);
    await _setLanguageCode();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    } finally {
      _setIsLoading(false);
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    _setIsLoading(true);
    await _setLanguageCode();
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name separately
        await userCredential.user!.updateProfile(displayName: name);

        // Create user in Firestore
        await DatabaseService().createUser(
          UserModel(uid: userCredential.user!.uid, name: name, email: email),
        );

        // Trigger a reload to get updated user data
        await userCredential.user!.reload();

        // Get the updated user object
        final updatedUser = _auth.currentUser;

        // Print for debugging
        print('User created: ${updatedUser!.uid}');
        print('Display name: ${updatedUser.displayName}');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'The email address is already in use by another account.';
      } else {
        throw _authError(e.code);
      }
    } catch (e) {
      print('SignUp error: $e');
      throw 'Failed to create account. Please try again.';
    } finally {
      _setIsLoading(false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateProfileName(String name) async {
    try {
      if (user != null) {
        await user!.updateDisplayName(name);
        await user!.reload();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  void _setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Invalid password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email';
      case 'weak-password':
        return 'Password is too weak';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return 'Authentication failed';
    }
  }
}
