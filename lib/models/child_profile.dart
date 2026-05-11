class ChildProfile {
  final String id;
  final String name;
  final String?
  avatarPath; // For now, we can use a local asset path or an emoji

  ChildProfile({required this.id, required this.name, this.avatarPath});
}
