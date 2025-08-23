import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guideon/components/buttons.dart';
import 'package:guideon/screens/login_page.dart';
import 'package:guideon/services/auth_service.dart';
import 'admin_dashboard.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    dateOfBirthController.dispose();
    ageController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  DateTime? _parseDob(String input) {
    // Supports dd/mm/yyyy
    try {
      final parts = input.split('/');
      if (parts.length != 3) return null;
      final dd = int.tryParse(parts[0]);
      final mm = int.tryParse(parts[1]);
      final yyyy = int.tryParse(parts[2]);
      if (dd == null || mm == null || yyyy == null) return null;
      return DateTime(yyyy, mm, dd);
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitSignUp() async {
    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();
    final uname = usernameController.text.trim();
    final email = emailController.text.trim();
    final pass = passwordController.text;
    final confirm = confirmPasswordController.text;
    final dobStr = dateOfBirthController.text.trim();
    final ageStr = ageController.text.trim();

    if ([first, last, uname, email, pass, confirm, dobStr, ageStr]
        .any((e) => e.isEmpty)) {
      _showSnack('Please fill in all fields');
      return;
    }
    if (pass != confirm) {
      _showSnack('Passwords do not match');
      return;
    }
    final age = int.tryParse(ageStr);
    if (age == null || age <= 0) {
      _showSnack('Enter a valid age');
      return;
    }
    final dob = _parseDob(dobStr);
    if (dob == null) {
      _showSnack('Enter a valid date of birth (dd/mm/yyyy)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await AuthService.signUpAndCreateProfile(
        email: email,
        password: pass,
        firstName: first,
        lastName: last,
        username: uname,
        dob: dob,
        age: age,
      ).timeout(const Duration(seconds: 25));

      if (!mounted) return;
      // Stop loading before navigation to avoid stuck UI if routing fails
      setState(() => _isLoading = false);
      if (res.role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          (route) => false,
        );
      } else {
        _showSnack('Account created. Please log in.');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Authentication error');
    } on TimeoutException {
      _showSnack('Network timeout. Please try again.');
    } on Exception catch (e) {
      _showSnack('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dateOfBirthController.text =
          "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onTap: onTap,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontFamily: 'Comfortaa',
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(
                color: Color.fromARGB(255, 21, 77, 113), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 234, 239, 239),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // Header
              Column(
                children: const [
                  Text(
                    'Create an account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 51, 161, 224),
                      fontFamily: 'Coiny',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Let's make each day brighter",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                  Text(
                    'with',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                  Text(
                    'GuideOn',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 21, 77, 113),
                      fontFamily: 'Coiny',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Form Fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: firstNameController,
                      hintText: "First name",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: lastNameController,
                      hintText: "Last name",
                    ),
                  ),
                ],
              ),

              _buildTextField(
                controller: usernameController,
                hintText: "Enter your username",
              ),

              _buildTextField(
                controller: emailController,
                hintText: "Enter your email",
              ),

              _buildTextField(
                controller: passwordController,
                hintText: "Enter your password",
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),

              _buildTextField(
                controller: confirmPasswordController,
                hintText: "Confirm password",
                obscureText: !_isConfirmPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),

              _buildTextField(
                controller: dateOfBirthController,
                hintText: "Date of Birth",
                readOnly: true,
                onTap: _selectDate,
                suffixIcon: Icon(
                  Icons.calendar_today,
                  color: Colors.grey[600],
                ),
              ),

              _buildTextField(
                controller: ageController,
                hintText: "Age",
              ),

              const SizedBox(height: 20),

              // Sign Up Button
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 21, 77, 113)),
                    )
                  : PrimaryButton(
                      text: "Sign Up",
                      onPressed: _submitSignUp,
                    ),

              const SizedBox(height: 30),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'LogIn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 21, 77, 113),
                        fontFamily: 'Comfortaa',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
