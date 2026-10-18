import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Opens a full-screen, pinch-to-zoom view of a product photo.
void showFullScreenImage(BuildContext context, Uint8List bytes) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => _FullScreenImageViewer(bytes: bytes),
    ),
  );
}

class _FullScreenImageViewer extends StatelessWidget {
  final Uint8List bytes;
  const _FullScreenImageViewer({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.memory(bytes),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
