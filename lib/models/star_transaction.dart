import 'package:cloud_firestore/cloud_firestore.dart';

class StarTransaction {
  final String id;
  final String type; // 'earn' | 'spend'
  final int amount;
  final String source;
  final String description;
  final DateTime timestamp;
  final String? subjectId;
  final String? levelId;
  final String? rewardId;
  final String? sourceId;

  StarTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.source,
    required this.description,
    required this.timestamp,
    this.subjectId,
    this.levelId,
    this.rewardId,
    this.sourceId,
  });

  factory StarTransaction.fromFirestore(String id, Map<String, dynamic> data) {
    final sourceId = data['sourceID'] ?? data['sourceId'];
    return StarTransaction(
      id: id,
      type: data['type'] ?? 'earn',
      amount: (data['amount'] ?? 0).toInt(),
      source: data['source'] ?? data['description'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subjectId: data['subjectId'],
      levelId: data['levelId'],
      rewardId: data['rewardId'],
      sourceId: sourceId?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'amount': amount,
      'source': source,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      if (sourceId != null) 'sourceID': sourceId,
      if (subjectId != null) 'subjectId': subjectId,
      if (levelId != null) 'levelId': levelId,
      if (rewardId != null) 'rewardId': rewardId,
    };
  }
}
