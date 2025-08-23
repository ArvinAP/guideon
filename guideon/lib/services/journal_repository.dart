import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';
import 'daily_tasks_service.dart';

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
      final all = snap.docs.map(JournalEntry.fromDoc).toList();
      _entries
        ..clear()
        ..addAll(all.where((e) => !e.isDeleted));
      _deleted
        ..clear()
        ..addAll(all.where((e) => e.isDeleted));
      notifyListeners();
    });
  }

  Future<void> add(JournalEntry entry) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final col = _firestore.collection('users').doc(user.uid).collection('journals');
    final doc = col.doc(entry.id);
    await doc.set(entry.toMap(forCreate: true), SetOptions(merge: true));
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
    await doc.set(entry.toMap(), SetOptions(merge: true));
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
