class UserProgress {
  final String userId;
  final int currentStreak;
  final int totalDays;
  final int currentDay;
  final int journalEntries;
  final int quotesLiked;
  final DateTime lastUpdated;
  final DateTime? lastTaskDate; // last day any task was completed
  final DateTime? lastDailyReset; // last time daily tasks were reset
  final DateTime? lastStreakIncrement; // last day we incremented streak

  UserProgress({
    required this.userId,
    required this.currentStreak,
    required this.totalDays,
    required this.currentDay,
    required this.journalEntries,
    required this.quotesLiked,
    required this.lastUpdated,
    this.lastTaskDate,
    this.lastDailyReset,
    this.lastStreakIncrement,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'] ?? '',
      currentStreak: json['currentStreak'] ?? 0,
      totalDays: json['totalDays'] ?? 0,
      currentDay: json['currentDay'] ?? 1,
      journalEntries: json['journalEntries'] ?? 0,
      quotesLiked: json['quotesLiked'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      lastTaskDate: json['lastTaskDate'] != null ? DateTime.parse(json['lastTaskDate']) : null,
      lastDailyReset: json['lastDailyReset'] != null ? DateTime.parse(json['lastDailyReset']) : null,
      lastStreakIncrement: json['lastStreakIncrement'] != null ? DateTime.parse(json['lastStreakIncrement']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'totalDays': totalDays,
      'currentDay': currentDay,
      'journalEntries': journalEntries,
      'quotesLiked': quotesLiked,
      'lastUpdated': lastUpdated.toIso8601String(),
      'lastTaskDate': lastTaskDate?.toIso8601String(),
      'lastDailyReset': lastDailyReset?.toIso8601String(),
      'lastStreakIncrement': lastStreakIncrement?.toIso8601String(),
    };
  }

  UserProgress copyWith({
    String? userId,
    int? currentStreak,
    int? totalDays,
    int? currentDay,
    int? journalEntries,
    int? quotesLiked,
    DateTime? lastUpdated,
    DateTime? lastTaskDate,
    DateTime? lastDailyReset,
    DateTime? lastStreakIncrement,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      totalDays: totalDays ?? this.totalDays,
      currentDay: currentDay ?? this.currentDay,
      journalEntries: journalEntries ?? this.journalEntries,
      quotesLiked: quotesLiked ?? this.quotesLiked,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastTaskDate: lastTaskDate ?? this.lastTaskDate,
      lastDailyReset: lastDailyReset ?? this.lastDailyReset,
      lastStreakIncrement: lastStreakIncrement ?? this.lastStreakIncrement,
    );
  }

  // Helpers
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class DailyTask {
  final String id;
  final String title;
  final String description;
  final int currentCount;
  final int targetCount;
  final bool isCompleted;
  final TaskType type;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.currentCount,
    required this.targetCount,
    required this.isCompleted,
    required this.type,
  });

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      currentCount: json['currentCount'] ?? 0,
      targetCount: json['targetCount'] ?? 1,
      isCompleted: json['isCompleted'] ?? false,
      type: TaskType.values.firstWhere(
        (e) => e.toString() == 'TaskType.${json['type']}',
        orElse: () => TaskType.journal,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'currentCount': currentCount,
      'targetCount': targetCount,
      'isCompleted': isCompleted,
      'type': type.toString().split('.').last,
    };
  }
}

enum TaskType { journal, quotes, bible, meditation }
