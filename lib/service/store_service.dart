import 'dart:convert';
import 'package:dhartti/Model/store_model.dart';
import 'package:dhartti/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StoreService {
  final String baseUrl = AppConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Fetch all product categories
  Future<List<StoreCategory>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/store/categories'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['data'] != null && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((c) => StoreCategory.fromJson(c))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("StoreService fetchCategories error: $e");
    }
    return [];
  }

  // Fetch products with optional category, search, and sorting
  Future<List<StoreProduct>> fetchProducts({
    int? categoryId,
    String? search,
    String? sort,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categoryId != null && categoryId > 0) {
        queryParams['category_id'] = categoryId.toString();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }

      final uri = Uri.parse('$baseUrl/store/products').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['data'] != null && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((p) => StoreProduct.fromJson(p))
              .toList();
        }
      } else {
        debugPrint("StoreService fetchProducts response: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("StoreService fetchProducts error: $e");
    }
    return [];
  }

  // Fetch single product details with reviews & recommended items
  Future<Map<String, dynamic>?> fetchProductDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/store/products/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['data'] != null) {
          final product = StoreProduct.fromJson(decoded['data']);
          List<StoreProduct> recommended = [];
          if (decoded['recommended'] != null && decoded['recommended'] is List) {
            recommended = (decoded['recommended'] as List)
                .map((r) => StoreProduct.fromJson(r))
                .toList();
          }
          return {
            'product': product,
            'recommended': recommended,
          };
        }
      }
    } catch (e) {
      debugPrint("StoreService fetchProductDetail error: $e");
    }
    return null;
  }

  // Place a new store order
  Future<Map<String, dynamic>> placeOrder({
    required String customerName,
    required String phone,
    required String email,
    required String shippingAddress,
    required List<StoreCartItem> items,
    int? userId,
  }) async {
    try {
      final itemsPayload = items.map((item) => {
        'product_id': item.product.id,
        'quantity': item.quantity,
        'price': item.product.effectivePrice,
      }).toList();

      final body = json.encode({
        'customer_name': customerName,
        'phone': phone,
        'email': email,
        'shipping_address': shippingAddress,
        'user_id': userId,
        'items': itemsPayload,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/store/place-order'),
        headers: await _getHeaders(),
        body: body,
      );

      final decoded = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Order placed successfully!',
          'order_id': decoded['order_id'],
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Failed to place order (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint("StoreService placeOrder error: $e");
      return {
        'success': false,
        'message': 'Network error: Could not reach the server. Please try again.',
      };
    }
  }

  // Fetch orders for the current user
  Future<List<StoreOrderModel>> fetchUserOrders({int? userId, String? phone}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dynamic rawUserId = prefs.get('userId');
      final safeUserId = rawUserId is int ? rawUserId : (rawUserId is String ? int.tryParse(rawUserId) : null);
      final effectiveUserId = userId ?? safeUserId;
      final effectivePhone = phone ?? prefs.getString('userPhone') ?? prefs.getString('phone');

      final queryParams = <String, String>{};
      if (effectiveUserId != null) {
        queryParams['user_id'] = effectiveUserId.toString();
      }
      if (effectivePhone != null && effectivePhone.isNotEmpty) {
        queryParams['phone'] = effectivePhone;
      }
      final savedOrderIds = prefs.getStringList('my_placed_order_ids');
      if (savedOrderIds != null && savedOrderIds.isNotEmpty) {
        queryParams['order_ids'] = savedOrderIds.join(',');
      }

      final uri = queryParams.isNotEmpty
          ? Uri.parse('$baseUrl/store/orders').replace(queryParameters: queryParams)
          : Uri.parse('$baseUrl/store/orders');

      final headers = await _getHeaders();
      if (effectiveUserId != null) {
        headers['X-User-Id'] = effectiveUserId.toString();
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['data'] != null && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((o) => StoreOrderModel.fromJson(o))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("StoreService fetchUserOrders error: $e");
    }
    return [];
  }

  // Submit product review
  Future<bool> submitReview({
    required int productId,
    required int rating,
    required String comment,
    int? userId,
  }) async {
    try {
      final body = json.encode({
        'rating': rating,
        'comment': comment,
        'user_id': userId,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/store/products/$productId/reviews'),
        headers: await _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      debugPrint("StoreService submitReview error: $e");
    }
    return false;
  }
}

// Global Cart Manager with Local Persistence
class CartManager extends ChangeNotifier {
  static final CartManager instance = CartManager._internal();

  CartManager._internal() {
    _loadFromPrefs();
  }

  final List<StoreCartItem> _items = [];

  List<StoreCartItem> get items => List.unmodifiable(_items);

  int get totalCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.totalPrice);

  double get deliveryCharge {
    if (subtotal == 0) return 0.0;
    if (subtotal >= 10000) return 0.0; // Free delivery for orders >= PKR 10,000
    return 350.0;
  }

  double get grandTotal => subtotal + deliveryCharge;

  bool get isEmpty => _items.isEmpty;

  void addToCart(StoreProduct product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(StoreCartItem(product: product, quantity: quantity));
    }
    _saveToPrefs();
    notifyListeners();
  }

  void increment(int productId) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity < _items[index].product.stockQuantity) {
        _items[index].quantity++;
        _saveToPrefs();
        notifyListeners();
      }
    }
  }

  void decrement(int productId) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      _saveToPrefs();
      notifyListeners();
    }
  }

  void removeItem(int productId) {
    _items.removeWhere((i) => i.product.id == productId);
    _saveToPrefs();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _items.map((i) => i.toJson()).toList();
      await prefs.setString('store_cart_data', json.encode(list));
    } catch (_) {}
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('store_cart_data');
      if (str != null && str.isNotEmpty) {
        final decoded = json.decode(str) as List;
        _items.clear();
        for (var raw in decoded) {
          _items.add(StoreCartItem.fromJson(raw));
        }
        notifyListeners();
      }
    } catch (_) {}
  }
}
