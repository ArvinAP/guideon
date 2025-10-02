import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_user_detail.dart';

class AdminUsersListPage extends StatelessWidget {
  const AdminUsersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  SizedBox(height: 4),
                  Text(
                    'Total Users',
                    style: TextStyle(
                      color: Color(0xFFF4A100),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Coiny',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Registered',
                    style: TextStyle(
                      color: Color(0xFF2EC4B6),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Coiny',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Failed to load users. Check Firestore rules/connection.',
                        style: TextStyle(
                            fontFamily: 'Comfortaa', color: Colors.black87),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF2EC4B6)),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No users found.',
                        style: TextStyle(
                            fontFamily: 'Comfortaa', color: Colors.black87),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final first = (data['firstName'] ?? '').toString().trim();
                      final last = (data['lastName'] ?? '').toString().trim();
                      String name =
                          [first, last].where((e) => e.isNotEmpty).join(' ');
                      if (name.isEmpty) {
                        name = (data['displayName'] ?? data['name'] ?? '')
                            .toString();
                      }
                      // Card-like list item matching the design

                      return Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF9ED),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Color(0xFFB3E5FC), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB3E5FC).withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE0E0E0),
                            child: Icon(Icons.person, color: Colors.black54),
                          ),
                          title: Text(
                            name.isEmpty ? 'Username' : name,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              fontFamily: 'Comfortaa',
                            ),
                          ),
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
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
