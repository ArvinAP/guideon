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
    return Scaffold(
      backgroundColor: const Color(0xFFEAEFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7AA1),
        elevation: 0,
        title: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Current Password', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _currentCtrl,
                  obscureText: !_showCurrent,
                  decoration: _passwordDecoration('Enter current password', _showCurrent, () => setState(() => _showCurrent = !_showCurrent)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                const Text('New Password', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: !_showNew,
                  decoration: _passwordDecoration('Enter new password', _showNew, () => setState(() => _showNew = !_showNew)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Confirm Password', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_showConfirm,
                  decoration: _passwordDecoration('Re-enter new password', _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
                  validator: (v) => (v != _newCtrl.text) ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC7EEF6),
                    foregroundColor: textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onPressed: _onSubmit,
                  child: const Text('Update Password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _passwordDecoration(String hint, bool shown, VoidCallback toggle) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      suffixIcon: IconButton(
        icon: Icon(shown ? Icons.visibility_off : Icons.visibility),
        onPressed: toggle,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2E7AA1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2E7AA1), width: 2),
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
