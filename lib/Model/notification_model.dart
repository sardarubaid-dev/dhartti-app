import 'package:flutter/material.dart';

class UserNotificationModel {
  final int id;
  final int? userId;
  final String title;
  final String message;
  final String category; // 'inquiry', 'scheme', 'bid', 'order', 'system'
  final String? targetScreen;
  final String? targetId;
  bool isRead;
  final DateTime createdAt;

  UserNotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    this.category = 'system',
    this.targetScreen,
    this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    return UserNotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      category: json['category']?.toString() ?? 'system',
      targetScreen: json['target_screen']?.toString(),
      targetId: json['target_id']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'category': category,
      'target_screen': targetScreen,
      'target_id': targetId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  IconData get iconData {
    switch (category.toLowerCase()) {
      case 'inquiry':
        return Icons.contact_support_rounded;
      case 'scheme':
      case 'loan':
        return Icons.account_balance_rounded;
      case 'bid':
      case 'project':
        return Icons.gavel_rounded;
      case 'order':
        return Icons.shopping_bag_rounded;
      case 'system':
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'inquiry':
        return const Color(0xFF0D9488); // Teal
      case 'scheme':
      case 'loan':
        return const Color(0xFF2563EB); // Royal Blue
      case 'bid':
      case 'project':
        return const Color(0xFF7C3AED); // Purple
      case 'order':
        return const Color(0xFFD97706); // Amber
      case 'system':
      default:
        return const Color(0xFF16A34A); // Emerald Green
    }
  }
}
