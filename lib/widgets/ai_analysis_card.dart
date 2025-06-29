// lib/widgets/ai_analysis_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futbol_analiz_app/widgets/ai_loading_indicator.dart';

class AiAnalysisCard extends StatelessWidget {
  final AsyncValue<String> aiCommentary;
  final List<Color> gradientColors;

  const AiAnalysisCard({
    super.key,
    required this.aiCommentary,
    required this.gradientColors,
  });

  // Yapay zekadan gelen metni bölümlere ayıran yardımcı metot
  Map<String, String> _parseAiCommentary(String commentary) {
    final sections = <String, String>{};
    final lines = commentary.split('\n');
    String? currentSection;
    StringBuffer content = StringBuffer();

    for (var line in lines) {
      if (line.startsWith('### ')) {
        if (currentSection != null) {
          sections[currentSection] = content.toString().trim();
        }
        currentSection = line.substring(4).trim();
        content.clear();
      } else if (currentSection != null) {
        content.writeln(line);
      }
    }
    if (currentSection != null) {
      sections[currentSection] = content.toString().trim();
    }
    return sections;
  }

  // Bölüm başlığını ve içeriğini oluşturan yardımcı widget
  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    final contentLines = content.replaceAll('- **', '• **').split('\n');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...contentLines.map((line) => _buildContentRow(context, line)).toList(),
        ],
      ),
    );
  }

  // Kalın metinleri işleyen içerik satırı oluşturan yardımcı widget
  Widget _buildContentRow(BuildContext context, String line) {
    if (line.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    List<TextSpan> spans = [];
    // Metni "**" karakterine göre bölerek kalın kısımları ayırıyoruz
    final parts = line.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (i.isOdd) { // Kalın yazılacak kısım
        spans.add(TextSpan(
          text: parts[i],
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ));
      } else { // Normal kısım
        spans.add(TextSpan(text: parts[i]));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          children: spans,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // İsteğiniz üzerine daha şık ve modern bir kart tasarımı
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined,
                    color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Yapay Zeka Maç Analizi',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),
            aiCommentary.when(
              data: (commentary) {
                if (commentary.isEmpty) {
                  return const SizedBox.shrink();
                }
                final sections = _parseAiCommentary(commentary);

                final temelBeklentiler = sections['Temel Beklentiler'] ?? '';
                final istatistikselBeklentiler = sections['İstatistiksel Beklentiler'] ?? '';
                final macYorumu = sections['Maç Yorumu ve Kilit Noktalar'] ?? '';
                final oneCikanTahmin = sections['Öne Çıkan Tahmin'] ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (temelBeklentiler.isNotEmpty) _buildSection(context, 'Temel Beklentiler', temelBeklentiler),
                    if (istatistikselBeklentiler.isNotEmpty) _buildSection(context, 'İstatistiksel Beklentiler', istatistikselBeklentiler),
                    if (macYorumu.isNotEmpty) _buildSection(context, 'Maç Yorumu', macYorumu),
                    if (oneCikanTahmin.isNotEmpty) ...[
                      const Divider(height: 16, thickness: 0.5),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                                children: [
                                  TextSpan(text: oneCikanTahmin.replaceAll('**', '') , style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 16))
                                ]
                            ),
                          )
                        ),
                      )
                    ]
                  ],
                );
              },
              loading: () => const AiLoadingIndicator(),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    "Yapay zeka analizi alınamadı.\nLütfen tekrar deneyin.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
