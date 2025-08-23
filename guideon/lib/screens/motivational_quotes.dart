import 'package:flutter/material.dart';
import 'dart:math' as math;
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

  final Color textPrimary = const Color(0xFF154D71);

  // Simple local motivational quotes list
  final List<String> _quotes = const [
    '"Believe you can and you\'re halfway there."\n— Theodore Roosevelt',
    '"It always seems impossible until it\'s done."\n— Nelson Mandela',
    '"Start where you are. Use what you have. Do what you can."\n— Arthur Ashe',
    '"Small deeds done are better than great deeds planned."\n— Peter Marshall',
  ];

  String get _todaysQuote => _quotes[DateTime.now().weekday % _quotes.length];

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
      // Mark quote viewed as a daily task
      DailyTasksService.instance.mark('quoteViewed');
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
                  'Motivational',
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
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
