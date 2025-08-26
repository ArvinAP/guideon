import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';

class JournalService {
  JournalService._();
  static final JournalService instance = JournalService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _secure = const FlutterSecureStorage();
  final _algo = AesGcm.with256bits();

  // Secure-storage key name
  static const _kDataKey = 'journal_aes256_key_b64';

  Future<void> _ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  Future<SecretKey> _getOrCreateKey() async {
    final stored = await _secure.read(key: _kDataKey);
    if (stored != null) {
      return SecretKey(base64Decode(stored));
    }
    final key = await _algo.newSecretKey();
    final raw = await key.extractBytes();
    await _secure.write(key: _kDataKey, value: base64Encode(raw));
    return key;
  }

  Future<Map<String, String>> _encrypt(String plaintext) async {
    final key = await _getOrCreateKey();
    final nonce = _randomBytes(12); // 12-byte nonce for AES-GCM
    final secretBox = await _algo.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    // Append MAC for storage
    final combined = <int>[]
      ..addAll(secretBox.cipherText)
      ..addAll(secretBox.mac.bytes);
    return {
      'ciphertext': base64Encode(combined),
      'nonce': base64Encode(secretBox.nonce),
    };
  }

  Future<String> _decrypt(String ciphertextB64, String nonceB64) async {
    final key = await _getOrCreateKey();
    final bytes = base64Decode(ciphertextB64);
    // AES-GCM MAC length is 16 bytes
    final mac = Mac(bytes.sublist(bytes.length - 16));
    final cipher = bytes.sublist(0, bytes.length - 16);
    final box = SecretBox(
      cipher,
      nonce: base64Decode(nonceB64),
      mac: mac,
    );
    final clear = await _algo.decrypt(box, secretKey: key);
    return utf8.decode(clear);
  }

  // Public helpers for other services (e.g., JournalRepository)
  Future<Map<String, String>> encryptText(String plaintext) => _encrypt(plaintext);
  Future<String> decryptText(String ciphertextB64, String nonceB64) => _decrypt(ciphertextB64, nonceB64);

  // Create a new journal entry (encrypted-at-rest)
  Future<String> addEntry({
    required String text,
    String? mood, // optional non-sensitive tag
  }) async {
    await _ensureSignedIn();
    final uid = _auth.currentUser!.uid;
    final enc = await _encrypt(text);

    final ref = _db.collection('users').doc(uid).collection('journals').doc();
    await ref.set({
      'ciphertext': enc['ciphertext'],
      'nonce': enc['nonce'],
      'mood': mood, // optional (stored as plain tag)
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // Optional: delete an entry
  Future<void> deleteEntry(String entryId) async {
    await _ensureSignedIn();
    final uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).collection('journals').doc(entryId).delete();
  }

  // ---- helpers ----
  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}
