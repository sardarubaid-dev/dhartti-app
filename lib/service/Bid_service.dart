import 'package:dhartti/constants.dart';
import 'dart:convert';
import 'package:dhartti/Model/Bid.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BidService {
  final String baseUrl = AppConstants.baseUrl; // Replace with your API URL

  Future<int> getBidCount(int projectId) async {
    final token = await _getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/projects/$projectId/bids/count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['count'] ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<List<Bid>> getBids(int projectId) async {
    final token = await _getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/projects/$projectId/bids'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final List<dynamic> responseData = responseBody['bids'] ?? [];
        return responseData.map((json) => Bid.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }



  Future<Bid> submitBid(int projectId, double bidPrice, String? bidDescription) async {
    final token = await _getToken();
    print('Token: $token'); // Debug token
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final url = Uri.parse('$baseUrl/projects/$projectId/bids');
    print('Request URL: $url'); // Debug URL

    final body = jsonEncode({
      'bid_price': bidPrice.toString(), // Convert to string to match model
      'bid_description': bidDescription,
    });
    print('Request Body: $body'); // Debug request body

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('Response Status: ${response.statusCode}'); // Debug status code
      print('Response Body: ${response.body}'); // Debug response body

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final bidData = responseData['bid'] ?? responseData['data'] ?? responseData;
        if (bidData is Map<String, dynamic>) {
          return Bid.fromJson(bidData);
        }
        return Bid(
          id: 0,
          userId: 0,
          projectId: projectId,
          bidPrice: bidPrice.toString(),
          bidDescription: bidDescription,
        );
      } else {
        String errMsg = 'Failed to submit bid (Status: ${response.statusCode})';
        try {
          final Map<String, dynamic> errJson = jsonDecode(response.body);
          if (errJson['message'] != null) {
            errMsg = errJson['message'];
          }
        } catch (_) {}
        throw Exception(errMsg);
      }
    } catch (e) {
      print('Error in submitBid: $e'); // Debug any exceptions
      rethrow;
    }
  }
  Future<Bid> updateBid(int projectId, int bidId, double bidPrice, String? bidDescription) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final url = Uri.parse('$baseUrl/projects/$projectId/bids/$bidId');

    final body = jsonEncode({
      'bid_price': bidPrice.toString(),
      'bid_description': bidDescription,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final bidData = responseData['bid'] ?? responseData['data'] ?? responseData;
        if (bidData is Map<String, dynamic>) {
          return Bid.fromJson(bidData);
        }
        return Bid(
          id: bidId,
          userId: 0,
          projectId: projectId,
          bidPrice: bidPrice.toString(),
          bidDescription: bidDescription,
        );
      } else {
        String errMsg = 'Failed to update bid (Status: ${response.statusCode})';
        try {
          final Map<String, dynamic> errJson = jsonDecode(response.body);
          if (errJson['message'] != null) {
            errMsg = errJson['message'];
          }
        } catch (_) {}
        throw Exception(errMsg);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
