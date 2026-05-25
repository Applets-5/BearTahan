import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Subject {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int progress;

  Subject({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.progress,
  });

  factory Subject.fromFirestore(String id, Map<String, dynamic> data) {
    return Subject(
      id: id,
      name: data['name'] ?? '',
      subtitle: data['subtitle'] ?? '',
      icon: _getIconData(data['icon'] ?? ''),
      color: _getColor(data['color'] ?? ''),
      progress: (data['progress'] ?? 0).toInt(),
    );
  }

  static IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'edit_rounded':
        return Icons.edit_rounded;
      case 'menu_book_rounded':
        return Icons.menu_book_rounded;
      case 'translate_rounded':
        return Icons.translate_rounded;
      case 'calculate_rounded':
        return Icons.calculate_rounded;
      case 'science_rounded':
        return Icons.science_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static Color _getColor(String colorName) {
    switch (colorName) {
      case 'bm':
        return AppColors.subjectBm;
      case 'english':
        return AppColors.subjectEnglish;
      case 'mandarin':
        return AppColors.subjectMandarin;
      case 'math':
        return AppColors.subjectMath;
      case 'science':
        return AppColors.subjectScience;
      default:
        return Colors.grey;
    }
  }
}
