class DataContracts {
  const DataContracts._();

  static String normalizeSubjectId(String subjectId) {
    switch (subjectId.toLowerCase()) {
      case 'en':
      case 'english':
        return 'bi';
      case 'science':
        return 'sci';
      default:
        return subjectId.toLowerCase();
    }
  }

  static String normalizeLevelId(String levelId) {
    final normalized = levelId.toLowerCase();
    if (RegExp(r'^l\d+$').hasMatch(normalized)) {
      return 'c1_$normalized';
    }
    return normalized;
  }

  static String? legacyLevelId(String levelId) {
    final normalized = normalizeLevelId(levelId);
    final match = RegExp(r'^c1_(l\d+)$').firstMatch(normalized);
    return match?.group(1);
  }

  static String levelPrefix(String subjectId, String levelId) {
    return '${normalizeSubjectId(subjectId)}_${normalizeLevelId(levelId)}_';
  }
}
