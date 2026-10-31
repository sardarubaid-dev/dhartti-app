import 'package:dhartti/constants.dart';
import 'dart:convert';
import 'package:dhartti/Model/joinVenture.dart';
import 'package:dhartti/Model/join_venture_bid_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JoinVentureService {
  static const String baseUrl = AppConstants.baseUrl;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<JoinVenture>> fetchVentures() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/join-ventures'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => JoinVenture.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load ventures: ${response.statusCode}');
    }
  }

  Future<List<JoinVenture>> fetchAllVentures() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/join-ventures/all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => JoinVenture.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load ventures: ${response.statusCode}');
    }
  }

  Future<List<JoinVenture>> fetchAllVenturesWithBidCounts() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/join-ventures/with-bid-counts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => JoinVenture.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load ventures with bid counts: ${response.statusCode}');
    }
  }

  Future<void> createJoinVenture(Map<String, dynamic> ventureData) async {
    final token = await getToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.post(
      Uri.parse('$baseUrl/join-ventures'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(ventureData),
    );

    if (response.statusCode == 201) {
      return; // Success
    } else {
      throw Exception('Failed to create venture: ${response.statusCode}');
    }
  }

  Future<void> updateJoinVenture(int id, Map<String, dynamic> ventureData) async {
    final token = await getToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.put(
      Uri.parse('$baseUrl/join-ventures/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(ventureData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update venture: ${response.statusCode}');
    }
  }

  Future<JoinVenture> getVentureDetails(int id) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/join-ventures/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return JoinVenture.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load venture details: ${response.statusCode}');
    }
  }

  Future<List<JoinVentureBid>> getVentureBids(int ventureId) async {
    final token = await getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/join-ventures/$ventureId/bids'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => JoinVentureBid.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bids: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch bids: $e');
    }
  }

  Future<JoinVentureBid> placeBid({
    required int ventureId,
    required String amount,
    String? message,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/join-ventures/$ventureId/bids'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'amount': amount,
        'message': message,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final bidData = decoded is Map<String, dynamic> ? (decoded['bid'] ?? decoded) : decoded;
      return JoinVentureBid.fromJson(bidData);
    } else {
      String errorMsg = 'Failed to place bid (${response.statusCode})';
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          errorMsg = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }

  Future<JoinVentureBid> updateBid({
    required int ventureId,
    required int bidId,
    required String amount,
    String? message,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/join-ventures/$ventureId/bids/$bidId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'amount': amount,
        'message': message,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      final bidData = decoded is Map<String, dynamic> ? (decoded['bid'] ?? decoded) : decoded;
      return JoinVentureBid.fromJson(bidData);
    } else {
      String errorMsg = 'Failed to update proposal (${response.statusCode})';
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          errorMsg = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }
}
