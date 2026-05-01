import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  String? _signupErrorMessage;

  final RegExp emailReg =
      RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");

  Future<void> _registerUser() async {
    setState(() {
      _signupErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final box = await Hive.openBox<UserModel>('users');

    if (box.isNotEmpty) {
      setState(() {
        _signupErrorMessage = 'User already registered! Please login instead.';
      });
      return;
    }

    // Using a default name since field is removed
    final user = UserModel(
      name: _emailController.text.trim().split('@')[0], // Creates name from email
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    await box.add(user);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('registered', true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please login.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Text(
                "AuralSight",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const Text(
                "Let your ears guide your eyes",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email Address",
                        hintText: "example@gmail.com",
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Email is required";
                        } else if (!emailReg.hasMatch(val.trim())) {
                          return "Enter a valid email format";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (_signupErrorMessage != null) {
                          setState(() => _signupErrorMessage = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        hintText: "Minimum 6 characters",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "Password is required";
                        } else if (val.length < 6) {
                          return "Minimum 6 characters required";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (_signupErrorMessage != null) {
                          setState(() => _signupErrorMessage = null);
                        }
                      },
                    ),
                    if (_signupErrorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _signupErrorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _registerUser,
                child: const Text("Sign Up"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}