import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SystemLogsPage extends StatefulWidget {
  const SystemLogsPage({super.key});

  @override
  State<SystemLogsPage> createState() => _SystemLogsPageState();
}

class _SystemLogsPageState extends State<SystemLogsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const headerColor = Color(0xFF154D71);
    const cardBg = Color(0xFFEAEFEF);

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'System Logs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Coiny',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(
                        fontFamily: 'Comfortaa',
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: 'Comfortaa',
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.person_outline),
                          text: 'User Logs',
                        ),
                        Tab(
                          icon: Icon(Icons.bug_report_outlined),
                          text: 'Error Logs',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _UserLogsTab(),
                  _ErrorLogsTab(),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserLogsTab extends StatelessWidget {
  Stream<QuerySnapshot> _getUserLogs() {
    return FirebaseFirestore.instance
        .collection('userLogs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isSensitiveAction(String? action) {
    return action?.toLowerCase().contains('journal') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUserLogs(),
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
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading user logs',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontFamily: 'Comfortaa',
                  ),
                ),
              ],
            ),
          );
        }

        final logs = snapshot.data?.docs ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 64, color: Color(0xFF154D71)),
                const SizedBox(height: 16),
                Text(
                  'No User Logs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontFamily: 'Coiny',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No user activity logs found.',
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
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            final timestamp = log['timestamp'] as Timestamp?;

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
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF154D71),
                  child: Text(
                    (log['userId'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  log['action'] ?? 'Unknown Action',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF154D71),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log['details'] != null &&
                        !_isSensitiveAction(log['action']))
                      Text(
                        log['details'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      timestamp != null
                          ? _formatTimestamp(timestamp)
                          : 'Unknown time',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.person,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ErrorLogsTab extends StatelessWidget {
  Stream<QuerySnapshot> _getErrorLogs() {
    return FirebaseFirestore.instance
        .collection('errorLogs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'error':
        return Colors.orange;
      case 'warning':
        return Colors.amber;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getErrorLogs(),
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
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading error logs',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontFamily: 'Comfortaa',
                  ),
                ),
              ],
            ),
          );
        }

        final logs = snapshot.data?.docs ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'No Error Logs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontFamily: 'Coiny',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'System is running smoothly!',
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
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            final timestamp = log['timestamp'] as Timestamp?;
            final severity = log['severity'] as String?;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _getSeverityColor(severity).withOpacity(0.3)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getSeverityColor(severity),
                  child: Icon(
                    Icons.bug_report,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  log['error'] ?? 'Unknown Error',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF154D71),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log['message'] != null)
                      Text(
                        log['message'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (severity != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(severity),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              severity.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          timestamp != null
                              ? _formatTimestamp(timestamp)
                              : 'Unknown time',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.error_outline,
                  color: _getSeverityColor(severity),
                  size: 20,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
