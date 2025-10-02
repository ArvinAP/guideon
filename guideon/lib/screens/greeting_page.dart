import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../components/buttons.dart';
import 'mood.dart';

class GreetingPage extends StatefulWidget {
  final String? username;
  const GreetingPage({super.key, this.username});

  @override
  State<GreetingPage> createState() => _GreetingPageState();
}

class _GreetingPageState extends State<GreetingPage> {
  String? _resolvedUsername;

  @override
  void initState() {
    super.initState();
    _loadUsernameIfNeeded();
  }

  Future<void> _loadUsernameIfNeeded() async {
    if (widget.username != null && widget.username!.trim().isNotEmpty) {
      setState(() => _resolvedUsername = widget.username!.trim());
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Not signed in; fallback generic greeting
      setState(() => _resolvedUsername = null);
      return;
    }
    try {
      final profile = await AuthService.getUserProfile(user.uid);
      final uname = (profile?['username'] as String?)?.trim();
      final first = (profile?['firstName'] as String?)?.trim();
      final last = (profile?['lastName'] as String?)?.trim();
      final full = [first, last].where((s) => (s ?? '').isNotEmpty).join(' ');
      final display = uname?.isNotEmpty == true
          ? uname
          : (full.isNotEmpty
              ? full
              : (user.displayName?.trim().isNotEmpty == true
                  ? user.displayName!.trim()
                  : null));
      setState(() => _resolvedUsername = display);
    } catch (_) {
      setState(() => _resolvedUsername = null);
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    final name = _resolvedUsername ?? widget.username;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Greeting text above, lamb image centered below
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Speech bubble-like greeting
                  Container(
                    constraints: const BoxConstraints(maxWidth: 260),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAEEAD8), // mint bubble
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000), // subtle shadow
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      "Hi ${name ?? 'there'}! I'm Guideon!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Comfortaa',
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Centered lamb image
                  Image.asset(
                    'lib/assets/images/guideon_lamb.png',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Center(
                child: PrimaryButton(
                  text: 'Continue',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MoodPage(username: name),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
