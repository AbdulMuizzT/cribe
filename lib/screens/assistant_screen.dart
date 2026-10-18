import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/demo_service.dart';
import '../theme/app_theme.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _ChatMessage {
  final String text;
  final bool fromUser;
  final bool isLive; // answered by the real Gemini backend vs. a fallback
  _ChatMessage(this.text, this.fromUser, {this.isLive = false});
}

class _AssistantScreenState extends State<AssistantScreen> {
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      "Hi! I'm your CribeIt AI Business Manager. Ask me about pricing, promotion, "
      "sales strategy, or anything about your products — I know what's in your catalog.",
      false,
    ),
  ];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _sending = false;

  static const _questions = [
    'Which product should I promote?',
    'How should I price this?',
    'How can I increase sales?',
    'Create an advertisement for my saree',
    'Which products are performing best?',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _languageName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hindi:
        return 'Hindi';
      case AppLanguage.tamil:
        return 'Tamil';
      case AppLanguage.english:
        return 'English';
    }
  }

  /// Realistic canned answers used only if the live Gemini backend can't be
  /// reached — keeps the demo working offline or without a configured key.
  String _fallbackAnswer(String question, AppState appState) {
    final products = appState.products;
    final best = products.isNotEmpty
        ? (List<Product>.of(products)..sort((a, b) => b.price.compareTo(a.price))).first
        : null;

    switch (question) {
      case 'Which product should I promote?':
        return best == null
            ? "Add a product first, then I can tell you which one to promote."
            : 'I\'d promote "${best.name}" — it\'s your highest-value listing right now and photographs well once enhanced.';
      case 'How should I price this?':
        return 'Based on your demo pricing model, the Handwoven Cotton Saree is recommended at ₹2,850 (range ₹2,500–₹3,200). Use the AI Price Assistant on each product for a tailored number.';
      case 'How can I increase sales?':
        return 'Three quick wins: enhance your product photos with AI Image Studio, make sure every listing is published (not left as a draft), and respond quickly to matched buyer opportunities in Markets.';
      case 'Create an advertisement for my saree':
        return '"Handwoven in Madurai, worn with pride. Discover a cotton saree that carries generations of craftsmanship — soft, breathable, and made just for you by Lakshmi Devi."';
      case 'Which products are performing best?':
        return 'You have ${appState.publishedCount} published out of ${products.length} products, worth ₹${appState.inventoryValue.toStringAsFixed(0)} in total inventory value.';
      default:
        return "I can help with pricing, promotion, sales strategy, and product descriptions — try one of the quick questions above or ask me directly.";
    }
  }

  Future<void> _ask(String question) async {
    if (question.trim().isEmpty || _sending) return;
    final appState = context.read<AppState>();

    setState(() {
      _messages.add(_ChatMessage(question, true));
      _sending = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    String answer;
    bool isLive = false;
    try {
      answer = await ApiService.askBusinessManager(
        question: question,
        language: _languageName(appState.language),
        artisanName: appState.artisan.name,
        products: appState.products
            .map((p) => {
                  'name': p.name,
                  'category': p.category,
                  'price': p.price,
                  'status': p.status.name,
                })
            .toList(),
      );
      if (answer.trim().isEmpty) throw Exception('empty response');
      isLive = true;
    } catch (_) {
      answer = _fallbackAnswer(question, appState);
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(answer, false, isLive: isLive));
      _sending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Business Manager')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.burgundy),
                        ),
                      ),
                    );
                  }
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: msg.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          decoration: BoxDecoration(
                            color: msg.fromUser ? AppColors.burgundy : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: msg.fromUser ? null : Border.all(color: AppColors.charcoal.withOpacity(0.1)),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(color: msg.fromUser ? Colors.white : AppColors.charcoal),
                          ),
                        ),
                        if (!msg.fromUser && msg.isLive)
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              'Answered live by Gemini',
                              style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _questions.map((q) => ActionChip(label: Text(q), onPressed: () => _ask(q))).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      decoration: const InputDecoration(hintText: 'Ask your business manager anything...'),
                      onSubmitted: (v) => _ask(v),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.burgundy),
                    onPressed: _sending ? null : () => _ask(_inputCtrl.text),
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
