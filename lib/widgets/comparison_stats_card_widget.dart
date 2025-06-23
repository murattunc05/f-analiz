// lib/widgets/comparison_stats_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:futbol_analiz_app/main.dart';
import 'package:futbol_analiz_app/widgets/stat_comparison_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:futbol_analiz_app/services/logo_service.dart';
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
    final String? league1Name = team1Data['leagueNameForLogo'] as String?;
    final String? league2Name = team2Data['leagueNameForLogo'] as String?;
    String? team1LogoUrl = (league1Name != null && originalTeam1Name.isNotEmpty) ? LogoService.getTeamLogoUrl(originalTeam1Name, league1Name) : null;
    String? team2LogoUrl = (league2Name != null && originalTeam2Name.isNotEmpty) ? LogoService.getTeamLogoUrl(originalTeam2Name, league2Name) : null;
    const double titleLogoSize = 20.0;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // TAKIM 1 (SOL)
                      Expanded(
                        flex: 4,
                        child: InkWell(
                          onTap: () => onShowTeamGraphs(context, team1Data),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (team1LogoUrl != null)
                                Padding(padding: const EdgeInsets.only(right: 4.0), child: CachedNetworkImage(imageUrl: team1LogoUrl, width: titleLogoSize, height: titleLogoSize, fit: BoxFit.contain, placeholder: (c,u) => const SizedBox(width: titleLogoSize, height: titleLogoSize), errorWidget: (c,u,e) => Icon(Icons.shield_outlined, size: titleLogoSize, color: theme.colorScheme.onSurfaceVariant.withAlpha(128))))
                              else if (originalTeam1Name.isNotEmpty)
                                Padding(padding: const EdgeInsets.only(right: 4.0), child: Icon(Icons.shield_outlined, size: titleLogoSize, color: theme.colorScheme.onSurfaceVariant.withAlpha(128))),
                              Expanded(child: Text(team1DisplayTitle, textAlign: TextAlign.start, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2)),
                            ],
                          ),
                        ),
                      ),
                      // ORTA BAŞLIK
                      Expanded(
                        flex: 3,
                        child: Text('İst. (Son $numberOfMatchesToCompare)', textAlign: TextAlign.center, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant, fontSize: 11.5), overflow: TextOverflow.ellipsis),
                      ),
                      // TAKIM 2 (SAĞ) - DEĞİŞİKLİK BURADA
                      Expanded(
                        flex: 4,
                        child: InkWell(
                          onTap: () => onShowTeamGraphs(context, team2Data),
                          child: Row(
                             mainAxisAlignment: MainAxisAlignment.end, // Sağa yaslamak için
                            children: [
                              Expanded(child: Text(team2DisplayTitle, textAlign: TextAlign.end, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2)),
                              if (team2LogoUrl != null)
                                Padding(padding: const EdgeInsets.only(left: 4.0), child: CachedNetworkImage(imageUrl: team2LogoUrl, width: titleLogoSize, height: titleLogoSize, fit: BoxFit.contain, placeholder: (c,u) => const SizedBox(width: titleLogoSize, height: titleLogoSize), errorWidget: (c,u,e) => Icon(Icons.shield_outlined, size: titleLogoSize, color: theme.colorScheme.onSurfaceVariant.withAlpha(128))))
                              else if (originalTeam2Name.isNotEmpty)
                                Padding(padding: const EdgeInsets.only(left: 4.0), child: Icon(Icons.shield_outlined, size: titleLogoSize, color: theme.colorScheme.onSurfaceVariant.withAlpha(128))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (statRows.isNotEmpty)
                  ...statRows
                else
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: Text("Görüntülenecek istatistik yok veya ayarlar kapalı."))),
              ],
            ),
          ),
        ),
        if (statsSettings.showSon5MacDetaylari) ...[
          //... ExpansionTile kısımları aynı kalıyor ...
           const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 8.0), iconColor: theme.colorScheme.primary, collapsedIconColor: theme.colorScheme.onSurfaceVariant.withAlpha(204),
            title: Text('$team1DisplayTitle Son $analyzedMatchCount1 Maç Detayları', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            children: <Widget>[
                if (matchDetails1.isNotEmpty)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), child: Column(children: [ ...matchDetails1.map((match) => _buildShortMatchSummaryRow(match, theme)), const Divider(height: 12, thickness: 0.3, indent: 8, endIndent: 8), ListTile( dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8.0), title: Text('Tüm ${matchDetails1.length} Maçın Detaylarını Gör', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)), leading: Icon(Icons.open_in_new, color: theme.colorScheme.primary, size: 18), onTap: () { HapticFeedback.lightImpact(); onShowDetailedMatchList(context, matchDetails1, team1DisplayTitle); })]))
                else
                  Padding(padding: const EdgeInsets.all(12.0), child: Text("Maç detayı bulunamadı.", style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic))),
              ],
          ),
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 8.0), iconColor: theme.colorScheme.primary, collapsedIconColor: theme.colorScheme.onSurfaceVariant.withAlpha(204),
            title: Text('$team2DisplayTitle Son $analyzedMatchCount2 Maç Detayları', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            children: <Widget>[
                if (matchDetails2.isNotEmpty)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), child: Column( children: [ ...matchDetails2.map((match) => _buildShortMatchSummaryRow(match, theme)), const Divider(height: 12, thickness: 0.3, indent: 8, endIndent: 8), ListTile( dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8.0), title: Text('Tüm ${matchDetails2.length} Maçın Detaylarını Gör', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)), leading: Icon(Icons.open_in_new, color: theme.colorScheme.primary, size: 18), onTap: () { HapticFeedback.lightImpact(); onShowDetailedMatchList(context, matchDetails2, team2DisplayTitle); })]))
                else
                  Padding(padding: const EdgeInsets.all(12.0), child: Text("Maç detayı bulunamadı.", style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic))),
              ],
          ),
        ]
      ],
    );
  }
}