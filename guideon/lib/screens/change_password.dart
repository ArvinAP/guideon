import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF154D71);
    const headerTeal = Color(0xFF6ED3C0);
    const cardCream = Color(0xFFFEF7EC);
    const btnOrange = Color(0xFFF5A623);

    // Sizing to match EditProfile layout
    final media = MediaQuery.of(context);
    final double headerHeight = media.size.height * 0.5; // teal covers half screen
    const double contentTopPadding = 110; // keep overlap similar
    final double minCardHeight = media.size.height - contentTopPadding - media.padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFEAEFEF),
      body: Stack(
        children: [
          // Header
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
                ),
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text(
                        'Change Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Coiny',
                          shadows: [
                            Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                          ],
                        ),
                      ),
                      // Keep space on the right so the title stays visually centered if needed
                      const Positioned(right: 0, child: SizedBox(width: 48, height: 48)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF154D71)),
                        tooltip: 'Back',
                        onPressed: () async {
                          final didPopLocal = await Navigator.maybePop(context);
                          if (!didPopLocal) {
                            final root = Navigator.of(context, rootNavigator: true);
                            if (root.canPop()) {
                              root.pop();
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Current Password',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Comfortaa',
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _currentCtrl,
                            obscureText: !_showCurrent,
                            decoration: _passwordDecoration(
                              'Enter current password',
                              _showCurrent,
                              () => setState(() => _showCurrent = !_showCurrent),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'New Password',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Comfortaa',
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _newCtrl,
                            obscureText: !_showNew,
                            decoration: _passwordDecoration(
                              'Enter new password',
                              _showNew,
                              () => setState(() => _showNew = !_showNew),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (v.length < 8) return 'At least 8 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          const Text('Confirm Password', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontFamily: 'Comfortaa')),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: !_showConfirm,
                            decoration: _passwordDecoration('Re-enter new password', _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
                            validator: (v) => (v != _newCtrl.text) ? 'Passwords do not match' : null,
                          ),
                          const SizedBox(height: 24),

                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: btnOrange,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: const StadiumBorder()
                              ),
                              onPressed: _onSubmit,
                              child: const Text('Update Password'),
                            ),
                          ),
                        ],
                      ),
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

  InputDecoration _passwordDecoration(String hint, bool shown, VoidCallback toggle) {
    const fill = Color(0xFFFFFCF7);
    const borderColor = Color(0xFF2FB7AA);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      suffixIcon: IconButton(
        icon: Icon(shown ? Icons.visibility_off : Icons.visibility),
        onPressed: toggle,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 2),
      ),
    );
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // TODO: backend call to update password
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated')),
    );
    Navigator.pop(context);
  }
}
