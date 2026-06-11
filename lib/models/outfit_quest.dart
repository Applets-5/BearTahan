import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/data_contracts.dart';

class OutfitQuest {
  const OutfitQuest({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.conditionType,
    required this.target,
    required this.displayOrder,
    this.subjectId,
  });

  final String id;
  final String name;
  final String description;
  final String imagePath;
  final String conditionType;
  final String? subjectId;
  final int target;
  final int displayOrder;

  bool get isStarter => conditionType == 'starter';

  factory OutfitQuest.fromFirestore(String id, Map<String, dynamic> data) {
    return OutfitQuest(
      id: id,
      name: data['name']?.toString() ?? id,
      description: data['description']?.toString() ?? '',
      imagePath: data['imagePath']?.toString() ?? 'assets/images/bear1.png',
      conditionType: data['conditionType']?.toString() ?? 'starter',
      subjectId: data['subjectId'] == null
          ? null
          : DataContracts.normalizeSubjectId(data['subjectId'].toString()),
      target: (data['target'] ?? 0).toInt(),
      displayOrder: (data['displayOrder'] ?? 999).toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'conditionType': conditionType,
      if (subjectId != null) 'subjectId': subjectId,
      'target': target,
      'displayOrder': displayOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static const List<OutfitQuest> defaults = [
    OutfitQuest(
      id: 'scholar_bear',
      name: 'Scholar Bear',
      description: 'Starter outfit',
      imagePath: 'assets/images/bear1.png',
      conditionType: 'starter',
      target: 0,
      displayOrder: 0,
    ),
    OutfitQuest(
      id: 'chef_bear',
      name: 'Chef Bear',
      description: 'Complete 5 BM lessons',
      imagePath: 'assets/images/bear2.png',
      conditionType: 'completed_lessons',
      subjectId: 'bm',
      target: 5,
      displayOrder: 1,
    ),
    OutfitQuest(
      id: 'astro_bear',
      name: 'Astro Bear',
      description: 'Score 100% on 3 Maths quizzes',
      imagePath: 'assets/images/bear3.png',
      conditionType: 'perfect_quizzes',
      subjectId: 'math',
      target: 3,
      displayOrder: 2,
    ),
    OutfitQuest(
      id: 'pirate_bear',
      name: 'Pirate Bear',
      description: 'Complete 10 English lessons',
      imagePath: 'assets/images/bear4.png',
      conditionType: 'completed_lessons',
      subjectId: 'bi',
      target: 10,
      displayOrder: 3,
    ),
    OutfitQuest(
      id: 'super_bear',
      name: 'Super Bear',
      description: 'Earn 500 total stars',
      imagePath: 'assets/images/bear5.png',
      conditionType: 'total_stars',
      target: 500,
      displayOrder: 4,
    ),
    OutfitQuest(
      id: 'explorer_bear',
      name: 'Explorer Bear',
      description: 'Complete all Science topics',
      imagePath: 'assets/images/bear6.png',
      conditionType: 'complete_all_topics',
      subjectId: 'sci',
      target: 8,
      displayOrder: 5,
    ),
  ];

  static OutfitQuest byId(String id) {
    return defaults.firstWhere(
      (quest) => quest.id == id,
      orElse: () => defaults.first,
    );
  }
}

class OutfitQuestProgress {
  const OutfitQuestProgress({
    required this.outfitId,
    required this.currentValue,
    required this.targetValue,
    required this.isUnlocked,
    this.unlockedAt,
  });

  final String outfitId;
  final int currentValue;
  final int targetValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  double get percentage {
    if (targetValue <= 0) return isUnlocked ? 1 : 0;
    return (currentValue / targetValue).clamp(0.0, 1.0).toDouble();
  }

  factory OutfitQuestProgress.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final unlockedAtValue = data['unlockedAt'];
    return OutfitQuestProgress(
      outfitId: id,
      currentValue: (data['currentValue'] ?? 0).toInt(),
      targetValue: (data['targetValue'] ?? 0).toInt(),
      isUnlocked: data['isUnlocked'] == true,
      unlockedAt: unlockedAtValue is Timestamp
          ? unlockedAtValue.toDate()
          : null,
    );
  }
}
