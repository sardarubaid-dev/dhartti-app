import 'package:dhartti/Model/service_model.dart';

class Cart {
  final int id;
  final int userId;
  final int serviceId;
  final double price;
  final Service? service;

  Cart({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.price,
    this.service,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      serviceId: json['service_id'] ?? 0,
      price: _parsePrice(json['price']),
      service: json['service'] != null ? Service.fromJson(json['service']) : null,
    );
  }

  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }
}
