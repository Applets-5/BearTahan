class ChapterData {
  final String id;
  final String name;
  final List<String> levelIds;

  ChapterData({
    required this.id,
    required this.name,
    required this.levelIds,
  });

  factory ChapterData.fromFirestore(String id, Map<String, dynamic> data) {
    return ChapterData(
      id: id,
      name: data['name'] ?? '',
      levelIds: List<String>.from(data['levelIds'] ?? []),
    );
  }
}
