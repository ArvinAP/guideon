import 'package:flutter/material.dart';
import '../services/daily_tasks_service.dart';
import '../services/auth_service.dart';
import '../models/user_data.dart';

class StreakPetPage extends StatefulWidget {
  const StreakPetPage({super.key});

  @override
  State<StreakPetPage> createState() => _StreakPetPageState();
}

class _StreakPetPageState extends State<StreakPetPage> {
  static const Color primaryBlue = Color(0xFF154D71);
  UserProgress? _progress;

  @override
  void initState() {
    super.initState();
    // Mark pet visited (idempotent)
    DailyTasksService.instance.mark('streakPetVisited');
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final data = await AuthService.getUserProgress(user.uid);
    if (!mounted) return;
    setState(() {
      if (data != null) {
        _progress = UserProgress(
          userId: data['userId'] ?? user.uid,
          currentStreak: data['currentStreak'] ?? 0,
          totalDays: data['totalDays'] ?? 30,
          currentDay: data['currentDay'] ?? 1,
          journalEntries: data['journalEntries'] ?? 0,
          quotesLiked: data['quotesLiked'] ?? 0,
          petPoints: data['petPoints'] ?? 0,
          petLevel: data['petLevel'] ??
              (((data['petPoints'] ?? 0) as int) ~/ 100) + 1,
          lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
          lastTaskDate: data['lastTaskDate']?.toDate(),
          lastDailyReset: data['lastDailyReset']?.toDate(),
          lastStreakIncrement: data['lastStreakIncrement']?.toDate(),
        );
      } else {
        _progress = UserProgress(
          userId: user.uid,
          currentStreak: 0,
          totalDays: 30,
          currentDay: 1,
          journalEntries: 0,
          quotesLiked: 0,
          petPoints: 0,
          petLevel: 1,
          lastUpdated: DateTime.now(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _progress;
    final int points = p?.petPoints ?? 0;
    final int level = p?.petLevel ?? 1;
    final int inLevel = points % 100;
    final int toNext = 100 - inLevel;
    final double frac = (inLevel.clamp(0, 100)) / 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFEAEFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAEFEF),
        elevation: 0,
        title: const Text(
          'Streak Pet',
          style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.bold,
              fontFamily: 'Coiny'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: primaryBlue),
            onPressed: _loadProgress,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFDFF7FF), Colors.white],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 8,
                      offset: Offset(0, 4),
                      color: Color(0x33000000)),
                ],
              ),
              child: Column(
                children: [
                  // Pet GIF
                  SizedBox(
                    height: 160,
                    child: Image.asset(
                      'lib/assets/pet/streakpet.gif',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Level $level',
                    style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Coiny'),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar with value/label
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      minHeight: 16,
                      value: frac,
                      backgroundColor: const Color(0xFFE6EEF3),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF2E86C1)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${inLevel}/100',
                    style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Comfortaa'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$toNext points to unlock the next look',
                    style: const TextStyle(
                        color: Colors.black45, fontFamily: 'Comfortaa'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Checklist similar to screenshot
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 8,
                      offset: Offset(0, 4),
                      color: Color(0x22000000)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grow your Pet',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                        fontFamily: 'Coiny'),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<DailyTasks>(
                    stream: DailyTasksService.instance.watchToday(),
                    builder: (context, snapshot) {
                      final t = snapshot.data ?? DailyTasks.empty('');
                      Widget row(String title, bool done, String subtitle) =>
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  done
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color:
                                      done ? Colors.green[700] : Colors.black26,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Comfortaa')),
                                      const SizedBox(height: 2),
                                      Text(subtitle,
                                          style: const TextStyle(
                                              color: Colors.black45,
                                              fontSize: 12,
                                              fontFamily: 'Comfortaa')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );

                      return Column(
                        children: [
                          row("Write a journal entry", t.journalDone,
                              "+10 growth points when all tasks are done"),
                          row("Read today's Bible verse", t.bibleRead,
                              "+10 when all tasks are done"),
                          row("View today's quote", t.quoteViewed,
                              "+10 when all tasks are done"),
                          row("Visit Streak Pet", t.streakPetVisited,
                              "+10 when all tasks are done"),
                          row("Use Chatbot", t.chatbotUsed,
                              "+10 when all tasks are done"),
                          row("Check Mood", t.moodChecked,
                              "+10 when all tasks are done"),
                        ],
                      );
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
