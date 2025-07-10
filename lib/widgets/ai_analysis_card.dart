// lib/widgets/ai_analysis_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futbol_analiz_app/widgets/ai_loading_indicator.dart';
import 'dart:ui';

class AiAnalysisCard extends StatelessWidget {
  final AsyncValue<String> aiCommentary;

  const AiAnalysisCard({
    super.key,
    required this.aiCommentary,
  });

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

  Widget _buildContentRow(BuildContext context, String line) {
    if (line.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    List<TextSpan> textSpans = [];
    final parts = line.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (i.isOdd) {
        textSpans.add(TextSpan(
          text: parts[i],
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ));
      } else {
        textSpans.add(TextSpan(text: parts[i]));
      }
    }
    
    if (line.trim().startsWith('- ')) {
      final contentWithoutDash = line.trim().substring(2);
      final contentParts = contentWithoutDash.split('**');
      List<TextSpan> contentSpans = [];
      for (int i = 0; i < contentParts.length; i++) {
          if (i.isOdd) {
              contentSpans.add(TextSpan(text: contentParts[i], style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)));
          } else {
              contentSpans.add(TextSpan(text: contentParts[i]));
          }
      }
      return Padding(
        padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("• ", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.colorScheme.onSurface.withOpacity(0.85)),
                  children: contentSpans,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.colorScheme.onSurface.withOpacity(0.85)),
          children: textSpans,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: theme.colorScheme.surface.withOpacity(0.7),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.surface.withOpacity(0.0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight
            )
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withOpacity(0.15),
                      ),
                      child: Icon(Icons.auto_awesome_outlined, color: theme.colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Yapay Zeka Analizi',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                aiCommentary.when(
                  data: (commentary) {
                    if (commentary.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final sections = _parseAiCommentary(commentary);
                    
                    final oneCikanTahmin = sections.remove('Öne Çıkan Tahmin');
                    
                    // YENİ: İkon haritası ile dinamik bölüm oluşturma
                    final Map<String, IconData> sectionIcons = {
                        'Temel Beklentiler': Icons.gavel_rounded,
                        'İstatistiksel Beklentiler': Icons.bar_chart_rounded,
                        'Detaylı Yorum': Icons.notes_outlined, // <<< HATA DÜZELTİLDİ
                        // Bu alt başlıklar otomatik olarak 'Detaylı Yorum' altında işlenecek.
                        'Oyun Stilleri': Icons.sports_soccer_outlined,
                        'Kilit Faktör': Icons.vpn_key_outlined,
                        'Lig Kalitesi Etkisi': Icons.military_tech_outlined,
                    };

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...sections.entries.map((entry) {
                          // 'Detaylı Yorum' bölümünü ve alt başlıklarını daha iyi gruplamak için
                          // özel bir mantık ekleyebiliriz veya basitçe gösterebiliriz.
                          // Şimdilik hepsi aynı stilde gösterilecek.
                           if (entry.value.trim().isEmpty) return const SizedBox.shrink();
                           return _buildSection(context, entry.key, entry.value, sectionIcons[entry.key] ?? Icons.info_outline);
                        }),
                        if (oneCikanTahmin != null && oneCikanTahmin.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildFeaturedPrediction(context, oneCikanTahmin),
                        ]
                      ],
                    );
                  },
                  loading: () => const AiLoadingIndicator(),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            "Yapay zeka analizi alınamadı.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Lütfen tekrar deneyin.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.error.withOpacity(0.8)),
                          ),
                        ],
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

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    final theme = Theme.of(context);
    final contentLines = content.split('\n');

    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...contentLines.where((l) => l.trim().isNotEmpty).map((line) => _buildContentRow(context, line)),
        ],
      ),
    );
  }
  
  Widget _buildFeaturedPrediction(BuildContext context, String predictionText) {
    final theme = Theme.of(context);
    final cleanText = predictionText.replaceAll('**', '');

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border_rounded, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cleanText,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 16
              ),
            ),
          ),
        ],
      ),
    );
  }
}
