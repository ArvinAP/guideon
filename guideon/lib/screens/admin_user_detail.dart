import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final roleRaw = (widget.data['role'] ?? 'user').toString().toLowerCase();
    _role = roleRaw == 'admin' ? 'admin' : 'user';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'role': _role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated')),
        );
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

    final isActive = (widget.data['active'] ?? true) == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Details',
          style: TextStyle(
            color: Color(0xFF154D71),
            fontFamily: 'Coiny',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF154D71)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF154D71)),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFEAEFEF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Align(
              alignment: Alignment.center,
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                  color: Color(0xFFB8860B), // golden-like
                  fontFamily: 'Coiny',
                  fontSize: 28,
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
                value: _role,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('user')),
                  DropdownMenuItem(value: 'admin', child: Text('admin')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _role = v);
                },
                decoration: _inputDecoration('Role'),
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
            color: Color(0xFF154D71),
            fontWeight: FontWeight.w700,
            fontFamily: 'Comfortaa',
          ),
        ),
      );

  Widget _box({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1DA), // light warm fill
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 3),
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
