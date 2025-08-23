import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'change_password.dart';
import '../services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  Map<String, dynamic>? userProfile;
  User? currentUser;
  bool isLoading = true;
  bool isSaving = false;

  // Store original values for cancel functionality
  String? originalFirstName;
  String? originalLastName;
  String? originalUsername;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        final profileData = await AuthService.getUserProfile(user.uid);
        if (mounted) {
          setState(() {
            currentUser = user;
            userProfile = profileData;

            // Populate form fields
            _firstNameCtrl.text = profileData?['firstName'] ?? '';
            _lastNameCtrl.text = profileData?['lastName'] ?? '';
            _usernameCtrl.text = profileData?['username'] ?? '';
            _emailCtrl.text = user.email ?? '';

            // Handle date of birth
            if (profileData?['dob'] != null) {
              final dob = DateTime.parse(profileData!['dob']);
              _dobCtrl.text = _formatDate(dob);
            }
            _ageCtrl.text = profileData?['age']?.toString() ?? '';

            // Store original values
            originalFirstName = _firstNameCtrl.text;
            originalLastName = _lastNameCtrl.text;
            originalUsername = _usernameCtrl.text;

            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final yyyy = d.year.toString().padLeft(4, '0');
    return "$mm/$dd/$yyyy";
  }

  void _cancelChanges() {
    setState(() {
      _firstNameCtrl.text = originalFirstName ?? '';
      _lastNameCtrl.text = originalLastName ?? '';
      _usernameCtrl.text = originalUsername ?? '';
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF154D71);

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFEAEFEF),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7AA1),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEAEFEF),
      body: Stack(
        children: [
          // Header positioned behind content
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7AA1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Coiny',
                  ),
                ),
              ),
            ),
          ),

          // Content that can scroll over header
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 100, 0, 24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back and Save icons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: textPrimary),
                            onPressed: () {
                              _cancelChanges();
                              Navigator.pop(context);
                            },
                          ),
                          isSaving
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: textPrimary,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.check,
                                      color: textPrimary),
                                  onPressed: _onSave,
                                ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Avatar with edit badge (placeholder action)
                      Center(
                        child: Stack(
                          children: [
                            const CircleAvatar(
                              radius: 48,
                              backgroundColor: Color(0xFFE0E0E0),
                              child: Icon(Icons.person,
                                  size: 56, color: Colors.grey),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Change photo coming soon')),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: const Icon(Icons.settings,
                                      size: 16, color: Colors.black54),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text('First Name',
                          style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Comfortaa')),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _firstNameCtrl,
                        decoration: _inputDecoration('First Name'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'First name is required'
                            : null,
                      ),

                      const SizedBox(height: 14),

                      const Text('Last Name',
                          style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Comfortaa')),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _lastNameCtrl,
                        decoration: _inputDecoration('Last Name'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Last name is required'
                            : null,
                      ),

                      const SizedBox(height: 14),

                      const Text('Email Address',
                          style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Comfortaa')),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailCtrl,
                        enabled: false,
                        decoration: _inputDecoration('username@gmail.com')
                            .copyWith(
                                suffixIcon:
                                    const Icon(Icons.lock_outline, size: 18)),
                      ),

                      const SizedBox(height: 14),

                      const Text('Username',
                          style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Comfortaa')),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: _inputDecoration('Username'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Username is required'
                            : null,
                      ),

                      const SizedBox(height: 14),

                      const Text('Date of Birth',
                          style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Comfortaa')),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _dobCtrl,
                        enabled: false,
                        decoration: _inputDecoration('00/00/0000').copyWith(
                            suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18)),
                      ),

                      const SizedBox(height: 22),

                      // Change Password
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF59E),
                            foregroundColor: textPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChangePasswordPage()),
                            );
                          },
                          child: const Text(
                            'Change Password',
                            style: TextStyle(fontFamily: 'Comfortaa'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2E7AA1), width: 1),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black26, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2E7AA1), width: 2),
      ),
    );
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = currentUser;
    if (user == null) return;

    setState(() => isSaving = true);

    try {
      final updatedData = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
      };

      await AuthService.updateUserProfile(user.uid, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }
}
