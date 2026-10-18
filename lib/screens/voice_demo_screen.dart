import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../services/api_service.dart';
import '../services/demo_service.dart';
import '../theme/app_theme.dart';
import 'catalog_screen.dart';

enum _VoiceStage { idle, listening, processing, done }

class VoiceDemoScreen extends StatefulWidget {
  const VoiceDemoScreen({super.key});

  @override
  State<VoiceDemoScreen> createState() => _VoiceDemoScreenState();
}

class _VoiceDemoScreenState extends State<VoiceDemoScreen> {
  final AudioRecorder _recorder = AudioRecorder();

  _VoiceStage _stage = _VoiceStage.idle;
  int _checks = 0;
  late final bool _hadProductAlready;

  bool _usedRealMic = false;
  bool _usedRealTranscription = false;
  String _liveTranscript = _fallbackTranscript;
  String _detectedLanguageCode = 'ta';

  static const _fallbackTranscript = 'This is a handwoven cotton saree made in Madurai.';

  @override
  void initState() {
    super.initState();
    _hadProductAlready = context.read<AppState>().activeProduct != null;
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'ta':
        return 'Tamil';
      case 'hi':
        return 'Hindi';
      case 'en':
        return 'English';
      default:
        return code == 'unknown' ? 'Tamil' : code;
    }
  }

  List<String> get _resultSteps => [
        'Language detected: ${_languageLabel(_detectedLanguageCode)}',
        'Product details understood',
        'Catalogue created',
      ];

  Future<void> _start() async {
    setState(() => _stage = _VoiceStage.listening);

    String? recordingPath;
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        recordingPath = '${dir.path}/cribeit_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: recordingPath);
        _usedRealMic = true;
      }
    } catch (_) {
      _usedRealMic = false;
    }

    // Let the artisan speak for a few seconds.
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    Uint8List? audioBytes;
    if (_usedRealMic) {
      try {
        final path = await _recorder.stop();
        if (path != null) {
          audioBytes = await File(path).readAsBytes();
        }
      } catch (_) {
        audioBytes = null;
      }
    }

    setState(() => _stage = _VoiceStage.processing);

    if (audioBytes != null && audioBytes.isNotEmpty) {
      try {
        final result = await ApiService.transcribeVoice(audioBytes);
        if (result.text.trim().isNotEmpty) {
          _liveTranscript = result.text.trim();
          _detectedLanguageCode = result.language;
          _usedRealTranscription = true;
        }
      } catch (_) {
        _usedRealTranscription = false;
      }
    }

    if (!mounted) return;
    setState(() => _stage = _VoiceStage.done);

    for (int i = 0; i < _resultSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _checks = i + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finished = _stage == _VoiceStage.done && _checks == _resultSteps.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Assistant')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _stage == _VoiceStage.listening
                      ? AppColors.terracotta.withOpacity(0.18)
                      : AppColors.lavender.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _stage == _VoiceStage.listening ? Icons.mic : Icons.mic_none_outlined,
                  size: 52,
                  color: AppColors.burgundy,
                ),
              ),
              const SizedBox(height: 24),
              if (_stage == _VoiceStage.idle) ...[
                const Text('Tap the mic and describe your product',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 6),
                const Text(
                  'Speaks for ~4 seconds, then transcribes with a real speech-to-text backend.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ] else if (_stage == _VoiceStage.listening) ...[
                const Text('🎙 Listening...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(
                  _usedRealMic ? 'Recording your voice now...' : '"$_fallbackTranscript"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textMuted),
                ),
              ] else if (_stage == _VoiceStage.processing) ...[
                const Text('Processing your voice...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: AppColors.burgundy),
              ] else ...[
                const Text('Voice understood!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                  '"$_liveTranscript"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                ...List.generate(_resultSteps.length, (i) {
                  final done = i < _checks;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(done ? Icons.check_circle : Icons.circle_outlined,
                            size: 18, color: done ? AppColors.success : AppColors.charcoal.withOpacity(0.3)),
                        const SizedBox(width: 8),
                        Flexible(child: Text(_resultSteps[i], textAlign: TextAlign.center)),
                      ],
                    ),
                  );
                }),
                if (finished) ...[
                  const SizedBox(height: 8),
                  Text(
                    _usedRealTranscription
                        ? 'Transcribed live by the speech-to-text backend (AssemblyAI).'
                        : 'Backend unreachable — showing the simulated demo transcript.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
              const Spacer(),
              if (_stage == _VoiceStage.idle)
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.mic),
                  label: const Text('Start speaking'),
                )
              else if (finished)
                ElevatedButton.icon(
                  onPressed: () {
                    final appState = context.read<AppState>();
                    if (_hadProductAlready) {
                      Navigator.of(context).pop();
                    } else {
                      if (appState.activeProduct == null) appState.startAddProduct();
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CatalogScreen()));
                    }
                  },
                  icon: Icon(_hadProductAlready ? Icons.arrow_back : Icons.arrow_forward),
                  label: Text(_hadProductAlready ? 'Back to Catalog' : 'Create Catalogue'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
