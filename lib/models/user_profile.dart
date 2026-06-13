import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/streak_utils.dart';

class DailyGoal {
  final String type; // 'lessons' or 'minutes'
  final int target;
  final int todayProgress;
  final String? lastUpdatedDate;
  final String? lastNotifiedDate;

  const DailyGoal({
    required this.type,
    required this.target,
    this.todayProgress = 0,
    this.lastUpdatedDate,
    this.lastNotifiedDate,
  });

  bool get isValid => (type == 'lessons' || type == 'minutes') && target > 0;

  String get unitLabel => type == 'minutes' ? 'minutes' : 'lessons';

  factory DailyGoal.fromMap(Map<String, dynamic> data) {
    return DailyGoal(
      type: data['type']?.toString() ?? 'lessons',
      target: (data['target'] ?? 0).toInt(),
      todayProgress: (data['todayProgress'] ?? 0).toInt(),
      lastUpdatedDate: data['lastUpdatedDate']?.toString(),
      lastNotifiedDate: data['lastNotifiedDate']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'target': target,
      'todayProgress': todayProgress,
      'lastUpdatedDate': lastUpdatedDate,
      'lastNotifiedDate': lastNotifiedDate,
    };
  }
}

class UserProfile {
  final String uid;
  final String name;
  final int lifetimeStarsEarned;
  final int availableStars;
  final String activeMascotOutfit;
  final String? parentId;
  final int streakCount;
  final DateTime? lastActivityDate;
  final DailyGoal? dailyGoal;
  final int? age;
  final String? grade; // Standard 1, Standard 2, etc.
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String? avatarPath;
  final int? passwordLength;
  final String? lastAiInsight;
  final DateTime? lastAiInsightDate;

  UserProfile({
    required this.uid,
    required this.name,
    required this.lifetimeStarsEarned,
    required this.availableStars,
    required this.activeMascotOutfit,
    this.parentId,
    this.streakCount = 0,
    this.lastActivityDate,
    this.dailyGoal,
    this.age,
    this.grade,
    this.username,
    this.email,
    this.phoneNumber,
    this.avatarPath,
    this.passwordLength,
    this.lastAiInsight,
    this.lastAiInsightDate,
  });

  int get starBalance => availableStars;

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    final dailyGoalData = data['dailyGoal'];
    final availableStars =
        (data['availableStars'] ?? data['starBalance'] ?? data['stars'] ?? 0)
            .toInt();
    final storedStreak = (data['streakCount'] ?? 0).toInt();
    final lastActivityDate = data['lastActivityDate'] != null
        ? (data['lastActivityDate'] as Timestamp).toDate()
        : null;

    final streakCount = StreakUtils.getEffectiveStreak(
      storedStreak: storedStreak,
      lastActivityDate: lastActivityDate,
      now: DateTime.now(),
    );

    return UserProfile(
      uid: uid,
      name: data['name'] ?? 'Student',
      lifetimeStarsEarned: (data['lifetimeStarsEarned'] ?? availableStars)
          .toInt(),
      availableStars: availableStars,
      activeMascotOutfit:
          data['activeOutfitID'] ??
          data['activeMascotOutfit'] ??
          'scholar_bear',
      parentId: data['parentId'],
      streakCount: streakCount,
      lastActivityDate: lastActivityDate,
      dailyGoal: dailyGoalData is Map
          ? DailyGoal.fromMap(Map<String, dynamic>.from(dailyGoalData))
          : null,
      age: data['age'] != null ? (data['age'] as num).toInt() : null,
      grade: data['grade']?.toString(),
      username: data['username']?.toString(),
      email: data['email']?.toString(),
      phoneNumber: data['phoneNumber']?.toString(),
      avatarPath: data['avatarPath']?.toString(),
      passwordLength: data['passwordLength'] != null
          ? (data['passwordLength'] as num).toInt()
          : null,
      lastAiInsight: data['lastAiInsight']?.toString(),
      lastAiInsightDate: data['lastAiInsightDate'] != null
          ? (data['lastAiInsightDate'] as Timestamp).toDate()
          : null,
    );
  }
}
