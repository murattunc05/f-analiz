// lib/comparison_screen.dart (Yeniden Tasarlandı)
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

  // --- Fonksiyonlar ---
  // Bu fonksiyonlar, UI'dan ayrıştırılmış ve mantığı içerir.

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

  // --- YENİ UI/UX WIDGET'LARI ---

  /// Kurulum kartı, lig ve iki takım seçimini bir arada barındırır.
  Widget _buildSetupCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controllerState = ref.watch(comparisonControllerProvider);
    final selectedLeague = controllerState.selectedLeague;
    final team1 = controllerState.originalTeam1;
    final team2 = controllerState.originalTeam2;

    final String? leagueLogoAsset = selectedLeague != null ? _getLeagueLogoAssetName(selectedLeague) : null;
    final String? team1LogoUrl = (selectedLeague != null && team1 != null) ? LogoService.getTeamLogoUrl(team1, selectedLeague) : null;
    final String? team2LogoUrl = (selectedLeague != null && team2 != null) ? LogoService.getTeamLogoUrl(team2, selectedLeague) : null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Takım Karşılaştırma", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSelectionButton(
              context: context,
              assetPath: leagueLogoAsset,
              label: selectedLeague ?? "Lig Seçin",
              isSelected: selectedLeague != null,
              onTap: () => _selectLeague(context, ref),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSelectionButton(
                    context: context,
                    logoUrl: team1LogoUrl,
                    label: team1 != null ? TeamNameService.getCorrectedTeamName(team1) : "1. Takım",
                    isSelected: team1 != null,
                    onTap: () => _selectTeam(context, ref, 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelectionButton(
                    context: context,
                    logoUrl: team2LogoUrl,
                    label: team2 != null ? TeamNameService.getCorrectedTeamName(team2) : "2. Takım",
                    isSelected: team2 != null,
                    onTap: () => _selectTeam(context, ref, 2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Seçim butonları için yeniden kullanılabilir yardımcı widget.
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              leadingWidget,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Karşılaştırma için boş durum (empty state) ekranı.
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows_rounded, size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(
            "Karşılaştırma Sonuçları",
            style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Yukarıdan bir lig ve iki takım seçerek aralarındaki istatistiksel karşılaştırmayı görüntüleyebilirsiniz.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Sonuçları gösteren ana widget.
  Widget _buildResults(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controllerState = ref.watch(comparisonControllerProvider);
    final team1Data = controllerState.team1Stats.value;
    final team2Data = controllerState.team2Stats.value;
    final comparisonResult = controllerState.comparisonResult.value;

    if (team1Data == null || team2Data == null) {
      return const SizedBox.shrink();
    }

    final String team1DisplayName = team1Data["displayTeamName"] ?? "Takım 1";
    final String team2DisplayName = team2Data["displayTeamName"] ?? "Takım 2";
    final String? team1LogoUrl = LogoService.getTeamLogoUrl(team1Data["takim"], controllerState.selectedLeague!);
    final String? team2LogoUrl = LogoService.getTeamLogoUrl(team2Data["takim"], controllerState.selectedLeague!);
    
    final int analyzedMatchCount1 = team1Data['lastNMatchesUsed'] as int? ?? 5;
    final List<Map<String, dynamic>> matchDetails1 = (team1Data["son${analyzedMatchCount1}MacDetaylari"] as List?)?.cast<Map<String, dynamic>>() ?? [];
    
    final int analyzedMatchCount2 = team2Data['lastNMatchesUsed'] as int? ?? 5;
    final List<Map<String, dynamic>> matchDetails2 = (team2Data["son${analyzedMatchCount2}MacDetaylari"] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // KG Var ihtimalini burada hesaplıyoruz.
    final double team1KgVar = (team1Data['kgVarYuzdesi'] as num?)?.toDouble() ?? 0.0;
    final double team2KgVar = (team2Data['kgVarYuzdesi'] as num?)?.toDouble() ?? 0.0;
    final double comparisonKgVar = (team1KgVar + team2KgVar) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // İstatistik Karşılaştırma Kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTeamHeader(theme, team1DisplayName, team1LogoUrl, team2DisplayName, team2LogoUrl),
                  const Divider(height: 24),
                  ..._buildStatRows(theme, team1Data, team2Data),
                  if(statsSettings.showSon5MacDetaylari && (matchDetails1.isNotEmpty || matchDetails2.isNotEmpty))
                    const Divider(height: 20),
                  if(statsSettings.showSon5MacDetaylari && matchDetails1.isNotEmpty)
                    _buildLastMatchesExpansion(theme, team1DisplayName, matchDetails1),
                  if(statsSettings.showSon5MacDetaylari && matchDetails2.isNotEmpty)
                    _buildLastMatchesExpansion(theme, team2DisplayName, matchDetails2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Sonuç Kartı
          if (comparisonResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildResultContent(theme, comparisonResult, comparisonKgVar),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(ThemeData theme, String name1, String? logo1, String name2, String? logo2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _TeamDisplay(theme: theme, name: name1, logoUrl: logo1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text("VS", style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        _TeamDisplay(theme: theme, name: name2, logoUrl: logo2),
      ],
    );
  }
  
  List<Widget> _buildStatRows(ThemeData theme, Map<String, dynamic> team1Data, Map<String, dynamic> team2Data) {
    List<Widget> rows = [];
    
    void addStat(String key, String label, {bool higherIsBetter = true, bool isPercentage = false}) {
      if (statsSettings.showOverallLast5Stats) {
        String val1 = team1Data[key]?.toString() ?? "-";
        String val2 = team2Data[key]?.toString() ?? "-";
        if (isPercentage && val1 != "-" && !val1.contains('%')) val1 = '%$val1';
        if (isPercentage && val2 != "-" && !val2.contains('%')) val2 = '%$val2';
        if (val1 != "-" || val2 != "-") {
          rows.add(StatComparisonRowWidget(
            theme: theme,
            label: label,
            homeValue: val1,
            awayValue: val2,
            higherIsBetter: higherIsBetter,
          ));
        }
      }
    }

    addStat('galibiyet', 'Galibiyet');
    addStat('beraberlik', 'Beraberlik');
    addStat('maglubiyet', 'Mağlubiyet', higherIsBetter: false);
    addStat('attigi', 'Attığı Gol');
    addStat('yedigi', 'Yediği Gol', higherIsBetter: false);
    addStat('macBasiOrtalamaGol', 'Maç Başı Ort. Gol');
    addStat('maclardaOrtalamaToplamGol', 'Maçlarda Ort. Toplam Gol');
    addStat('kgVarYuzdesi', 'KG Var %', isPercentage: true);
    addStat('cleanSheetYuzdesi', 'Clean Sheet %', isPercentage: true);
    addStat('ortalamaKorner', 'Ort. Korner');

    return rows;
  }
  
  Widget _buildResultContent(ThemeData theme, Map<String, dynamic> result, double kgVarPercent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Karşılaştırma Özeti", style: theme.textTheme.titleLarge),
        const Divider(height: 24),
        _ResultRow(
          icon: Icons.emoji_events_outlined,
          label: "İstatistiksel Kazanan",
          value: result["kazanan"].toString(),
          iconColor: Colors.amber.shade700,
        ),
        _ResultRow(
          icon: Icons.sports_soccer_outlined,
          label: "Beklenen Toplam Gol",
          value: result["beklenenToplamGol"].toString(),
        ),
        _ResultRow(
          icon: Icons.percent_rounded,
          label: "2+ Gol Olma Olasılığı",
          value: "%${result["gol2PlusOlasilik"]}",
        ),
        _ResultRow(
          icon: Icons.sync_alt_rounded,
          label: "Olası KG İhtimali",
          value: "%${kgVarPercent.toStringAsFixed(1)}",
        ),
      ],
    );
  }

  /// Son maçları gösteren açılır/kapanır liste.
  Widget _buildLastMatchesExpansion(ThemeData theme, String teamName, List<Map<String, dynamic>> matches) {
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text("$teamName Son Maçlar", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        children: matches.map((match) => _buildMatchResultRow(theme, match)).toList(),
      ),
    );
  }

  /// Açılır liste içindeki her bir maç sonucunu gösterir.
  Widget _buildMatchResultRow(ThemeData theme, Map<String, dynamic> match) {
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
    final controllerState = ref.watch(comparisonControllerProvider);
    final isLoading = controllerState.team1Stats.isLoading || controllerState.team2Stats.isLoading || controllerState.isLoadingTeams;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 24.0),
      children: [
        _buildSetupCard(context, ref),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            icon: isLoading 
                ? SpinKitThreeBounce(color: theme.colorScheme.onPrimary, size: 18.0) 
                : const Icon(Icons.compare_arrows_rounded, size: 20),
            label: const Text('Takımları Karşılaştır'),
            onPressed: (controllerState.selectedLeague == null || isLoading || controllerState.originalTeam1 == null || controllerState.originalTeam2 == null)
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    ref.read(comparisonControllerProvider.notifier).fetchComparisonStats(currentSeasonApiValue);
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        if (isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(32.0), child: SpinKitPouringHourGlassRefined(color: Colors.deepOrange, size: 50.0)))
        else if (controllerState.errorMessage != null)
          Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(controllerState.errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error, fontSize: 16.0))))
        else if (controllerState.team1Stats.value != null && controllerState.team2Stats.value != null)
          _buildResults(context, ref)
        else
          _buildEmptyState(context),
      ],
    );
  }
}

// --- YARDIMCI WIDGET'LAR ---

class _TeamDisplay extends StatelessWidget {
  const _TeamDisplay({
    required this.theme,
    required this.name,
    required this.logoUrl,
  });

  final ThemeData theme;
  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final String? localLogoUrl = logoUrl;
    return Expanded(
      child: Column(
        children: [
          if (localLogoUrl != null)
            CachedNetworkImage(imageUrl: localLogoUrl, height: 48, width: 48, fit: BoxFit.contain)
          else
            Icon(Icons.shield_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            name,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
