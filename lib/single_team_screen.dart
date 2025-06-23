// lib/single_team_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_service.dart';
import '../widgets/league_selection_dialog_content.dart';
import '../widgets/team_selection_dialog_content.dart';
import '../main.dart'; 
import '../utils.dart';
import '../utils/dialog_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/logo_service.dart';
import '../widgets/team_setup_card_widget.dart';
import '../features/single_team_analysis/single_team_controller.dart'; 
import '../services/team_name_service.dart';
import '../widgets/modern_header_widget.dart';

class SingleTeamScreen extends ConsumerWidget {
  final StatsDisplaySettings statsSettings;
  final String currentSeasonApiValue;
  final ScrollController scrollController;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onSearchTap;

  const SingleTeamScreen({
    super.key,
    required this.statsSettings,
    required this.currentSeasonApiValue,
    required this.scrollController,
    required this.scaffoldKey,
    required this.onSearchTap,
  });

  Future<void> _selectLeague(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(singleTeamControllerProvider.notifier);
    final selectedLeague = ref.read(singleTeamControllerProvider).selectedLeague;
    final displaySeason = DataService.getDisplaySeasonFromApiValue(currentSeasonApiValue);

    final selectedLeagueName = await showAnimatedDialog<String>(
      context: context,
      titleWidget: Text("Lig Seçin (Sezon: $displaySeason)", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18), textAlign: TextAlign.center),
      contentWidget: LeagueSelectionDialogContent( availableLeagues: DataService.leagueDisplayNames, currentSelectedLeague: selectedLeague),
      actionsWidget: [ TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop())],
    );

    if (selectedLeagueName != null) {
      controller.selectLeague(selectedLeagueName);
      controller.fetchAvailableTeams(selectedLeagueName, currentSeasonApiValue);
    }
  }

  Future<void> _selectTeam(BuildContext context, WidgetRef ref) async {
    final controllerState = ref.read(singleTeamControllerProvider);
    if (controllerState.selectedLeague == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen önce bir lig seçin.'), backgroundColor: Colors.redAccent));
      return;
    }
    if (controllerState.isLoadingTeams) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Takım listesi yükleniyor...')));
      return; 
    }
    
    HapticFeedback.lightImpact();
    final displaySeason = DataService.getDisplaySeasonFromApiValue(currentSeasonApiValue);
    final dialogTitleText = "Takım Seç\n(${controllerState.selectedLeague} - $displaySeason)";

    final selectedOriginalTeamName = await showAnimatedDialog<String>(
      context: context,
      titleWidget: Text(dialogTitleText, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18), textAlign: TextAlign.center),
      contentWidget: TeamSelectionDialogContent( availableOriginalTeamNames: controllerState.availableTeams, leagueName: controllerState.selectedLeague!),
      actionsWidget: [ TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop()) ],
    );

    if (selectedOriginalTeamName != null) {
      ref.read(singleTeamControllerProvider.notifier).selectTeam(selectedOriginalTeamName);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controllerState = ref.watch(singleTeamControllerProvider);
    final teamStatsAsyncValue = controllerState.teamStats;
    
    final selectedLeague = controllerState.selectedLeague;
    final selectedTeam = controllerState.selectedTeam;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            ModernHeaderWidget(
              onSettingsTap: () => scaffoldKey.currentState?.openDrawer(),
              onSearchTap: onSearchTap,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TeamSetupCardWidget(
                    theme: theme,
                    cardTitle: "Tek Takım Analizi",
                    selectedLeague: selectedLeague,
                    currentTeamName: selectedTeam ?? '',
                    selectedSeasonApiVal: currentSeasonApiValue,
                    globalCurrentSeasonApiValue: currentSeasonApiValue,
                    onLeagueSelectTap: () => _selectLeague(context, ref),
                    onTeamSelectTap: () => _selectTeam(context, ref),
                  ),
                  const SizedBox(height: 12.0),
                  ElevatedButton.icon(
                    icon: teamStatsAsyncValue.isLoading 
                        ? SpinKitThreeBounce(color: theme.colorScheme.onPrimary, size: 18.0) 
                        : const Icon(Icons.analytics_outlined, size: 20),
                    label: teamStatsAsyncValue.isLoading ? const SizedBox.shrink() : const Text('İstatistikleri Getir'),
                    onPressed: (selectedLeague == null || teamStatsAsyncValue.isLoading || selectedTeam == null) 
                        ? null 
                        : () {
                            HapticFeedback.mediumImpact(); 
                            ref.read(singleTeamControllerProvider.notifier).fetchTeamStats(currentSeasonApiValue);
                          },
                     style: ElevatedButton.styleFrom(
                       padding: teamStatsAsyncValue.isLoading ? const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0) : null, 
                       minimumSize: teamStatsAsyncValue.isLoading ? const Size(64, 48) : null
                     ),
                  )
                ]
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16,0,16,16),
              child: teamStatsAsyncValue.when(
                data: (stats) {
                  if (stats == null || stats.isEmpty || stats['oynananMacSayisi'] == 0) {
                    if (selectedLeague == null || selectedTeam == null) {
                      return const Padding(
                        padding: EdgeInsets.only(top:32.0),
                        child: Center(child: Text('İstatistikler burada görünecek.\nLig ve takım seçimi yapın.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                  
                  return InkWell(
                    onTap: () => _showTeamGraphsDialog(context, stats, selectedLeague),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildTeamStatsCardContent(stats, theme, selectedLeague)
                      )
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: SpinKitPouringHourGlassRefined(color: Colors.deepOrange, size: 50.0)
                  )
                ),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 16.0),
                    )
                  )
                ),
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme, {required bool show, IconData? icon, Color? iconColorOverride}) {
    if (!show) return const SizedBox.shrink();
    IconData iconData = icon ?? Icons.info_outline;
    Color finalIconColor = iconColorOverride ?? theme.colorScheme.onSurfaceVariant;

    if (icon == null) {
        if (label.contains('Attığı Gol')) { iconData = Icons.sports_soccer_outlined; finalIconColor = Colors.green.shade600; }
        else if (label.contains('Yediği Gol')) { iconData = Icons.shield_moon_outlined; finalIconColor = Colors.red.shade400; }
        else if (label.contains('Gol Farkı')) { iconData = Icons.swap_horiz_outlined; finalIconColor = theme.colorScheme.tertiary; }
        else if (label.contains('Galibiyet')) { iconData = Icons.emoji_events_outlined; finalIconColor = Colors.amber.shade700; }
        else if (label.contains('Beraberlik')) { iconData = Icons.handshake_outlined; finalIconColor = Colors.blueGrey.shade400; }
        else if (label.contains('Mağlubiyet')) { iconData = Icons.sentiment_very_dissatisfied_outlined; finalIconColor = Colors.red.shade700; }
        else if (label.contains('Maç Başına Ort. Gol')) { iconData = Icons.score_outlined; finalIconColor = theme.colorScheme.secondary; }
        else if (label.contains('Maçlarda Ort. Toplam Gol')) { iconData = Icons.public_outlined; finalIconColor = theme.colorScheme.secondary; }
        else if (label.contains('KG Var Yüzdesi')) { iconData = Icons.checklist_rtl_outlined; finalIconColor = Colors.teal.shade400; }
        else if (label.contains('KG Yok Yüzdesi')) { iconData = Icons.unpublished_outlined; finalIconColor = Colors.brown.shade400; }
        else if (label.contains('Clean Sheet Sayısı')) { iconData = Icons.shield_outlined; finalIconColor = Colors.blue.shade700; }
        else if (label.contains('Clean Sheet Yüzdesi')) { iconData = Icons.shield_outlined; finalIconColor = Colors.blue.shade700; }
        else if (label.contains('Olasılığı')) { iconData = Icons.percent_outlined; finalIconColor = theme.colorScheme.secondary; }
    }
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(iconData, size: 20.0, color: finalIconColor),
          const SizedBox(width: 10.0),
          Expanded(child: Text('$label:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))
        ]
      )
    );
  }

  void _showTeamGraphsDialog(BuildContext context, Map<String, dynamic> teamStats, String? selectedLeague) {
    ThemeData theme = Theme.of(context);
    if (teamStats.isEmpty) return;
    String teamDisplayTitle = teamStats["displayTeamName"] as String? ?? teamStats["takim"] as String? ?? "Takım";
    double galibiyet = (teamStats['galibiyet'] as num?)?.toDouble() ?? 0;
    double beraberlik = (teamStats['beraberlik'] as num?)?.toDouble() ?? 0;
    double maglubiyet = (teamStats['maglubiyet'] as num?)?.toDouble() ?? 0;
    double toplamMac = galibiyet + beraberlik + maglubiyet;
    List<PieChartSectionData> pieSections = [];
    if (toplamMac > 0) {
      if (galibiyet > 0) pieSections.add(PieChartSectionData(color: Colors.green.shade400, value: galibiyet, title: 'G:${galibiyet.toInt()}', radius: 45, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)));
      if (beraberlik > 0) pieSections.add(PieChartSectionData(color: Colors.blueGrey.shade400, value: beraberlik, title: 'B:${beraberlik.toInt()}', radius: 45, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)));
      if (maglubiyet > 0) pieSections.add(PieChartSectionData(color: Colors.red.shade400, value: maglubiyet, title: 'M:${maglubiyet.toInt()}', radius: 45, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)));
    } else {
      pieSections.add(PieChartSectionData(color: Colors.grey.shade300, value: 1, title: 'Veri Yok', radius: 45, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)));
    }
    double attigi = (teamStats['attigi'] as num?)?.toDouble() ?? 0.0;
    double yedigi = (teamStats['yedigi'] as num?)?.toDouble() ?? 0.0;
    final int analyzedMatchCount = teamStats['oynananMacSayisi'] as int? ?? (teamStats['lastNMatchesUsed'] as int? ?? 5);
    final String matchDetailsKey = "son${analyzedMatchCount}MacDetaylari";
    List<Map<String, dynamic>> sonMaclar = (teamStats[matchDetailsKey] as List?)?.cast<Map<String, dynamic>>() ?? [];
    List<Widget> formWidgets = [];
    if (sonMaclar.isNotEmpty) {
        for (var match in sonMaclar.take(5).toList().reversed) {
            String resultChar = "?"; Color resultColor = Colors.grey;
            String matchResult = match['result']?.toString() ?? "";
            if (matchResult.startsWith("G")) { resultChar = "G"; resultColor = Colors.green.shade400; }
            else if (matchResult.startsWith("B")) { resultChar = "B"; resultColor = Colors.blueGrey.shade400; }
            else if (matchResult.startsWith("M")) { resultChar = "M"; resultColor = Colors.red.shade400; }
            formWidgets.add(Container(margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: resultColor, shape: BoxShape.circle), child: Text(resultChar, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))));
        }
    } else {
      formWidgets.add(Text("Form verisi yok", style: theme.textTheme.bodySmall));
    }
    double formPuani = (teamStats['formPuani'] as num?)?.toDouble() ?? 0.0;
    String ortSut = (teamStats['ortalamaSut'] as num?)?.toStringAsFixed(1) ?? "N/A";
    String ortIsabetliSut = (teamStats['ortalamaIsabetliSut'] as num?)?.toStringAsFixed(1) ?? "N/A";
    String ortFaul = (teamStats['ortalamaFaul'] as num?)?.toStringAsFixed(1) ?? "N/A";
    String ortKorner = (teamStats['ortalamaKorner'] as num?)?.toStringAsFixed(1) ?? "N/A";
    String ortSariKart = (teamStats['ortalamaSariKart'] as num?)?.toStringAsFixed(2) ?? "N/A";
    String ortKirmiziKart = (teamStats['ortalamaKirmiziKart'] as num?)?.toStringAsFixed(2) ?? "N/A";
    String iyAttigiOrt = (teamStats['iyAttigiOrt'] as num?)?.toStringAsFixed(2) ?? "N/A";
    String iyYedigiOrt = (teamStats['iyYedigiOrt'] as num?)?.toStringAsFixed(2) ?? "N/A";
    String iyGalibiyetYuzdesi = (teamStats['iyGalibiyetYuzdesi'] as num?) != null ? "%${(teamStats['iyGalibiyetYuzdesi'] as num).toStringAsFixed(1)}" : "N/A";
    Widget buildDialogStatRow(String label, String value, ThemeData th, {required bool show, IconData? icon, Color? iconColorOverride, Color? valueColor}) {
      if (!show) return const SizedBox.shrink();
      IconData iconData = icon ?? Icons.info_outline; Color finalIconColor = iconColorOverride ?? th.colorScheme.onSurfaceVariant;
       if (icon == null) {
        if (label.contains('Ortalama Şut')) { iconData = Icons.radar_outlined; finalIconColor = Colors.orange.shade700; }
        else if (label.contains('Ort. İsabetli Şut') || label.contains('Ortalama İsabetli Şut') ) { iconData = Icons.gps_fixed; finalIconColor = Colors.deepOrange.shade700; }
        else if (label.contains('Ortalama Faul')) { iconData = Icons.sports_kabaddi_outlined; finalIconColor = Colors.yellow.shade800; }
        else if (label.contains('Ortalama Korner')) { iconData = Icons.flag_circle_outlined; finalIconColor = Colors.green.shade700; }
        else if (label.contains('Ortalama Sarı Kart')) { iconData = Icons.style_outlined ; finalIconColor = Colors.amber.shade900; }
        else if (label.contains('Ortalama Kırmızı Kart')) { iconData = Icons.style; finalIconColor = Colors.red.shade900; }
        else if (label.contains('İY Attığı Ort.') || label.contains('İY Attığı Ortalama Gol')) { iconData = Icons.wb_sunny_outlined; finalIconColor = Colors.cyan.shade700; }
        else if (label.contains('İY Yediği Ort.') || label.contains('İY Yediği Ortalama Gol')) { iconData = Icons.nightlight_round_outlined; finalIconColor = Colors.orange.shade800; }
        else if (label.contains('İY Galibiyet %') || label.contains('İY Galibiyet Yüzdesi')) { iconData = Icons.looks_one_outlined; finalIconColor = Colors.green.shade700; }
      }
      return Padding( padding: const EdgeInsets.symmetric(vertical: 5.0), child: Row(children: [
            Icon(iconData, size: 18.0, color: finalIconColor), const SizedBox(width: 8.0),
            Expanded(child: Text('$label:', style: th.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
            Text(value, style: th.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: valueColor ?? th.textTheme.bodySmall!.color))
          ]));
    }
    showAnimatedDialog( context: context, titleWidget: Text('$teamDisplayTitle Detaylı İstatistikler', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary), textAlign: TextAlign.center), dialogPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      contentWidget: SingleChildScrollView(
        child: Column( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text('Maç Sonuç Dağılımı (Son $analyzedMatchCount)', style: theme.textTheme.titleMedium), SizedBox(height: 140, child: PieChart(PieChartData(sections: pieSections, centerSpaceRadius: 25, sectionsSpace: 2, borderData: FlBorderData(show: false)))), const SizedBox(height: 16), Text('Gol İstatistikleri (Son $analyzedMatchCount)', style: theme.textTheme.titleMedium), SizedBox(height: 180, child: BarChart(BarChartData( alignment: BarChartAlignment.spaceAround, maxY: (attigi > yedigi ? attigi : yedigi) * 1.2 + 2, barTouchData: BarTouchData(enabled: true), titlesData: FlTitlesData(show: true, bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (double value, TitleMeta meta) { const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 10); String text; switch (value.toInt()) { case 0: text = 'Attığı'; break; case 1: text = 'Yediği'; break; default: return Container(); } return Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(text, style: style, textAlign: TextAlign.center)); })), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: ((attigi > yedigi ? attigi : yedigi) / 5).ceilToDouble().clamp(1,double.infinity), getTitlesWidget: (double value, TitleMeta meta) { if (value == meta.max || value == meta.min) return Container(); return Padding(padding: const EdgeInsets.only(right: 4.0), child: Text(value.toInt().toString(), style: TextStyle(color: theme.textTheme.bodySmall?.color?.withAlpha(178) ?? Colors.grey, fontSize: 10), textAlign: TextAlign.right)); })), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))), gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: ((attigi > yedigi ? attigi : yedigi) / 5).ceilToDouble().clamp(1,double.infinity), getDrawingHorizontalLine: (value) => FlLine(color: theme.dividerColor.withAlpha(77), strokeWidth: 0.5)), borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha(128), width: 1), left: BorderSide(color: theme.dividerColor.withAlpha(128), width: 1))), barGroups: [ BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: attigi, color: Colors.green.shade400, width: 25, borderRadius: BorderRadius.circular(4))]), BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: yedigi, color: Colors.red.shade400, width: 25, borderRadius: BorderRadius.circular(4))])]))),
            const SizedBox(height: 16), Text('Son 5 Maç Formu (Sağdan Sola: Eski -> Yeni)', style: theme.textTheme.titleMedium), const SizedBox(height: 8), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: formWidgets)), const SizedBox(height: 16), Text('Form Puanı: ${formPuani.toStringAsFixed(1)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16),
            Text('Maç Başına Ortalama Detaylar', style: theme.textTheme.titleMedium), buildDialogStatRow('Ortalama Şut', ortSut, theme, show: statsSettings.showAvgShots), buildDialogStatRow('Ortalama İsabetli Şut', ortIsabetliSut, theme, show: statsSettings.showAvgShotsOnTarget), buildDialogStatRow('Ortalama Faul', ortFaul, theme, show: statsSettings.showAvgFouls), buildDialogStatRow('Ortalama Korner', ortKorner, theme, show: statsSettings.showAvgCorners), buildDialogStatRow('Ortalama Sarı Kart', ortSariKart, theme, show: statsSettings.showAvgYellowCards), buildDialogStatRow('Ortalama Kırmızı Kart', ortKirmiziKart, theme, show: statsSettings.showAvgRedCards), const SizedBox(height: 16),
            Text('İlk Yarı Ortalamaları', style: theme.textTheme.titleMedium), buildDialogStatRow('İY Attığı Ortalama Gol', iyAttigiOrt, theme, show: statsSettings.showIyGolOrt), buildDialogStatRow('İY Yediği Ortalama Gol', iyYedigiOrt, theme, show: statsSettings.showIyGolOrt), buildDialogStatRow('İY Galibiyet Yüzdesi', iyGalibiyetYuzdesi, theme, show: statsSettings.showIySonuclar), const SizedBox(height: 16),
          ],
        ),
      ),
      actionsWidget: [ TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop()) ], maxHeightFactor: 0.85,
    );
  }

  Widget _buildTeamStatsCardContent(Map<String, dynamic> stats, ThemeData theme, String? selectedLeague) {
    if (!statsSettings.showOverallLast5Stats) return const SizedBox.shrink();

    final int analyzedMatchCount = stats['oynananMacSayisi'] as int? ?? (stats['lastNMatchesUsed'] as int? ?? 5);
    final String matchDetailsKey = "son${analyzedMatchCount}MacDetaylari";
    final List<Map<String, dynamic>> matchDetails = (stats[matchDetailsKey] as List?)?.cast<Map<String, dynamic>>() ?? [];
    
    final String originalTeamName = stats["takim"] as String? ?? "";
    final String teamDisplayTitle = stats["displayTeamName"] as String? ?? capitalizeFirstLetterOfWordsUtils(originalTeamName);
    
    final String titleSuffix = (stats['lastNMatchesUsed'] == null || (stats['lastNMatchesUsed'] as int) <= 0) ? "(Tüm Maçlar)" : "(Son ${stats['lastNMatchesUsed']} Maç)";

    String? teamLogoUrl;
    if (selectedLeague != null && originalTeamName.isNotEmpty) {
      teamLogoUrl = LogoService.getTeamLogoUrl(originalTeamName, selectedLeague);
    }
    const double titleLogoSize = 22.0;

    return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row( crossAxisAlignment: CrossAxisAlignment.center, children: [
            if (teamLogoUrl != null) Padding( padding: const EdgeInsets.only(right: 8.0),
                child: CachedNetworkImage( imageUrl: teamLogoUrl, width: titleLogoSize, height: titleLogoSize, fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(width: titleLogoSize, height: titleLogoSize),
                  errorWidget: (context, url, error) => Icon(Icons.shield_outlined, size: titleLogoSize, color: theme.colorScheme.onSurfaceVariant.withAlpha(128)),
                ))
            else if (originalTeamName.isNotEmpty)
              Padding( padding: const EdgeInsets.only(right: 8.0),
                child: Icon(Icons.shield_outlined, size: titleLogoSize, color: theme.colorScheme.onSurfaceVariant.withAlpha(128)),
              ),
            Expanded( child: Text( '$teamDisplayTitle $titleSuffix', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, ))
          ]),
        const Divider(height: 20, thickness: 0.5),
        _buildStatRow('Attığı Gol', stats["attigi"].toString(), theme, show: statsSettings.showAttigiGol),
        _buildStatRow('Yediği Gol', stats["yedigi"].toString(), theme, show: statsSettings.showYedigiGol),
        _buildStatRow('Gol Farkı', stats["golFarki"].toString(), theme, show: statsSettings.showGolFarki),
        _buildStatRow('Galibiyet', stats["galibiyet"].toString(), theme, show: statsSettings.showGalibiyet),
        _buildStatRow('Beraberlik', stats["beraberlik"].toString(), theme, show: statsSettings.showBeraberlik),
        _buildStatRow('Mağlubiyet', stats["maglubiyet"].toString(), theme, show: statsSettings.showMaglubiyet),
        _buildStatRow('Maç Başına Ort. Gol', (stats["macBasiOrtalamaGol"] as num?)?.toStringAsFixed(2) ?? "-", theme, show: statsSettings.showMacBasiOrtGol),
        _buildStatRow('Maçlarda Ort. Toplam Gol', (stats["maclardaOrtalamaToplamGol"] as num?)?.toStringAsFixed(2) ?? "-", theme, show: statsSettings.showMaclardaOrtTplGol),
        _buildStatRow('KG Var Yüzdesi', '%${(stats["kgVarYuzdesi"] as num?)?.toStringAsFixed(1) ?? "-"}', theme, show: statsSettings.showKgVarYok),
        _buildStatRow('KG Yok Yüzdesi', '%${(stats["kgYokYuzdesi"] as num?)?.toStringAsFixed(1) ?? "-"}', theme, show: statsSettings.showKgVarYok),
        _buildStatRow('Clean Sheet Sayısı', stats["cleanSheetSayisi"].toString(), theme, show: statsSettings.showCleanSheet, icon: Icons.shield_outlined, iconColorOverride: Colors.blue.shade700),
        _buildStatRow('Clean Sheet Yüzdesi', '%${(stats["cleanSheetYuzdesi"] as num?)?.toStringAsFixed(1) ?? "-"}', theme, show: statsSettings.showCleanSheet, icon: Icons.shield_outlined, iconColorOverride: Colors.blue.shade700),
        _buildStatRow('2+ Gol Olasılığı', '%${(stats["gol2UstuOlasilik"] as num?)?.toStringAsFixed(1) ?? "-"}', theme, show: statsSettings.showGol2UstuOlasilik),

        if (statsSettings.showSon5MacDetaylari)
            Theme( data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0), iconColor: theme.colorScheme.primary, collapsedIconColor: theme.colorScheme.onSurfaceVariant,
                    title: Row(children: [
                            Icon(Icons.event_note_outlined, color: theme.textTheme.titleSmall?.color?.withAlpha(204)), const SizedBox(width: 8),
                            Text('Son $analyzedMatchCount Maç Detayları', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ]),
                    children: matchDetails.isNotEmpty
                        ? matchDetails.map((match) => Padding( padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0), child: Text( '${match["date"]}: ${capitalizeFirstLetterOfWordsUtils(match["homeTeam"])} ${match["homeGoals"]} - ${match["awayGoals"]} ${capitalizeFirstLetterOfWordsUtils(match["awayTeam"])} (${match["result"]})', style: theme.textTheme.bodySmall))).toList()
                        : [Padding( padding: const EdgeInsets.all(8.0), child: Text("Son $analyzedMatchCount maç detayı bulunamadı.", style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic), textAlign: TextAlign.center)) ],
                ),
            ),
      ],
    );
  }
}