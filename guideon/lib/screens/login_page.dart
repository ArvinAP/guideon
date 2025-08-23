import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guideon/components/buttons.dart';
import 'package:guideon/screens/signup_page.dart';
import 'package:guideon/screens/greeting_page.dart';
import 'package:guideon/screens/admin_dashboard.dart';
import 'package:guideon/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _keepSignedIn = false;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontFamily: 'Comfortaa',
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide:
                BorderSide(color: Color.fromARGB(255, 21, 77, 113), width: 2),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter both email and password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await AuthService.signInWithEmail(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;
      setState(() => _isLoading = false);

      final role = result.profile?['role'] ?? 'user';
      if (role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const GreetingPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        default:
          message = e.message ?? 'Login failed';
      }
      _showSnack(message);
    } on TimeoutException {
      _showSnack('Login timeout. Please try again.');
    } on Exception catch (e) {
      _showSnack('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 239, 239),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // Welcome text
              Column(
                children: const [
                  Text(
                    'welcome to',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 51, 161, 224),
                      fontFamily: 'Coiny',
                    ),
                  ),
                  Text(
                    'GuideOn',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 21, 77, 113),
                      fontFamily: 'Coiny',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'where stronger spirits start',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Email field (styled like signup page)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 21, 77, 113),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: emailController,
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
              ),

              // Password field with visibility toggle
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 21, 77, 113),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: passwordController,
                hintText: 'Enter your password',
                obscureText: !_isPasswordVisible,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  },
                ),
              ),

              // Keep me signed in + Forgot password
              Row(
                children: [
                  Checkbox(
                    value: _keepSignedIn,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _keepSignedIn = value);
                    },
                    activeColor: const Color.fromARGB(255, 21, 77, 113),
                  ),
                  const Text(
                    'Keep me signed in',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot password',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 51, 161, 224),
                        fontFamily: 'Coiny',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Login button
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 21, 77, 113)),
                    )
                  : PrimaryButton(
                      text: "Login",
                      onPressed: _handleLogin,
                    ),

              const SizedBox(height: 20),

              // Social connect
              const Text(
                'You can connect with',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontFamily: 'Comfortaa',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png',
                    height: 30,
                    errorBuilder: (context, error, stack) => const Icon(
                      Icons.g_translate,
                      color: Color.fromARGB(255, 66, 133, 244),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Replaced SVG (not supported by Image) with Material icon to prevent invalid image errors
                  const Icon(
                    Icons.facebook,
                    color: Color(0xFF1877F2),
                    size: 30,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don’t have an account? ",
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign Up here",
                      style: TextStyle(
                        color: Color.fromARGB(255, 21, 77, 113),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Comfortaa',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
