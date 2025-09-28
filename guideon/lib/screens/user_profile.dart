import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile.dart';
import 'streak_pet.dart';
import 'login_page.dart';
import 'journal_list.dart';
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
    const headerColor = Color(0xFF2EC4B6); // Teal header to match design
    const cardBg = Color(0xFFFFF9ED); // Cream background to match design

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
        '${userProfile?['firstName'] ?? ''} ${userProfile?['lastName'] ?? ''}'
            .trim();
    final displayName = name.isEmpty ? 'User' : name;
    final mail = currentUser?.email ?? 'No email';

    return Scaffold(
      backgroundColor: headerColor, // Teal background
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'My Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Coiny',
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Content area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardBg, // Cream background
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar (show stored photo if available)
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFE0E0E0),
                        backgroundImage: (userProfile?['photoUrl'] != null &&
                                (userProfile!['photoUrl'] as String).isNotEmpty)
                            ? NetworkImage(userProfile!['photoUrl'] as String)
                            : null,
                        child: (userProfile?['photoUrl'] == null ||
                                (userProfile!['photoUrl'] as String).isEmpty)
                            ? const Icon(Icons.person,
                                size: 60, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Name & email
                      Text(
                        displayName,
                        style: const TextStyle(
                          color:
                              Color(0xFFF4A100), // Orange color to match design
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          fontFamily: 'Coiny',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mail,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Edit Profile button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFF4A100), // Orange background
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w700),
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
                        icon: Icons.delete_outline,
                        label: 'Recently Deleted',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const JournalListPage(showDeletedInitially: true),
                            ),
                          );
                        },
                      ),
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
    final bg = isDestructive
        ? const Color(0xFFFFC1B8) // Light red for logout
        : Colors.white; // White background for normal items
    final fg = isDestructive ? const Color(0xFF753A32) : textPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: fg, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: 'Comfortaa',
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: fg, size: 16),
        onTap: onTap,
      ),
    );
  }
}
