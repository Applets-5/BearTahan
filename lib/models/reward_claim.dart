import 'package:cloud_firestore/cloud_firestore.dart';

class RewardClaim {
  final String id;
  final String parentId;
  final String childId;
  final String childName;
  final String rewardId;
  final String rewardName;
  final String rewardDescription;
  final int starCost;
  final String status; // 'pending' | 'approved' | 'rejected' | 'expired'
  final DateTime claimedAt;
  final DateTime? resolvedAt;
  final DateTime expiresAt;

  const RewardClaim({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.childName,
    required this.rewardId,
    required this.rewardName,
    required this.rewardDescription,
    required this.starCost,
    required this.status,
    required this.claimedAt,
    this.resolvedAt,
    required this.expiresAt,
  });

  bool get isPending => status == 'pending';

  factory RewardClaim.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? readNullableDate(dynamic value) {
      if (value == null) return null;
      return readDate(value);
    }

    return RewardClaim(
      id: id,
      parentId: data['parentId']?.toString() ?? '',
      childId: data['childId']?.toString() ?? '',
      childName: data['childName']?.toString() ?? 'Student',
      rewardId: data['rewardId']?.toString() ?? '',
      rewardName: data['rewardName']?.toString() ?? '',
      rewardDescription: data['rewardDescription']?.toString() ?? '',
      starCost: (data['starCost'] ?? 0).toInt(),
      status: data['status']?.toString() ?? 'pending',
      claimedAt: readDate(data['claimedAt']),
      resolvedAt: readNullableDate(data['resolvedAt']),
      expiresAt: readDate(data['expiresAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'parentId': parentId,
      'childId': childId,
      'childName': childName,
      'rewardId': rewardId,
      'rewardName': rewardName,
      'rewardDescription': rewardDescription,
      'starCost': starCost,
      'status': status,
      'claimedAt': Timestamp.fromDate(claimedAt),
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }
}
