import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile.dart';
import 'streak_pet.dart';
import 'login_page.dart';
import '../services/auth_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {

  Map<String, dynamic>? userProfile;
  User? currentUser;
  bool isLoading = true;

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
        setState(() {
          currentUser = user;
          userProfile = profileData;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const headerColor = Color(0xFF2E7AA1); // blue header
    const textPrimary = Color(0xFF154D71);
    const cardBg = Color(0xFFEAEFEF);
    const accentCyan = Color(0xFFC7EEF6);
    const logoutRed = Color(0xFFFFC1B8);

    if (isLoading) {
      return Scaffold(
        backgroundColor: cardBg,
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7AA1),
          ),
        ),
      );
    }

    final name = currentUser?.displayName ?? 
                 '${userProfile?['firstName'] ?? ''} ${userProfile?['lastName'] ?? ''}'.trim();
    final displayName = name.isEmpty ? 'User' : name;
    final mail = currentUser?.email ?? 'No email';

    return Scaffold(
      backgroundColor: cardBg,
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
                  color: headerColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'My Profile',
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back button inside the card top-left
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: textPrimary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Avatar
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFFE0E0E0),
                      child: Icon(Icons.person, size: 48, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // Name & email
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Color(0xFF154D71),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        fontFamily: 'Comfortaa',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mail,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontFamily: 'Comfortaa',
                      ),
                    ),
                    if (userProfile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Username: ${userProfile!['username'] ?? 'Not set'}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontFamily: 'Comfortaa',
                        ),
                      ),
                      Text(
                        'Role: ${userProfile!['role'] ?? 'user'}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontFamily: 'Comfortaa',
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Edit Profile button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF59E), // pale yellow
                        foregroundColor: textPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfilePage()),
                        );
                        // Reload profile if edit was successful
                        if (result == true) {
                          _loadUserData();
                        }
                      },
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(fontFamily: 'Comfortaa'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action list
                    _ActionItem(
                      icon: Icons.bookmark_border,
                      label: 'Favorites',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Favorites coming soon')),
                        );
                      },
                    ),
                    _ActionItem(
                      icon: Icons.pets_outlined,
                      label: 'Pet',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const StreakPetPage()),
                        );
                      },
                    ),
                    _ActionItem(
                      icon: Icons.favorite_border,
                      label: 'Likes',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Likes coming soon')),
                        );
                      },
                    ),
                    _ActionItem(
                      icon: Icons.delete_outline,
                      label: 'Recently Deleted',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Recently Deleted coming soon')),
                        );
                      },
                    ),

                    const SizedBox(height: 6),

                    _ActionItem(
                      icon: Icons.logout,
                      label: 'Logout',
                      isDestructive: true,
                      onTap: _handleLogout,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF154D71);
    final bg =
        isDestructive ? const Color(0xFFFFC1B8) : const Color(0xFFC7EEF6);
    final fg = isDestructive ? const Color(0xFF753A32) : textPrimary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: ListTile(
        leading: Icon(icon, color: fg),
        title: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontFamily: 'Comfortaa',
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: fg, size: 16),
        onTap: onTap,
      ),
    );
  }
}
