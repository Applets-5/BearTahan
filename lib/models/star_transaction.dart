import 'package:cloud_firestore/cloud_firestore.dart';

class StarTransaction {
  final String id;
  final String type; // 'earn' | 'spend'
  final int amount;
  final String description;
  final DateTime timestamp;
  final String? subjectId;
  final String? levelId;
  final String? rewardId;

  StarTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    this.subjectId,
    this.levelId,
    this.rewardId,
  });

  factory StarTransaction.fromFirestore(String id, Map<String, dynamic> data) {
    return StarTransaction(
      id: id,
      type: data['type'] ?? 'earn',
      amount: (data['amount'] ?? 0).toInt(),
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subjectId: data['subjectId'],
      levelId: data['levelId'],
      rewardId: data['rewardId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'amount': amount,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      if (subjectId != null) 'subjectId': subjectId,
      if (levelId != null) 'levelId': levelId,
      if (rewardId != null) 'rewardId': rewardId,
    };
  }
}
