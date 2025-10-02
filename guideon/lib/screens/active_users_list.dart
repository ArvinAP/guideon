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

  // Formats a Firestore Timestamp into a short relative string (e.g., "5m ago").
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
      backgroundColor: const Color(0xFFFFF9ED),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom header with back button
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
            // Two-line title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  SizedBox(height: 4),
                  Text(
                    'Active Users',
                    style: TextStyle(
                      color: Color(0xFF2EC4B6),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Coiny',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Today',
                    style: TextStyle(
                      color: Color(0xFFF4A100),
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
              child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getActiveUsersToday(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2EC4B6)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading active users',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final activeUsers = snapshot.data ?? [];

          if (activeUsers.isEmpty) {
            return const Center(
              child: Text(
                'No active users today.',
                style: TextStyle(fontFamily: 'Comfortaa', color: Colors.black87),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: activeUsers.length,
            itemBuilder: (context, index) {
              final user = activeUsers[index];
              final ts = user['lastUpdated'] as Timestamp?;
              final chipText = ts != null
                  ? 'Active ${_formatTimestamp(ts)}'
                  : 'Active recently';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFFFE0B2), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF4A100).withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0E0E0),
                    child: Icon(Icons.person, color: Colors.black54),
                  ),
                  title: Text(
                    (user['displayName'] as String?)?.isNotEmpty == true
                        ? user['displayName']
                        : 'Username',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        chipText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontFamily: 'Comfortaa',
                        ),
                      ),
                    ),
                  ),
                  // trailing online indicator if needed
                  trailing: const Icon(Icons.circle, color: Color(0xFF4CAF50), size: 12),
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
