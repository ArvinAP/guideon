import 'package:flutter/material.dart';
import '../services/daily_tasks_service.dart';

class StreakPetPage extends StatelessWidget {
  const StreakPetPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mark pet visited (idempotent true flag)
    DailyTasksService.instance.mark('streakPetVisited');
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 239, 239),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 234, 239, 239),
        elevation: 0,
        title: const Text(
          'Streak Pet',
          style: TextStyle(color: Color(0xFF154D71), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF154D71)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🐑', style: TextStyle(fontSize: 96)),
            SizedBox(height: 16),
            Text('Your streak pet will evolve with your streak!',
                style: TextStyle(color: Color(0xFF154D71))),
          ],
        ),
      ),
    );
  }
}
