import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyTasksService {
  DailyTasksService._();
  static final DailyTasksService instance = DailyTasksService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String get _todayId {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  DocumentReference<Map<String, dynamic>>? _docRefForToday() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _db.collection('users').doc(user.uid).collection('dailyTasks').doc(_todayId);
  }

  Stream<DailyTasks> watchToday() {
    final ref = _docRefForToday();
    if (ref == null) return const Stream.empty();
    return ref.snapshots().map((s) => DailyTasks.fromDoc(s, _todayId));
  }

  Future<DailyTasks> getToday() async {
    final ref = _docRefForToday();
    if (ref == null) return DailyTasks.empty(_todayId);
    final s = await ref.get();
    return DailyTasks.fromDoc(s, _todayId);
  }

  Future<void> _ensureDocExists() async {
    final ref = _docRefForToday();
    if (ref == null) return;
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'journalCount': 0,
        'journalDone': false,
        'bibleRead': false,
        'quoteViewed': false,
        'streakPetVisited': false,
        'chatbotUsed': false,
        'moodChecked': false,
      }, SetOptions(merge: true));
    }
  }

  Future<void> mark(String key) async {
    await _ensureDocExists();
    final ref = _docRefForToday();
    if (ref == null) return;

    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    switch (key) {
      case 'bibleRead':
      case 'quoteViewed':
      case 'streakPetVisited':
      case 'chatbotUsed':
      case 'moodChecked':
        updates[key] = true;
        break;
      default:
        return;
    }
    await ref.set(updates, SetOptions(merge: true));
  }

  Future<void> incrementJournal() async {
    await _ensureDocExists();
    final ref = _docRefForToday();
    if (ref == null) return;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['journalCount'] ?? 0) as int;
      tx.set(ref, {
        'journalCount': current + 1,
        'journalDone': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}

class DailyTasks {
  final String id; // yyyy-MM-dd
  final int journalCount;
  final bool journalDone;
  final bool bibleRead;
  final bool quoteViewed;
  final bool streakPetVisited;
  final bool chatbotUsed;
  final bool moodChecked;

  const DailyTasks({
    required this.id,
    required this.journalCount,
    required this.journalDone,
    required this.bibleRead,
    required this.quoteViewed,
    required this.streakPetVisited,
    required this.chatbotUsed,
    required this.moodChecked,
  });

  factory DailyTasks.empty(String id) => DailyTasks(
        id: id,
        journalCount: 0,
        journalDone: false,
        bibleRead: false,
        quoteViewed: false,
        streakPetVisited: false,
        chatbotUsed: false,
        moodChecked: false,
      );

  factory DailyTasks.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, String id) {
    final d = doc.data() ?? const {};
    return DailyTasks(
      id: doc.id.isNotEmpty ? doc.id : id,
      journalCount: (d['journalCount'] ?? 0) as int,
      journalDone: (d['journalDone'] ?? false) as bool,
      bibleRead: (d['bibleRead'] ?? false) as bool,
      quoteViewed: (d['quoteViewed'] ?? false) as bool,
      streakPetVisited: (d['streakPetVisited'] ?? false) as bool,
      chatbotUsed: (d['chatbotUsed'] ?? false) as bool,
      moodChecked: (d['moodChecked'] ?? false) as bool,
    );
  }

  int get completedCount => [
        journalDone,
        bibleRead,
        quoteViewed,
        streakPetVisited,
        chatbotUsed,
        moodChecked,
      ].where((e) => e).length;
}
