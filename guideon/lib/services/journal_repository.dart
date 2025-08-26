import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';
import 'daily_tasks_service.dart';
import 'journal_service.dart';

/// Firestore-backed repository for journals.
/// Collection path: users/{uid}/journals/{entryId}
class JournalRepository extends ChangeNotifier {
  static final JournalRepository instance = JournalRepository._internal();
  JournalRepository._internal();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final List<JournalEntry> _entries = [];
  final List<JournalEntry> _deleted = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<JournalEntry> get entries => List.unmodifiable(_entries);
  List<JournalEntry> get recentlyDeleted => List.unmodifiable(_deleted);

  /// Call when opening the journal for the first time (e.g., in JournalListPage.initState).
  Future<void> init() async {
    // Ensure persistence (usually enabled by default; set explicitly just in case)
    _firestore.settings = const Settings(persistenceEnabled: true);

    await _attachListener();
  }

  Future<void> _attachListener() async {
    await _sub?.cancel();
    final user = _auth.currentUser;
    if (user == null) {
      _entries.clear();
      _deleted.clear();
      notifyListeners();
      return;
    }

    final col = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('journals');

    _sub = col.orderBy('date', descending: true).snapshots().listen((snap) {
      // Process snapshot asynchronously to decrypt fields
      _processSnapshot(snap);
    });
  }

  Future<void> _processSnapshot(QuerySnapshot<Map<String, dynamic>> snap) async {
    final result = <JournalEntry>[];
    final deleted = <JournalEntry>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      // Prefer encrypted fields if present
      String title = d['title'] as String? ?? '';
      String body = d['body'] as String? ?? '';
      if (d['cipherTitle'] is String && d['nonceTitle'] is String) {
        try {
          title = await JournalService.instance
              .decryptText(d['cipherTitle'] as String, d['nonceTitle'] as String);
        } catch (_) {}
      }
      if (d['cipherBody'] is String && d['nonceBody'] is String) {
        try {
          body = await JournalService.instance
              .decryptText(d['cipherBody'] as String, d['nonceBody'] as String);
        } catch (_) {}
      }

      final entry = JournalEntry(
        id: doc.id,
        date: (d['date'] is Timestamp) ? (d['date'] as Timestamp).toDate() : DateTime.now(),
        moodEmoji: (d['mood'] as String?) ?? '🙂',
        title: title,
        body: body,
        cardColor: Color((d['color'] as int?) ?? Colors.white.value),
        imagePaths: List<String>.from(d['imagePaths'] ?? const []),
        stickers: List<String>.from(d['stickers'] ?? const []),
        isDeleted: (d['deleted'] as bool?) ?? false,
        createdAt: (d['createdAt'] is Timestamp) ? (d['createdAt'] as Timestamp).toDate() : null,
        updatedAt: (d['updatedAt'] is Timestamp) ? (d['updatedAt'] as Timestamp).toDate() : null,
      );
      if (entry.isDeleted) {
        deleted.add(entry);
      } else {
        result.add(entry);
      }
    }
    _entries
      ..clear()
      ..addAll(result);
    _deleted
      ..clear()
      ..addAll(deleted);
    notifyListeners();
  }

  Future<void> add(JournalEntry entry) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final col = _firestore.collection('users').doc(user.uid).collection('journals');
    final doc = col.doc(entry.id);
    // Encrypt sensitive fields
    final encTitle = await JournalService.instance.encryptText(entry.title);
    final encBody = await JournalService.instance.encryptText(entry.body);
    final data = {
      'date': Timestamp.fromDate(entry.date),
      'mood': entry.moodEmoji,
      'color': entry.cardColor.value,
      'imagePaths': entry.imagePaths,
      'stickers': entry.stickers,
      'deleted': entry.isDeleted,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // encrypted fields
      'cipherTitle': encTitle['ciphertext'],
      'nonceTitle': encTitle['nonce'],
      'cipherBody': encBody['ciphertext'],
      'nonceBody': encBody['nonce'],
      // Optional: remove plaintext fields if they exist
      'title': FieldValue.delete(),
      'body': FieldValue.delete(),
    };
    await doc.set(data, SetOptions(merge: true));
    // Track daily task completion
    await DailyTasksService.instance.incrementJournal();
  }

  Future<void> update(JournalEntry entry) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('journals')
        .doc(entry.id);
    final encTitle = await JournalService.instance.encryptText(entry.title);
    final encBody = await JournalService.instance.encryptText(entry.body);
    final data = {
      'date': Timestamp.fromDate(entry.date),
      'mood': entry.moodEmoji,
      'color': entry.cardColor.value,
      'imagePaths': entry.imagePaths,
      'stickers': entry.stickers,
      'deleted': entry.isDeleted,
      'updatedAt': FieldValue.serverTimestamp(),
      'cipherTitle': encTitle['ciphertext'],
      'nonceTitle': encTitle['nonce'],
      'cipherBody': encBody['ciphertext'],
      'nonceBody': encBody['nonce'],
      'title': FieldValue.delete(),
      'body': FieldValue.delete(),
    };
    await doc.set(data, SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('journals')
        .doc(id);
    await doc.set({'deleted': true, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<void> restore(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('journals')
        .doc(id);
    await doc.set({'deleted': false, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<void> disposeListener() async {
    await _sub?.cancel();
    _sub = null;
  }
}
