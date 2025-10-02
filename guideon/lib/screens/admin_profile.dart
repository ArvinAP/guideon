import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'admin_users_list.dart';
import 'motivational_quotes_page.dart';
import 'bible_verses_list_page.dart';
import 'edit_profile.dart';
import 'system_logs.dart';
import 'admin_dashboard.dart';
import 'dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  bool _loading = true;
  String _role = 'admin';

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        final data = await AuthService.getUserProfile(user.uid);
        setState(() {
          _role = (data?['role'] ?? 'admin').toString();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const headerColor = Color(0xFF2EC4B6); // teal
    const textPrimary = Colors.black87;
    const cardBg = Color(0xFFFFF9ED); // cream

    if (_loading) {
      return const Scaffold(
        backgroundColor: cardBg,
        body: Center(
          child: CircularProgressIndicator(color: headerColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cardBg,
      body: Stack(
        children: [
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    const Center(
                      child: Text(
                        'Admin Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Coiny',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 110, 0, 24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFFFFF9ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: textPrimary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Admin avatar
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFFE0E0E0),
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Admin',
                      style: TextStyle(
                        color: headerColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        fontFamily: 'Coiny',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontFamily: 'Comfortaa',
                      ),
                    ),
                    const SizedBox(height: 12),

                    _ActionItem(
                      icon: Icons.edit_outlined,
                      label: 'Edit Profile',
                      routeBuilder: _RouteBuilder.editProfile,
                    ),
                    const SizedBox(height: 6),

                    // Common admin actions (both admin and super_admin)
                    if (_role == 'admin' || _role == 'super_admin') ...[
                      _ActionItem(
                        icon: Icons.group_outlined,
                        label: 'Manage Users',
                        routeBuilder: _RouteBuilder.adminUsers,
                      ),
                      _ActionItem(
                        icon: Icons.format_quote_outlined,
                        label: 'Manage Quotes',
                        routeBuilder: _RouteBuilder.quotes,
                      ),
                      _ActionItem(
                        icon: Icons.menu_book_outlined,
                        label: 'Manage Verses',
                        routeBuilder: _RouteBuilder.verses,
                      ),
                      _ActionItem(
                        icon: Icons.dashboard_outlined,
                        label: 'Admin Dashboard',
                        routeBuilder: _RouteBuilder.adminDashboard,
                      ),
                    ],

                    // Super admin only actions
                    if (_role == 'super_admin') ...[
                      _ActionItem(
                        icon: Icons.person_outline,
                        label: 'User Dashboard',
                        routeBuilder: _RouteBuilder.userDashboard,
                      ),
                    ],
                    const SizedBox(height: 6),
                    _ActionItem(
                      icon: Icons.logout,
                      label: 'Logout',
                      isDestructive: true,
                      customOnTap: () => _handleLogout(context),
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

// Simple route builder helper to keep item declarations concise
class _RouteBuilder {
  static void editProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }

  static void adminUsers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminUsersListPage()),
    );
  }

  static void quotes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MotivationalQuotesPage()),
    );
  }

  static void verses(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BibleVersesListPage()),
    );
  }

  static void userSide(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  static void adminDashboard(BuildContext context) async {
    try {
      // Get current user's role from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final userRole = userDoc.data()?['role'] ?? 'user';

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  AdminDashboardPage(loading: false, userRole: userRole)),
        );
      }
    } catch (e) {
      // Fallback to admin if there's an error
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                const AdminDashboardPage(loading: false, userRole: 'admin')),
      );
    }
  }

  static void userDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  static void systemLogs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SystemLogsPage()),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final void Function(BuildContext)? routeBuilder;
  final VoidCallback? customOnTap;
  final bool isDestructive;
  const _ActionItem({
    required this.icon,
    required this.label,
    this.routeBuilder,
    this.customOnTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        isDestructive ? Colors.transparent : const Color(0xFFFFE0B2);
    final Color bg =
        isDestructive ? const Color(0xFFE57373) : const Color(0xFFFFF9ED);
    final Color fg = isDestructive ? Colors.white : Colors.black87;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isDestructive ? 0 : 2),
        boxShadow: isDestructive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFFF4A100).withOpacity(0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
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
        onTap: () {
          if (customOnTap != null) {
            customOnTap!();
          } else {
            routeBuilder?.call(context);
          }
        },
      ),
    );
  }
}
