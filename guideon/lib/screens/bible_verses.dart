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
  Set<String> _debugThemes = {};

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
    if (_isFront) {
      _controller.reverse();
    } else {
      _controller.forward();
      // Mark verse viewed as a daily task
      DailyTasksService.instance.mark('bibleRead');
      // advance to another verse within the filtered theme
      if (_filteredItems.isNotEmpty) {
        // choose a random next index different from current when possible
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
    final sel = _selectedTheme.trim();
    final selLower = sel.toLowerCase();
    final selUpper = sel.toUpperCase();
    final selCap = sel.isEmpty ? sel : selLower[0].toUpperCase() + selLower.substring(1);
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('verses');
    if (selLower != 'all' && selLower.isNotEmpty) {
      q = q.where('themes', arrayContainsAny: [selLower, selCap, selUpper]);
    }
    _sub = q.snapshots().listen((snap) {
      final items = snap.docs.map((d) {
        final data = d.data();
        final text = (data['text'] ?? '').toString();
        final ref = (data['reference'] ?? data['ref'] ?? '').toString();
        final themes = _parseThemes(data['themes']);
        return _VerseItem(text: text, reference: ref, themes: themes);
      }).where((e) => e.text.isNotEmpty).toList();

      setState(() {
        _filteredItems = items;
        _debugThemes = items
            .expand((e) => e.themes)
            .map((t) => t.toString().toLowerCase().trim())
            .where((t) => t.isNotEmpty)
            .toSet();
        _currentIndex = _filteredItems.isEmpty ? 0 : _currentIndex % _filteredItems.length;
      });
      // Debug
      // ignore: avoid_print
      debugPrint('Verses (server-filtered) loaded: ${_filteredItems.length} for theme "$selLower"');
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
    if (_filteredItems.isEmpty) return 'No verses found for this theme.';
    final it = _filteredItems[_currentIndex];
    final ref = it.reference.isNotEmpty ? '\n— ${it.reference}' : '';
    return '${it.text}$ref';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEFEF),
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
                    color: Color(0xFF154D71),
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
                    // Tiny debug counter (remove later if desired)
                    Text(
                      'Loaded: ${_filteredItems.length}',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Themes seen: ${_debugThemes.join(', ')}',
                      style: const TextStyle(color: Colors.black45, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF154D71), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          // Clip inner rotating faces to rounded bounds
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
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
                                    child: Image.asset(
                                      'lib/assets/images/bible verse card.png',
                                      fit: BoxFit.cover,
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
