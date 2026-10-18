import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/app_strings.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/demo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';
import '../widgets/ai_processing_view.dart';
import '../widgets/fullscreen_image_viewer.dart';
import 'heritage_passport_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Future<void> _improveWithAI(Product product) async {
    final original = product.originalImageBytes;
    final backendCall = original != null
        ? ApiService.enhanceImage(original).then<dynamic>((bytes) => bytes).catchError((_) => null)
        : Future<dynamic>.value(null);

    await showAIProcessingDialog(
      context: context,
      title: 'Improving with AI',
      steps: const ['Analyzing image', 'Removing background', 'Improving lighting', 'Optimizing composition'],
    );
    if (!mounted) return;

    final result = await backendCall;
    if (result is Uint8List) {
      product.enhancedImageBytes = result;
    }
    product.imageEnhanced = true;
    if (product.status == ProductStatus.draft) product.status = ProductStatus.aiOptimized;
    await context.read<AppState>().updateProduct(product);
    setState(() {});
  }

  Future<void> _changePrice(Product product) async {
    final controller = TextEditingController(text: product.price.toStringAsFixed(0));
    final newPrice = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Price'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₹ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newPrice != null && mounted) {
      product.price = newPrice;
      await context.read<AppState>().updateProduct(product);
      setState(() {});
    }
  }

  Future<void> _publish(Product product) async {
    await showAIProcessingDialog(
      context: context,
      title: 'Publishing',
      steps: const ['Product information', 'Professional image', 'Description', 'Price', 'Artisan profile'],
    );
    if (!mounted) return;
    product.status = ProductStatus.published;
    await context.read<AppState>().updateProduct(product);
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Your product is market-ready. Published ✓')));
  }

  Future<void> _addPhoto(Product product, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      if (!mounted) return;
      await context.read<AppState>().addGalleryImage(product, bytes);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add photo: $e')));
      }
    }
  }

  void _showAddPhotoOptions(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _addPhoto(product, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _addPhoto(product, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editListing(Product product) {
    final appState = context.read<AppState>();
    final nameCtrl = TextEditingController(text: product.name);
    final descCtrl = TextEditingController(text: product.descriptionFor(appState.language));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product name')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                product.name = nameCtrl.text.trim().isEmpty ? product.name : nameCtrl.text.trim();
                product.descriptions[appState.language.code] = descCtrl.text;
                await appState.updateProduct(product);
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                if (mounted) setState(() {});
              },
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final product = appState.findProduct(widget.productId);

    if (product == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Product not found.')));
    }

    final description = product.descriptionFor(appState.language);
    final lang = appState.language;
    final coverBytes = product.enhancedImageBytes ?? product.originalImageBytes;

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: coverBytes != null ? () => showFullScreenImage(context, coverBytes) : null,
                child: ProductImage(
                  product: product,
                  preferEnhanced: true,
                  width: double.infinity,
                  height: 200,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 10),

              // Extra photo gallery for this specific product.
              SizedBox(
                height: 64,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...product.gallery.map((bytes) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => showFullScreenImage(context, bytes),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover),
                            ),
                          ),
                        )),
                    InkWell(
                      onTap: () => _showAddPhotoOptions(product),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.charcoal.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.charcoal.withOpacity(0.15)),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: AppColors.burgundy, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('₹${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.burgundy)),
              const SizedBox(height: 12),
              Text(description),
              const SizedBox(height: 16),
              _row('Material', product.material),
              _row('Craft', product.craft),
              _row('Origin', product.origin),
              _row('AI status', product.imageEnhanced ? 'Enhanced' : 'Original'),
              _row(
                'Marketplace status',
                product.status == ProductStatus.published
                    ? 'Published'
                    : product.status == ProductStatus.aiOptimized
                        ? 'AI Optimized'
                        : 'Draft',
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => HeritagePassportScreen(productId: product.id))),
                icon: const Icon(Icons.verified_outlined),
                label: Text(AppStrings.t(lang, 'heritagePassport')),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                      onPressed: () => _editListing(product),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(AppStrings.t(lang, 'edit'))),
                  OutlinedButton.icon(
                      onPressed: () => _improveWithAI(product),
                      icon: const Icon(Icons.auto_fix_high),
                      label: Text(AppStrings.t(lang, 'improveWithAI'))),
                  OutlinedButton.icon(
                      onPressed: () => _changePrice(product),
                      icon: const Icon(Icons.sell_outlined),
                      label: Text(AppStrings.t(lang, 'changePrice'))),
                  ElevatedButton.icon(
                    onPressed: product.status == ProductStatus.published ? null : () => _publish(product),
                    icon: const Icon(Icons.publish_outlined),
                    label: Text(product.status == ProductStatus.published ? 'Published' : AppStrings.t(lang, 'publish')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
