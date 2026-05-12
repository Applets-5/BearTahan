import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final int starBalance;
  final String activeMascotOutfit;
  final String? parentId;

  final int streakCount;
  final DateTime? lastActivityDate;

  UserProfile({
    required this.uid,
    required this.name,
    required this.starBalance,
    required this.activeMascotOutfit,
    this.parentId,
    this.streakCount = 0,
    this.lastActivityDate,
  });

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      name: data['name'] ?? 'Student',
      starBalance: (data['starBalance'] ?? 0).toInt(),
      activeMascotOutfit: data['activeMascotOutfit'] ?? 'default',
      parentId: data['parentId'],
      streakCount: (data['streakCount'] ?? 0).toInt(),
      lastActivityDate: data['lastActivityDate'] != null
          ? (data['lastActivityDate'] as Timestamp).toDate()
          : null,
    );
  }
}
