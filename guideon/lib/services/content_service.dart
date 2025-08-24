import 'package:cloud_firestore/cloud_firestore.dart';

class ContentService {
  ContentService._();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Seeds the expected collections if empty.
  /// Returns a map of collectionName -> number of docs created.
  static Future<Map<String, int>> seedIfEmpty() async {
    final results = <String, int>{};

    results['quotes'] = await _ensureQuotes();
    results['verses'] = await _ensureVerses();

    return results;
  }

  // ===== One-shot aggregate helpers for Admin Dashboard =====
  /// Returns total number of documents in the provided collection using server-side aggregate count.
  static Future<int> collectionCount(String collection) async {
    final res = await _db.collection(collection).count().get();
    return res.count ?? 0;
  }

  /// Returns total number of users in 'users' collection (one-shot aggregate).
  static Future<int> usersCount() => collectionCount('users');

  /// Checks if 'users' collection is empty.
  static Future<bool> isUsersEmpty() async {
    final c = await usersCount();
    return c == 0;
  }

  /// Returns count of active users today based on userProgress.lastUpdated >= startOfDay.
  /// Note: Requires 'lastUpdated' to be maintained (see AuthService.updateUserProgress()).
  static Future<int> activeUsersTodayCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final q = _db.collection('userProgress').where('lastUpdated',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay));
    final res = await q.count().get();
    return res.count ?? 0;
  }

  static Future<int> _ensureQuotes() async {
    final col = _db.collection('quotes');
    final snap = await col.limit(1).get();
    if (snap.size > 0) return 0;

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    final samples = [
      {
        'text': "Believe you can and you're halfway there.",
        'author': 'Theodore Roosevelt',
        'createdAt': now,
      },
      {
        'text': "It always seems impossible until it's done.",
        'author': 'Nelson Mandela',
        'createdAt': now,
      },
      {
        'text': 'Start where you are. Use what you have. Do what you can.',
        'author': 'Arthur Ashe',
        'createdAt': now,
      },
    ];

    for (final s in samples) {
      batch.set(col.doc(), s);
    }

    await batch.commit();
    return samples.length;
  }

  static Future<int> _ensureVerses() async {
    final col = _db.collection('verses');
    final snap = await col.limit(1).get();
    if (snap.size > 0) return 0;

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    final samples = [
      {
        'text': 'I can do all things through Christ who strengthens me.',
        'reference': 'Philippians 4:13',
        'createdAt': now,
      },
      {
        'text': 'The Lord is my shepherd; I shall not want.',
        'reference': 'Psalm 23:1',
        'createdAt': now,
      },
      {
        'text':
            'Be strong and courageous... for the Lord your God will be with you wherever you go.',
        'reference': 'Joshua 1:9',
        'createdAt': now,
      },
    ];

    for (final s in samples) {
      batch.set(col.doc(), s);
    }

    await batch.commit();
    return samples.length;
  }
}
