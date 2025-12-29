import 'dart:convert';

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? image;
  final String category;
  final double stockQuantity;
  final List<String> images;
  final List<dynamic> variants;
  final Map<String, dynamic> specifications;
  final Map<String, dynamic> variantImages;
  final Map<String, double> variantPrices;
  final Map<String, double> variantStocks;
  final int? categoryId;
  final bool isTrending;
  final bool isNewArrival;
  final bool isAdvertised;
  final double averageRating;
  final int reviewCount;
  final int purchasesLastMonth;
  final String unit;
  final double gstPercent;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    required this.category,
    this.categoryId,
    required this.stockQuantity,
    this.images = const [],
    this.variants = const [],
    this.specifications = const {},
    this.variantImages = const {},
    this.variantPrices = const {},
    this.variantStocks = const {},
    this.isTrending = false,
    this.isNewArrival = false,
    this.isAdvertised = false,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.purchasesLastMonth = 0,
    this.unit = 'Piece',
    this.gstPercent = 0.0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String?,
      category: json['category'] as String? ?? 'Uncategorized', // Handle legacy
      categoryId: json['category_id'] as int?,
      stockQuantity: (json['stock_quantity'] as num?)?.toDouble() ?? 0.0,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      variants: _parseVariants(json['variants']),
      specifications: json['specifications'] != null ? Map<String, dynamic>.from(json['specifications']) : {},
      variantImages: json['variant_images'] != null ? Map<String, dynamic>.from(json['variant_images']) : {},
      variantPrices: json['variant_prices'] != null 
          ? Map<String, dynamic>.from(json['variant_prices']).map((k, v) => MapEntry(k, (v as num).toDouble())) 
          : {},
      variantStocks: json['variant_stocks'] != null 
          ? Map<String, dynamic>.from(json['variant_stocks']).map((k, v) => MapEntry(k, (v as num).toDouble())) 
          : {},
      isTrending: json['is_trending'] == 1 || json['is_trending'] == true,
      isNewArrival: json['is_new_arrival'] == 1 || json['is_new_arrival'] == true,
      isAdvertised: json['is_advertised'] == 1 || json['is_advertised'] == true,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,

      purchasesLastMonth: json['purchases_last_month'] as int? ?? 0,
      unit: json['unit'] as String? ?? 'Piece',
      gstPercent: (json['gst_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Helper to calculate tax-inclusive price
  double getPriceWithTax(double basePrice) {
    if (gstPercent <= 0) return basePrice;
    return basePrice + (basePrice * gstPercent / 100);
  }

  // Getters for display
  double get displayPrice => getPriceWithTax(price);

  String get formattedUnit {
    final u = unit.toLowerCase();
    if (u == 'piece' || u == 'pieces') return 'pc';
    if (u == 'meter' || u == 'meters') return 'm';
    if (u == 'centimeter' || u == 'cm') return 'cm';
    if (u == 'kilogram' || u == 'kg') return 'kg';
    if (u == 'gram' || u == 'g') return 'g';
    if (u == 'liter' || u == 'l') return 'L';
    if (u == 'milliliter' || u == 'ml') return 'ml';
    return unit;
  }

  bool get allowDecimal => !['piece', 'pieces', 'pc', 'pcs'].contains(unit.toLowerCase());

  static List<dynamic> _parseVariants(dynamic val) {
    if (val == null) return [];
    if (val is List) return List<dynamic>.from(val);
    if (val is String) {
      try {
        final decoded = jsonDecode(val);
        if (decoded is List) return List<dynamic>.from(decoded);
      } catch (e) {
        print('Error parsing variants JSON: $e');
      }
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category': category,
      'stock_quantity': stockQuantity,
      'images': images,
      'variants': variants,
      'specifications': specifications,
      'variant_images': variantImages,
      'variant_prices': variantPrices,
      'variant_stocks': variantStocks,
      'is_trending': isTrending,
      'is_new_arrival': isNewArrival,
      'is_advertised': isAdvertised,
      'average_rating': averageRating,
      'review_count': reviewCount,
      'purchases_last_month': purchasesLastMonth,
      'unit': unit,
    };
  }
}
