import 'package:dhartti/constants.dart';

class StoreCategory {
  final int id;
  final String name;
  final String? slug;

  StoreCategory({
    required this.id,
    required this.name,
    this.slug,
  });

  factory StoreCategory.fromJson(Map<String, dynamic> json) {
    return StoreCategory(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'General',
      slug: json['slug']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
  };
}

class StoreReviewItem {
  final int id;
  final int? userId;
  final String userName;
  final int rating;
  final String comment;
  final String? createdAt;

  StoreReviewItem({
    required this.id,
    this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory StoreReviewItem.fromJson(Map<String, dynamic> json) {
    String uName = 'Verified Buyer';
    if (json['user'] != null && json['user'] is Map) {
      uName = json['user']['name']?.toString() ?? 'Verified Buyer';
    } else if (json['user_name'] != null) {
      uName = json['user_name'].toString();
    }

    return StoreReviewItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
      userName: uName,
      rating: json['rating'] is int ? json['rating'] : int.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }
}

class StoreProduct {
  final int id;
  final int? userId;
  final int? categoryId;
  final String name;
  final String? slug;
  final String description;
  final double price;
  final double? discountPrice;
  final int stockQuantity;
  final String status;
  final String imagePath;
  final String? rawImageUrl;
  final String categoryName;
  final double ratingAvg;
  final int reviewsCount;
  final List<StoreReviewItem> reviews;

  StoreProduct({
    required this.id,
    this.userId,
    this.categoryId,
    required this.name,
    this.slug,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.stockQuantity,
    required this.status,
    required this.imagePath,
    this.rawImageUrl,
    required this.categoryName,
    this.ratingAvg = 0.0,
    this.reviewsCount = 0,
    this.reviews = const [],
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      parsedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
    }

    double? parsedDiscount;
    if (json['discount_price'] != null && json['discount_price'].toString().isNotEmpty) {
      parsedDiscount = double.tryParse(json['discount_price'].toString());
    }

    String catName = 'Materials';
    if (json['category'] != null && json['category'] is Map) {
      catName = json['category']['name']?.toString() ?? 'Materials';
    } else if (json['category_name'] != null) {
      catName = json['category_name'].toString();
    }

    List<StoreReviewItem> revs = [];
    if (json['approved_reviews'] != null && json['approved_reviews'] is List) {
      revs = (json['approved_reviews'] as List).map((r) => StoreReviewItem.fromJson(r)).toList();
    } else if (json['reviews'] != null && json['reviews'] is List) {
      revs = (json['reviews'] as List).map((r) => StoreReviewItem.fromJson(r)).toList();
    }

    double rAvg = 0.0;
    if (json['rating_avg'] != null) {
      rAvg = double.tryParse(json['rating_avg'].toString()) ?? 0.0;
    }

    int rCount = 0;
    if (json['reviews_count'] != null) {
      rCount = int.tryParse(json['reviews_count'].toString()) ?? 0;
    } else {
      rCount = revs.length;
    }

    return StoreProduct(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id']?.toString() ?? ''),
      name: json['name']?.toString() ?? 'Construction Material',
      slug: json['slug']?.toString(),
      description: json['description']?.toString() ?? '',
      price: parsedPrice,
      discountPrice: parsedDiscount,
      stockQuantity: json['stock_quantity'] is int ? json['stock_quantity'] : int.tryParse(json['stock_quantity']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'Active',
      imagePath: json['image_path']?.toString() ?? '',
      rawImageUrl: json['image_url']?.toString(),
      categoryName: catName,
      ratingAvg: rAvg,
      reviewsCount: rCount,
      reviews: revs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'category_id': categoryId,
    'name': name,
    'slug': slug,
    'description': description,
    'price': price,
    'discount_price': discountPrice,
    'stock_quantity': stockQuantity,
    'status': status,
    'image_path': imagePath,
    'image_url': rawImageUrl,
    'category_name': categoryName,
    'rating_avg': ratingAvg,
    'reviews_count': reviewsCount,
  };

  double get effectivePrice {
    if (discountPrice != null && discountPrice! > 0 && discountPrice! < price) {
      return discountPrice!;
    }
    return price;
  }

  bool get hasDiscount => discountPrice != null && discountPrice! > 0 && discountPrice! < price;

  int get discountPercent {
    if (!hasDiscount || price <= 0) return 0;
    return (((price - discountPrice!) / price) * 100).round();
  }

  bool get isInStock => stockQuantity > 0 && status.toLowerCase() == 'active';

  String get displayImageUrl {
    if (rawImageUrl != null && rawImageUrl!.isNotEmpty && rawImageUrl!.startsWith('http')) {
      return rawImageUrl!;
    }
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    if (imagePath.isNotEmpty) {
      final base = AppConstants.baseUrl.replaceAll('/api', '');
      var clean = imagePath.trim();
      if (clean.startsWith('/')) clean = clean.substring(1);
      if (!clean.startsWith('uploads/')) {
        clean = 'uploads/products/$clean';
      }
      return '$base/$clean';
    }
    return '';
  }
}

class StoreCartItem {
  final StoreProduct product;
  int quantity;

  StoreCartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.effectivePrice * quantity;

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };

  factory StoreCartItem.fromJson(Map<String, dynamic> json) {
    return StoreCartItem(
      product: StoreProduct.fromJson(json['product']),
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
    );
  }
}

class StoreOrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double price;

  StoreOrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.price,
  });

  factory StoreOrderItemModel.fromJson(Map<String, dynamic> json) {
    String pName = 'Product #$json';
    String? pImg;

    if (json['product'] != null && json['product'] is Map) {
      pName = json['product']['name']?.toString() ?? pName;
      pImg = json['product']['image_url']?.toString() ?? json['product']['image_path']?.toString();
    }

    return StoreOrderItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: pName,
      productImage: pImg,
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  double get subtotal => price * quantity;
}

class StoreOrderModel {
  final int id;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String customerName;
  final String phone;
  final String email;
  final String shippingAddress;
  final String? createdAt;
  final List<StoreOrderItemModel> items;

  StoreOrderModel({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.shippingAddress,
    this.createdAt,
    this.items = const [],
  });

  factory StoreOrderModel.fromJson(Map<String, dynamic> json) {
    List<StoreOrderItemModel> itemsList = [];
    if (json['items'] != null && json['items'] is List) {
      itemsList = (json['items'] as List).map((i) => StoreOrderItemModel.fromJson(i)).toList();
    }

    return StoreOrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0.0') ?? 0.0,
      status: json['status']?.toString() ?? 'Pending',
      paymentStatus: json['payment_status']?.toString() ?? 'Pending',
      customerName: json['customer_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      shippingAddress: json['shipping_address']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      items: itemsList,
    );
  }
}
