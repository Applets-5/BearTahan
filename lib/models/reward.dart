class Reward {
  final String id;
  final String title;
  final String description;
  final int cost;
  final String status; // 'available', 'pending', 'redeemed'
  final String? claimedByChildId;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    this.status = 'available',
    this.claimedByChildId,
  });

  factory Reward.fromFirestore(String id, Map<String, dynamic> data) {
    return Reward(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      cost: (data['cost'] ?? 0).toInt(),
      status: data['status'] ?? 'available',
      claimedByChildId: data['claimedByChildId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'cost': cost,
      'status': status,
      if (claimedByChildId != null) 'claimedByChildId': claimedByChildId,
    };
  }

  Reward copyWith({
    String? id,
    String? title,
    String? description,
    int? cost,
    String? status,
    String? claimedByChildId,
  }) {
    return Reward(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      status: status ?? this.status,
      claimedByChildId: claimedByChildId ?? this.claimedByChildId,
    );
  }
}
