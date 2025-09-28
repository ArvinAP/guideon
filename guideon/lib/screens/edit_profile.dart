import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'change_password.dart';
  import '../services/auth_service.dart';
  import 'dart:io';
  import 'package:image_picker/image_picker.dart';
  import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
  import 'package:flutter/foundation.dart' show kIsWeb;
  import 'dart:typed_data';

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
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _pickedBytes; // for Web previews/uploads
  String? _photoUrl;
  bool _removePhoto = false;

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
            _photoUrl = profileData?['photoUrl'] as String?;

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

  Future<void> _pickImageFrom(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _pickedImage = picked;
          _pickedBytes = null;
          _removePhoto = false;
        });
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          if (!mounted) return;
          setState(() => _pickedBytes = bytes);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get image: ${e.toString()}')),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFrom(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFrom(ImageSource.gallery);
                },
              ),
              if (_photoUrl != null && _photoUrl!.isNotEmpty || _pickedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _pickedImage = null;
                      _photoUrl = '';
                      _removePhoto = true;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF154D71);
    // UI palette tuned to the provided mock
    const headerTeal = Color(0xFF6ED3C0); // top header
    const cardCream = Color(0xFFFEF7EC); // card background
    const btnOrange = Color(0xFFF5A623); // change password button

    // Sizing helpers
    final media = MediaQuery.of(context);
    final double headerHeight = media.size.height * 0.5; // teal area covers half screen
    const double contentTopPadding = 110; // keep existing overlap placement
    final double minCardHeight =
        media.size.height - contentTopPadding - media.padding.top;

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
                height: headerHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: headerTeal,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                alignment: Alignment.topCenter,
                child: const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Coiny',
                      shadows: [
                        Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content that can scroll over header
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, contentTopPadding, 0, 0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardCream,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.black26, width: 1.2),
                ),
                constraints: BoxConstraints(minHeight: minCardHeight),
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

                      // Avatar with pick image action
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: const Color(0xFFE0E0E0),
                              backgroundImage: _pickedImage != null
                                  ? (kIsWeb
                                      ? (_pickedBytes != null
                                          ? MemoryImage(_pickedBytes!)
                                          : null)
                                      : FileImage(File(_pickedImage!.path))
                                          as ImageProvider?)
                                  : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                      ? NetworkImage(_photoUrl!)
                                      : null,
                              child: (_pickedImage == null && (_photoUrl == null || _photoUrl!.isEmpty))
                                  ? const Icon(Icons.person, size: 56, color: Colors.grey)
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: _showPhotoOptions,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black26),
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.black54),
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
                                suffixIcon: const Icon(Icons.lock_outline,
                                    size: 18)),
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
                            backgroundColor: btnOrange,
                            foregroundColor: Colors.white,
                            elevation: 1,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Comfortaa',
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChangePasswordPage()),
                            );
                          },
                          child: const Text('Change Password'),
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
    const fill = Color(0xFFFFFCF7);
    const borderColor = Color(0xFF2FB7AA);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black26, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 2),
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

      // If a new image was picked, upload to Firebase Storage
      if (_pickedImage != null) {
        final storage = firebase_storage.FirebaseStorage.instance;
        final ref = storage.ref().child('user_photos/${user.uid}.jpg');
        if (kIsWeb) {
          // Use bytes on Web
          final bytes = _pickedBytes ?? await _pickedImage!.readAsBytes();
          await ref.putData(
            bytes,
            firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          final file = File(_pickedImage!.path);
          await ref.putFile(
            file,
            firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
          );
        }
        final url = await ref.getDownloadURL();
        _photoUrl = url;
        updatedData['photoUrl'] = url;
      } else if (_removePhoto) {
        updatedData['photoUrl'] = '';
      }

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
