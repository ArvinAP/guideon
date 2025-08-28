import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatServiceResult {
  final String quoteText;
  final String quoteSource; // author or book
  final String quoteVerse; // bible verse reference
  final String interpretation; // deepseek response

  ChatServiceResult({
    required this.quoteText,
    required this.quoteSource,
    required this.quoteVerse,
    required this.interpretation,
  });
}

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<void> _ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  Future<ChatServiceResult> generateQuoteInterpretation({
    required String theme,
    required String message,
  }) async {
    await _ensureSignedIn();

    final callable = _functions.httpsCallable('generateQuoteInterpretation');
    final result = await callable.call({
      'theme': theme,
      'message': message,
    });

    final data = (result.data as Map).cast<String, dynamic>();
    final quote = (data['quote'] as Map).cast<String, dynamic>();

    return ChatServiceResult(
      quoteText: (quote['text'] as String?) ?? '',
      quoteSource: (quote['source'] as String?) ?? '',
      quoteVerse: (quote['verse'] as String?) ?? '',
      interpretation: (data['interpretation'] as String?) ?? '',
    );
  }

  // Calls the Vercel serverless endpoint directly via HTTPS.
  Future<ChatServiceResult> generateViaVercel({
    required String theme,
    required String message,
    required bool askForQuote,
    bool askForVerse = false,
    List<Map<String, String>> history = const [],
  }) async {
    await _ensureSignedIn();
    final idToken = await _auth.currentUser!.getIdToken();

    final uri = Uri.parse(
      'https://guideon-vercel.vercel.app/api/generateQuoteInterpretation',
    );

    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'theme': theme,
        'message': message,
        'askForQuote': askForQuote,
        'askForVerse': askForVerse,
        'history': history,
      }),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Vercel error ${resp.statusCode}: ${resp.body}');
    }

    final data = (jsonDecode(resp.body) as Map).cast<String, dynamic>();
    if (data.containsKey('reply')) {
      // Chat mode: no quote, just a reply.
      return ChatServiceResult(
        quoteText: '',
        quoteSource: '',
        quoteVerse: '',
        interpretation: (data['reply'] as String?) ?? '',
      );
    } else if (data.containsKey('quote')) {
      final quote = (data['quote'] as Map?)?.cast<String, dynamic>() ?? {};
      return ChatServiceResult(
        quoteText: (quote['text'] as String?) ?? '',
        quoteSource: (quote['source'] as String?) ?? '',
        quoteVerse: (quote['verse'] as String?) ?? '',
        interpretation: (data['interpretation'] as String?) ?? '',
      );
    } else if (data.containsKey('verse')) {
      final verse = (data['verse'] as Map?)?.cast<String, dynamic>() ?? {};
      // Map verse response into ChatServiceResult fields
      return ChatServiceResult(
        quoteText: (verse['text'] as String?) ?? '',
        quoteSource: (verse['translation'] as String?) ?? '',
        quoteVerse: (verse['reference'] as String?) ?? '',
        interpretation: (data['interpretation'] as String?) ?? '',
      );
    }
    // Fallback: unknown payload
    return ChatServiceResult(
      quoteText: '',
      quoteSource: '',
      quoteVerse: '',
      interpretation: (data['interpretation'] as String?) ?? '',
    );
  }

  // Fetch decrypted conversation history via Vercel API (server decrypts).
  // If ymd is provided, returns that day; else returns recent conversations up to limitDays (default 7).
  Future<Map<String, dynamic>> fetchHistory({String? ymd, int limitDays = 7}) async {
    await _ensureSignedIn();
    final idToken = await _auth.currentUser!.getIdToken();

    final uri = Uri.parse(
      'https://guideon-vercel.vercel.app/api/generateQuoteInterpretation',
    );

    final payload = <String, dynamic>{
      'getHistory': true,
    };
    if (ymd != null && ymd.isNotEmpty) {
      payload['ymd'] = ymd;
    } else {
      payload['limitDays'] = limitDays;
    }

    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(payload),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Vercel history error ${resp.statusCode}: ${resp.body}');
    }

    final data = (jsonDecode(resp.body) as Map).cast<String, dynamic>();
    return data; // { conversations: [ { id, updatedAt, themeLast, messages: [ {role, content, ...} ] } ] }
  }

  // Convenience: get the latest day's messages (user/assistant only) as a simple list.
  Future<List<Map<String, String>>> fetchLatestMessages({int lookbackDays = 7}) async {
    final data = await fetchHistory(limitDays: lookbackDays);
    final convs = (data['conversations'] as List?) ?? const [];
    if (convs.isEmpty) return [];
    final first = (convs.first as Map).cast<String, dynamic>();
    final msgs = (first['messages'] as List?) ?? const [];
    final out = <Map<String, String>>[];
    for (final m in msgs) {
      final mm = (m as Map).cast<String, dynamic>();
      final role = (mm['role'] as String?) ?? '';
      final content = (mm['content'] as String?) ?? '';
      if (role == 'user' || role == 'assistant') {
        out.add({'role': role, 'content': content});
      }
    }
    return out;
  }
}
