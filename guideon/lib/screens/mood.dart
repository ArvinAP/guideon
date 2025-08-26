import 'package:flutter/material.dart';
import '../components/buttons.dart';
import 'chatbot.dart';

class MoodOption {
  final String label;
  final String emoji;
  final Color color;
  const MoodOption(this.label, this.emoji, this.color);
}

class MoodPage extends StatefulWidget {
  final String? username;
  const MoodPage({super.key, this.username});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  final List<MoodOption> moods = const [
    MoodOption('Angry', '😡', Color(0xFFFF6B6B)),
    MoodOption('Sad', '😞', Color(0xFFFFA559)),
    MoodOption('Neutral', '😐', Color(0xFFFFD166)),
    MoodOption('Happy', '😊', Color(0xFF2EC4B6)),
    MoodOption('Excited', '😆', Color(0xFF5B6BFF)),
  ];

  int index = 3; // default to Happy

  void prev() =>
      setState(() => index = (index - 1 + moods.length) % moods.length);
  void next() => setState(() => index = (index + 1) % moods.length);

  @override
  Widget build(BuildContext context) {
    final mood = moods[index];
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 239, 239),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),

            // Header with sheep and bubble (below back button)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lamb image
                  Image.asset(
                    'lib/assets/images/guideon_lamb.png',
                    height: 120,
                    width: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 240),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFF7FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color.fromARGB(255, 21, 77, 113),
                        width: 1.2,
                      ),
                    ),
                    child: const Text(
                      'How would you describe your mood today?',
                      style: TextStyle(
                        color: Color.fromARGB(255, 21, 77, 113),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Comfortaa',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center the mood carousel and feeling text vertically
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mood carousel centered in the middle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_left, size: 32),
                        onPressed: prev,
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: mood.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          mood.emoji,
                          style: const TextStyle(fontSize: 44),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_right, size: 32),
                        onPressed: next,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'I feel ${mood.label}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 21, 77, 113),
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                ],
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Center(
                child: PrimaryButton(
                  text: 'Continue',
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatbotPage(
                          mood: mood.label,
                          username: widget.username,
                        ),
                      ),
                    );
                    // Bubble the engagement result (true/false) back to Dashboard
                    if (!context.mounted) return;
                    Navigator.pop(context, res == true);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
