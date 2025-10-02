import 'package:flutter/material.dart';
import 'package:guideon/components/bottom_nav.dart';
import '../services/chat_service.dart';
import '../services/daily_tasks_service.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _engaged =
      false; // becomes true after user saves mood/motivation or sends a message
  late String _selectedMood;
  bool _hasShownQuote = false; // controls when to fetch another quote
  bool _showChoice = true; // show initial choice buttons until user picks one
  static const List<String> _moodOptions = [
    'Happy',
    'Excited',
    'Angry',
    'Sad',
    'Neutral',
  ];

  String _normalizeMood(String v) {
    final s = v.trim();
    for (final opt in _moodOptions) {
      if (opt.toLowerCase() == s.toLowerCase()) return opt;
    }
    return 'Neutral';
  }

  Widget _buildChoiceSection() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hello',
            style: const TextStyle(
              fontFamily: 'Coiny',
              fontSize: 32,
              color: Color(0xFF3DB5A6),
            ),
          ),
          Text(
            '${widget.username ?? 'there'}!',
            style: const TextStyle(
              fontFamily: 'Coiny',
              fontSize: 32,
              color: Color(0xFFF4A100),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'What would you like to start with?',
            style: TextStyle(
              fontFamily: 'Comfortaa',
              color: Color(0xFF154D71),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _isSending ? null : _fetchInitialQuote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2EC4B6),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(
                      fontFamily: 'Comfortaa', fontWeight: FontWeight.w700),
                ),
                child: const Text('Motivational Quote'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isSending ? null : _fetchInitialVerse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4A100),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(
                      fontFamily: 'Comfortaa', fontWeight: FontWeight.w700),
                ),
                child: const Text('Bible Verse'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _fetchInitialQuote() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _engaged = true;
    });
    try {
      DailyTasksService.instance.mark('chatbotUsed');
      DailyTasksService.instance.mark('moodChecked');

      final result = await ChatService.instance.generateViaVercel(
        theme: _selectedMood.toLowerCase(),
        message: 'Please reflect on this for me.',
        askForQuote: true,
        askForVerse: false,
        history: const [],
      );
      if (!mounted) return;
      setState(() {
        if (result.quoteText.isNotEmpty) {
          final quote = _formatQuote(
            text: result.quoteText,
            source: result.quoteSource,
            verse: result.quoteVerse,
          );
          _messages.add(ChatMessage(role: 'assistant', content: quote));
        }
        if (result.interpretation.isNotEmpty) {
          _messages.add(
              ChatMessage(role: 'assistant', content: result.interpretation));
        }
        _hasShownQuote = true;
        _isSending = false;
        _showChoice = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
            role: 'assistant',
            content: 'Sorry, something went wrong fetching a quote.'));
        _isSending = false;
      });
      _scrollToBottom();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _fetchInitialVerse() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _engaged = true;
    });
    try {
      DailyTasksService.instance.mark('chatbotUsed');
      DailyTasksService.instance.mark('moodChecked');

      final result = await ChatService.instance.generateViaVercel(
        theme: _selectedMood.toLowerCase(),
        message: 'Please reflect on this Bible verse for me.',
        askForQuote: false,
        askForVerse: true,
        history: const [],
      );
      if (!mounted) return;
      setState(() {
        if (result.quoteText.isNotEmpty) {
          final quote = _formatQuote(
            text: result.quoteText,
            source: result.quoteSource,
            verse: result.quoteVerse,
          );
          _messages.add(ChatMessage(role: 'assistant', content: quote));
        }
        if (result.interpretation.isNotEmpty) {
          _messages.add(
              ChatMessage(role: 'assistant', content: result.interpretation));
        }
        _hasShownQuote = true;
        _isSending = false;
        _showChoice = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
            role: 'assistant',
            content: 'Sorry, something went wrong fetching a verse.'));
        _isSending = false;
      });
      _scrollToBottom();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _loadHistory() async {
    try {
      final latest =
          await ChatService.instance.fetchLatestMessages(lookbackDays: 7);
      if (latest.isEmpty) return;
      if (!mounted) return;
      setState(() {
        // Append loaded messages (user/assistant only). System message stays hidden in UI anyway.
        for (final m in latest) {
          final role = m['role'] ?? 'assistant';
          final content = m['content'] ?? '';
          _messages.add(ChatMessage(role: role, content: content));
        }
      });
      _scrollToBottom(smooth: false);
    } catch (_) {
      // Silently ignore history errors; chat still works.
    }
  }

  void _scrollToBottom({bool smooth = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (smooth) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(max);
      }
    });
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color.fromARGB(255, 21, 77, 113),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation(Color.fromARGB(255, 21, 77, 113)),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'GuideOn is typing…',
              style: TextStyle(
                color: Color.fromARGB(255, 21, 77, 113),
                fontFamily: 'Comfortaa',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedMood = _normalizeMood(widget.mood);
    // Seed the conversation with a system message using mood
    final intro =
        "You are GuideOn, a friendly, empathetic mental-health companion. The user's current mood is '${widget.mood}'. Respond briefly, kindly, and ask one gentle follow-up.";
    _messages.add(ChatMessage(role: 'system', content: intro));
    // Load previous chats (latest day) and append to thread.
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant ChatbotPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newMood = _normalizeMood(widget.mood);
    if (newMood != _selectedMood) {
      setState(() {
        _selectedMood = newMood;
        // Re-show the choice buttons when mood changes
        _showChoice = true;
        // Allow another quote/verse suggestion for the new mood
        _hasShownQuote = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
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
      _showChoice = false;
    });

    // Mark tasks as completed when user engages with chatbot
    if (_engaged) {
      DailyTasksService.instance.mark('chatbotUsed');
      DailyTasksService.instance.mark('moodChecked');
    }
    _scrollToBottom();

    try {
      final askForQuote = _wantsQuote(text) || !_hasShownQuote;

      // Prepare chat history for backend chat mode.
      // Prepend a system style guide to encourage natural conversation
      // (avoid asking a question every time; vary responses; be concise and empathetic).
      final List<Map<String, String>> history = [
        {
          'role': 'system',
          'content': "You are GuideOn, a friendly, empathetic companion. Chat naturally like a person, not a survey."
              " Keep replies short and supportive. It's OK to respond without a question; only ask at most every 2-3 turns,"
              " and only if it truly helps move the conversation forward. Offer validation, reflections, and small, practical suggestions."
              " Avoid repeating the same question format. The user's current mood is '$_selectedMood'.",
        },
        ..._messages
            .where((m) => m.role == 'user' || m.role == 'assistant')
            .toList()
            .take(10)
            .map((m) => {
                  'role': m.role,
                  'content': m.content,
                })
            .toList(),
      ];

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
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
            role: 'assistant',
            content: 'Sorry, something went wrong. Please try again later.'));
        _isSending = false;
      });
      _scrollToBottom();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      body: SafeArea(
        child: Column(
          children: [
            // Small spacer (header removed; chip moved inside card)
            const SizedBox(height: 8),

            // Conversation card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9ED),
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: const Color(0xFF2EC4B6), width: 3),
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
                          // Pill chip for current mood on the top-right
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9AF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF2EC4B6),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'I feel $_selectedMood',
                              style: const TextStyle(
                                color: Color(0xFF154D71),
                                fontFamily: 'Comfortaa',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_showChoice) _buildChoiceSection(),
                      const SizedBox(height: 8),
                      if (!_showChoice)
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _messages.length + (_isSending ? 1 : 0),
                            padding: const EdgeInsets.only(bottom: 12),
                            itemBuilder: (context, i) {
                              if (_isSending && i == _messages.length) {
                                return _typingBubble();
                              }
                              if (i >= _messages.length) return const SizedBox.shrink();
                              final m = _messages[i];
                              if (m.role == 'system') {
                                return const SizedBox.shrink();
                              }
                              final isUser = m.role == 'user';
                              return Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  constraints: const BoxConstraints(maxWidth: 280),
                                  decoration: BoxDecoration(
                                    color: isUser ? const Color(0xFFFFF9AF) : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color.fromARGB(255, 21, 77, 113),
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

            // Input bar with icons inside capsule
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    border: InputBorder.none,
                    hintText: 'Ask Guideon',
                    hintStyle: const TextStyle(fontFamily: 'Comfortaa'),
                    prefixIcon: const Icon(Icons.add, color: Color(0xFF3DB5A6)),
                    suffixIcon: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Color(0xFF3DB5A6)),
                              ),
                            )
                          : const Icon(Icons.arrow_forward,
                              color: Color(0xFF3DB5A6)),
                      onPressed: _isSending ? null : _send,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(fontFamily: 'Comfortaa'),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GuideOnPillNav(
        currentIndex: 0,
        onItemSelected: (i) {
          if (i == 0) return; // Already on chat
          if (i == 1) {
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
