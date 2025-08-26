import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserProgressPage extends StatelessWidget {
  const AdminUserProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    const headerColor = Color(0xFF2E7AA1);
    const textPrimary = Color(0xFF154D71);
    const cardBg = Color(0xFFEAEFEF);

    final stream = FirebaseFirestore.instance
        .collection('userProgress')
        .orderBy('lastUpdated', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: cardBg,
      body: Stack(
        children: [
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
                  'User Progress',
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 110, 12, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(color: headerColor),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('Failed to load progress'),
                        ),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('No progress records found'),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final d = docs[index].data();
                        final userId =
                            d['userId']?.toString() ?? docs[index].id;
                        final streak = d['streak']?.toString() ?? '-';
                        final ts = d['lastUpdated'];
                        String time = '';
                        if (ts is Timestamp) {
                          time = ts.toDate().toLocal().toString();
                        }
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFC7EEF6),
                            child: Icon(Icons.person, color: textPrimary),
                          ),
                          title: Text(userId,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle:
                              Text('Streak: $streak\nLast Updated: $time'),
                          isThreeLine: true,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
