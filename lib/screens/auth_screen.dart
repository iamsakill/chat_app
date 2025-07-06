import 'package:chat_app/services.dart/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!_isLogin)
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: 'Name'),
                        validator: (value) =>
                            value!.isEmpty ? 'Name cannot be empty' : null,
                      ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value!.isEmpty ? 'Email cannot be empty' : null,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) => value!.length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isLogin ? 'Login' : 'Sign Up'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? 'Create new account'
                            : 'I already have an account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (_isLogin) {
        await auth.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await auth.signUp(
          _emailController.text,
          _passwordController.text,
          _nameController.text,
        );

        // Add small delay to ensure Firebase updates propagate
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      String message = e.toString();

      // Suggest alternative if email exists
      if (message.contains('already in use')) {
        final parts = _emailController.text.split('@');
        if (parts.length == 2) {
          final suggestion = '${parts[0]}a@${parts[1]}';
          message += '\n\nTry using: $suggestion';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
