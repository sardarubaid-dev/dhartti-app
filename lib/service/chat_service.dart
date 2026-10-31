import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/constants.dart';

class ChatService {
  final String baseUrl = AppConstants.baseUrl;

  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final dynamic rawUserId = prefs.get('userId') ?? prefs.get('user_id');
    final String? userId = rawUserId?.toString();

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (userId != null && userId.isNotEmpty) {
      headers['X-User-Id'] = userId;
    }
    return headers;
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic raw = prefs.get('userId') ?? prefs.get('user_id');
    return raw?.toString();
  }

  /// 1. Fetch all chat conversations / rooms
  Future<List<Map<String, dynamic>>> fetchChatRooms() async {
    final headers = await _getHeaders();
    final userId = await _getUserId();

    final uri = Uri.parse('$baseUrl/chat/rooms${userId != null ? '?user_id=$userId' : ''}');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded['data'] ?? [];
      return List<Map<String, dynamic>>.from(data.map((x) => Map<String, dynamic>.from(x)));
    } else {
      throw Exception('Failed to load chat conversations: ${response.statusCode}');
    }
  }

  /// 2. Initiate or open existing chat between current user and seller/agent
  Future<Map<String, dynamic>> initiateChat({
    required int sellerId,
    int? propertyId,
    int? projectId,
    String? initialMessage,
  }) async {
    final headers = await _getHeaders();
    final userId = await _getUserId();

    final payload = {
      if (userId != null) 'user_id': userId,
      'seller_id': sellerId,
      if (propertyId != null) 'property_id': propertyId,
      if (projectId != null) 'project_id': projectId,
      if (initialMessage != null && initialMessage.trim().isNotEmpty)
        'initial_message': initialMessage.trim(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/chat/initiate'),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return Map<String, dynamic>.from(decoded['data'] ?? {});
    } else {
      String msg = 'Failed to initiate chat';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded['message'] != null) msg = decoded['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// 3. Fetch messages for a specific room
  Future<Map<String, dynamic>> fetchRoomMessages(int roomId) async {
    final headers = await _getHeaders();
    final userId = await _getUserId();

    final uri = Uri.parse('$baseUrl/chat/room/$roomId/messages${userId != null ? '?user_id=$userId' : ''}');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return Map<String, dynamic>.from(decoded['data'] ?? {});
    } else {
      throw Exception('Failed to load messages');
    }
  }

  /// 4. Send message (with optional voice note)
  Future<Map<String, dynamic>> sendMessage({
    required int roomId,
    required String message,
  }) async {
    final headers = await _getHeaders();
    final userId = await _getUserId();

    final payload = {
      if (userId != null) 'user_id': userId,
      'chat_room_id': roomId,
      'message': message.trim(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/chat/send'),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return Map<String, dynamic>.from(decoded['data'] ?? {});
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  /// 5. Get total unread count for badge
  Future<int> getUnreadCount() async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();
      if (userId == null) return 0;

      final response = await http.get(
        Uri.parse('$baseUrl/chat/unread-count?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return (decoded['unread_count'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  // ==========================================
  // DRAFT PERSISTENCE (Type karke chhorne par draft rehna)
  // ==========================================
  static String _draftKey(int roomId) => 'chat_draft_room_$roomId';

  Future<void> saveDraft(int roomId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (text.trim().isEmpty) {
      await prefs.remove(_draftKey(roomId));
    } else {
      await prefs.setString(_draftKey(roomId), text);
    }
  }

  Future<String> getDraft(int roomId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_draftKey(roomId)) ?? '';
  }

  Future<void> clearDraft(int roomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey(roomId));
  }
}
