import 'package:flutter/material.dart';
import 'dart:math' as math;
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

  // Simple local quotes list. Replace with Firestore later if needed.
  final List<String> _quotes = const [
    '"I can do all things through Christ who strengthens me."\n— Philippians 4:13',
    '"The Lord is my shepherd; I shall not want."\n— Psalm 23:1',
    '"Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go."\n— Joshua 1:9',
    '"Cast all your anxiety on Him because He cares for you."\n— 1 Peter 5:7',
  ];

  String get _todaysQuote => _quotes[DateTime.now().day % _quotes.length];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) {
      _controller.reverse();
    } else {
      _controller.forward();
      // Mark verse viewed as a daily task
      DailyTasksService.instance.mark('bibleRead');
    }
    setState(() => _isFront = !_isFront);
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
                                            _todaysQuote,
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

class _CardBack extends StatelessWidget {
  final String imagePath;
  const _CardBack({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final String quote;
  final Color textPrimary;
  const _CardFront({super.key, required this.quote, required this.textPrimary});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.format_quote, size: 36, color: textPrimary.withOpacity(0.7)),
          const SizedBox(height: 12),
          Text(
            quote,
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
    );
  }
}
