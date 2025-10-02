import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUserDetailPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> data;

  const AdminUserDetailPage(
      {super.key, required this.userId, required this.data});

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage> {
  late final TextEditingController _nameCtrl;
  String _role = 'user';
  String _currentUserRole = 'user';
  String _originalRole = 'user';
  bool _loadingViewerRole = true;

  String _normalizeRole(String r) {
    final v = (r).toString().trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    if (v == 'superadmin') return 'super_admin';
    if (v == 'super_admin') return 'super_admin';
    if (v == 'admin') return 'admin';
    return 'user';
  }

  @override
  void initState() {
    super.initState();
    final first = (widget.data['firstName'] ?? '').toString().trim();
    final last = (widget.data['lastName'] ?? '').toString().trim();
    final fallback = (widget.data['displayName'] ?? widget.data['name'] ?? '')
        .toString()
        .trim();
    final name =
        [first, last].where((e) => e.isNotEmpty).join(' ').trim().isNotEmpty
            ? [first, last].where((e) => e.isNotEmpty).join(' ')
            : fallback;
    _nameCtrl = TextEditingController(text: name);
    _role = _normalizeRole((widget.data['role'] ?? 'user').toString());
    _originalRole = _role;

    // Fetch the current signed-in admin's role to gate permissions
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((doc) {
        if (mounted && doc.data() != null) {
          setState(() {
            _currentUserRole = _normalizeRole((doc.data()!['role'] ?? 'user').toString());
            _loadingViewerRole = false;
          });
        }
      }).catchError((_) {});
    }
    if (mounted) {
      setState(() {
        _loadingViewerRole = false; // fallback if no user
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      // Only super_admins can change the user's role
      final canEditRole = _currentUserRole == 'super_admin';
      if (_loadingViewerRole) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait, checking permissions...')),
        );
        return;
      }
      if (!canEditRole && _role != _originalRole) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only super_admin can change user role.')),
        );
        return;
      }
      if (_role == _originalRole) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes to save.')),
        );
        return;
      }
      final newRole = canEditRole ? _role : _originalRole;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User updated. Role: $newRole')),
        );
        _originalRole = newRole;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = (widget.data['email'] ?? '').toString();
    final dob =
        (widget.data['dob'] ?? '').toString(); // adjust key if different
    final createdAt = widget.data['createdAt'];
    String createdAtStr = '';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      createdAtStr =
          '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
    }


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF2EC4B6)),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFFF9ED),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFFB0BEC5),
              child: Icon(Icons.person, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 12),
            // Username header
            Center(
              child: Text(
                _usernameFromName(_nameCtrl.text),
                style: const TextStyle(
                  color: Color(0xFFF4A100),
                  fontFamily: 'Coiny',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _label('Name'),
            _box(
                child: TextField(
                    readOnly: true,
                    controller: _nameCtrl,
                    style: const TextStyle(fontFamily: 'Comfortaa'),
                    decoration: _inputDecoration('Name'))),
            const SizedBox(height: 16),

            _label('Role'),
            _box(
              child: DropdownButtonFormField<String>(
                value: _normalizeRole(_role),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('user')),
                  DropdownMenuItem(value: 'admin', child: Text('admin')),
                  DropdownMenuItem(value: 'super_admin', child: Text('super_admin')),
                ],
                onChanged: !_loadingViewerRole && _normalizeRole(_currentUserRole) == 'super_admin'
                    ? (v) {
                        if (v == null) return;
                        setState(() => _role = _normalizeRole(v));
                      }
                    : null,
                decoration: _inputDecoration('Role'),
              ),
            ),
            if (_loadingViewerRole)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Checking permissions...',
                  style: TextStyle(fontFamily: 'Comfortaa', color: Colors.black54, fontSize: 12),
                ),
              )
            else if (_normalizeRole(_currentUserRole) != 'super_admin')
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Only super_admin can change role.',
                  style: TextStyle(fontFamily: 'Comfortaa', color: Colors.black54, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),

            _label('Email Address'),
            _box(
                child: TextField(
                    readOnly: true,
                    controller: TextEditingController(text: email),
                    style: const TextStyle(fontFamily: 'Comfortaa'),
                    decoration: _inputDecoration('Email'))),
            const SizedBox(height: 16),

            _label('Date of Birth'),
            _box(
                child: TextField(
                    readOnly: true,
                    controller: TextEditingController(
                        text: dob.isEmpty ? '00/00/0000' : dob),
                    style: const TextStyle(fontFamily: 'Comfortaa'),
                    decoration: _inputDecoration('Date of Birth'))),
            const SizedBox(height: 16),

            _label('Date Registered'),
            _box(
                child: TextField(
                    readOnly: true,
                    controller: TextEditingController(
                        text:
                            createdAtStr.isEmpty ? '00/00/0000' : createdAtStr),
                    style: const TextStyle(fontFamily: 'Comfortaa'),
                    decoration: _inputDecoration('Date Registered'))),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF154D71),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text(
                'Save Changes',
                style: TextStyle(fontFamily: 'Coiny'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _usernameFromName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'Username';
    return clean;
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF1E88E5),
            fontWeight: FontWeight.w700,
            fontFamily: 'Comfortaa',
          ),
        ),
      );

  Widget _box({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE0B2), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF4A100).withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: child,
      );

  InputDecoration _inputDecoration(String hint) => const InputDecoration(
        border: InputBorder.none,
        hintText: '',
      );
}
