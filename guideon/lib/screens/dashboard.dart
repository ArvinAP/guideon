import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'mood.dart';
import 'admin_profile.dart';

class DashboardPage extends StatefulWidget {
  final bool suppressAutoChat;
  const DashboardPage({super.key, this.suppressAutoChat = false});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // App palette (from screenshot)
  static const Color bgLight = Color(0xFFFFF9ED); // page bg to match screenshot
  static const Color primaryBlue = Color(0xFFF4A100); // title/icon (orange)
  static const Color accentBlue = Color(0xFF2EC4B6); // section titles (teal)
  static const Color tileShadow = Color(0x33000000); // 20% black

  UserProgress? userProgress;
  List<DailyTask> dailyTasks = [];
  Timer? _midnightTimer;
  bool _chatbotAttemptedToday =
      false; // prevent repeated launches in one session
  String _userRole = 'user'; // Default to user role
  bool _showTaskTips = true; // Controls the visibility of the how-to popup
  String? _photoUrl; // User profile photo URL

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
      // Get user profile to check role
      final profileData = await AuthService.getUserProfile(user.uid);
      final role = profileData?['role'] ?? 'user';
      final String? photoUrl = (profileData?['photoUrl'] as String?)?.trim();

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
        petPoints: progressData['petPoints'] ?? 0,
        petLevel: progressData['petLevel'] ??
            (((progressData['petPoints'] ?? 0) as int) ~/ 100) + 1,
        lastUpdated: progressData['lastUpdated']?.toDate() ?? DateTime.now(),
        lastTaskDate: progressData['lastTaskDate']?.toDate(),
        lastDailyReset: progressData['lastDailyReset']?.toDate(),
        lastStreakIncrement: progressData['lastStreakIncrement']?.toDate(),
      );

      // Check if streak should be reset due to missed days
      final updatedProgress = _checkAndResetStreakIfNeeded(progress);
      
      setState(() {
        userProgress = updatedProgress;
        _userRole = role.toString();
        _photoUrl = (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null;
        _updateDailyTasks(updatedProgress);
      });
      
      // Update progress if it was modified (check by comparing streak values)
      if (updatedProgress.currentStreak != progress.currentStreak || 
          updatedProgress.currentDay != progress.currentDay) {
        _updateUserProgress();
      }
      
      _scheduleMidnightReset();
      _maybeShowDailyChatbot();
    } catch (e) {
      // Fallback to default data if Firestore fails
      final progress = UserProgress(
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
      setState(() {
        userProgress = progress;
        _updateDailyTasks(progress);
      });
      _scheduleMidnightReset();
      _maybeShowDailyChatbot();
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
      'petPoints': progress.petPoints,
      'petLevel': progress.petLevel,
      'lastTaskDate': progress.lastTaskDate,
      'lastDailyReset': progress.lastDailyReset,
      'lastStreakIncrement': progress.lastStreakIncrement,
    };

    await AuthService.updateUserProgress(user.uid, progressData);
  }

  UserProgress _checkAndResetStreakIfNeeded(UserProgress progress) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastIncrement = progress.lastStreakIncrement;
    
    // If no last increment date, return as is (new user)
    if (lastIncrement == null) {
      return progress;
    }
    
    final lastIncrementDay = DateTime(lastIncrement.year, lastIncrement.month, lastIncrement.day);
    final daysSinceLastIncrement = today.difference(lastIncrementDay).inDays;
    
    // If more than 1 day has passed since last increment, reset streak
    if (daysSinceLastIncrement > 1) {
      return progress.copyWith(
        currentStreak: 0,
        currentDay: 1,
        lastUpdated: now,
      );
    }
    
    return progress;
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
                      if (_userRole == 'super_admin') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminProfilePage()),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UserProfilePage()),
                        );
                      }
                    },
                    child: _photoUrl != null && _photoUrl!.isNotEmpty
                        ? CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: NetworkImage(_photoUrl!),
                          )
                        : Container(
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

              // Streak Goal Section - original structure
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFF4A100), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Show week progress based on current streak
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        final weekNumber = index + 1;
                        final isActiveWeek = progress.currentDay == weekNumber;
                        final isCompletedWeek = progress.currentDay > weekNumber;
                        
                        return Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isCompletedWeek 
                                ? const Color(0xFF2EC4B6) // Completed weeks - teal
                                : isActiveWeek 
                                    ? const Color(0xFFF4A100) // Active week - orange
                                    : Colors.white, // Future weeks - white
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF4A100),
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isCompletedWeek
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24,
                                  )
                                : Text(
                                    '$weekNumber',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isActiveWeek 
                                          ? Colors.white 
                                          : const Color(0xFFF4A100),
                                      fontFamily: 'Coiny',
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${progress.currentStreak} \\ ${progress.totalDays} ',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Coiny',
                            ),
                          ),
                          const TextSpan(
                            text: 'DAYS',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              fontFamily: 'Comfortaa',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Daily Tasks Section - original structure
              const Text(
                'Daily Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accentBlue,
                  fontFamily: 'Coiny',
                ),
              ),
              if (_showTaskTips) ...[
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFFC3EFB6), width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 14, 48, 14),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How to finish Daily Tasks',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: accentBlue,
                              fontFamily: 'Coiny',
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Tap any tile to open its page and complete it.\n'
                            '• Finish all 6 tasks today (Journal, Bible, Quote, Streak Pet, Chatbot, Mood).\n'
                            '• Complete all tasks before midnight to maintain your streak!',
                            style: TextStyle(
                                fontFamily: 'Comfortaa', color: Colors.black87),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Benefits for your Streak Pet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: accentBlue,
                              fontFamily: 'Coiny',
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Completing all tasks adds +1 to your streak.\n'
                            '• Each completed day gives +10 pet points.\n'
                            '• Your pet levels up every 100 points.\n'
                            '• Missing a day resets your streak to 0!',
                            style: TextStyle(
                                fontFamily: 'Comfortaa', color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() => _showTaskTips = false);
                        },
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xFFC3EFB6),
                          child: Icon(Icons.close, size: 16, color: Color(0xFF154D71)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
                    final alreadyAwardedToday =
                        lastInc != null && UserProgress.isSameDay(lastInc, ymd);
                    
                    // Only award if we haven't already awarded today
                    if (!alreadyAwardedToday) {
                      // Defer state updates to after build to avoid setState() during build
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        
                        // Increment streak day (max 30)
                        final nextStreak = (userProgress!.currentStreak + 1)
                            .clamp(0, userProgress!.totalDays);
                        
                        // Award pet points (+10) and compute level (every 100)
                        final nextPoints = userProgress!.petPoints + 10;
                        final nextLevel = (nextPoints ~/ 100) + 1;
                        
                        // Calculate current week (1-4) based on streak
                        final week = ((nextStreak - 1) ~/ 7 + 1).clamp(1, 4);
                        
                        setState(() {
                          userProgress = userProgress!.copyWith(
                            currentStreak: nextStreak,
                            currentDay: week,
                            petPoints: nextPoints,
                            petLevel: nextLevel,
                            lastStreakIncrement: ymd,
                            lastTaskDate: ymd,
                            lastUpdated: now,
                          );
                        });
                        
                        // Update Firestore with new progress
                        _updateUserProgress();
                        
                        // Show success feedback to user
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '🎉 Daily tasks completed! +10 pet points earned! Streak: $nextStreak days',
                                style: const TextStyle(fontFamily: 'Comfortaa'),
                              ),
                              backgroundColor: const Color(0xFF2EC4B6),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      });
                    }
                  }
                  Widget tile({
                    required String id,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Container(
                            // inner border to simulate inside stroke (C3EFB6, 5px)
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9ED), // FFF9ED fill
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Color(0xFFC3EFB6), width: 5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.center,
                                      child: Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                        maxLines: 3,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          height: 1.2,
                                          fontFamily: 'Comfortaa',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (subtitle != null)
                                    Text(
                                      subtitle,
                                      style: const TextStyle(
                                        color: Color(0xFF154D71), // deep teal
                                        fontFamily: 'Coiny',
                                        fontSize: 18,
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Icon(
                                    done ? Icons.check_circle : Icons.check_circle_outline,
                                    color: done
                                        ? const Color(0xFF2EC4B6) // teal when done
                                        : const Color(0xFFC3EFB6), // light green outline when not done
                                    size: 26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            tile(
                              id: 'journal',
                              title: 'Write a\nJournal\nentry',
                              done: today.journalDone,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const JournalListPage()),
                                );
                              },
                              gradient: const [Color(0xFFDFF7FF), Colors.white],
                            ),
                            const SizedBox(width: 16),
                            tile(
                              id: 'bible',
                              title: 'Read today\'s\nBible verse',
                              done: today.bibleRead,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const BibleVersesPage()),
                                );
                              },
                              gradient: const [Color(0xFFD8F1FF), Colors.white],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.transparent, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            tile(
                              id: 'quote',
                              title: 'View today\'s\nQuote',
                              done: today.quoteViewed,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const MotivationalQuotesPage()),
                                );
                              },
                              gradient: const [
                                Color(0xFFD8F1FF),
                                Color(0xFFFFDDE3)
                              ],
                            ),
                            const SizedBox(width: 16),
                            tile(
                              id: 'pet',
                              title: 'Visit\nStreak Pet',
                              done: today.streakPetVisited,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const StreakPetPage()),
                                );
                              },
                              gradient: const [Color(0xFFFFF0E6), Colors.white],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.transparent, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            tile(
                              id: 'chatbot',
                              title: 'Use\nChatbot',
                              done: today.chatbotUsed,
                              onTap: _openMoodChatFlow,
                              gradient: const [Color(0xFFDFF7FF), Colors.white],
                            ),
                            const SizedBox(width: 16),
                            tile(
                              id: 'mood',
                              title: 'Check\nMood',
                              done: today.moodChecked,
                              onTap: _openMoodChatFlow,
                              gradient: const [Color(0xFFDFF7FF), Colors.white],
                            ),
                          ],
                        ),
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
                    color: const Color.fromARGB(255, 245, 246, 249),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1),
                    boxShadow: const [
                      BoxShadow(
                          blurRadius: 6,
                          offset: Offset(0, 3),
                          color: tileShadow),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'lib/assets/pet/streakpet.gif',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 120), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 0,
        child: GuideOnPillNav(
          currentIndex: -1, // No specific tab active on dashboard
          onItemSelected: (i) {
            if (i == 0) {
              _openMoodChatFlow();
            } else if (i == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BibleVersesPage()),
              );
            } else if (i == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MotivationalQuotesPage()),
              );
            } else if (i == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JournalListPage()),
              );
            }
          },
        ),
      ),
    );
  }

  // --- Daily Chatbot auto-open (6:00 AM Philippines time) ------------------
  DateTime _manilaNow() {
    // Manila (Asia/Manila) is UTC+8, no DST. Compute relative to UTC to be consistent
    return DateTime.now().toUtc().add(const Duration(hours: 8));
  }

  Future<void> _maybeShowDailyChatbot() async {
    if (widget.suppressAutoChat) return; // skip when explicitly suppressed
    try {
      final nowPh = _manilaNow();
      final shownKey = 'chatbot_last_shown_ymd';
      final ymd =
          '${nowPh.year}-${nowPh.month.toString().padLeft(2, '0')}-${nowPh.day.toString().padLeft(2, '0')}';
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getString(shownKey);

      final isAfterSix = nowPh.hour > 6 ||
          (nowPh.hour == 6 && (nowPh.minute > 0 || nowPh.second > 0));
      if (isAfterSix && lastShown != ymd && !_chatbotAttemptedToday) {
        _chatbotAttemptedToday = true; // only once per app session
        // Defer navigation to after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final username = AuthService.currentUser?.displayName;
          // Show Mood selection first; it will forward to Chatbot and return true when engaged
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MoodPage(username: username),
            ),
          );
          // If user engaged/completed, store today's date to stop further prompts today
          if (result == true) {
            await prefs.setString(shownKey, ymd);
          }
        });
      }
    } catch (_) {
      // Swallow errors to keep dashboard resilient
    }
  }

  Future<void> _loadTaskTipsPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nowPh = _manilaNow();
      final ymd =
          '${nowPh.year}-${nowPh.month.toString().padLeft(2, '0')}-${nowPh.day.toString().padLeft(2, '0')}';
      const key = 'task_tips_hidden_ymd';
      final hiddenYmd = prefs.getString(key);
      final shouldShow = hiddenYmd != ymd; // show unless already hidden today
      if (!mounted) return;
      setState(() {
        _showTaskTips = shouldShow;
      });
    } catch (_) {
      // If prefs fails, keep default true so tips still show
    }
  }

  Future<void> _hideTaskTipsToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nowPh = _manilaNow();
      final ymd =
          '${nowPh.year}-${nowPh.month.toString().padLeft(2, '0')}-${nowPh.day.toString().padLeft(2, '0')}';
      const key = 'task_tips_hidden_ymd';
      await prefs.setString(key, ymd);
    } catch (_) {
      // Ignore errors; UI already hid the tips in this session
    }
  }

  Future<void> _openMoodChatFlow() async {
    final username = AuthService.currentUser?.displayName;
    final res = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MoodPage(username: username),
      ),
    );
    if (res == true) {
      // User engaged with chatbot after selecting mood
      DailyTasksService.instance.mark('moodChecked');
      DailyTasksService.instance.mark('chatbotUsed');
    }
  }
}
