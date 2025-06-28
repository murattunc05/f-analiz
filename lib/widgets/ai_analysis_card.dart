// lib/widgets/ai_analysis_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futbol_analiz_app/widgets/ai_loading_indicator.dart';
import 'package:markdown_widget/markdown_widget.dart';

class AiAnalysisCard extends StatelessWidget {
  // GÜNCELLENDİ: Tekrar String tipini alacak
  final AsyncValue<String> aiCommentary;
  final List<Color> gradientColors;

  const AiAnalysisCard({
    super.key,
    required this.aiCommentary,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withAlpha((255 * 0.3).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Yapay Zeka Maç Analizi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
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
                    // GÜNCELLENDİ: MarkdownWidget, yeni formatı işleyecek şekilde ayarlandı.
                    return MarkdownWidget(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      data: commentary,
                      config: MarkdownConfig(
                        configs: [
                          PConfig(
                            textStyle: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                          ),
                          // ### ile gelen başlıklar için stil
                          H3Config(
                            style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                  height: 2.0
                                ),
                          ),
                          // - ile gelen liste elemanları için stil
                          LiConfig(
                             style: theme.textTheme.bodyMedium,
                             dotSize: 5,
                             dotMargin: const EdgeInsets.only(top: 4, left: 4, right: 8),
                             // Liste elemanları arasındaki boşluk
                             childMargin: const EdgeInsets.symmetric(vertical: 4),
                          )
                        ],
                      ),
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
        ),
      ),
    );
  }
}
