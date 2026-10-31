import 'package:dhartti/constants.dart';
import 'dart:convert';
import 'package:dhartti/Model/Service_cart.dart';
import 'package:dhartti/Model/service_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServiceService {
  static const String baseUrl = AppConstants.baseUrl;
  // static const String baseUrl = AppConstants.baseUrl; // Update with your API

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> getServices() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/services'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'services': (data['services'] as List).map((json) => Service.fromJson(json)).toList(),
        'hasPurchased': List<int>.from(data['hasPurchased']),
        'cart': data['cart'] != null ? Cart.fromJson(data['cart']) : null,
      };
    } else {
      throw Exception('Failed to load services');
    }
  }

  Future<Cart> addToCart(int serviceId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/services/add-to-cart'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Cart.fromJson(data['cart']);
    } else {
      throw Exception(json.decode(response.body)['message']);
    }
  }

  Future<Map<String, dynamic>> checkout() async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/services/checkout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message']);
    }
  }
}
