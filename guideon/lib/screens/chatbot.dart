import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import '../components/bottom_nav.dart';
import 'dashboard.dart';

/// Set your OpenAI API key at build/run time using a Dart define:
/// flutter run --dart-define=OPENAI_API_KEY=sk-xxxxxxxx
const String kOpenAIApiKey = String.fromEnvironment('OPENAI_API_KEY');

class ChatMessage {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  ChatMessage({required this.role, required this.content});
}

class ChatbotPage extends StatefulWidget {
  final String mood;
  final String? username;
  const ChatbotPage({super.key, required this.mood, this.username});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Seed the conversation with a system message using mood
    final intro =
        "You are GuideOn, a friendly, empathetic mental-health companion. The user's current mood is '${widget.mood}'. Respond briefly, kindly, and ask one gentle follow-up.";
    _messages.add(ChatMessage(role: 'system', content: intro));
    // First assistant message
    _messages.add(ChatMessage(
      role: 'assistant',
      content:
          "Hi ${widget.username ?? 'there'}! I see you're feeling ${widget.mood.toLowerCase()}. Would you like to tell me a bit about what's on your mind?",
    ));
  }

  Future<String> _callOpenAI(List<ChatMessage> history) async {
    if (kOpenAIApiKey.isEmpty) {
      // No key yet: return a mock response to keep the app functional.
      await Future.delayed(const Duration(milliseconds: 600));
      return "(Demo) Thanks for sharing. Once the API key is added, I'll generate thoughtful responses. How are you feeling right now?";
    }

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $kOpenAIApiKey');

      // Convert history to OpenAI format
      final msgs = history
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      final body = jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': msgs,
        'temperature': 0.7,
      });
      req.add(utf8.encode(body));

      final res = await req.close();
      final text = await utf8.decoder.bind(res).join();

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(text);
        final content = data['choices'][0]['message']['content'] as String?;
        return content ?? "I'm here with you.";
      } else {
        return 'Error ${res.statusCode}: ${res.reasonPhrase}\n$text';
      }
    } finally {
      client.close();
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _controller.clear();
      _messages.add(ChatMessage(role: 'user', content: text));
      _isSending = true;
    });

    final reply = await _callOpenAI(_messages);

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(role: 'assistant', content: reply));
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 239, 239),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    backgroundColor: const Color(0xFFFFF9AF),
                    label: Text('I feel ${widget.mood}'),
                    labelStyle: const TextStyle(
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                ],
              ),
            ),

            // Conversation card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBF1F5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: ListView.builder(
                    itemCount: _messages.length,
                    padding: const EdgeInsets.only(bottom: 12),
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      if (m.role == 'system') {
                        return const SizedBox.shrink();
                      }
                      final isUser = m.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color:
                                isUser ? const Color(0xFFFFF9AF) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color.fromARGB(255, 21, 77, 113),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            m.content,
                            style: const TextStyle(
                                color: Color.fromARGB(255, 21, 77, 113)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Input bar + send
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Ask GuideOn',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            fontFamily: 'Comfortaa',
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154D71),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                      ),
                      onPressed: _isSending ? null : _send,
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.arrow_forward,
                              color: Colors.white),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: GuideOnBottomNav(
        currentIndex: 0,
        onItemSelected: (i) {
          if (i == 0) return; // already here
          String label = i == 1
              ? 'Bible Verses'
              : i == 2
                  ? 'Motivational Quotes'
                  : 'Journal';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigate to: $label')),
          );
        },
      ),
    );
  }
}
