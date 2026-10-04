import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'craft_visual.dart';

/// Shows the product's real photo (picked from camera/gallery, optionally
/// background-removed by the backend) when we have one, and falls back to
/// the local illustrated placeholder otherwise — so the UI never breaks
/// just because a photo hasn't been taken yet or the backend is offline.
class ProductImage extends StatelessWidget {
  final Product product;
  final bool preferEnhanced;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.product,
    this.preferEnhanced = false,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes =
        preferEnhanced ? (product.enhancedImageBytes ?? product.originalImageBytes) : product.originalImageBytes;

    Widget child;
    if (bytes != null) {
      child = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CraftVisual(
          visualIndex: product.visual,
          enhanced: preferEnhanced && product.imageEnhanced,
          width: width,
          height: height,
        ),
      );
    } else {
      child = CraftVisual(
        visualIndex: product.visual,
        enhanced: preferEnhanced && product.imageEnhanced,
        width: width,
        height: height,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
