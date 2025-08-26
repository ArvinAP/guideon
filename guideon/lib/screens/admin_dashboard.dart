import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_users_list.dart';
import 'active_users_list.dart';
import 'motivational_quotes_page.dart';
import 'bible_verses_list_page.dart';
import 'admin_profile.dart';

class AdminDashboardPage extends StatelessWidget {
  final bool _loading;
  final String _userRole;
  const AdminDashboardPage(
      {super.key, required bool loading, required String userRole})
      : _loading = loading,
        _userRole = userRole;

  // Streams for live counts from Firestore
  Stream<int> _countUsers() {
    // Real-time stream of total documents in users collection
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((s) => s.size);
  }

  Stream<int> _countQuotes() {
    return FirebaseFirestore.instance
        .collection('quotes')
        .snapshots()
        .map((s) => s.size);
  }

  Stream<int> _countVerses() {
    return FirebaseFirestore.instance
        .collection('verses')
        .snapshots()
        .map((s) => s.size);
  }

  Stream<int> _countActiveToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return FirebaseFirestore.instance
        .collection('userProgress')
        .where('lastUpdated',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((s) => s.size);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEAEFEF),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF154D71)),
        ),
      );
    }

    if (_userRole != 'admin' && _userRole != 'super_admin') {
      return Scaffold(
        backgroundColor: const Color(0xFFEAEFEF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Unauthorized',
            style: TextStyle(
              color: Color(0xFF154D71),
              fontFamily: 'Coiny',
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Color(0xFF154D71),
              ),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF154D71),
                  fontFamily: 'Coiny',
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Only administrators can access this page.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontFamily: 'Comfortaa',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEAEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Admin Stats',
          style: TextStyle(
            color: Color(0xFF154D71),
            fontFamily: 'Coiny',
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProfilePage()),
                );
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFB0BEC5),
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Row 1: Total users / Active users today
            _StatCardRow(
              left: StreamBuilder<int>(
                stream: _countUsers(),
                initialData: 0,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    // Likely Firestore permission error or network
                    // ignore: avoid_print
                    print('Users count error: ${snapshot.error}');
                    return const _StatCard(
                      title: 'Total users registered',
                      value: '!',
                      subtitle: 'Check Firestore rules/connection',
                      bg: Color(0xFFD7E9FF),
                    );
                  }
                  final val = (snapshot.data ?? 0).toString();
                  return _StatCard(
                    title: 'Total users registered',
                    value: val,
                    subtitle: '+ / - vs last 7 days',
                    bg: const Color(0xFFD7E9FF),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminUsersListPage(),
                        ),
                      );
                    },
                  );
                },
              ),
              right: StreamBuilder<int>(
                stream: _countActiveToday(),
                initialData: 0,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    // ignore: avoid_print
                    print('Active today count error: ${snapshot.error}');
                    return const _StatCard(
                      title: 'Active users today',
                      value: '!',
                      subtitle: 'Check Firestore rules/connection',
                      bg: Color(0xFFFFE0B2),
                    );
                  }
                  final val = (snapshot.data ?? 0).toString();
                  return _StatCard(
                    title: 'Active users today',
                    value: val,
                    subtitle: '- / + vs last 7 days',
                    bg: const Color(0xFFFFE0B2),
                    onTap: _userRole == 'super_admin'
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ActiveUsersListPage(),
                              ),
                            );
                          }
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Row 2: Total quotes (full-width)
            StreamBuilder<int>(
              stream: _countQuotes(),
              initialData: 0,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // ignore: avoid_print
                  print('Quotes count error: ${snapshot.error}');
                  return const _WideStatCard(
                    title: 'Total no. of Motivational Quotes',
                    value: '!',
                    subtitle: 'Check Firestore rules/connection',
                    bg: Color(0xFFC8F5C8),
                  );
                }
                final val = (snapshot.data ?? 0).toString();
                return _WideStatCard(
                  title: 'Total no. of Motivational Quotes',
                  value: val,
                  subtitle: 'View',
                  bg: const Color(0xFFC8F5C8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MotivationalQuotesPage(),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Row 3: Total verses (full-width)
            StreamBuilder<int>(
              stream: _countVerses(),
              initialData: 0,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // ignore: avoid_print
                  print('Verses count error: ${snapshot.error}');
                  return const _WideStatCard(
                    title: 'Total no. of Bible Verses',
                    value: '!',
                    subtitle: 'Check Firestore rules/connection',
                    bg: Color(0xFFFFF2B3),
                  );
                }
                final val = (snapshot.data ?? 0).toString();
                return _WideStatCard(
                  title: 'Total no. of Bible Verses',
                  value: val,
                  subtitle: 'View',
                  bg: const Color(0xFFFFF2B3),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BibleVersesListPage(),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCardRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _StatCardRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }
}

class _WideStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color bg;
  final VoidCallback? onTap;
  const _WideStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.bg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = _StatShell(
      bg: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E6286),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Color(0xFF154D71),
              fontFamily: 'Coiny',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color bg;
  final VoidCallback? onTap;
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.bg,
    this.onTap,
  });

  // Convenience to change only the displayed value when used with builders
  _StatCard copyWithValue(String newValue) => _StatCard(
        title: title,
        value: newValue,
        subtitle: subtitle,
        bg: bg,
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _StatShell(
        bg: bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E6286),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Color(0xFF154D71),
                fontFamily: 'Coiny',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatShell extends StatelessWidget {
  final Color bg;
  final Widget child;
  const _StatShell({required this.bg, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
