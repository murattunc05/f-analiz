// lib/comparison_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futbol_analiz_app/main.dart';
import 'package:futbol_analiz_app/utils.dart';
import 'package:futbol_analiz_app/utils/dialog_utils.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:futbol_analiz_app/services/logo_service.dart';
import 'package:futbol_analiz_app/services/team_name_service.dart';
import 'package:futbol_analiz_app/features/team_comparison/comparison_controller.dart';
import 'package:futbol_analiz_app/data_service.dart';
import 'package:futbol_analiz_app/widgets/league_selection_dialog_content.dart';
import 'package:futbol_analiz_app/widgets/team_selection_dialog_content.dart';
import 'package:futbol_analiz_app/widgets/stat_comparison_row.dart';

class ComparisonScreen extends ConsumerWidget {
  final StatsDisplaySettings statsSettings;
  final String currentSeasonApiValue;
  final ScrollController scrollController;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onSearchTap;

  const ComparisonScreen({
    super.key,
    required this.statsSettings,
    required this.currentSeasonApiValue,
    required this.scrollController,
    required this.scaffoldKey,
    required this.onSearchTap,
  });

  static const List<Color> _cardGradient = [Color(0xff22d3ee), Color(0xff0e7490), Color(0xff4c1d95)];

  Future<void> _selectLeague(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(comparisonControllerProvider.notifier);
    final selectedLeague = ref.read(comparisonControllerProvider).selectedLeague;
    
    final displaySeason = DataService.getDisplaySeasonFromApiValue(currentSeasonApiValue);
    final selectedLeagueName = await showAnimatedDialog<String>(
      context: context,
      titleWidget: Text("Lig Seçin (Sezon: $displaySeason)", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18), textAlign: TextAlign.center),
      contentWidget: LeagueSelectionDialogContent( availableLeagues: DataService.leagueDisplayNames, currentSelectedLeague: selectedLeague),
      actionsWidget: [ TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop()) ], maxHeightFactor: 0.7,
    );
    if (selectedLeagueName != null) {
      controller.selectLeague(selectedLeagueName);
      controller.fetchAvailableTeams(selectedLeagueName, currentSeasonApiValue);
    }
  }

  Future<void> _selectTeam(BuildContext context, WidgetRef ref, int teamNumber) async {
    final controllerState = ref.read(comparisonControllerProvider);
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
    final dialogTitleText = "$teamNumber. Takım Seç\n(${controllerState.selectedLeague} - $displaySeason)";

    final selectedOriginalTeamName = await showAnimatedDialog<String>(
      context: context,
      titleWidget: Text(dialogTitleText, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18), textAlign: TextAlign.center,),
      contentWidget: TeamSelectionDialogContent( availableOriginalTeamNames: controllerState.availableTeams, leagueName: controllerState.selectedLeague!),
      actionsWidget: [ TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop()) ], maxHeightFactor: 0.65,
    );

    if (selectedOriginalTeamName != null) {
      ref.read(comparisonControllerProvider.notifier).selectTeam(teamNumber: teamNumber, teamName: selectedOriginalTeamName);
    }
  }
  
  String _getLeagueLogoAssetName(String leagueName) {
    String normalized = leagueName.toLowerCase().replaceAll(' - ', '_').replaceAll(' ', '_');
    const Map<String, String> charMap = { 'ı': 'i', 'ğ': 'g', 'ü': 'u', 'ş': 's', 'ö': 'o', 'ç': 'c', };
    charMap.forEach((tr, en) => normalized = normalized.replaceAll(tr, en));
    return 'assets/logos/leagues/${normalized.replaceAll(RegExp(r'[^\w_.-]'), '')}.png';
  }

  Widget _buildSelectionRow(ThemeData theme, {IconData? icon, String? logoUrl, String? assetPath, required String text, required VoidCallback onTap}) {
    const double logoSize = 24.0;
    final bool isSelected = text != 'Lig Seçin' && text != '1. Takım' && text != '2. Takım';

    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12.0),
      child: Container( padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all( color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? theme.colorScheme.outline.withAlpha(128), width: 1.0)
        ),
        child: Row(children: [
            if (logoUrl != null) CachedNetworkImage(imageUrl: logoUrl, width: logoSize, height: logoSize, fit: BoxFit.contain, placeholder: (c, u) => SizedBox(width: logoSize, height: logoSize, child: Center(child: CircularProgressIndicator(strokeWidth: 1.5))), errorWidget: (c, u, e) => Icon(icon, size: logoSize, color: theme.inputDecorationTheme.prefixIconColor))
            else if (assetPath != null) Image.asset(assetPath, width: logoSize, height: logoSize, fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(icon, size: logoSize, color: theme.inputDecorationTheme.prefixIconColor))
            else if (icon != null) Icon(icon, size: logoSize, color: theme.inputDecorationTheme.prefixIconColor),
            const SizedBox(width: 10),
            Expanded(child: Text( text, style: !isSelected ? theme.textTheme.bodyLarge?.copyWith(color: theme.inputDecorationTheme.hintStyle?.color) : theme.textTheme.bodyLarge, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ]),
      ),
    );
  }
  
  Widget _GradientBorderCard({required Widget child, required BuildContext context}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        gradient: const LinearGradient(
          colors: _cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5), 
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTeamStatsContent(Map<String, dynamic> team1Data, Map<String, dynamic> team2Data, ThemeData theme, String? selectedLeague) {
    if (!statsSettings.showOverallLast5Stats) return const SizedBox.shrink();

    final int analyzedMatchCount1 = team1Data['lastNMatchesUsed'] as int? ?? 5;
    final List<Map<String, dynamic>> matchDetails1 = (team1Data["son${analyzedMatchCount1}MacDetaylari"] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final String originalTeam1Name = team1Data["takim"] as String? ?? "";
    final String team1DisplayTitle = team1Data["displayTeamName"] as String? ?? TeamNameService.getCorrectedTeamName(originalTeam1Name);
    
    final int analyzedMatchCount2 = team2Data['lastNMatchesUsed'] as int? ?? 5;
    final List<Map<String, dynamic>> matchDetails2 = (team2Data["son${analyzedMatchCount2}MacDetaylari"] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final String originalTeam2Name = team2Data["takim"] as String? ?? "";
    final String team2DisplayTitle = team2Data["displayTeamName"] as String? ?? TeamNameService.getCorrectedTeamName(originalTeam2Name);

    String? team1LogoUrl = selectedLeague != null ? LogoService.getTeamLogoUrl(originalTeam1Name, selectedLeague) : null;
    String? team2LogoUrl = selectedLeague != null ? LogoService.getTeamLogoUrl(originalTeam2Name, selectedLeague) : null;
      
    final String titleSuffix = "(Son 5 Maç)";
    const double titleLogoSize = 20.0;
    
    List<Widget> statRows = [];
    void addStatIfEnabled(String key, String displayLabel, {bool higherIsBetter = true, bool isPercentage = false}) {
      bool shouldShow = true;
      if (displayLabel == 'Attığı Gol') { shouldShow = statsSettings.showAttigiGol; } else if (displayLabel == 'Yediği Gol') { shouldShow = statsSettings.showYedigiGol; } else if (displayLabel == 'Gol Farkı') { shouldShow = statsSettings.showGolFarki; } else if (displayLabel == 'Galibiyet') { shouldShow = statsSettings.showGalibiyet; } else if (displayLabel == 'Beraberlik') { shouldShow = statsSettings.showBeraberlik; } else if (displayLabel == 'Mağlubiyet') { shouldShow = statsSettings.showMaglubiyet; } else if (displayLabel == 'Maç Başına Ort. Gol') { shouldShow = statsSettings.showMacBasiOrtGol; } else if (displayLabel == 'Maçlarda Ort. Toplam Gol') { shouldShow = statsSettings.showMaclardaOrtTplGol; } else if (displayLabel == 'KG Var Yüzdesi') { shouldShow = statsSettings.showKgVarYok; } else if (displayLabel == 'KG Yok Yüzdesi') { shouldShow = statsSettings.showKgVarYok; } else if (displayLabel == 'Clean Sheet Sayısı') { shouldShow = statsSettings.showCleanSheet; } else if (displayLabel == 'Clean Sheet Yüzdesi') { shouldShow = statsSettings.showCleanSheet; } else if (displayLabel == '2+ Gol Olasılığı') { shouldShow = statsSettings.showGol2UstuOlasilik; }

      if (shouldShow && team1Data.containsKey(key) && team2Data.containsKey(key)) {
        String val1 = team1Data[key]?.toString() ?? "-"; String val2 = team2Data[key]?.toString() ?? '-';
        if (isPercentage && val1 != "-" && !val1.startsWith('%')) val1 = '%$val1';
        if (isPercentage && val2 != "-" && !val2.startsWith('%') && val2 != '-') val2 = '%$val2';
        statRows.add(StatComparisonRowWidget(theme: theme, label: displayLabel, homeValue: val1, awayValue: val2, higherIsBetter: higherIsBetter));
      }
    }

    addStatIfEnabled('attigi', 'Attığı Gol'); addStatIfEnabled('yedigi', 'Yediği Gol', higherIsBetter: false); addStatIfEnabled('golFarki', 'Gol Farkı');
    addStatIfEnabled('galibiyet', 'Galibiyet'); addStatIfEnabled('beraberlik', 'Beraberlik'); addStatIfEnabled('maglubiyet', 'Mağlubiyet', higherIsBetter: false);
    addStatIfEnabled('macBasiOrtalamaGol', 'Maç Başına Ort. Gol'); addStatIfEnabled('maclardaOrtalamaToplamGol', 'Maçlarda Ort. Toplam Gol');
    addStatIfEnabled('kgVarYuzdesi', 'KG Var Yüzdesi', isPercentage: true); addStatIfEnabled('kgYokYuzdesi', 'KG Yok Yüzdesi', isPercentage: true);
    addStatIfEnabled('cleanSheetSayisi', 'Clean Sheet Sayısı'); addStatIfEnabled('cleanSheetYuzdesi', 'Clean Sheet Yüzdesi', isPercentage: true);
    addStatIfEnabled('gol2UstuOlasilik', '2+ Gol Olasılığı', isPercentage: true);
    
    return Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(flex: 4, child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            if (team1LogoUrl != null) Padding(padding: const EdgeInsets.only(right: 4.0), child: CachedNetworkImage(imageUrl: team1LogoUrl, width: titleLogoSize, height: titleLogoSize, fit: BoxFit.contain, placeholder: (c, u) => SizedBox(width: titleLogoSize, height: titleLogoSize), errorWidget: (c,u,e) => Icon(Icons.shield_outlined, size: titleLogoSize))) else Padding(padding: const EdgeInsets.only(right: 4.0), child: Icon(Icons.shield_outlined, size: titleLogoSize)),
            Expanded(child: Text(team1DisplayTitle, textAlign: TextAlign.start, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2))
          ])),
          Expanded(flex: 3, child: Text('İst. $titleSuffix', textAlign: TextAlign.center, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant, fontSize: 11.5), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 4, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Expanded(child: Text(team2DisplayTitle, textAlign: TextAlign.end, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2)),
            if (team2LogoUrl != null) Padding(padding: const EdgeInsets.only(left: 4.0), child: CachedNetworkImage(imageUrl: team2LogoUrl, width: titleLogoSize, height: titleLogoSize, fit: BoxFit.contain, placeholder: (c,u) => SizedBox(width: titleLogoSize, height: titleLogoSize), errorWidget: (c,u,e) => Icon(Icons.shield_outlined, size: titleLogoSize))) else Padding(padding: const EdgeInsets.only(left: 4.0), child: Icon(Icons.shield_outlined, size: titleLogoSize)),
          ]))
        ])),
        const Divider(height: 1),
        if (statRows.isNotEmpty) ...statRows else const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: Text("Görüntülenecek istatistik yok."))),
        if (statsSettings.showSon5MacDetaylari && matchDetails1.isNotEmpty) ...[const SizedBox(height: 10), ExpansionTile(tilePadding: EdgeInsets.zero, iconColor: theme.colorScheme.primary, collapsedIconColor: theme.colorScheme.onSurfaceVariant, title: Text('Maç Detayları ($team1DisplayTitle)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)), children: matchDetails1.map((match) => ListTile(dense: true, title: Text('${match["date"]}: ${capitalizeFirstLetterOfWordsUtils(match["homeTeam"])} ${match["homeGoals"]} - ${match["awayGoals"]} ${capitalizeFirstLetterOfWordsUtils(match["awayTeam"])} (${match["result"]})', style: theme.textTheme.bodySmall))).toList())],
        if (statsSettings.showSon5MacDetaylari && matchDetails2.isNotEmpty) ...[const SizedBox(height: 10), ExpansionTile(tilePadding: EdgeInsets.zero, iconColor: theme.colorScheme.primary, collapsedIconColor: theme.colorScheme.onSurfaceVariant, title: Text('Maç Detayları ($team2DisplayTitle)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)), children: matchDetails2.map((match) => ListTile(dense: true, title: Text('${match["date"]}: ${capitalizeFirstLetterOfWordsUtils(match["homeTeam"])} ${match["homeGoals"]} - ${match["awayGoals"]} ${capitalizeFirstLetterOfWordsUtils(match["awayTeam"])} (${match["result"]})', style: theme.textTheme.bodySmall))).toList())]
      ]));
  }

  Widget _buildComparisonResultCard(Map<String, dynamic> result, Map<String, dynamic> team1Data, Map<String, dynamic> team2Data, ThemeData theme) {
    double team1KgVar = (team1Data['kgVarYuzdesi'] as num?)?.toDouble() ?? 0.0;
    double team2KgVar = (team2Data['kgVarYuzdesi'] as num?)?.toDouble() ?? 0.0;
    double comparisonKgVar = (team1KgVar + team2KgVar) / 2;
    const String analyzedMatchesSuffix = "(Son 5 Maç)";

    Widget buildSingleInfoRow(String label, String value, {IconData? icon, Color? iconColor}) {
      return Padding( padding: const EdgeInsets.symmetric(vertical: 6.0), child: Row(children: [
        if (icon != null) ...[Icon(icon, size: 20.0, color: iconColor ?? theme.colorScheme.onSurfaceVariant), const SizedBox(width: 10.0)],
        Expanded(child: Text('$label:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ]));
    }
    return Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.military_tech_outlined, color: theme.colorScheme.primary, size: 24), const SizedBox(width: 8), Text('Karşılaştırma Sonuçları $analyzedMatchesSuffix:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary))]),
      const Divider(height: 20, thickness: 0.5),
      buildSingleInfoRow('İstatistiklere Göre Olası Kazanan', result["kazanan"].toString(), icon: Icons.emoji_events_outlined, iconColor: Colors.amber.shade700),
      buildSingleInfoRow('Beklenen Toplam Gol', result["beklenenToplamGol"].toString(), icon: Icons.sports_soccer),
      if(statsSettings.showComparisonKgVar) buildSingleInfoRow('Olası Karşılıklı Gol İhtimali', '%${comparisonKgVar.toStringAsFixed(1)}', icon: Icons.sync_alt_outlined),
      buildSingleInfoRow('2+ Gol Olma Olasılığı', '%${result["gol2PlusOlasilik"]}', icon: Icons.stacked_line_chart_outlined),
    ]));
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controllerState = ref.watch(comparisonControllerProvider);
    final isLoading = controllerState.team1Stats.isLoading || controllerState.isLoadingTeams;

    final selectedLeague = controllerState.selectedLeague;
    final team1 = controllerState.originalTeam1;
    final team2 = controllerState.originalTeam2;

    // DEĞİŞİKLİK: Scaffold ve SafeArea kaldırıldı, doğrudan ListView döndürülüyor
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        // DEĞİŞİKLİK: ModernHeaderWidget kaldırıldı
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: _GradientBorderCard(
            context: context,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Takım Karşılaştırma", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  const SizedBox(height: 16),
                  _buildSelectionRow(theme, icon: Icons.shield_outlined, assetPath: selectedLeague != null ? _getLeagueLogoAssetName(selectedLeague) : null, text: selectedLeague ?? 'Lig Seçin', onTap: () => _selectLeague(context, ref)),
                  const SizedBox(height: 12),
                  _buildSelectionRow(theme, icon: Icons.group_outlined, logoUrl: selectedLeague != null && team1 != null ? LogoService.getTeamLogoUrl(team1, selectedLeague) : null, text: team1 != null ? TeamNameService.getCorrectedTeamName(team1) : '1. Takım', onTap: () => _selectTeam(context, ref, 1)),
                  const SizedBox(height: 12),
                  _buildSelectionRow(theme, icon: Icons.group_outlined, logoUrl: selectedLeague != null && team2 != null ? LogoService.getTeamLogoUrl(team2, selectedLeague) : null, text: team2 != null ? TeamNameService.getCorrectedTeamName(team2) : '2. Takım', onTap: () => _selectTeam(context, ref, 2)),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 20.0),
          child: ElevatedButton.icon(
            icon: isLoading ? SpinKitThreeBounce(color: theme.colorScheme.onPrimary, size: 18.0) : const Icon(Icons.compare_arrows, size: 20),
            label: isLoading ? const SizedBox.shrink() : const Text('Takımları Karşılaştır'),
            onPressed: (selectedLeague == null || isLoading || team1 == null || team2 == null)
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    ref.read(comparisonControllerProvider.notifier).fetchComparisonStats(currentSeasonApiValue);
                  },
            style: (isLoading) ? ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0), minimumSize: const Size(64, 48),) : null,
          ),
        ),
        if (isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SpinKitPouringHourGlassRefined(color: Colors.deepOrange, size: 40.0)))
        else if (controllerState.errorMessage != null)
          Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(controllerState.errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error, fontSize: 16.0))))
        else if (controllerState.team1Stats.hasValue && controllerState.team2Stats.hasValue && controllerState.team1Stats.value != null && controllerState.team2Stats.value != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16,0,16,16),
            child: Column(
              children: [
                _GradientBorderCard(
                  context: context,
                  child: _buildTeamStatsContent(controllerState.team1Stats.value!, controllerState.team2Stats.value!, theme, selectedLeague),
                ),
                if (controllerState.comparisonResult.hasValue && controllerState.comparisonResult.value != null) ...[
                  _GradientBorderCard(
                     context: context,
                     child: _buildComparisonResultCard(controllerState.comparisonResult.value!, controllerState.team1Stats.value!, controllerState.team2Stats.value!, theme),
                  )
                ]
              ],
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 32.0, bottom: 32.0),
            child: Center(child: Text('Karşılaştırma sonuçları burada görünecek.\nLig ve takımları seçip karşılaştırın.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
          ),
      ],
    );
  }
}
