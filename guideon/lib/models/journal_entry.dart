import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final DateTime date;
  final String moodEmoji; // e.g., "😊", "😐", "😢"
  final String title;
  final String body;
  final Color cardColor;
  final List<String> imagePaths; // local file paths or asset paths
  final List<String> stickers; // to be filled from Figma later
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JournalEntry({
    required this.id,
    required this.date,
    required this.moodEmoji,
    required this.title,
    required this.body,
    required this.cardColor,
    this.imagePaths = const [],
    this.stickers = const [],
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  JournalEntry copyWith({
    String? id,
    DateTime? date,
    String? moodEmoji,
    String? title,
    String? body,
    Color? cardColor,
    List<String>? imagePaths,
    List<String>? stickers,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      title: title ?? this.title,
      body: body ?? this.body,
      cardColor: cardColor ?? this.cardColor,
      imagePaths: imagePaths ?? this.imagePaths,
      stickers: stickers ?? this.stickers,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Firestore serialization
  Map<String, dynamic> toMap({bool forCreate = false}) {
    return {
      'date': Timestamp.fromDate(date),
      'mood': moodEmoji,
      'title': title,
      'body': body,
      'color': cardColor.value,
      'imagePaths': imagePaths,
      'stickers': stickers,
      'deleted': isDeleted,
      if (forCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static JournalEntry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return JournalEntry(
      id: doc.id,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      moodEmoji: (d['mood'] as String?) ?? '🙂',
      title: (d['title'] as String?) ?? '',
      body: (d['body'] as String?) ?? '',
      cardColor: Color((d['color'] as int?) ?? Colors.white.value),
      imagePaths: List<String>.from(d['imagePaths'] ?? const []),
      stickers: List<String>.from(d['stickers'] ?? const []),
      isDeleted: (d['deleted'] as bool?) ?? false,
      createdAt: (d['createdAt'] is Timestamp) ? (d['createdAt'] as Timestamp).toDate() : null,
      updatedAt: (d['updatedAt'] is Timestamp) ? (d['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}
