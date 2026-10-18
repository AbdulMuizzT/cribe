import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/heritage_templates.dart';
import '../models/models.dart';
import '../services/demo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';

class HeritagePassportScreen extends StatelessWidget {
  final String productId;
  const HeritagePassportScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final product = appState.findProduct(productId);
    final artisan = appState.artisan;

    if (product == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Product not found.')));
    }

    final authenticityId = HeritageTemplates.authenticityId(product);
    final verificationUrl = HeritageTemplates.verificationUrl(product);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Heritage Passport')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Passport "card" header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.burgundy,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, color: AppColors.lavender, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'CRIBEIT AUTHENTICITY PASSPORT',
                          style: TextStyle(color: AppColors.lavender, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ProductImage(
                      product: product,
                      preferEnhanced: true,
                      width: double.infinity,
                      height: 180,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      product.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text('Made by: ${artisan.name}', style: const TextStyle(color: Colors.white70)),
                    Text('Craft: ${product.craft}', style: const TextStyle(color: Colors.white70)),
                    Text('Location: ${product.origin}', style: const TextStyle(color: Colors.white70)),
                    Text('Material: ${product.material}', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text('"Meet the artisan behind the product."',
                  style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textMuted)),

              const SizedBox(height: 20),
              _sectionTitle('Making Process'),
              const SizedBox(height: 8),
              Text(HeritageTemplates.makingProcess(product)),

              const SizedBox(height: 20),
              _sectionTitle("The Artisan's Story"),
              const SizedBox(height: 8),
              Text(HeritageTemplates.artisanStory(artisan, product)),

              const SizedBox(height: 24),
              _sectionTitle('Authenticity'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.charcoal.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: verificationUrl,
                      version: QrVersions.auto,
                      size: 160,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.burgundy),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 14),
                    const Text('Authenticity ID', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(authenticityId, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    const Text(
                      'Concept demo — scanning this QR shows how a buyer could one day verify a product\'s origin. No live verification server exists yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
}
