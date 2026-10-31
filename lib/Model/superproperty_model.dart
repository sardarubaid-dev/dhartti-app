class PropertySuperAdmin {
  int? id;
  String? purpose;
  String? propertyType;
  String? subPropertyType;
  String? city;
  String? plotNumber;
  String? title;
  String? description;
  String? imagePath;
  String? landline;
  String? whatsappNumber;
  String? imagePath2;
  String? imagePath3;
  String? imagePath4;
  String? imagePath5;
  List<String> allImages;
  int? userId;
  String? username;
  dynamic price;
  dynamic areaSize;
  String? areaUnit;
  int? bedrooms;
  int? bathrooms;
  bool? installmentAvailable;
  bool? readyForPossession;
  dynamic mobileNumbers;
  String? email;
  String? currency;
  dynamic advanceAmount;
  dynamic monthlyInstallment;
  dynamic amenities;
  bool? isHot;
  bool? isSuperHot;
  bool? isActive;
  String? status;

  PropertySuperAdmin({
    this.id,
    this.purpose,
    this.propertyType,
    this.subPropertyType,
    this.city,
    this.plotNumber,
    this.title,
    this.description,
    this.imagePath,
    this.landline,
    this.whatsappNumber,
    this.imagePath2,
    this.imagePath3,
    this.imagePath4,
    this.imagePath5,
    this.allImages = const [],
    this.userId,
    this.username,
    this.price,
    this.areaSize,
    this.areaUnit,
    this.bedrooms,
    this.bathrooms,
    this.installmentAvailable,
    this.readyForPossession,
    this.mobileNumbers,
    this.email,
    this.currency,
    this.advanceAmount,
    this.monthlyInstallment,
    this.amenities,
    this.isHot,
    this.isSuperHot,
    this.isActive,
    this.status,
  });

  factory PropertySuperAdmin.fromJson(Map<String, dynamic> json) {
    final List<String> gatheredImages = [];
    void collectImage(dynamic val) {
      if (val == null) return;
      if (val is List) {
        for (var item in val) {
          collectImage(item);
        }
      } else if (val is Map) {
        collectImage(val['url'] ?? val['image'] ?? val['image_path'] ?? val['path']);
      } else {
        final s = val.toString().trim().replaceAll(r'\', '/');
        if (s.isNotEmpty && s != 'null' && s != '[]' && s != '{}') {
          if (!gatheredImages.contains(s)) {
            gatheredImages.add(s);
          }
        }
      }
    }

    collectImage(json['image_path']);
    collectImage(json['image_pat2'] ?? json['image_path2']);
    collectImage(json['image_path3']);
    collectImage(json['image_path4']);
    collectImage(json['image_path5']);
    collectImage(json['image_path6']);
    collectImage(json['images']);
    collectImage(json['photos']);
    collectImage(json['gallery']);
    collectImage(json['property_images']);

    json.forEach((k, v) {
      if (k.toLowerCase().startsWith('image') &&
          !['image_path', 'image_pat2', 'image_path2', 'image_path3', 'image_path4', 'image_path5'].contains(k)) {
        collectImage(v);
      }
    });

    return PropertySuperAdmin(
      id: json['id'],
      purpose: json['purpose'],
      propertyType: json['property_type'],
      subPropertyType: json['sub_property_type'],
      city: json['city'],
      plotNumber: json['plot_number']?.toString() ?? json['plotNumber']?.toString(),
      title: json['title'],
      description: json['description'],
      imagePath: json['image_path'],
      landline: json['landline'],
      whatsappNumber: json['whatsappnumber'],
      imagePath2: json['image_pat2'] ?? json['image_path2'],
      imagePath3: json['image_path3'],
      imagePath4: json['image_path4'],
      imagePath5: json['image_path5'],
      allImages: gatheredImages,
      userId: json['userId'] != null
          ? int.tryParse(json['userId'].toString())
          : (json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null),
      username: json['username'],
      price: json['price'],
      areaSize: json['area_size'],
      areaUnit: json['area_unit'],
      bedrooms: json['bedrooms'] != null ? int.tryParse(json['bedrooms'].toString()) : null,
      bathrooms: json['bathrooms'] != null ? int.tryParse(json['bathrooms'].toString()) : null,
      installmentAvailable: json['installment_available'] == 1 ||
          json['installment_available'] == true ||
          json['installment_available'] == '1',
      readyForPossession: json['ready_for_possession'] == 1 ||
          json['ready_for_possession'] == true ||
          json['ready_for_possession'] == '1',
      mobileNumbers: json['mobile_numbers'],
      email: json['email'],
      currency: json['currency'],
      advanceAmount: json['advance_amount'],
      monthlyInstallment: json['monthly_installment'],
      amenities: json['amenities'],
      isHot: json['is_hot'] == 1 || json['is_hot'] == true || json['is_hot'] == '1',
      isSuperHot: json['is_super_hot'] == 1 || json['is_super_hot'] == true || json['is_super_hot'] == '1',
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1' || json['is_active'] == null,
      status: json['status']?.toString() ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purpose': purpose,
      'property_type': propertyType,
      'sub_property_type': subPropertyType,
      'city': city,
      'plot_number': plotNumber,
      'title': title,
      'description': description,
      'image_path': imagePath,
      'landline': landline,
      'whatsappnumber': whatsappNumber,
      'image_pat2': imagePath2,
      'image_path3': imagePath3,
      'image_path4': imagePath4,
      'image_path5': imagePath5,
      'userId': userId,
      'username': username,
      'price': price,
      'area_size': areaSize,
      'area_unit': areaUnit,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'installment_available': installmentAvailable,
      'ready_for_possession': readyForPossession,
      'mobile_numbers': mobileNumbers,
      'email': email,
      'currency': currency,
      'advance_amount': advanceAmount,
      'monthly_installment': monthlyInstallment,
      'amenities': amenities,
      'is_hot': isHot,
      'is_super_hot': isSuperHot,
      'is_active': isActive,
      'status': status,
    };
  }
}
