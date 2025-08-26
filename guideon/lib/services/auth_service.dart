import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Replace with your real admin identification logic
  static const Set<String> _adminEmails = {
    'admin@guideon.app',
  };

  static Future<({User user, String role})> signUpAndCreateProfile({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    required DateTime? dob,
    required int? age,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;
    // Default all new signups to 'user'. Admins must be promoted via DB.
    const String role = 'user';

    // Attempt to create the user profile document with retries so the
    // collection is created automatically once Firestore becomes available.
    // Do not await to avoid blocking signup UX if Firestore is still provisioning.
    unawaited(_writeUserProfileWithRetry(
      uid: uid,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'dob': dob?.toIso8601String(),
        'age': age,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ));

    return (user: cred.user!, role: role);
  }

  static Future<void> ensureUserDocument({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final docRef = _db.collection('users').doc(uid);
    try {
      final snap = await docRef.get();
      if (!snap.exists) {
        await docRef.set({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } on FirebaseException catch (e) {
      // If rules still block or DB missing, swallow for now; caller may retry later.
      if (e.code == 'permission-denied' || e.code == 'not-found') {
        return;
      }
      rethrow;
    }
  }

  // Retries Firestore write for transient setup cases (e.g., database not yet
  // created or rules just updated). Collections are created implicitly when the
  // first document is written; this ensures that happens automatically.
  static Future<void> _writeUserProfileWithRetry({
    required String uid,
    required Map<String, dynamic> data,
    int maxAttempts = 6,
    Duration initialDelay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    while (true) {
      try {
        await _db
            .collection('users')
            .doc(uid)
            .set(data, SetOptions(merge: true));
        return; // success
      } on FirebaseException catch (e) {
        final code = e.code;
        final retriable = code == 'not-found' ||
            code == 'permission-denied' ||
            code == 'unavailable' ||
            code == 'aborted' ||
            code == 'deadline-exceeded';
        attempt++;
        if (!retriable || attempt >= maxAttempts) {
          // Give up silently so signup continues; caller can backfill later.
          return;
        }
        await Future.delayed(delay);
        // Exponential backoff up to a reasonable cap
        final nextMs = (delay.inMilliseconds * 2).clamp(2000, 15000);
        delay = Duration(milliseconds: nextMs);
      }
    }
  }

  static Future<({User user, Map<String, dynamic>? profile})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user!;
    Map<String, dynamic>? profile;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        profile = doc.data();
      } else {
        // Backfill profile for users created before Firestore was available
        const String role = 'user';
        profile = {
          'firstName': '',
          'lastName': '',
          'username': '',
          'email': user.email ?? email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await ensureUserDocument(uid: user.uid, data: profile);
      }
    } on FirebaseException catch (e) {
      // If Firestore read fails, continue with basic profile
      if (e.code == 'permission-denied' || e.code == 'not-found') {
        profile = {
          'email': user.email ?? email,
          // Without Firestore, assume regular user; admins must be read from DB.
          'role': 'user',
        };
      } else {
        rethrow;
      }
    }

    return (user: user, profile: profile);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<Map<String, dynamic>?> getUserProgress(String uid) async {
    try {
      final doc = await _db.collection('userProgress').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'not-found') {
        return null;
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'not-found') {
        return null;
      }
      rethrow;
    }
  }

  static Future<void> updateUserProgress(
      String uid, Map<String, dynamic> progressData) async {
    try {
      await _db.collection('userProgress').doc(uid).set({
        ...progressData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'not-found') {
        // Silently fail for now, can be retried later
        return;
      }
      rethrow;
    }
  }

  static Future<void> updateUserProfile(
      String uid, Map<String, dynamic> profileData) async {
    try {
      await _db.collection('users').doc(uid).update({
        ...profileData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'not-found') {
        // Silently fail for now, can be retried later
        return;
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> initializeUserProgress(String uid) async {
    final defaultProgress = {
      'userId': uid,
      'currentStreak': 0,
      'totalDays': 30,
      'currentDay': 1,
      'journalEntries': 0,
      'quotesLiked': 0,
      'petPoints': 0,
      'petLevel': 1,
      'lastTaskDate': null,
      'lastDailyReset': null,
      'lastStreakIncrement': null,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await updateUserProgress(uid, defaultProgress);
    return defaultProgress;
  }
}
