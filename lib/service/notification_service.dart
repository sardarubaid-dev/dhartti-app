import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/Model/notification_model.dart';
import 'package:dhartti/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> liveUpdateTrigger = ValueNotifier<int>(0);

  final String _baseUrl = AppConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    final userId = await _getStoredUserId();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (userId != null) 'X-User-Id': userId.toString(),
    };
  }

  Future<int?> _getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('userId')) {
      final dynamic raw = prefs.get('userId');
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw);
    }
    if (prefs.containsKey('user_id')) {
      final dynamic raw = prefs.get('user_id');
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw);
    }
    return null;
  }

  /// Fetch notifications list with optional category filter from backend
  Future<List<UserNotificationModel>> fetchNotifications({String category = 'all'}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    // Guests don't have notifications
    if (token == null || token.isEmpty) {
      unreadCountNotifier.value = 0;
      return [];
    }

    try {
      final headers = await _getHeaders();
      final userId = await _getStoredUserId();
      final uri = Uri.parse('$_baseUrl/notifications').replace(
        queryParameters: {
          if (category != 'all') 'category': category,
          if (userId != null) 'user_id': userId.toString(),
        },
      );

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] != null) {
          final List list = body['data'];
          final notifs = list.map((item) => UserNotificationModel.fromJson(item)).toList();
          
          final unread = notifs.where((n) => !n.isRead).length;
          unreadCountNotifier.value = unread;
          
          // Cache real server notifications locally
          _cacheNotifications(notifs);
          return notifs;
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications from server: $e');
    }

    // Fallback: Read only genuinely cached notifications for this user
    return _getCachedNotifications(category);
  }

  /// Mark single notification as read in backend and update local cache
  Future<bool> markAsRead(int id) async {
    // 1. Update local cache immediately
    await _updateLocalReadStatus(id);

    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$_baseUrl/notifications/$id/read');
      final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notification as read on server: $e');
      return true;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    // 1. Mark all local cached as read
    await _markAllLocalAsRead();
    unreadCountNotifier.value = 0;

    try {
      final headers = await _getHeaders();
      final userId = await _getStoredUserId();
      final url = Uri.parse('$_baseUrl/notifications/mark-all-read');
      await http.post(
        url, 
        headers: headers, 
        body: jsonEncode({if (userId != null) 'user_id': userId}),
      ).timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      debugPrint('Error marking all as read on server: $e');
      return true;
    }
  }

  /// Delete a single notification
  Future<bool> deleteNotification(int id) async {
    await _deleteFromLocalCache(id);

    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$_baseUrl/notifications/$id');
      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return true;
    }
  }

  /// Clear all notifications
  Future<bool> clearAll() async {
    unreadCountNotifier.value = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_notifications');

    try {
      final headers = await _getHeaders();
      final userId = await _getStoredUserId();
      final url = Uri.parse('$_baseUrl/notifications/clear-all');
      await http.delete(
        url, 
        headers: headers, 
        body: jsonEncode({if (userId != null) 'user_id': userId}),
      ).timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
      return true;
    }
  }

  /// Check unread count on app start or screen focus
  Future<int> refreshUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      unreadCountNotifier.value = 0;
      return 0;
    }

    try {
      final list = await fetchNotifications();
      final count = list.where((n) => !n.isRead).length;
      unreadCountNotifier.value = count;
      return count;
    } catch (_) {
      return unreadCountNotifier.value;
    }
  }

  // --- Real Offline caching helpers (NO FAKE / DUMMY NOTIFICATIONS) ---
  Future<void> _cacheNotifications(List<UserNotificationModel> notifs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifs.map((n) => n.toJson()).toList();
      await prefs.setString('cached_user_notifications', jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<UserNotificationModel>> _getCachedNotifications(String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cached_user_notifications');
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        var notifs = decoded.map((e) => UserNotificationModel.fromJson(e)).toList();
        if (category != 'all') {
          notifs = notifs.where((n) => n.category.toLowerCase() == category.toLowerCase()).toList();
        }
        unreadCountNotifier.value = notifs.where((n) => !n.isRead).length;
        return notifs;
      }
    } catch (_) {}

    unreadCountNotifier.value = 0;
    return [];
  }

  Future<void> _updateLocalReadStatus(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cached_user_notifications');
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        for (var item in decoded) {
          final itemId = item['id'] is int ? item['id'] : int.tryParse(item['id'].toString());
          if (itemId == id) {
            item['is_read'] = true;
          }
        }
        await prefs.setString('cached_user_notifications', jsonEncode(decoded));
        
        final unread = decoded.where((item) => item['is_read'] != true && item['is_read'] != 1).length;
        unreadCountNotifier.value = unread;
      } else if (unreadCountNotifier.value > 0) {
        unreadCountNotifier.value = unreadCountNotifier.value - 1;
      }
    } catch (_) {}
  }

  Future<void> _markAllLocalAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cached_user_notifications');
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        for (var item in decoded) {
          item['is_read'] = true;
        }
        await prefs.setString('cached_user_notifications', jsonEncode(decoded));
      }
    } catch (_) {}
  }

  Future<void> _deleteFromLocalCache(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cached_user_notifications');
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        decoded.removeWhere((item) {
          final itemId = item['id'] is int ? item['id'] : int.tryParse(item['id'].toString());
          return itemId == id;
        });
        await prefs.setString('cached_user_notifications', jsonEncode(decoded));
        final unread = decoded.where((item) => item['is_read'] != true && item['is_read'] != 1).length;
        unreadCountNotifier.value = unread;
      }
    } catch (_) {}
  }
}
