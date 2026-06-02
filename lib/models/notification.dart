import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ParentNotification {
  final String id;
  final String title;
  final String type; // 'reward', 'goal', 'progress'
  final DateTime timestamp;
  final bool isRead;
  final String? childId;
  final String? childName;

  ParentNotification({
    required this.id,
    required this.title,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.childId,
    this.childName,
  });

  factory ParentNotification.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return ParentNotification(
      id: id,
      title: data['title'] ?? '',
      type: data['type'] ?? 'info',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      childId: data['childId'],
      childName: data['childName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'childId': childId,
      'childName': childName,
    };
  }

  IconData get icon {
    switch (type) {
      case 'reward':
        return Icons.card_giftcard;
      case 'goal':
        return Icons.flag;
      case 'progress':
        return Icons.trending_up;
      default:
        return Icons.notifications;
    }
  }
}
