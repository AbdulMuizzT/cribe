import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_strings.dart';
import '../models/models.dart';
import '../services/demo_service.dart';
import '../theme/app_theme.dart';

class MarketsScreen extends StatelessWidget {
  final bool embedded;
  const MarketsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.language;
    final matches = appState.buyerMatches;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (embedded) ...[
            Text(AppStrings.t(lang, 'markets'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
          ],
          Text(AppStrings.t(lang, 'buyerOpportunities'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Matched against your products — a local demo heuristic, not a live marketplace feed.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          ...matches.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BuyerMatchCard(match: m, lang: lang),
              )),

          const SizedBox(height: 12),
          Text(AppStrings.t(lang, 'demandBoard'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _DemandBoard(buyers: appState.buyers),

          const SizedBox(height: 20),
          const Text('Government / Digital Marketplace', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.lavender.withOpacity(0.2), borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.public, color: AppColors.burgundy),
                    SizedBox(width: 10),
                    Expanded(child: Text('Explore supported marketplaces', style: TextStyle(fontWeight: FontWeight.w700))),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'ONDC, GeM and state emporiums — a simulated demo connection, not a live integration.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => _showDemoConnection(context),
                  child: const Text('Connect (Demo)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (embedded) return content;
    return Scaffold(appBar: AppBar(title: Text(AppStrings.t(lang, 'markets'))), body: content);
  }

  void _showDemoConnection(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Simulated connection'),
        content: const Text(
          'This is a hackathon demo. In a live version, CribeIt would securely connect your catalog to ONDC / GeM digital marketplaces.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Got it')),
        ],
      ),
    );
  }
}

class _BuyerMatchCard extends StatelessWidget {
  final BuyerMatch match;
  final AppLanguage lang;
  const _BuyerMatchCard({required this.match, required this.lang});

  Color _matchColor(int percent) {
    if (percent >= 85) return AppColors.success;
    if (percent >= 65) return AppColors.terracotta;
    return AppColors.charcoal.withOpacity(0.5);
  }

  @override
  Widget build(BuildContext context) {
    final buyer = match.buyer;
    final color = _matchColor(match.matchPercent);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.charcoal.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.terracotta.withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.storefront, color: AppColors.terracotta),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(buyer.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${buyer.type} · ${buyer.location}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${match.matchPercent}% ${AppStrings.t(lang, 'match')}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _row('Looking for', buyer.product),
          _row('Quantity', '${buyer.quantity} pieces'),
          _row('Budget', '₹${buyer.budgetMin.toStringAsFixed(0)} – ₹${buyer.budgetMax.toStringAsFixed(0)}'),
          _row('Delivery', '${buyer.deliveryDays} days'),
          if (match.matchedProduct != null) _row('Best match in your catalog', match.matchedProduct!.name),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _sendQuote(context, buyer),
              icon: const Icon(Icons.send_outlined, size: 16),
              label: Text(AppStrings.t(lang, 'sendQuote')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  void _sendQuote(BuildContext context, Buyer buyer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quote sent!'),
        content: Text(
          'Your quote for "${match.matchedProduct?.name ?? buyer.product}" has been sent to ${buyer.name}. '
          '(Simulated for this demo — no real message is sent.)',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
        ],
      ),
    );
  }
}

/// Simple board showing what buyers currently want, grouped by product.
class _DemandBoard extends StatelessWidget {
  final List<Buyer> buyers;
  const _DemandBoard({required this.buyers});

  @override
  Widget build(BuildContext context) {
    if (buyers.isEmpty) {
      return const Text('No buyer demand data yet.', style: TextStyle(color: AppColors.textMuted));
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.charcoal.withOpacity(0.08)),
      ),
      child: Column(
        children: List.generate(buyers.length, (i) {
          final b = buyers[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: i == buyers.length - 1
                  ? null
                  : Border(bottom: BorderSide(color: AppColors.charcoal.withOpacity(0.06))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(b.product, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('${b.quantity} units', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('₹${b.budgetMin.toStringAsFixed(0)}+', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
