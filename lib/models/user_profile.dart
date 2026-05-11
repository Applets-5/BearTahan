class UserProfile {
  final String uid;
  final String name;
  final int starBalance;
  final String activeMascotOutfit;
  final String? parentId;

  UserProfile({
    required this.uid,
    required this.name,
    required this.starBalance,
    required this.activeMascotOutfit,
    this.parentId,
  });

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      name: data['name'] ?? 'Student',
      starBalance: (data['starBalance'] ?? 0).toInt(),
      activeMascotOutfit: data['activeMascotOutfit'] ?? 'default',
      parentId: data['parentId'],
    );
  }
}
