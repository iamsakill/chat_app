import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_page.dart'; // Assuming this exists

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;
  String error = '';

  // Removed _defaultAvatarNetworkUrl as we're using Icons now.
  // The 'profile_pic' field in Firestore will be an empty string for default.

  // URL for a common Google "G" logo (still using network for this specific brand logo)
  static const String _googleLogoNetworkUrl =
      'https://developers.google.com/static/images/oauth-native-app-128.png';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> createUserDocument(User user) async {
    final email = user.email!;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': email,
      // Used for search functionality, splitting email for better matching
      'email_search': email.toLowerCase().split(RegExp(r'[\.@]')).where((s) => s.isNotEmpty).toList(),
      'name': user.displayName ?? email.split('@').first, // Use Google name if available, else derive from email
      'username': email.split('@').first, // Default username from email
      // Set profile_pic to an empty string if Google photoURL is null
      'profile_pic': user.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // Use merge to avoid overwriting existing fields if called again
  }

  Future<void> signInWithEmail() async {
    setState(() => error = ''); // Clear previous errors
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      goToHome();
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'An unknown error occurred');
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> signUpWithEmail() async {
    setState(() => error = ''); // Clear previous errors
    try {
      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await createUserDocument(userCredential.user!);
      goToHome();
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'An unknown error occurred');
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() => error = ''); // Clear previous errors
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User cancelled the sign-in

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Create/update user document for both new and existing Google users
      await createUserDocument(userCredential.user!);

      goToHome();
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'An unknown error occurred');
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  void goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Color(0xFF2575FC), // Kept original blue for icon
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chat Me',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect with your friends',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          isLogin ? 'Welcome back!' : 'Create account',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        if (error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              error,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                            isLogin ? signInWithEmail : signUpWithEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor, // Use app primary color
                              foregroundColor: Colors.white, // Text color on button
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              isLogin ? 'Login' : 'Sign Up',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              setState(() => isLogin = !isLogin),
                          child: Text(
                            isLogin
                                ? 'Don\'t have an account? Sign up'
                                : 'Already have an account? Login',
                            style: TextStyle(color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Or continue with',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: signInWithGoogle,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- Using Image.network for the Google logo as it's a specific brand asset ---
                        Image.network(
                          _googleLogoNetworkUrl,
                          height: 24,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error_outline, size: 24, color: Colors.red);
                          },
                        ),
                        // --- End of change ---
                        const SizedBox(width: 10),
                        const Text(
                          'Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}