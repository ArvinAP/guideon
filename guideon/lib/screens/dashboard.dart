import 'dart:async';
import 'package:flutter/material.dart';
import '../components/bottom_nav.dart';
import '../models/user_data.dart';
import '../services/auth_service.dart';
import '../services/daily_tasks_service.dart';
import 'user_profile.dart';
import 'streak_pet.dart';
import 'bible_verses.dart';
import 'motivational_quotes.dart';
import 'journal_list.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // App palette (from screenshot)
  static const Color bgLight = Color(0xFFEAEFEF); // page bg
  static const Color primaryBlue = Color(0xFF154D71); // title/icon
  static const Color accentBlue = Color(0xFF33A1E0); // section titles
  static const Color cardBorderBlue = Color(0xFF2EC4B6); // borders/accents
  static const Color streakPanel = Color(0xFFDBF1F5); // streak panel bg
  static const Color tileHeaderBlue = Color(0xFF2E6286); // tile top cap
  static const Color tileShadow = Color(0x33000000); // 20% black
  static const Color quotePink = Color(0xFFFFC4C9); // light pink
  static const Color cream = Color(0xFFFFF3E9); // streak pet panel

  UserProgress? userProgress;
  List<DailyTask> dailyTasks = [];
  Timer? _midnightTimer;
  DateTime? _lastAwardedDay;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final user = AuthService.currentUser;
    if (user == null) {
      // Redirect to login if not authenticated
      return;
    }

    try {
      // Get or initialize user progress from Firestore
      Map<String, dynamic>? progressData =
          await AuthService.getUserProgress(user.uid);

      if (progressData == null) {
        // Initialize progress for new user
        progressData = await AuthService.initializeUserProgress(user.uid);
      }

      final progress = UserProgress(
        userId: user.uid,
        currentStreak: progressData['currentStreak'] ?? 0,
        totalDays: progressData['totalDays'] ?? 30,
        currentDay: progressData['currentDay'] ?? 1,
        journalEntries: progressData['journalEntries'] ?? 0,
        quotesLiked: progressData['quotesLiked'] ?? 0,
        lastUpdated: progressData['lastUpdated']?.toDate() ?? DateTime.now(),
        lastTaskDate: progressData['lastTaskDate']?.toDate(),
        lastDailyReset: progressData['lastDailyReset']?.toDate(),
        lastStreakIncrement: progressData['lastStreakIncrement']?.toDate(),
      );

      setState(() {
        userProgress = progress;
        _updateDailyTasks(progress);
      });
      _scheduleMidnightReset();
    } catch (e) {
      // Fallback to default data if Firestore fails
      final progress = UserProgress(
        userId: user.uid,
        currentStreak: 0,
        totalDays: 30,
        currentDay: 1,
        journalEntries: 0,
        quotesLiked: 0,
        lastUpdated: DateTime.now(),
      );
      setState(() {
        userProgress = progress;
        _updateDailyTasks(progress);
      });
      _scheduleMidnightReset();
    }
  }

  Future<void> _updateUserProgress() async {
    final user = AuthService.currentUser;
    final progress = userProgress;
    if (user == null || progress == null) return;

    final progressData = {
      'userId': progress.userId,
      'currentStreak': progress.currentStreak,
      'totalDays': progress.totalDays,
      'currentDay': progress.currentDay,
      'journalEntries': progress.journalEntries,
      'quotesLiked': progress.quotesLiked,
      'lastTaskDate': progress.lastTaskDate,
      'lastDailyReset': progress.lastDailyReset,
      'lastStreakIncrement': progress.lastStreakIncrement,
    };

    await AuthService.updateUserProgress(user.uid, progressData);
  }

  // Midnight reset ---------------------------------------------------------
  DateTime _nextMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    final duration = _nextMidnight().difference(DateTime.now());
    _midnightTimer = Timer(duration, () {
      _resetDailyTasks();
      _scheduleMidnightReset(); // reschedule for next day
    });
  }

  void _updateDailyTasks(UserProgress progress) {
    dailyTasks = [
      DailyTask(
        id: '1',
        title: 'Write a\nJournal\nentry',
        description: 'Daily reflection',
        currentCount: 0, // Reset daily count
        targetCount: 1,
        isCompleted: false,
        type: TaskType.journal,
      ),
      DailyTask(
        id: '2',
        title: 'Like 5\nQuotes',
        description: 'Motivational quotes',
        currentCount: 0, // Reset daily count
        targetCount: 5,
        isCompleted: false,
        type: TaskType.quotes,
      ),
    ];
  }

  void _resetDailyTasks() {
    final progress = userProgress;
    if (progress == null) return;
    final now = DateTime.now();
    setState(() {
      // Reset daily tasks
      _updateDailyTasks(progress);
      userProgress = progress.copyWith(
        lastDailyReset: now,
        lastUpdated: now,
      );
    });
    _updateUserProgress();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = userProgress;

    if (progress == null) {
      return Scaffold(
        backgroundColor: bgLight,
        body: const Center(
          child: CircularProgressIndicator(
            color: primaryBlue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - exact match to Figma
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'GuideOn',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      fontFamily: 'Coiny',
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UserProfilePage()),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Streak Goal Section - exact match
              const Text(
                'Streak Goal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accentBlue,
                  fontFamily: 'Coiny',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFDFF7FF), Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: tileShadow),
                  ],
                ),
                child: Column(
                  children: [
                    // Derive active week from currentStreak to avoid highlighting before any completion
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        final derivedWeek = ((progress.currentStreak + 6) ~/ 7).clamp(0, 4);
                        bool isActive = index < derivedWeek;
                        return Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isActive ? tileHeaderBlue : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: tileHeaderBlue,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(blurRadius: 4, offset: Offset(0, 2), color: tileShadow),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : tileHeaderBlue,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${progress.currentStreak}/${progress.totalDays} DAYS',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Daily Tasks Section
              const Text(
                'Daily Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accentBlue,
                  fontFamily: 'Coiny',
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<DailyTasks>(
                stream: DailyTasksService.instance.watchToday(),
                builder: (context, snapshot) {
                  final today = snapshot.data ?? DailyTasks.empty('');

                  // Auto-award 1 day when all daily tasks are completed for the day
                  final now = DateTime.now();
                  final ymd = DateTime(now.year, now.month, now.day);
                  final allDone = today.journalDone &&
                      today.bibleRead &&
                      today.quoteViewed &&
                      today.streakPetVisited &&
                      today.chatbotUsed &&
                      today.moodChecked;

                  if (allDone && userProgress != null) {
                    final lastInc = userProgress!.lastStreakIncrement;
                    final alreadyAwardedToday = lastInc != null &&
                        UserProgress.isSameDay(lastInc, ymd);
                    final guardAwarded = _lastAwardedDay != null &&
                        UserProgress.isSameDay(_lastAwardedDay!, ymd);
                    if (!alreadyAwardedToday && !guardAwarded) {
                      // Increment streak day (max 30) and update week box 1..4
                      final nextStreak = (userProgress!.currentStreak + 1).clamp(0, userProgress!.totalDays);
                      final week = ((nextStreak + 6) ~/ 7).clamp(1, 4);
                      setState(() {
                        userProgress = userProgress!.copyWith(
                          currentStreak: nextStreak,
                          currentDay: week,
                          lastStreakIncrement: ymd,
                          lastTaskDate: ymd,
                          lastUpdated: ymd,
                        );
                        _lastAwardedDay = ymd;
                      });
                      _updateUserProgress();
                    }
                  }
                  Widget tile({
                    required String title,
                    required bool done,
                    required VoidCallback onTap,
                    required List<Color> gradient,
                    String? subtitle,
                  }) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: onTap,
                        child: Container(
                          height: 170,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradient,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(blurRadius: 8, offset: Offset(0, 4), color: tileShadow),
                            ],
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                // Full-width top cap inside the card (no light bg edges)
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: tileHeaderBlue,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(24),
                                        topRight: Radius.circular(24),
                                        bottomLeft: Radius.circular(18),
                                        bottomRight: Radius.circular(18),
                                      ),
                                      boxShadow: [
                                        BoxShadow(blurRadius: 6, offset: Offset(0, 3), color: tileShadow),
                                      ],
                                    ),
                                  ),
                                ),
                                // Content
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 14),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.center,
                                          child: Text(
                                            title,
                                            textAlign: TextAlign.center,
                                            softWrap: true,
                                            maxLines: 2,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (subtitle != null)
                                        Text(
                                          subtitle,
                                          style: const TextStyle(color: Colors.black54),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 6),
                                      Icon(
                                        done ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: done ? Colors.green[700] : Colors.black38,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          tile(
                            title: 'Write a\nJournal\nentry',
                            subtitle: '${today.journalCount} today',
                            done: today.journalDone,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const JournalListPage()),
                              );
                            },
                            gradient: const [Color(0xFFDFF7FF), Colors.white],
                          ),
                          const SizedBox(width: 16),
                          tile(
                            title: 'Read today\'s\nBible verse',
                            done: today.bibleRead,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BibleVersesPage()),
                              );
                            },
                            gradient: const [Color(0xFFD8F1FF), Colors.white],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          tile(
                            title: 'View today\'s\nQuote',
                            done: today.quoteViewed,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MotivationalQuotesPage()),
                              );
                            },
                            gradient: const [Color(0xFFD8F1FF), Color(0xFFFFDDE3)],
                          ),
                          const SizedBox(width: 16),
                          tile(
                            title: 'Visit\nStreak Pet',
                            done: today.streakPetVisited,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const StreakPetPage()),
                              );
                            },
                            gradient: const [Color(0xFFFFF0E6), Colors.white],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          tile(
                            title: 'Use\nChatbot',
                            done: today.chatbotUsed,
                            onTap: () {
                              DailyTasksService.instance.mark('chatbotUsed');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Navigate to: Chatbot')),
                              );
                            },
                            gradient: const [Color(0xFFDFF7FF), Colors.white],
                          ),
                          const SizedBox(width: 16),
                          tile(
                            title: 'Check\nMood',
                            done: today.moodChecked,
                            onTap: () {
                              DailyTasksService.instance.mark('moodChecked');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Mood checked!')),
                              );
                            },
                            gradient: const [Color(0xFFDFF7FF), Colors.white],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Checkout Section - exact match
              const Text(
                'Checkout your Streak pet!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accentBlue,
                  fontFamily: 'Coiny',
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StreakPetPage()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: cream,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1),
                    boxShadow: const [
                      BoxShadow(blurRadius: 6, offset: Offset(0, 3), color: tileShadow),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🐑',
                      style: TextStyle(fontSize: 64),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 120), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: GuideOnBottomNav(
        currentIndex: -1, // No specific tab active on dashboard
        onItemSelected: (i) {
          // TODO: Implement proper navigation to each section
          if (i == 0) {
            // Navigate to chatbot
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Navigate to: Chatbot')),
            );
          } else if (i == 1) {
            // Navigate to Bible Verses
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BibleVersesPage()),
            );
          } else if (i == 2) {
            // Navigate to Motivational Quotes
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MotivationalQuotesPage()),
            );
          } else if (i == 3) {
            // Navigate to Journal list
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JournalListPage()),
            );
          }
        },
      ),
    );
  }
}
