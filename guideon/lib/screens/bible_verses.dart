import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/daily_tasks_service.dart';

class BibleVersesPage extends StatefulWidget {
  const BibleVersesPage({super.key});

  @override
  State<BibleVersesPage> createState() => _BibleVersesPageState();
}

class _BibleVersesPageState extends State<BibleVersesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isFront = false; // false = back image showing, true = front showing

  final Color headerColor = const Color(0xFF2E7AA1);
  final Color textPrimary = const Color(0xFF154D71);

  // Firestore-backed data
  List<_VerseItem> _filteredItems = [];
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
      // Mark verse viewed as a daily task only if we have verses
      if (_filteredItems.isNotEmpty) {
        DailyTasksService.instance.mark('bibleRead');
        // advance to another verse within the filtered theme
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
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('verses');
      
      // Improved query logic for theme filtering
      if (selLower != 'all' && selLower.isNotEmpty) {
        // Try multiple variations of the theme for better matching
        final variations = [
          selLower,                                           // lowercase: "happy"
          selLower[0].toUpperCase() + selLower.substring(1), // Capitalized: "Happy"
          selLower.toUpperCase(),                            // All caps: "HAPPY"
        ];
        q = q.where('themes', arrayContainsAny: variations);
        debugPrint('Filtering verses for theme variations: $variations');
      }
      
      _sub = q.snapshots().listen(
        (snap) {
          try {
            final items = snap.docs.map((d) {
              final data = d.data();
              final text = (data['text'] ?? '').toString().trim();
              final ref = (data['reference'] ?? data['ref'] ?? '').toString().trim();
              final themes = _parseThemes(data['themes']);
              
              // Only include verses with actual text content
              if (text.isEmpty) return null;
              
              return _VerseItem(text: text, reference: ref, themes: themes);
            }).where((e) => e != null).cast<_VerseItem>().toList();

            setState(() {
              _filteredItems = items;
              _currentIndex = _filteredItems.isEmpty ? 0 : _currentIndex % _filteredItems.length;
              _isLoading = false;
              _errorMessage = null;
            });
            
            debugPrint('Verses loaded: ${_filteredItems.length} for theme "$selLower"');
            
            // Don't fallback to all verses - keep the filter strict
            if (_filteredItems.isEmpty && selLower != 'all') {
              debugPrint('No verses found for theme "$selLower". Try a different theme or check your database.');
            }
          } catch (e) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Error processing verses: ${e.toString()}';
            });
            debugPrint('Error processing verses: $e');
          }
        },
        onError: (error) {
          debugPrint('Firestore error: $error');
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load verses from database: ${error.toString()}';
          });
        },
      );
    } catch (e) {
      debugPrint('Connection error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: ${e.toString()}';
      });
    }
  }

  void _loadAllVerses() {
    // Load all verses when 'All' theme is selected or as a fallback
    final selectedTheme = _selectedTheme.toLowerCase();
    
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('verses');
    
    // If a specific theme was selected but no results found, still try to filter
    if (selectedTheme != 'all' && selectedTheme.isNotEmpty) {
      final variations = [
        selectedTheme,
        selectedTheme[0].toUpperCase() + selectedTheme.substring(1),
        selectedTheme.toUpperCase(),
      ];
      query = query.where('themes', arrayContainsAny: variations);
      debugPrint('Fallback: Still filtering for theme variations: $variations');
    }
    
    query.limit(50).get().then((snap) {
      final items = snap.docs.map((d) {
        final data = d.data();
        final text = (data['text'] ?? '').toString().trim();
        final ref = (data['reference'] ?? data['ref'] ?? '').toString().trim();
        final themes = _parseThemes(data['themes']);
        
        if (text.isEmpty) return null;
        return _VerseItem(text: text, reference: ref, themes: themes);
      }).where((e) => e != null).cast<_VerseItem>().toList();

      setState(() {
        _filteredItems = items;
        _currentIndex = 0;
        _isLoading = false;
        _errorMessage = items.isEmpty ? 'No verses found for "$_selectedTheme"' : null;
      });
      
      debugPrint('Fallback: Loaded ${items.length} verses for theme "$selectedTheme"');
    }).catchError((error) {
      debugPrint('Fallback loading failed: $error');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load verses from database: ${error.toString()}';
      });
    });
  }



  List<String> _parseThemes(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      // Allow comma-separated string fallback
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  // Filtering is handled server-side via arrayContains; _filteredItems mirrors query results.

  String get _currentText {
    if (_isLoading) return 'Loading verses...';
    if (_errorMessage != null) return 'Error: $_errorMessage\n\nTap to retry.';
    if (_filteredItems.isEmpty) {
      if (_selectedTheme.toLowerCase() == 'all') {
        return 'No verses found in database.\n\nPlease add some verses through the admin panel.';
      } else {
        return 'No verses found for "$_selectedTheme".\n\nTry selecting "All" or a different feeling.';
      }
    }
    
    final it = _filteredItems[_currentIndex];
    final ref = it.reference.isNotEmpty ? '\n\n— ${it.reference}' : '';
    return '${it.text}$ref';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED), // Cream background to match design
      body: SafeArea(
        child: Stack(
          children: [
            // Close (back) button like the figma small X
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
                  'Bible Verses',
                  style: const TextStyle(
                    color: Color(0xFFF4A100), // Orange color to match design
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Coiny',
                  ),
                ),
              ),
            ),

            // Themes dropdown
            Positioned(
              top: 56,
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
                    // Status indicator
                    Text(
                      _isLoading 
                          ? 'Loading...' 
                          : _errorMessage != null 
                              ? 'Error - Tap card to retry'
                              : 'Loaded: ${_filteredItems.length}',
                      style: TextStyle(
                        color: _errorMessage != null ? Colors.red : Colors.black54, 
                        fontSize: 12,
                        fontWeight: _errorMessage != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card area
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: AspectRatio(
                  aspectRatio: 3 / 4.6, // tuned to look like your figma card
                  child: GestureDetector(
                    onTap: _toggleCard,
                    onHorizontalDragEnd: (details) {
                      final v = details.velocity.pixelsPerSecond.dx;
                      // Right swipe -> forward, Left swipe -> reverse
                      if (v > 0) {
                        if (!_isFront) _toggleCard();
                      } else {
                        if (_isFront) _toggleCard();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        // eased progress 0..1
                        final t = Curves.easeInOut.transform(_controller.value);
                        // Two-sided flip: back rotates 0..pi/2, front -pi/2..0
                        final angleBack = t * (math.pi / 2);
                        final angleFront = (-math.pi / 2) + t * (math.pi / 2);

                        // Outer static card shell (prevents stretching/shadow warping)
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: const Color(0xFF115280), width: 4), // Thicker border to match the card design
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
                                // Back face (first half)
                                Opacity(
                                  opacity: (1 - t * 2).clamp(0.0, 1.0),
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.0008)
                                      ..rotateY(angleBack),
                                    child: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: Image.asset(
                                        'lib/assets/images/bible verse card.png',
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                                // Front face (second half)
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

            // Small hint at bottom
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
                      _isFront ? 'Swipe/tap to view the card back' : 'Swipe/tap to reveal today\'s verse',
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

class _VerseItem {
  final String text;
  final String reference;
  final List<String> themes;
  _VerseItem({required this.text, required this.reference, required this.themes});
}
