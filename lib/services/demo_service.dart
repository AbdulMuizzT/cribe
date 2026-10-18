import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/demo_data.dart';
import 'storage_service.dart';

/// Single app-wide state holder. Keeps the MVP simple: no backend,
/// everything is seeded/simulated and persisted locally when possible.
class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();

  Artisan artisan = DemoData.seedArtisan();
  AppLanguage language = AppLanguage.tamil;
  List<Product> products = DemoData.seedProducts();
  List<Buyer> buyers = DemoData.seedBuyers();
  bool onboarded = false;
  bool loaded = false;

  /// The product currently moving through Add -> Image Studio -> Catalog
  /// -> Pricing -> Listing -> Publish.
  Product? activeProduct;

  Future<void> init() async {
    onboarded = await _storage.isOnboarded();
    final savedLang = await _storage.loadLanguage();
    if (savedLang != null) language = savedLang;
    final savedArtisan = await _storage.loadArtisan();
    if (savedArtisan != null) artisan = savedArtisan;
    final savedProducts = await _storage.loadProducts();
    if (savedProducts != null && savedProducts.isNotEmpty) products = savedProducts;
    loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    language = lang;
    await _storage.saveLanguage(lang);
    notifyListeners();
  }

  Future<void> completeOnboarding(Artisan a) async {
    artisan = a;
    onboarded = true;
    await _storage.saveArtisan(a);
    await _storage.setOnboarded(true);
    notifyListeners();
  }

  /// Starts the demo add-product flow. Field VALUES are seeded from the
  /// sample saree purely as realistic demo defaults (so pricing etc. behave
  /// the same as before), but the new product always gets a fresh, unique
  /// id — so publishing it can never overwrite the real "Handwoven Cotton
  /// Saree" (or any other existing product) already sitting in the list.
  void startAddProduct() {
    final seed = DemoData.seedProducts().first;
    activeProduct = Product(
      id: 'product_${DateTime.now().millisecondsSinceEpoch}',
      name: seed.name,
      category: seed.category,
      material: seed.material,
      craft: seed.craft,
      origin: seed.origin,
      descriptions: Map<String, String>.of(seed.descriptions),
      keywords: List<String>.of(seed.keywords),
      rawMaterialCost: seed.rawMaterialCost,
      craftingDays: seed.craftingDays,
      otherCosts: seed.otherCosts,
      price: seed.price,
      recommendedPrice: seed.recommendedPrice,
      rangeLow: seed.rangeLow,
      rangeHigh: seed.rangeHigh,
      status: ProductStatus.draft,
      imageEnhanced: false,
      visual: products.length % 5,
    );
    notifyListeners();
  }

  /// Offline fallback used when the real backend can't be reached — flips
  /// the "enhanced" flag so the UI can at least show the tinted placeholder.
  void markImageEnhanced() {
    activeProduct?.imageEnhanced = true;
    notifyListeners();
  }

  /// Stores the real photo the artisan just took/picked.
  void setOriginalImage(Uint8List bytes) {
    activeProduct?.originalImageBytes = bytes;
    notifyListeners();
  }

  /// Stores the real background-removed photo returned by the backend.
  void setEnhancedImage(Uint8List bytes) {
    final p = activeProduct;
    if (p == null) return;
    p.enhancedImageBytes = bytes;
    p.imageEnhanced = true;
    notifyListeners();
  }

  /// Adds an extra photo to a specific product's gallery (works for any
  /// product in the list, not just the one being actively added — each
  /// product keeps its own independent set of images).
  Future<void> addGalleryImage(Product product, Uint8List bytes) async {
    product.gallery.add(bytes);
    await _storage.saveProducts(products);
    notifyListeners();
  }

  void updateActiveDescription(AppLanguage lang, String text) {
    activeProduct?.descriptions[lang.code] = text;
    notifyListeners();
  }

  void updateActiveKeywords(List<String> keywords) {
    if (keywords.isEmpty) return;
    activeProduct?.keywords = keywords;
    notifyListeners();
  }

  /// Demo pricing "AI": a simple, explainable formula computed from the
  /// artisan's own entered costs — not a real external market lookup.
  PricingRecommendation calculatePricing({
    required double materialCost,
    required int craftingDays,
    required double otherCosts,
  }) {
    final craftsmanship = craftingDays * 267.0;
    final marketPattern = materialCost * 0.375;
    final margin = otherCosts + 100.0;
    final recommended = materialCost + craftsmanship + marketPattern + margin;
    return PricingRecommendation(
      materialCost: materialCost,
      craftsmanship: craftsmanship,
      marketPattern: marketPattern,
      margin: margin,
      recommended: recommended,
      rangeLow: recommended - 350,
      rangeHigh: recommended + 350,
    );
  }

  void applyPricing(
    PricingRecommendation rec, {
    required double materialCost,
    required int craftingDays,
    required double otherCosts,
  }) {
    final p = activeProduct;
    if (p == null) return;
    p.rawMaterialCost = materialCost;
    p.craftingDays = craftingDays;
    p.otherCosts = otherCosts;
    p.recommendedPrice = rec.recommended;
    p.price = rec.recommended;
    p.rangeLow = rec.rangeLow;
    p.rangeHigh = rec.rangeHigh;
    p.status = ProductStatus.aiOptimized;
    notifyListeners();
  }

  Future<void> publishActiveProduct() async {
    final p = activeProduct;
    if (p == null) return;
    p.status = ProductStatus.published;
    final index = products.indexWhere((existing) => existing.id == p.id);
    if (index >= 0) {
      products[index] = p;
    } else {
      products.insert(0, p);
    }
    await _storage.saveProducts(products);
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    products.removeWhere((p) => p.id == id);
    await _storage.saveProducts(products);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      products[index] = product;
    }
    await _storage.saveProducts(products);
    notifyListeners();
  }

  Product? findProduct(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  int get publishedCount => products.where((p) => p.status == ProductStatus.published).length;
  double get inventoryValue => products.fold(0.0, (sum, p) => sum + p.price);

  // ---------------------------------------------------------------------
  // AI Demand & Business Intelligence (demo/calculated — no ML model,
  // just a transparent formula over the artisan's own product data).
  // ---------------------------------------------------------------------

  int _calculateHealthScore() {
    if (products.isEmpty) return 0;
    final publishedRatio = publishedCount / products.length;
    final avgPrice = inventoryValue / products.length;
    final base = (publishedRatio * 60).round();
    final priceBonus = avgPrice > 300 ? 16 : 8;
    final diversityBonus = products.map((p) => p.category).toSet().length * 4;
    return (base + priceBonus + diversityBonus).clamp(0, 100).toInt();
  }

  BusinessInsight get businessInsight {
    if (products.isEmpty) {
      return BusinessInsight(
        bestProductName: '—',
        demandHeadline: 'Add a product to see insights',
        demandDetail: '',
        recommendedProductionQty: 0,
        healthScore: 0,
      );
    }
    final textiles = products.where((p) => p.category.toLowerCase().contains('textile')).toList();
    final pool = textiles.isNotEmpty ? textiles : products;
    final sorted = List<Product>.of(pool)..sort((a, b) => b.price.compareTo(a.price));
    final best = sorted.first;

    final recommendedQty = 20 + (best.craftingDays * 3) + publishedCount;

    return BusinessInsight(
      bestProductName: best.name,
      demandHeadline: 'Pongal Demand Prediction',
      demandDetail: '${best.category} demand ↑ 32% this season',
      recommendedProductionQty: recommendedQty,
      healthScore: _calculateHealthScore(),
    );
  }

  // ---------------------------------------------------------------------
  // AI Buyer Matching — a local, explainable heuristic (keyword overlap +
  // budget fit) rather than a real matching service, so it works offline
  // and is reproducible for a demo.
  // ---------------------------------------------------------------------

  List<BuyerMatch> get buyerMatches {
    final matches = buyers.map((b) {
      Product? best;
      int bestScore = 0;
      final buyerWords = b.product.toLowerCase().split(RegExp(r'\s+'));
      for (final p in products) {
        int score = 0;
        final productText = '${p.name} ${p.category} ${p.material}'.toLowerCase();
        for (final w in buyerWords) {
          if (w.length > 2 && productText.contains(w)) score += 25;
        }
        if (p.price >= b.budgetMin * 0.7 && p.price <= b.budgetMax * 1.3) score += 20;
        if (score > bestScore) {
          bestScore = score;
          best = p;
        }
      }
      final matchPercent = (55 + bestScore).clamp(0, 97).toInt();
      return BuyerMatch(buyer: b, matchedProduct: best, matchPercent: matchPercent);
    }).toList();

    matches.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return matches;
  }
}
