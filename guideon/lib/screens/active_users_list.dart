import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveUsersListPage extends StatelessWidget {
  const ActiveUsersListPage({super.key});

  Stream<List<Map<String, dynamic>>> _getActiveUsersToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return FirebaseFirestore.instance
        .collection('userProgress')
        .where('lastUpdated',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> activeUsers = [];

      for (var doc in snapshot.docs) {
        try {
          // Get user details from users collection
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(doc.id)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            activeUsers.add({
              'uid': doc.id,
              'email': userData['email'] ?? 'Unknown',
              'displayName': userData['displayName'] ?? 'Unknown User',
              'role': userData['role'] ?? 'user',
              'lastUpdated': doc.data()['lastUpdated'],
              'progressData': doc.data(),
            });
          }
        } catch (e) {
          print('Error fetching user ${doc.id}: $e');
        }
      }

      // Sort by last updated (most recent first)
      activeUsers.sort((a, b) => (b['lastUpdated'] as Timestamp)
          .compareTo(a['lastUpdated'] as Timestamp));

      return activeUsers;
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Active Users Today',
          style: TextStyle(
            color: Color(0xFF154D71),
            fontFamily: 'Coiny',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF154D71)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getActiveUsersToday(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF154D71)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading active users',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final activeUsers = snapshot.data ?? [];

          if (activeUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Color(0xFF154D71),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Users Today',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      fontFamily: 'Coiny',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No users have been active today yet.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeUsers.length,
            itemBuilder: (context, index) {
              final user = activeUsers[index];
              final lastUpdated = user['lastUpdated'] as Timestamp;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        user['role'] == 'admin' || user['role'] == 'super_admin'
                            ? const Color(0xFF154D71)
                            : const Color(0xFFB0BEC5),
                    child: Text(
                      user['displayName'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user['displayName'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF154D71),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['email'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: user['role'] == 'admin' ||
                                      user['role'] == 'super_admin'
                                  ? const Color(0xFF154D71)
                                  : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user['role'].toUpperCase(),
                              style: TextStyle(
                                color: user['role'] == 'admin' ||
                                        user['role'] == 'super_admin'
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Active ${_formatTimestamp(lastUpdated)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.circle,
                    color: const Color(0xFF4CAF50),
                    size: 12,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
