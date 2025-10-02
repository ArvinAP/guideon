import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/daily_tasks_service.dart';

class MotivationalQuotesPage extends StatefulWidget {
  const MotivationalQuotesPage({super.key});

  @override
  State<MotivationalQuotesPage> createState() => _MotivationalQuotesPageState();
}

class _MotivationalQuotesPageState extends State<MotivationalQuotesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isFront = false; // false = back image showing, true = front showing

  final Color headerColor = const Color(0xFF2E7AA1);
  final Color textPrimary = const Color(0xFF154D71);

  // Firestore-backed data
  List<_MotivItem> _filteredItems = [];
  List<String> _themes = const ['All', 'happy', 'neutral', 'excited', 'angry', 'sad'];
  String _selectedTheme = 'All';
  int _currentIndex = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _subscribe();
  }

  @override
  void dispose() {
    _controller.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _toggleCard() {
    // If there's an error, retry loading
    if (_errorMessage != null) {
      _subscribe();
      return;
    }
    
    if (_isFront) {
      _controller.reverse();
    } else {
      _controller.forward();
      // Mark quote viewed as a daily task only if we have quotes
      if (_filteredItems.isNotEmpty) {
        DailyTasksService.instance.mark('quoteViewed');
        // advance to another quote within the filtered theme
        final rand = math.Random();
        int next = _filteredItems.length == 1 ? 0 : rand.nextInt(_filteredItems.length);
        if (next == _currentIndex && _filteredItems.length > 1) {
          next = (next + 1) % _filteredItems.length;
        }
        setState(() => _currentIndex = next);
      }
    }
    setState(() => _isFront = !_isFront);
  }

  void _subscribe() {
    _sub?.cancel();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final sel = _selectedTheme.trim();
    final selLower = sel.toLowerCase();
    
    try {
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('quotes');
      
      // Improved query logic for theme filtering
      if (selLower != 'all' && selLower.isNotEmpty) {
        // Try multiple variations of the theme for better matching
        final variations = [
          selLower,                                           // lowercase: "happy"
          selLower[0].toUpperCase() + selLower.substring(1), // Capitalized: "Happy"
          selLower.toUpperCase(),                            // All caps: "HAPPY"
        ];
        q = q.where('themes', arrayContainsAny: variations);
      }
      
      _sub = q.snapshots().listen(
        (snap) {
          try {
            final items = snap.docs.map((d) {
              final data = d.data();
              final text = (data['text'] ?? '').toString().trim();
              final author = (data['author'] ?? '').toString().trim();
              final themes = _parseThemes(data['themes']);
              
              // Only include quotes with actual text content
              if (text.isEmpty) return null;
              
              return _MotivItem(text: text, author: author, themes: themes);
            }).where((e) => e != null).cast<_MotivItem>().toList();

            setState(() {
              _filteredItems = items;
              _currentIndex = _filteredItems.isEmpty ? 0 : _currentIndex % _filteredItems.length;
              _isLoading = false;
              _errorMessage = null;
            });
            // Keep the filter strict even if empty
          } catch (e) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Error processing quotes: ${e.toString()}';
            });
          }
        },
        onError: (error) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load quotes from database: ${error.toString()}';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: ${e.toString()}';
      });
    }
  }


  List<String> _parseThemes(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  String get _currentText {
    if (_isLoading) return 'Loading quotes...';
    if (_errorMessage != null) return 'Error: $_errorMessage\n\nTap to retry.';
    if (_filteredItems.isEmpty) {
      if (_selectedTheme.toLowerCase() == 'all') {
        return 'No quotes found in database.\n\nPlease add some quotes through the admin panel.';
      } else {
        return 'No quotes found for "$_selectedTheme".\n\nTry selecting "All" or a different feeling.';
      }
    }
    
    final it = _filteredItems[_currentIndex];
    final author = it.author.isNotEmpty ? '\n\n— ${it.author}' : '';
    return '${it.text}$author';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED), // Cream background to match design
      body: SafeArea(
        child: Stack(
          children: [
            // Close button
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Title
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Motivational\nquotes',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF4A100), // Orange color to match design
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Coiny',
                    height: 1.1, // Tighter line spacing
                  ),
                ),
              ),
            ),

            // Themes dropdown
            Positioned(
              top: 90,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTheme,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: _themes
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t, style: const TextStyle(fontFamily: 'Comfortaa')),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() => _selectedTheme = val);
                            _subscribe();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status indicator (hide count when loaded)
                    if (_isLoading)
                      const Text(
                        'Loading...',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      )
                    else if (_errorMessage != null)
                      const Text(
                        'Error - Tap card to retry',
                        style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                      )
                    else
                      const SizedBox.shrink(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Card area
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                child: AspectRatio(
                  aspectRatio: 3 / 4.6,
                  child: GestureDetector(
                    onTap: _toggleCard,
                    onHorizontalDragEnd: (details) {
                      final v = details.velocity.pixelsPerSecond.dx;
                      if (v > 0) {
                        if (!_isFront) _toggleCard();
                      } else {
                        if (_isFront) _toggleCard();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final t = Curves.easeInOut.transform(_controller.value);
                        final angleBack = t * (math.pi / 2);
                        final angleFront = (-math.pi / 2) + t * (math.pi / 2);

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: const Color(0xFFED654A), width: 4), // Updated border color
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          // Clip inner rotating faces to rounded bounds
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Back face
                                Opacity(
                                  opacity: (1 - t * 2).clamp(0.0, 1.0),
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.0008)
                                      ..rotateY(angleBack),
                                    child: Image.asset(
                                      'lib/assets/images/motivational.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Front face
                                Opacity(
                                  opacity: ((t - 0.5) * 2).clamp(0.0, 1.0),
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.0008)
                                      ..rotateY(angleFront),
                                    child: Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.format_quote, size: 36, color: textPrimary.withOpacity(0.7)),
                                          const SizedBox(height: 12),
                                          Text(
                                            _currentText,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontFamily: 'Comfortaa',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Icon(Icons.format_quote, size: 36, color: textPrimary.withOpacity(0.7)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Hint
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      _isFront ? 'Swipe/tap to view the card back' : 'Swipe/tap to reveal today\'s quote',
                      style: TextStyle(color: textPrimary, fontFamily: 'Comfortaa', fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotivItem {
  final String text;
  final String author;
  final List<String> themes;
  _MotivItem({required this.text, required this.author, required this.themes});
}
