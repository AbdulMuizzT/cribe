import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/demo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/craft_visual.dart';
import 'image_studio_screen.dart';
import 'voice_demo_screen.dart';

class AddProductScreen extends StatefulWidget {
  final bool embedded;
  const AddProductScreen({super.key, this.embedded = false});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  bool _busy = false;

  void _selectSeededProduct(BuildContext context) {
    context.read<AppState>().startAddProduct();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImageStudioScreen()));
  }

  /// Opens the real camera or gallery, reads the picked photo, and starts
  /// the add-product flow with that real image (used by AI Image Studio).
  Future<void> _pickRealPhoto(BuildContext context, ImageSource source) async {
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
      if (xfile == null) return; // user cancelled — nothing to do
      final bytes = await xfile.readAsBytes();
      if (!context.mounted) return;
      final appState = context.read<AppState>();
      appState.startAddProduct();
      appState.setOriginalImage(bytes);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImageStudioScreen()));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera/gallery: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add a product', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Bring one of your handmade products into CribeIt.', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickRealPhoto(context, ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Take Photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickRealPhoto(context, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Upload'),
                ),
              ),
            ],
          ),
          if (_busy) const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(color: AppColors.burgundy),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VoiceDemoScreen())),
            icon: const Icon(Icons.mic_none_outlined),
            label: const Text('Describe by Voice'),
          ),
          const SizedBox(height: 28),
          const Text('Or use a sample (no camera needed)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _selectSeededProduct(context),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.charcoal.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    child: CraftVisual(visualIndex: 0, width: 64, height: 64),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Handwoven Cotton Saree', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('Tap to use a demo illustration instead', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.burgundy),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(appBar: AppBar(title: const Text('Add Product')), body: content);
  }
}
