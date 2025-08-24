import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'admin_user_detail.dart';

class AdminUsersListPage extends StatelessWidget {
  const AdminUsersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Users',
          style: TextStyle(
            color: Color(0xFF154D71),
            fontFamily: 'Coiny',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF154D71)),
      ),
      backgroundColor: const Color(0xFFEAEFEF),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                  'Failed to load users. Check Firestore rules/connection.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final first = (data['firstName'] ?? '').toString().trim();
              final last = (data['lastName'] ?? '').toString().trim();
              String name = [first, last].where((e) => e.isNotEmpty).join(' ');
              if (name.isEmpty) {
                name = (data['displayName'] ?? data['name'] ?? '').toString();
              }
              final email = (data['email'] ?? '').toString();
              final createdAt = data['createdAt'];
              String subtitle = email;
              if (createdAt is Timestamp) {
                final dt = createdAt.toDate();
                subtitle = [
                  if (email.isNotEmpty) email,
                  'Joined: ${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
                ].where((e) => e.isNotEmpty).join('  •  ');
              }

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFB0BEC5),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  name.isEmpty ? '(No name)' : name,
                  style: const TextStyle(
                    color: Color(0xFF154D71),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminUserDetailPage(
                        userId: docs[index].id,
                        data: data,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
