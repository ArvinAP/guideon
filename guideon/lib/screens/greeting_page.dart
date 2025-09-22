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
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Greeting text above, sheep GIF centered below
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Speech bubble-like greeting
                  Container(
                    constraints: const BoxConstraints(maxWidth: 260),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color.fromARGB(255, 21, 77, 113),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      "Hi ${username ?? 'Username'}! I'm Guideon!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 21, 77, 113),
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Comfortaa',
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Centered sheep GIF
                  Image.asset(
                    'lib/assets/images/Wave.gif',
                    height: 180,
                    fit: BoxFit.contain,
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
