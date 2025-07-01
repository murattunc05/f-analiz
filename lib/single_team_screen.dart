// lib/single_team_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futbol_analiz_app/data_service.dart';
import 'package:futbol_analiz_app/widgets/league_selection_dialog_content.dart';
import 'package:futbol_analiz_app/widgets/team_selection_dialog_content.dart';
import 'package:futbol_analiz_app/main.dart';
import 'package:futbol_analiz_app/utils.dart';
import 'package:futbol_analiz_app/utils/dialog_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:futbol_analiz_app/services/logo_service.dart';
import 'package:futbol_analiz_app/features/single_team_analysis/single_team_controller.dart';
import 'package:futbol_analiz_app/services/team_name_service.dart';

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

  // --- Fonksiyonlar ---

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

  String _getLeagueLogoAssetName(String leagueName) {
    String normalized = leagueName.toLowerCase().replaceAll(' - ', '_').replaceAll(' ', '_');
    const Map<String, String> charMap = { 'ı': 'i', 'ğ': 'g', 'ü': 'u', 'ş': 's', 'ö': 'o', 'ç': 'c', };
    charMap.forEach((tr, en) => normalized = normalized.replaceAll(tr, en));
    return 'assets/logos/leagues/${normalized.replaceAll(RegExp(r'[^\w_.-]'), '')}.png';
  }

  // --- YENİ UI/UX WIDGET'LARI ---

  Widget _buildSetupCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controllerState = ref.watch(singleTeamControllerProvider);
    final selectedLeague = controllerState.selectedLeague;
    final selectedTeam = controllerState.selectedTeam;

    final String? leagueLogoAsset = selectedLeague != null ? _getLeagueLogoAssetName(selectedLeague) : null;
    final String? teamLogoUrl = (selectedLeague != null && selectedTeam != null) ? LogoService.getTeamLogoUrl(selectedTeam, selectedLeague) : null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Takım Analizi", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSelectionButton(
              context: context,
              assetPath: leagueLogoAsset,
              label: selectedLeague ?? "Lig Seçin",
              isSelected: selectedLeague != null,
              onTap: () => _selectLeague(context, ref),
            ),
            const SizedBox(height: 12),
            _buildSelectionButton(
              context: context,
              logoUrl: teamLogoUrl,
              label: selectedTeam != null ? TeamNameService.getCorrectedTeamName(selectedTeam) : "Takım Seçin",
              isSelected: selectedTeam != null,
              onTap: () => _selectTeam(context, ref),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSelectionButton({
    required BuildContext context,
    String? assetPath,
    String? logoUrl,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    const double logoSize = 24.0;

    Widget leadingWidget;
    if (logoUrl != null) {
      leadingWidget = CachedNetworkImage(
        imageUrl: logoUrl,
        width: logoSize, height: logoSize, fit: BoxFit.contain,
        errorWidget: (c, u, e) => Icon(Icons.shield_outlined, size: logoSize, color: theme.colorScheme.primary),
      );
    } else if (assetPath != null) {
      leadingWidget = Image.asset(
        assetPath,
        width: logoSize, height: logoSize, fit: BoxFit.contain,
        errorBuilder: (c, e, s) => Icon(Icons.shield_outlined, size: logoSize, color: theme.colorScheme.primary),
      );
    } else {
      leadingWidget = Icon(
        isSelected ? Icons.shield_rounded : Icons.shield_outlined, 
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant
      );
    }

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              leadingWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.query_stats_rounded, size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(
            "Analiz Sonuçları Burada",
            style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Yukarıdan bir lig ve takım seçerek o takımın detaylı istatistiklerini görüntüleyebilirsiniz.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatsCard(BuildContext context, Map<String, dynamic> stats, String selectedLeague) {
    final theme = Theme.of(context);
    final String originalTeamName = stats["takim"] as String? ?? "";
    final String teamDisplayTitle = stats["displayTeamName"] as String? ?? capitalizeFirstLetterOfWordsUtils(originalTeamName);
    final String? teamLogoUrl = LogoService.getTeamLogoUrl(originalTeamName, selectedLeague);
    final String titleSuffix = (stats['lastNMatchesUsed'] == null || (stats['lastNMatchesUsed'] as int) <= 0) 
                                ? "(Tüm Sezon)" 
                                : "(Son ${stats['lastNMatchesUsed']} Maç)";
    
    final int analyzedMatchCount = stats['lastNMatchesUsed'] as int? ?? 5;
    final String matchDetailsKey = "son${analyzedMatchCount}MacDetaylari";
    final List<Map<String, dynamic>> matchDetails = (stats[matchDetailsKey] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showTeamGraphsDialog(context, stats, selectedLeague),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Kart Başlığı
              Row(
                children: [
                  if (teamLogoUrl != null)
                    CachedNetworkImage(
                      imageUrl: teamLogoUrl,
                      width: 32, height: 32, fit: BoxFit.contain,
                      errorWidget: (c, u, e) => Icon(Icons.shield_outlined, size: 32, color: theme.colorScheme.primary),
                    )
                  else
                    Icon(Icons.shield_outlined, size: 32, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teamDisplayTitle, style: theme.textTheme.titleLarge),
                        Text(titleSuffix, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Icon(Icons.bar_chart_rounded, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                ],
              ),
              const Divider(height: 24),
              // İstatistikler
              _buildStatRow('Galibiyet / Beraberlik / Mağlubiyet', "${stats['galibiyet']} / ${stats['beraberlik']} / ${stats['maglubiyet']}", theme, icon: Icons.emoji_events_outlined),
              _buildStatRow('Attığı Gol / Yediği Gol', "${stats['attigi']} / ${stats['yedigi']}", theme, icon: Icons.sports_soccer_outlined),
              _buildStatRow('Maç Başına Ort. Gol', (stats["macBasiOrtalamaGol"] as num?)?.toStringAsFixed(2) ?? "-", theme, icon: Icons.score_outlined),
              _buildStatRow('KG Var / Yok Yüzdesi', "%${(stats["kgVarYuzdesi"] as num?)?.toStringAsFixed(1) ?? "-"} / %${(stats["kgYokYuzdesi"] as num?)?.toStringAsFixed(1) ?? "-"}", theme, icon: Icons.checklist_rtl_outlined),
              _buildStatRow('Clean Sheet Sayısı (Gol Yemeden)', stats["cleanSheetSayisi"].toString(), theme, icon: Icons.shield_outlined),
              _buildStatRow('Ortalama Korner', (stats["ortalamaKorner"] as num?)?.toStringAsFixed(1) ?? "N/A", theme, icon: Icons.flag_circle_outlined),
              _buildStatRow('Ortalama Şut', (stats["ortalamaSut"] as num?)?.toStringAsFixed(1) ?? "N/A", theme, icon: Icons.radar_outlined),
              _buildStatRow('Ortalama Faul', (stats["ortalamaFaul"] as num?)?.toStringAsFixed(1) ?? "N/A", theme, icon: Icons.sports_kabaddi_outlined),
              
              // **YENİ EKLENEN BÖLÜM**
              if (statsSettings.showSon5MacDetaylari && matchDetails.isNotEmpty) ...[
                const Divider(height: 24),
                Theme( // ExpansionTile'ın altındaki ve üstündeki çizgiyi kaldırmak için
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text("Son Maç Sonuçları", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    children: matchDetails.map((match) => _buildMatchResultRow(context, match)).toList(),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // **YENİ EKLENEN YARDIMCI WIDGET**
  /// Açılır liste içindeki her bir maç sonucunu gösterir.
  Widget _buildMatchResultRow(BuildContext context, Map<String, dynamic> match) {
    final theme = Theme.of(context);
    final homeTeam = capitalizeFirstLetterOfWordsUtils(match['homeTeam']?.toString() ?? 'Ev');
    final awayTeam = capitalizeFirstLetterOfWordsUtils(match['awayTeam']?.toString() ?? 'Dep');
    final homeGoals = match['homeGoals']?.toString() ?? '?';
    final awayGoals = match['awayGoals']?.toString() ?? '?';
    final date = match['date']?.toString() ?? '';
    final resultText = match['result']?.toString() ?? '';

    return ListTile(
      dense: true,
      title: Row(
        children: [
          Expanded(child: Text(homeTeam, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text("$homeGoals - $awayGoals", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(awayTeam, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)),
        ],
      ),
      subtitle: Text("$date ($resultText)", textAlign: TextAlign.center, style: theme.textTheme.labelSmall),
    );
  }


  // --- Build Metodu ---
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controllerState = ref.watch(singleTeamControllerProvider);
    final teamStatsAsyncValue = controllerState.teamStats;
    final selectedLeague = controllerState.selectedLeague;
    final selectedTeam = controllerState.selectedTeam;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        // Yeni Kurulum Kartı
        _buildSetupCard(context, ref),

        // Analiz Butonu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            icon: teamStatsAsyncValue.isLoading 
                ? SpinKitThreeBounce(color: theme.colorScheme.onPrimary, size: 18.0) 
                : const Icon(Icons.analytics_outlined, size: 20),
            label: const Text('İstatistikleri Getir'),
            onPressed: (selectedLeague == null || teamStatsAsyncValue.isLoading || selectedTeam == null) 
                ? null 
                : () {
                    HapticFeedback.mediumImpact(); 
                    ref.read(singleTeamControllerProvider.notifier).fetchTeamStats(currentSeasonApiValue);
                  },
             style: ElevatedButton.styleFrom(
               padding: const EdgeInsets.symmetric(vertical: 14),
               minimumSize: const Size(double.infinity, 50),
             ),
          ),
        ),
        
        // Sonuç Alanı
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
          child: teamStatsAsyncValue.when(
            data: (stats) {
              if (stats.isEmpty) {
                // Seçim yapılmadıysa veya yeni lig seçildiyse (takım sıfırlandı) boş durumu göster
                if (selectedLeague == null || selectedTeam == null) {
                  return _buildEmptyState(context);
                }
                // Seçim yapıldı ama veri yoksa (örn. yeni sezon veya hata) boşluk bırak
                return const SizedBox.shrink();
              }
              // Veri varsa yeni istatistik kartını göster
              return _buildModernStatsCard(context, stats, selectedLeague!);
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
    );
  }

  // --- Değişmeyen Orijinal Widget'lar (Stat Row ve Grafikler) ---
  Widget _buildStatRow(String label, String value, ThemeData theme, {required IconData icon}) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 22.0, color: theme.colorScheme.primary),
          const SizedBox(width: 12.0),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))
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
}
