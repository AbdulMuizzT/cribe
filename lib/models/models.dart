import 'dart:typed_data';

enum ProductStatus { draft, aiOptimized, published }

enum AppLanguage { english, hindi, tamil }

extension AppLanguageX on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.hindi:
        return 'hi';
      case AppLanguage.tamil:
        return 'ta';
    }
  }

  String get label {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.hindi:
        return 'हिन्दी';
      case AppLanguage.tamil:
        return 'தமிழ்';
    }
  }

  static AppLanguage fromCode(String code) {
    switch (code) {
      case 'hi':
        return AppLanguage.hindi;
      case 'ta':
        return AppLanguage.tamil;
      default:
        return AppLanguage.english;
    }
  }
}

class Artisan {
  String name;
  String craft;
  String location;
  AppLanguage language;

  Artisan({
    required this.name,
    required this.craft,
    required this.location,
    required this.language,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'craft': craft,
        'location': location,
        'language': language.code,
      };

  factory Artisan.fromJson(Map<String, dynamic> json) => Artisan(
        name: json['name'] ?? 'Lakshmi Devi',
        craft: json['craft'] ?? 'Handwoven Textiles',
        location: json['location'] ?? 'Madurai, Tamil Nadu',
        language: AppLanguageX.fromCode(json['language'] ?? 'ta'),
      );
}

class PricingRecommendation {
  final double materialCost;
  final double craftsmanship;
  final double marketPattern;
  final double margin;
  final double recommended;
  final double rangeLow;
  final double rangeHigh;

  PricingRecommendation({
    required this.materialCost,
    required this.craftsmanship,
    required this.marketPattern,
    required this.margin,
    required this.recommended,
    required this.rangeLow,
    required this.rangeHigh,
  });
}

class Buyer {
  final String id;
  final String name;
  final String type;
  final String product; // what they're looking for, e.g. "Cotton Sarees"
  final int quantity;
  final double budgetMin;
  final double budgetMax;
  final int deliveryDays;
  final String location;

  Buyer({
    required this.id,
    required this.name,
    required this.type,
    required this.product,
    required this.quantity,
    required this.budgetMin,
    required this.budgetMax,
    required this.deliveryDays,
    required this.location,
  });
}

/// A buyer request matched against the artisan's own products — powers the
/// AI Buyer Matching feature. matchPercent is a demo heuristic (keyword
/// overlap with the buyer's requested product + whether price fits their
/// budget), computed locally, not from a real matching API.
class BuyerMatch {
  final Buyer buyer;
  final Product? matchedProduct;
  final int matchPercent;

  BuyerMatch({required this.buyer, required this.matchedProduct, required this.matchPercent});
}

/// Demo/calculated business-intelligence summary shown on the Home dashboard.
class BusinessInsight {
  final String bestProductName;
  final String demandHeadline;
  final String demandDetail;
  final int recommendedProductionQty;
  final int healthScore;

  BusinessInsight({
    required this.bestProductName,
    required this.demandHeadline,
    required this.demandDetail,
    required this.recommendedProductionQty,
    required this.healthScore,
  });
}

class Product {
  final String id;
  String name;
  String category;
  String material;
  String craft;
  String origin;
  Map<String, String> descriptions; // keyed by language code: en / hi / ta
  List<String> keywords;
  double rawMaterialCost;
  int craftingDays;
  double otherCosts;
  double? recommendedPrice;
  double rangeLow;
  double rangeHigh;
  double price;
  ProductStatus status;
  bool imageEnhanced;
  int visual; // selects a placeholder illustration style

  /// Real photo bytes from the camera/gallery and from the backend's
  /// background-removal call. Session-only — intentionally left out of
  /// toJson/fromJson so we never try to stuff large binary blobs into
  /// shared_preferences.
  Uint8List? originalImageBytes;
  Uint8List? enhancedImageBytes;

  /// Extra photos beyond the cover image — each product keeps its own list,
  /// so adding a photo to one product never touches another's images.
  List<Uint8List> gallery;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.material,
    required this.craft,
    required this.origin,
    required this.descriptions,
    required this.keywords,
    required this.rawMaterialCost,
    required this.craftingDays,
    required this.otherCosts,
    this.recommendedPrice,
    this.rangeLow = 0,
    this.rangeHigh = 0,
    required this.price,
    this.status = ProductStatus.draft,
    this.imageEnhanced = false,
    this.visual = 0,
    this.originalImageBytes,
    this.enhancedImageBytes,
    List<Uint8List>? gallery,
  }) : gallery = gallery ?? <Uint8List>[];

  String descriptionFor(AppLanguage lang) =>
      descriptions[lang.code] ?? descriptions['en'] ?? '';

  Product copy() => Product(
        id: id,
        name: name,
        category: category,
        material: material,
        craft: craft,
        origin: origin,
        descriptions: Map<String, String>.of(descriptions),
        keywords: List<String>.of(keywords),
        rawMaterialCost: rawMaterialCost,
        craftingDays: craftingDays,
        otherCosts: otherCosts,
        recommendedPrice: recommendedPrice,
        rangeLow: rangeLow,
        rangeHigh: rangeHigh,
        price: price,
        status: status,
        imageEnhanced: imageEnhanced,
        visual: visual,
        gallery: List<Uint8List>.of(gallery),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'material': material,
        'craft': craft,
        'origin': origin,
        'descriptions': descriptions,
        'keywords': keywords,
        'rawMaterialCost': rawMaterialCost,
        'craftingDays': craftingDays,
        'otherCosts': otherCosts,
        'recommendedPrice': recommendedPrice,
        'rangeLow': rangeLow,
        'rangeHigh': rangeHigh,
        'price': price,
        'status': status.index,
        'imageEnhanced': imageEnhanced,
        'visual': visual,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        material: json['material'] as String,
        craft: json['craft'] as String,
        origin: json['origin'] as String,
        descriptions: Map<String, String>.from(json['descriptions'] ?? {}),
        keywords: List<String>.from(json['keywords'] ?? []),
        rawMaterialCost: (json['rawMaterialCost'] ?? 0).toDouble(),
        craftingDays: json['craftingDays'] ?? 1,
        otherCosts: (json['otherCosts'] ?? 0).toDouble(),
        recommendedPrice: (json['recommendedPrice'] as num?)?.toDouble(),
        rangeLow: (json['rangeLow'] ?? 0).toDouble(),
        rangeHigh: (json['rangeHigh'] ?? 0).toDouble(),
        price: (json['price'] ?? 0).toDouble(),
        status: ProductStatus.values[json['status'] ?? 0],
        imageEnhanced: json['imageEnhanced'] ?? false,
        visual: json['visual'] ?? 0,
      );
}
