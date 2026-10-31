class PropertyAreaGuide {
  int? id;
  String? purpose;
  String? propertyType;
  String? city;
  double? price;
  String? currency;
  String? title;
  String? description;
  String? imagePath;
  int? bedrooms;
  int? bathrooms;
  double? areaSize;
  String? areaUnit;

  PropertyAreaGuide({
    this.id,
    this.purpose,
    this.propertyType,
    this.city,
    this.price,
    this.currency,
    this.title,
    this.description,
    this.imagePath,
    this.bedrooms,
    this.bathrooms,
    this.areaSize,
    this.areaUnit,
  });

  factory PropertyAreaGuide.fromJson(Map<String, dynamic> json) {
    return PropertyAreaGuide(
      id: _parseInt(json['id']),
      purpose: _parseString(json['purpose']),
      propertyType: _parseString(json['property_type']),
      city: _parseString(json['city']),
      price: _parseDouble(json['price']),
      currency: _parseString(json['currency']),
      title: _parseString(json['title']),
      description: _parseString(json['description']),
      imagePath: _parseString(json['image_path']),
      bedrooms: _parseInt(json['bedrooms']),
      bathrooms: _parseInt(json['bathrooms']),
      areaSize: _parseDouble(json['area_size']),
      areaUnit: _parseString(json['area_unit']),
    );
  }

  // Helper methods for safe parsing
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove any commas or currency symbols
      final cleanedValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanedValue);
    }
    return null;
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purpose': purpose,
      'property_type': propertyType,
      'city': city,
      'price': price,
      'currency': currency,
      'title': title,
      'description': description,
      'image_path': imagePath,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area_size': areaSize,
      'area_unit': areaUnit,
    };
  }
}
