import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/wake_word_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  String? _loginErrorMessage;

  final RegExp emailReg =
      RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");

  Future<void> _loginUser() async {
    setState(() {
      _loginErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final box = await Hive.openBox<UserModel>('users');

    if (box.isEmpty) {
      setState(() {
        _loginErrorMessage = 'No account found. Please sign up first.';
      });
      return;
    }

    final user = box.getAt(0);

    if (user!.email == _emailController.text.trim() &&
        user.password == _passwordController.text.trim()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', true);

      bool isGranted = await Permission.microphone.request().isGranted;
      if (isGranted) {
        WakeWordService().startListening();
      } else {
        debugPrint("Mic permission denied after login");
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        _loginErrorMessage = 'Invalid email or password. Please try again.';
      });
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
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 100),
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          hintText: "example@gmail.com",
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Email is required";
                          } else if (!emailReg.hasMatch(val.trim())) {
                            return "Invalid email format";
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (_loginErrorMessage != null) {
                            setState(() {
                              _loginErrorMessage = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: "Password",
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
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (_loginErrorMessage != null) {
                            setState(() {
                              _loginErrorMessage = null;
                            });
                          }
                        },
                      ),
                      if (_loginErrorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _loginErrorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _loginUser,
                  child: const Text("Login"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text("New user? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}