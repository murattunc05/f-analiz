// lib/widgets/comparison_stats_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:futbol_analiz_app/main.dart';
import 'package:futbol_analiz_app/widgets/stat_comparison_row.dart';

import 'package:futbol_analiz_app/services/team_name_service.dart';

class ComparisonStatsCardWidget extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic> team1Data;
  final Map<String, dynamic> team2Data;
  final StatsDisplaySettings statsSettings;
  final int numberOfMatchesToCompare;
  final Function(BuildContext, List<Map<String, dynamic>>, String) onShowDetailedMatchList;
  final Function(BuildContext, Map<String, dynamic>) onShowTeamGraphs;

  const ComparisonStatsCardWidget({
    super.key,
    required this.theme,
    required this.team1Data,
    required this.team2Data,
    required this.statsSettings,
    required this.numberOfMatchesToCompare,
    required this.onShowDetailedMatchList,
    required this.onShowTeamGraphs,
  });

  Widget _buildShortMatchSummaryRow(Map<String, dynamic> match, ThemeData theme) {
    // ... Bu metodun içeriği değişmedi ...
    String date = match['date']?.toString() ?? '';
    String homeTeam = match['homeTeam']?.toString() ?? 'Ev';
    String awayTeam = match['awayTeam']?.toString() ?? 'Dep';
    String homeGoals = match['homeGoals']?.toString() ?? '?';
    String awayGoals = match['awayGoals']?.toString() ?? '?';
    String resultText = match['result']?.toString() ?? '';
    String displayHomeTeam = TeamNameService.getCorrectedTeamName(homeTeam);
    String displayAwayTeam = TeamNameService.getCorrectedTeamName(awayTeam);
    TextStyle teamNameStyle = theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500);
    TextStyle scoreStyle = theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary);
    TextStyle dateStyle = theme.textTheme.labelSmall!.copyWith(color: theme.textTheme.bodySmall?.color?.withAlpha(178));
    TextStyle resultStyle = theme.textTheme.bodySmall!.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(flex: 1, child: Text(date, style: dateStyle, textAlign: TextAlign.start)),
              Expanded(
                flex: 3,
                child: Text(displayHomeTeam, style: teamNameStyle, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6.0), child: Text('$homeGoals - $awayGoals', style: scoreStyle)),
              Expanded(
                flex: 3,
                child: Text(displayAwayTeam, style: teamNameStyle, textAlign: TextAlign.start, overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
              Expanded(flex: 2, child: Text(resultText, style: resultStyle, textAlign: TextAlign.end)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!statsSettings.showOverallLast5Stats) return const SizedBox.shrink();

    // İstatistik listesi oluşturma mantığı aynı kalıyor
    List<Widget> statRows = [];
    void addStatIfEnabled(String key, String displayLabel, {bool higherIsBetter = true, bool isPercentage = false}) {
      // ... Bu fonksiyonun içeriği değişmedi ...
        bool shouldShow = true;
        if (displayLabel == 'Attığı Gol') { shouldShow = statsSettings.showAttigiGol; } else if (displayLabel == 'Yediği Gol') { shouldShow = statsSettings.showYedigiGol; } else if (displayLabel == 'Gol Farkı') { shouldShow = statsSettings.showGolFarki; } else if (displayLabel == 'Galibiyet') { shouldShow = statsSettings.showGalibiyet; } else if (displayLabel == 'Beraberlik') { shouldShow = statsSettings.showBeraberlik; } else if (displayLabel == 'Mağlubiyet') { shouldShow = statsSettings.showMaglubiyet; } else if (displayLabel == 'Maç Başına Ortalama Gol') { shouldShow = statsSettings.showMacBasiOrtGol; } else if (displayLabel == 'Maçlarda Ortalama Toplam Gol') { shouldShow = statsSettings.showMaclardaOrtTplGol; } else if (displayLabel == 'KG Var Yüzdesi') { shouldShow = statsSettings.showKgVarYok; } else if (displayLabel == 'KG Yok Yüzdesi') { shouldShow = statsSettings.showKgVarYok; } else if (displayLabel == 'Clean Sheet Sayısı') { shouldShow = statsSettings.showCleanSheet; } else if (displayLabel == 'Clean Sheet Yüzdesi') { shouldShow = statsSettings.showCleanSheet; } else if (displayLabel == 'Form Puanı') { shouldShow = true; } else if (displayLabel == 'Ortalama Şut') { shouldShow = statsSettings.showAvgShots; } else if (displayLabel == 'Ortalama İsabetli Şut') { shouldShow = statsSettings.showAvgShotsOnTarget; } else if (displayLabel == 'Ortalama Faul') { shouldShow = statsSettings.showAvgFouls; } else if (displayLabel == 'Ortalama Korner') { shouldShow = statsSettings.showAvgCorners; } else if (displayLabel == 'Ortalama Sarı Kart') { shouldShow = statsSettings.showAvgYellowCards; } else if (displayLabel == 'Ortalama Kırmızı Kart') { shouldShow = statsSettings.showAvgRedCards; } else if (displayLabel == 'İY Attığı Ortalama Gol') { shouldShow = statsSettings.showIyGolOrt; } else if (displayLabel == 'İY Yediği Ortalama Gol') { shouldShow = statsSettings.showIyGolOrt; } else if (displayLabel == 'İY Galibiyet Yüzdesi') { shouldShow = statsSettings.showIySonuclar; } else if (displayLabel == '2+ Gol Olasılığı') { shouldShow = statsSettings.showGol2UstuOlasilik; }
        if (shouldShow) {
            String val1 = team1Data[key]?.toString() ?? "-"; String val2 = team2Data[key]?.toString() ?? "-";
            if (isPercentage && val1 != "-" && !val1.startsWith('%')) val1 = '%$val1';
            if (isPercentage && val2 != "-" && !val2.startsWith('%')) val2 = '%$val2';
            if (val1 != "-" || val2 != "-") {
                 statRows.add(StatComparisonRowWidget(theme: theme, label: displayLabel, homeValue: val1, awayValue: val2, higherIsBetter: higherIsBetter));
            }
        }
    }
    addStatIfEnabled('attigi', 'Attığı Gol'); addStatIfEnabled('yedigi', 'Yediği Gol', higherIsBetter: false); addStatIfEnabled('golFarki', 'Gol Farkı'); addStatIfEnabled('galibiyet', 'Galibiyet'); addStatIfEnabled('beraberlik', 'Beraberlik'); addStatIfEnabled('maglubiyet', 'Mağlubiyet', higherIsBetter: false); addStatIfEnabled('macBasiOrtalamaGol', 'Maç Başına Ortalama Gol'); addStatIfEnabled('maclardaOrtalamaToplamGol', 'Maçlarda Ortalama Toplam Gol'); addStatIfEnabled('kgVarYuzdesi', 'KG Var Yüzdesi', isPercentage: true); addStatIfEnabled('kgYokYuzdesi', 'KG Yok Yüzdesi', isPercentage: true); addStatIfEnabled('cleanSheetSayisi', 'Clean Sheet Sayısı'); addStatIfEnabled('cleanSheetYuzdesi', 'Clean Sheet Yüzdesi', isPercentage: true); addStatIfEnabled('formPuani', 'Form Puanı'); addStatIfEnabled('ortalamaSut', 'Ortalama Şut'); addStatIfEnabled('ortalamaIsabetliSut', 'Ortalama İsabetli Şut'); addStatIfEnabled('ortalamaFaul', 'Ortalama Faul', higherIsBetter: false); addStatIfEnabled('ortalamaKorner', 'Ortalama Korner'); addStatIfEnabled('ortalamaSariKart', 'Ortalama Sarı Kart', higherIsBetter: false); addStatIfEnabled('ortalamaKirmiziKart', 'Ortalama Kırmızı Kart', higherIsBetter: false); addStatIfEnabled('iyAttigiOrt', 'İY Attığı Ortalama Gol'); addStatIfEnabled('iyYedigiOrt', 'İY Yediği Ortalama Gol', higherIsBetter: false); addStatIfEnabled('iyGalibiyetYuzdesi', 'İY Galibiyet Yüzdesi', isPercentage: true); addStatIfEnabled('gol2UstuOlasilik', '2+ Gol Olasılığı', isPercentage: true);

    // Diğer değişken tanımlamaları aynı kalıyor
    final int analyzedMatchCount1 = team1Data['lastNMatchesUsed'] as int? ?? numberOfMatchesToCompare;
    final String matchDetailsKey1 = "son${analyzedMatchCount1}MacDetaylari";
    final List<Map<String, dynamic>> matchDetails1 = (team1Data[matchDetailsKey1] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final int analyzedMatchCount2 = team2Data['lastNMatchesUsed'] as int? ?? numberOfMatchesToCompare;
    final String matchDetailsKey2 = "son${analyzedMatchCount2}MacDetaylari";
    final List<Map<String, dynamic>> matchDetails2 = (team2Data[matchDetailsKey2] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final String originalTeam1Name = team1Data["takim"] as String? ?? "";
    final String team1DisplayTitle = team1Data["displayTeamName"] as String? ?? TeamNameService.getCorrectedTeamName(originalTeam1Name);
    final String originalTeam2Name = team2Data["takim"] as String? ?? "";
    final String team2DisplayTitle = team2Data["displayTeamName"] as String? ?? TeamNameService.getCorrectedTeamName(originalTeam2Name);


    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.03),
                theme.colorScheme.secondary.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium başlık alanı
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.08),
                          theme.colorScheme.secondary.withOpacity(0.05),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Başlık
                        Row(
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'İstatistiksel Karşılaştırma',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Son $numberOfMatchesToCompare maç verilerine dayalı',
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
                                color: theme.colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'DETAY',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Takım başlıkları
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // TAKIM 1 (SOL)
                            Expanded(
                              flex: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => onShowTeamGraphs(context, team1Data),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Text(
                                    team1DisplayTitle, 
                                    textAlign: TextAlign.center, 
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold, 
                                      color: theme.colorScheme.primary, 
                                      fontSize: 14
                                    ), 
                                    overflow: TextOverflow.ellipsis, 
                                    maxLines: 2
                                  ),
                                ),
                              ),
                            ),
                            // ORTA BAŞLIK
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.compare_arrows,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'VS', 
                                      textAlign: TextAlign.center, 
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold, 
                                        color: theme.colorScheme.onSurfaceVariant, 
                                        fontSize: 12
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // TAKIM 2 (SAĞ)
                            Expanded(
                              flex: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.secondary.withOpacity(0.2),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => onShowTeamGraphs(context, team2Data),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Text(
                                    team2DisplayTitle, 
                                    textAlign: TextAlign.center, 
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold, 
                                      color: theme.colorScheme.secondary, 
                                      fontSize: 14
                                    ), 
                                    overflow: TextOverflow.ellipsis, 
                                    maxLines: 2
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // İstatistikler alanı
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        if (statRows.isNotEmpty)
                          ...statRows
                        else
                          Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Görüntülenecek istatistik yok veya ayarlar kapalı.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (statsSettings.showSon5MacDetaylari) ...[
          const SizedBox(height: 16),
          // Premium maç detayları kartları
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.02),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                iconColor: theme.colorScheme.primary,
                collapsedIconColor: theme.colorScheme.onSurfaceVariant,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                title: Text(
                  '$team1DisplayTitle Son $analyzedMatchCount1 Maç',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Detaylı maç sonuçları ve performans',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (matchDetails1.isNotEmpty) ...[
                          ...matchDetails1.map((match) => _buildShortMatchSummaryRow(match, theme)),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onShowDetailedMatchList(context, matchDetails1, team1DisplayTitle);
                              },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: Text('Tüm ${matchDetails1.length} Maçın Detayını Gör'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                foregroundColor: theme.colorScheme.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Maç detayı bulunamadı.",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.secondary.withOpacity(0.02),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                iconColor: theme.colorScheme.secondary,
                collapsedIconColor: theme.colorScheme.onSurfaceVariant,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history,
                    color: theme.colorScheme.secondary,
                    size: 18,
                  ),
                ),
                title: Text(
                  '$team2DisplayTitle Son $analyzedMatchCount2 Maç',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Detaylı maç sonuçları ve performans',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (matchDetails2.isNotEmpty) ...[
                          ...matchDetails2.map((match) => _buildShortMatchSummaryRow(match, theme)),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onShowDetailedMatchList(context, matchDetails2, team2DisplayTitle);
                              },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: Text('Tüm ${matchDetails2.length} Maçın Detayını Gör'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                                foregroundColor: theme.colorScheme.secondary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Maç detayı bulunamadı.",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]
      ],
    );
  }
}