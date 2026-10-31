  import 'dart:convert';
  import 'package:dhartti/service/project_service.dart';

  class Project {
    final int id;
    final String title;
    final String description;
    final String detail;
    final String video;
    final String city;
    final String offering;
    final String propertyType;
    final String currency;
    final String areaUnit;
    final String developerTitle;
    final double budgetRangeMin;
    final double budgetRangeMax;
    final List<dynamic> areaRange;
    final List<dynamic> priceRanges;
    final List<dynamic> addresses;
    final String image;
    final String? image2;
    final String? image3;
    final String floorAreaUnit;
    final String floorCurrency;
    final List<dynamic> floorAreaRange;
    final List<dynamic> floorPriceRanges;
    final List<dynamic> floorAddresses;
    final int? userId;

    Project({
      required this.id,
      required this.title,
      required this.description,
      required this.detail,
      required this.video,
      required this.city,
      required this.offering,
      required this.propertyType,
      required this.currency,
      required this.areaUnit,
      required this.developerTitle,
      required this.budgetRangeMin,
      required this.budgetRangeMax,
      required this.areaRange,
      required this.priceRanges,
      required this.addresses,
      required this.image,
      this.image2,
      this.image3,
      required this.floorAreaUnit,
      required this.floorCurrency,
      required this.floorAreaRange,
      required this.floorPriceRanges,
      required this.floorAddresses,
      this.userId,
    });

    // Factory constructor to create Project from JSON
    factory Project.fromJson(Map<String, dynamic> json) {
      List<dynamic> parseJsonList(dynamic jsonField) {
        if (jsonField == null || jsonField == 'null') {
          return []; // Return an empty list if the value is null or a string "null"
        }
        if (jsonField is List) {
          return jsonField; // Already a List, return as is
        }
        if (jsonField is String && jsonField.isNotEmpty) {
          try {
            return jsonDecode(jsonField) as List<dynamic>; // Convert String to List
          } catch (e) {
            return []; // If decoding fails, return empty list
          }
        }
        return []; // Default empty list for any other case
      }

      double parseDouble(dynamic val) {
        if (val == null) return 0.0;
        if (val is num) return val.toDouble();
        if (val is String) {
          return double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
        }
        return 0.0;
      }

      return Project(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        detail: json['detail']?.toString() ?? '',
        video: json['video']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        offering: json['offering']?.toString() ?? '',
        propertyType: json['property_type']?.toString() ?? '',
        currency: json['currency']?.toString() ?? 'PKR',
        areaUnit: json['area_unit']?.toString() ?? 'marla',
        developerTitle: json['developer_title']?.toString() ?? '',
        budgetRangeMin: parseDouble(json['budget_range_min']),
        budgetRangeMax: parseDouble(json['budget_range_max']),
        areaRange: parseJsonList(json['area_range']),
        priceRanges: parseJsonList(json['price_ranges']),
        addresses: parseJsonList(json['addresses']),
        image: ProjectService.formatProjectImageUrl(json['image']?.toString()),
        image2: json['image_2'] != null && json['image_2'].toString().trim().isNotEmpty && json['image_2'].toString().trim() != 'null'
            ? ProjectService.formatProjectImageUrl(json['image_2'].toString())
            : null,
        image3: json['image_3'] != null && json['image_3'].toString().trim().isNotEmpty && json['image_3'].toString().trim() != 'null'
            ? ProjectService.formatProjectImageUrl(json['image_3'].toString())
            : null,
        floorAreaUnit: json['floor_area_unit']?.toString() ?? '',
        floorCurrency: json['floor_currency']?.toString() ?? 'PKR',
        floorAreaRange: parseJsonList(json['floor_area_range']),
        floorPriceRanges: parseJsonList(json['floor_price_ranges']),
        floorAddresses: parseJsonList(json['floor_addresses']),
        userId: json['userId'] != null
            ? int.tryParse(json['userId'].toString())
            : (json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null),
      );
    }

    Map<String, dynamic> toJson() {
      return {
        'title': title,
        'description': description,
        'detail': detail,
        'video': video,
        'city': city,
        'offering': offering,
        'property_type': propertyType,
        'currency': currency,
        'area_unit': areaUnit,
        'developer_title': developerTitle,
        'budget_range_min': budgetRangeMin,
        'budget_range_max': budgetRangeMax,
        'area_range': jsonEncode(areaRange),
        'price_ranges': jsonEncode(priceRanges),
        'addresses': jsonEncode(addresses),
        'image': image,
        'image_2': image2,
        'image_3': image3,
        'floor_area_unit': floorAreaUnit,
        'floor_currency': floorCurrency,
        'floor_area_range': jsonEncode(floorAreaRange),
        'floor_price_ranges': jsonEncode(floorPriceRanges),
        'floor_addresses': jsonEncode(floorAddresses),
        'userId': userId,
      };
    }

    List<String> get allImages {
      final list = <String>[];
      if (image.isNotEmpty) list.add(image);
      if (image2 != null && image2!.trim().isNotEmpty) list.add(image2!);
      if (image3 != null && image3!.trim().isNotEmpty) list.add(image3!);
      return list;
    }
  }
