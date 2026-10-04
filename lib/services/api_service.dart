import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Base URL of your local CribeIt backend (see the /backend folder).
///
/// - Android emulator, backend running on your own computer: leave this as
///   10.0.2.2 — that address always means "the host machine" from inside
///   the Android emulator.
/// - Physical Android phone: replace with your computer's LAN IP, e.g.
///   'http://192.168.1.42:3000' (phone and computer must be on the same
///   Wi-Fi network, and the backend must be running with `npm start`).
const String kBackendBaseUrl = 'http://127.0.0.1:3000';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class CatalogResult {
  final String en;
  final String hi;
  final String ta;
  final List<String> keywords;

  CatalogResult({required this.en, required this.hi, required this.ta, required this.keywords});
}

class VoiceResult {
  final String text;
  final String language;

  VoiceResult({required this.text, required this.language});
}

/// Thin wrapper around the three backend endpoints. Every method throws
/// ApiException on failure — callers are expected to catch it and fall back
/// to the local simulated demo behaviour, so the app never breaks when the
/// backend isn't running or a free API key has run out of quota.
class ApiService {
  static Future<Uint8List> enhanceImage(Uint8List imageBytes, {String filename = 'product.jpg'}) async {
    try {
      final uri = Uri.parse('$kBackendBaseUrl/api/enhance');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: filename));
      final streamed = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw ApiException('Image enhancement failed (HTTP ${response.statusCode}).');
      }
      return response.bodyBytes;
    } catch (e) {
      throw ApiException('Could not reach the AI Image Studio backend: $e');
    }
  }

  static Future<CatalogResult> generateCatalog({
    required String name,
    required String material,
    required String craft,
    required String origin,
    required String category,
  }) async {
    try {
      final uri = Uri.parse('$kBackendBaseUrl/api/catalog');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'material': material,
              'craft': craft,
              'origin': origin,
              'category': category,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw ApiException('Catalog generation failed (HTTP ${response.statusCode}).');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CatalogResult(
        en: (data['en'] ?? '').toString(),
        hi: (data['hi'] ?? '').toString(),
        ta: (data['ta'] ?? '').toString(),
        keywords: List<String>.from(data['keywords'] ?? const []),
      );
    } catch (e) {
      throw ApiException('Could not reach the AI Catalog backend: $e');
    }
  }

  static Future<VoiceResult> transcribeVoice(Uint8List audioBytes, {String filename = 'voice.m4a'}) async {
    try {
      final uri = Uri.parse('$kBackendBaseUrl/api/voice');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes('audio', audioBytes, filename: filename));
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw ApiException('Voice transcription failed (HTTP ${response.statusCode}).');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return VoiceResult(
        text: (data['text'] ?? '').toString(),
        language: (data['language'] ?? 'unknown').toString(),
      );
    } catch (e) {
      throw ApiException('Could not reach the Voice Assistant backend: $e');
    }
  }
}
