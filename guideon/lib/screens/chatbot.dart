import 'package:flutter/material.dart';
import 'package:guideon/services/chat_service.dart';
import '../components/bottom_nav.dart';
import 'dashboard.dart';
import 'bible_verses.dart';
import 'motivational_quotes.dart';
import 'journal_list.dart';

// Chat now uses Firebase Cloud Functions via ChatService; no direct API keys in app.

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
  bool _engaged =
      false; // becomes true after user saves mood/motivation or sends a message
  late String _selectedMood;
  bool _hasShownQuote = false; // controls when to fetch another quote
  static const List<String> _moodOptions = [
    'Happy',
    'Neutral',
    'Sad',
    'Anxious',
    'Stressed',
  ];

  String _normalizeMood(String v) {
    final s = v.trim();
    for (final opt in _moodOptions) {
      if (opt.toLowerCase() == s.toLowerCase()) return opt;
    }
    return 'Neutral';
  }

  @override
  void initState() {
    super.initState();
    _selectedMood = _normalizeMood(widget.mood);
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

  String _formatQuote({required String text, String? source, String? verse}) {
    final parts = <String>[];
    if (text.isNotEmpty) parts.add('"$text"');
    final tail = [
      if ((source ?? '').isNotEmpty) source,
      if ((verse ?? '').isNotEmpty) '(${verse!.trim()})'
    ].whereType<String>().join(' ');
    if (tail.isNotEmpty) parts.add('— $tail');
    return parts.join(' ');
  }

  bool _wantsQuote(String text) {
    final q = text.toLowerCase();
    return q.contains('quote') ||
        q.contains('another one') ||
        q.contains('give me one') ||
        q.contains('more inspiration');
  }

  String _empatheticReply(String userText) {
    // Simple local fallback to keep the convo flowing without requesting a new quote.
    // You can swap this to call a dedicated chat endpoint later.
    final mood = _selectedMood.toLowerCase();
    return "I hear you. Given you're feeling $mood, that sounds really valid. "
        "What do you think would help a little right now? I'm here to listen.";
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _controller.clear();
      _messages.add(ChatMessage(role: 'user', content: text));
      _isSending = true;
      _engaged = true; // user interacted
    });

    try {
      final askForQuote = _wantsQuote(text) || !_hasShownQuote;

      // Prepare short history for backend chat mode
      final history = _messages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .toList()
          .take(8)
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      final result = await ChatService.instance.generateViaVercel(
        theme: _selectedMood.toLowerCase(),
        message: text,
        askForQuote: askForQuote,
        history: history,
      );

      if (!mounted) return;
      setState(() {
        if (result.quoteText.isNotEmpty) {
          // Quote mode: show quote then interpretation
          final quote = _formatQuote(
            text: result.quoteText,
            source: result.quoteSource,
            verse: result.quoteVerse,
          );
          _messages.add(ChatMessage(role: 'assistant', content: quote));
          if (result.interpretation.isNotEmpty) {
            _messages.add(
                ChatMessage(role: 'assistant', content: result.interpretation));
          }
          _hasShownQuote = true;
        } else {
          // Chat mode: interpretation field carries the reply
          _messages.add(
              ChatMessage(role: 'assistant', content: result.interpretation));
        }
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
            role: 'assistant',
            content: 'Sorry, something went wrong. Please try again later.'));
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const DashboardPage(
                            suppressAutoChat: true,
                          ),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    backgroundColor: const Color(0xFFFFF9AF),
                    label: Text('I feel $_selectedMood'),
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
                    color: const Color(0xFFD6F1F6),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFF2EC4B6), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const DashboardPage(
                                    suppressAutoChat: true,
                                  ),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9AF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'I feel $_selectedMood',
                              style: const TextStyle(
                                fontFamily: 'Comfortaa',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
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
                                constraints:
                                    const BoxConstraints(maxWidth: 280),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFFFFF9AF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        const Color.fromARGB(255, 21, 77, 113),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  m.content,
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 21, 77, 113),
                                    fontFamily: 'Comfortaa',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
                        style: const TextStyle(
                          fontFamily: 'Comfortaa',
                        ),
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
          if (i == 0) {
            // Already on Chatbot; no-op
            return;
          } else if (i == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BibleVersesPage()),
            );
          } else if (i == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MotivationalQuotesPage()),
            );
          } else if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JournalListPage()),
            );
          }
        },
      ),
    );
  }
}
