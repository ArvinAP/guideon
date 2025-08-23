import 'package:flutter/material.dart';
import '../components/buttons.dart';
import 'mood.dart';

class GreetingPage extends StatelessWidget {
  final String? username;
  const GreetingPage({super.key, this.username});

  @override
  Widget build(BuildContext context) {
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
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Sheep + Speech bubble
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sheep avatar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Simple sheep icon substitute
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFFFF9AF),
                          child: Text(
                            '🐑',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Speech bubble
                        Container(
                          constraints: const BoxConstraints(maxWidth: 220),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color.fromARGB(255, 21, 77, 113),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            "Hi ${username ?? 'User'}! I'm GuideOn!",
                            style: const TextStyle(
                              color: Color.fromARGB(255, 21, 77, 113),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Comfortaa',
                            ),
                          ),
                        ),
                      ],
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MoodPage(username: username),
                      ),
                    );
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
