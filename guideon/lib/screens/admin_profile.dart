import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'admin_users_list.dart';
import 'motivational_quotes_page.dart';
import 'bible_verses_list_page.dart';
import 'edit_profile.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

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

  @override
  Widget build(BuildContext context) {
    const headerColor = Color(0xFF2E7AA1);
    const textPrimary = Color(0xFF154D71);
    const cardBg = Color(0xFFEAEFEF);

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
                  'Admin',
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

          // Content
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
                        Icons.admin_panel_settings,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Administrator',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        fontFamily: 'Comfortaa',
                      ),
                    ),
                    const SizedBox(height: 16),

                    _ActionItem(
                      icon: Icons.edit_outlined,
                      label: 'Edit Profile',
                      routeBuilder: _RouteBuilder.editProfile,
                    ),
                    const SizedBox(height: 6),

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
