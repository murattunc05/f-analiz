// lib/widgets/ai_analysis_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futbol_analiz_app/widgets/ai_loading_indicator.dart';
import 'dart:ui';

class AiAnalysisCard extends StatefulWidget {
  final AsyncValue<String> aiCommentary;

  const AiAnalysisCard({
    super.key,
    required this.aiCommentary,
  });

  @override
  State<AiAnalysisCard> createState() => _AiAnalysisCardState();
}

class _AiAnalysisCardState extends State<AiAnalysisCard> {
  // Açılır-kapanır bölümler için state
  final Map<String, bool> _expandedSections = {};

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
              contentSpans.add(TextSpan(text: contentParts[i], style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)));
          } else {
              contentSpans.add(TextSpan(text: contentParts[i]));
          }
      }
      return Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 6, right: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6, 
                    color: theme.colorScheme.onSurface.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  children: contentSpans,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6, 
            color: theme.colorScheme.onSurface.withOpacity(0.9),
            fontSize: 14,
          ),
          children: textSpans.map((span) {
            if (span.style?.fontWeight == FontWeight.bold) {
              return TextSpan(
                text: span.text,
                style: span.style?.copyWith(color: theme.colorScheme.primary),
              );
            }
            return span;
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.secondary.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium başlık
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.15),
                          theme.colorScheme.secondary.withOpacity(0.1),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Maç Analizi',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Gelişmiş yapay zeka yorumu',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'PREMIUM',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  widget.aiCommentary.when(
                    data: (commentary) {
                      if (commentary.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final sections = _parseAiCommentary(commentary);
                      
                      final oneCikanTahmin = sections.remove('Öne Çıkan Tahmin');
                      
                      // Gelişmiş ikon haritası - Yeni analiz bölümleri
                      final Map<String, IconData> sectionIcons = {
                          // Temel tahmin bölümleri
                          'Maç Tahmini': Icons.sports_soccer_rounded,
                          'Temel Beklentiler': Icons.gavel_rounded,
                          'İstatistiksel Beklentiler': Icons.bar_chart_rounded,
                          
                          // Taktiksel analiz
                          'Taktiksel Analiz': Icons.psychology_outlined,
                          'Oyun Stilleri': Icons.sports_outlined,
                          'Detaylı Yorum': Icons.notes_outlined,
                          
                          // Kritik faktörler
                          'Kritik Faktörler': Icons.priority_high_rounded,
                          'Kilit Faktör': Icons.vpn_key_outlined,
                          'Form Durumu': Icons.trending_up_rounded,
                          'Lig Kalitesi Etkisi': Icons.military_tech_outlined,
                          'Lig Farkı Etkisi': Icons.compare_arrows_rounded,
                          
                          // Bahis önerileri
                          'Bahis Önerileri': Icons.casino_outlined,
                          'Ana Bahis': Icons.star_border_rounded,
                          'Gol Beklentisi': Icons.sports_soccer_outlined,
                          'Alternatif Bahisler': Icons.more_horiz_rounded,
                      };

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...sections.entries.map((entry) {
                             if (entry.value.trim().isEmpty) return const SizedBox.shrink();
                             return _buildSection(context, entry.key, entry.value, sectionIcons[entry.key] ?? Icons.info_outline);
                          }),
                          if (oneCikanTahmin != null && oneCikanTahmin.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildFeaturedPrediction(context, oneCikanTahmin),
                          ],
                          // Açıklama metni
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bu yorumlar takımların istatistikleri ve form grafiklerinden yola çıkarak oluşturulmuş AI analizleridir. Sadece fikir edinmeniz için sunulmaktadır. Lütfen sunduğumuz istatistiklerden kendi analiz ve çıkarımlarınızı yapınız.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    final theme = Theme.of(context);
    final contentLines = content.split('\n');
    
    // Açılır-kapanır olacak bölümler
    final collapsibleSections = {
      'Taktiksel Analiz', 'Kritik Faktörler', 'Bahis Önerileri', 
      'Detaylı Yorum', 'Lig Farkı Etkisi', 'Form Durumu'
    };
    
    final isCollapsible = collapsibleSections.contains(title);
    final isExpanded = _expandedSections[title] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık - tıklanabilir
          InkWell(
            onTap: isCollapsible ? () {
              setState(() {
                _expandedSections[title] = !isExpanded;
              });
            } : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.1),
                          theme.colorScheme.secondary.withOpacity(0.05),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 16, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (isCollapsible)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // İçerik - açılır-kapanır
          if (!isCollapsible || isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: contentLines
                      .where((l) => l.trim().isNotEmpty)
                      .map((line) => _buildContentRow(context, line))
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFeaturedPrediction(BuildContext context, String predictionText) {
    final theme = Theme.of(context);
    final cleanText = predictionText.replaceAll('**', '');

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Öne Çıkan Tahmin',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Text(
              cleanText,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}