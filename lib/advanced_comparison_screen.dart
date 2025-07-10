// lib/advanced_comparison_screen.dart (Yeniden Tasarlandı)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futbol_analiz_app/main.dart';
import 'package:futbol_analiz_app/utils/dialog_utils.dart';
import 'package:futbol_analiz_app/widgets/ai_analysis_card.dart';
import 'package:futbol_analiz_app/widgets/comparison_stats_card_widget.dart';
import 'package:futbol_analiz_app/widgets/detailed_match_list_content.dart';
import 'package:futbol_analiz_app/widgets/h2h_popup_content.dart';
import 'package:futbol_analiz_app/widgets/h2h_summary_card.dart';
import 'package:futbol_analiz_app/widgets/league_selection_dialog_content.dart';
import 'package:futbol_analiz_app/widgets/statistical_expectations_card.dart';
import 'package:futbol_analiz_app/widgets/team_selection_dialog_content.dart';
import 'package:futbol_analiz_app/widgets/team_setup_card_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:futbol_analiz_app/services/logo_service.dart';
import 'features/advanced_comparison/advanced_comparison_controller.dart';
import 'data_service.dart';

class AdvancedComparisonScreen extends ConsumerWidget {
  final StatsDisplaySettings statsSettings;
  final String currentSeasonApiValue;
  final ScrollController scrollController;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onSearchTap;

  AdvancedComparisonScreen({
    super.key,
    required this.statsSettings,
    required this.currentSeasonApiValue,
    required this.scrollController,
    required this.scaffoldKey,
    required this.onSearchTap,
  });

  final TextEditingController _matchCountController = TextEditingController(text: '5');

  // --- Fonksiyonlar ---
  // Bu fonksiyonlar, UI'dan ayrıştırılmış ve mantığı içerir.

  Future<void> _selectLeagueForTeam(BuildContext context, WidgetRef ref, int teamNumber) async {
    final controller = ref.read(advancedComparisonControllerProvider.notifier);
    final controllerState = ref.read(advancedComparisonControllerProvider);
    final currentLeague = teamNumber == 1 ? controllerState.selectedLeague1 : controllerState.selectedLeague2;
    final currentSeason = teamNumber == 1 ? controllerState.selectedSeason1 : controllerState.selectedSeason2;
    final displaySeason = DataService.getDisplaySeasonFromApiValue(currentSeason ?? currentSeasonApiValue);

    final selectedLeagueName = await showAnimatedDialog<String>(
      context: context,
      titleWidget: Text(
          "$teamNumber. Takım İçin Lig Seçin\n(Sezon: $displaySeason)",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
          textAlign: TextAlign.center),
      contentWidget: LeagueSelectionDialogContent(
          availableLeagues: DataService.leagueDisplayNames,
          currentSelectedLeague: currentLeague),
    );

    if (selectedLeagueName != null) {
      controller.selectLeague(teamNumber, selectedLeagueName);
      controller.fetchAvailableTeams(
          teamNumber: teamNumber,
          league: selectedLeagueName,
          season: currentSeason ?? currentSeasonApiValue);
    }
  }

  Future<void> _selectTeam(BuildContext context, WidgetRef ref, int teamNumber) async {
    final controller = ref.read(advancedComparisonControllerProvider.notifier);
    final controllerState = ref.read(advancedComparisonControllerProvider);
    final teamData = teamNumber == 1 ? controllerState.team1Data : controllerState.team2Data;
    final league = teamNumber == 1 ? controllerState.selectedLeague1 : controllerState.selectedLeague2;
    final season = teamNumber == 1 ? controllerState.selectedSeason1 : controllerState.selectedSeason2;

    if (league == null || season == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$teamNumber. takım için önce lig ve sezon seçin.')));
      return;
    }
    if (teamData.isLoadingTeams) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Takım listesi yükleniyor...')));
      return;
    }

    HapticFeedback.lightImpact();
    final displaySeason = DataService.getDisplaySeasonFromApiValue(season);
    final dialogTitleText = "$teamNumber. Takım Seç\n($league - $displaySeason)";

    final selectedName = await showAnimatedDialog<String>(
      context: context,
      titleWidget: Text(dialogTitleText,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
          textAlign: TextAlign.center),
      contentWidget: TeamSelectionDialogContent(
          availableOriginalTeamNames: teamData.availableTeams,
          leagueName: league),
    );

    if (selectedName != null) {
      controller.selectTeam(teamNumber, selectedName);
    }
  }

  void _showSeasonSelectionDialogForTeam(BuildContext context, WidgetRef ref, int teamNumber) {
    final controller = ref.read(advancedComparisonControllerProvider.notifier);
    final controllerState = ref.read(advancedComparisonControllerProvider);
    final currentSeason = teamNumber == 1 ? controllerState.selectedSeason1 : controllerState.selectedSeason2;

    showAnimatedDialog(
      context: context,
      titleWidget: const Text('Sezon Seçin', textAlign: TextAlign.center),
      contentWidget: SizedBox(
        child: ListView(
          shrinkWrap: true,
          children: DataService.AVAILABLE_SEASONS_DISPLAY.entries
              .map((entry) => RadioListTile<String>(
                    title: Text(entry.key),
                    value: entry.value,
                    groupValue: currentSeason ?? currentSeasonApiValue,
                    onChanged: (newValue) {
                      if (newValue != null) {
                        controller.selectSeason(teamNumber, newValue);
                        final league = teamNumber == 1
                            ? controllerState.selectedLeague1
                            : controllerState.selectedLeague2;
                        if (league != null) {
                          controller.fetchAvailableTeams(
                              teamNumber: teamNumber,
                              league: league,
                              season: newValue);
                        }
                        Navigator.of(context).pop();
                      }
                    },
                  ))
              .toList(),
        ),
      ),
      actionsWidget: [
        TextButton(
            child: const Text('Kapat'),
            onPressed: () => Navigator.of(context).pop())
      ],
    );
  }

  void _showH2HMatchesPopup(BuildContext context, WidgetRef ref) {
    final controllerState = ref.read(advancedComparisonControllerProvider);
    final theme = Theme.of(context);

    if (controllerState.h2hMatches.isEmpty) return;

    showAnimatedDialog(
        context: context,
        titleWidget: const SizedBox.shrink(),
        dialogPadding: const EdgeInsets.all(12),
        contentWidget: H2HPopupContent(
            theme: theme,
            h2hMatches: controllerState.h2hMatches,
            team1Data: controllerState.team1Data.stats.value!,
            team2Data: controllerState.team2Data.stats.value!,
            h2hStats: controllerState.h2hStats),
        actionsWidget: [
          TextButton(
              child: const Text('Kapat'),
              onPressed: () => Navigator.of(context).pop())
        ],
        maxHeightFactor: 0.8);
  }

  void _showDetailedMatchListPopup(BuildContext context,
      List<Map<String, dynamic>> matches, String teamDisplayName) {
    ThemeData theme = Theme.of(context);
    String popupTitleText = matches.isNotEmpty
        ? '$teamDisplayName - Son ${matches.length} Maç'
        : '$teamDisplayName - Maç Detayı Yok';
    showAnimatedDialog(
      context: context,
      titleWidget: Text(popupTitleText,
          style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
          textAlign: TextAlign.center),
      dialogPadding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      contentWidget: DetailedMatchListContent(
        theme: theme,
        matches: matches,
        teamName: teamDisplayName,
        numberOfMatchesToCompare:
            int.tryParse(_matchCountController.text) ?? 5,
      ),
      actionsWidget: [
        TextButton(
            child: const Text('Kapat'),
            onPressed: () => Navigator.of(context).pop(),)
      ],
      maxHeightFactor: 0.55,
    );
  }
  
  // --- YENİ UI/UX WIDGET'LARI ---

  /// Karşılaştırma için boş durum (empty state) ekranı.
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(
            "Gelişmiş Analiz",
            style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Farklı lig ve sezonlardaki takımları karşılaştırın, yapay zeka yorumu alın ve aralarındaki maçları görün.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Sonuçları gösteren ana widget.
  Widget _buildAdvancedResults(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controllerState = ref.watch(advancedComparisonControllerProvider);
    final team1Data = controllerState.team1Data.stats.value!;
    final team2Data = controllerState.team2Data.stats.value!;
    
    final String team1DisplayName = team1Data["displayTeamName"] ?? "Takım 1";
    final String team2DisplayName = team2Data["displayTeamName"] ?? "Takım 2";
    final String? team1LogoUrl = LogoService.getTeamLogoUrl(team1Data["takim"], team1Data['leagueNameForLogo']);
    final String? team2LogoUrl = LogoService.getTeamLogoUrl(team2Data["takim"], team2Data['leagueNameForLogo']);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Takım Başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TeamDisplay(theme: theme, name: team1DisplayName, logoUrl: team1LogoUrl),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, left: 8, right: 8),
                  child: Text("VS", style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
                _TeamDisplay(theme: theme, name: team2DisplayName, logoUrl: team2LogoUrl),
              ],
            ),
            const Divider(height: 32),
            // İstatistikler
            ComparisonStatsCardWidget(
              theme: theme,
              team1Data: team1Data,
              team2Data: team2Data,
              statsSettings: statsSettings,
              numberOfMatchesToCompare: int.tryParse(_matchCountController.text) ?? 5,
              onShowDetailedMatchList: (ctx, matches, name) => _showDetailedMatchListPopup(ctx, matches, name),
              onShowTeamGraphs: (ctx, teamData) => ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Grafik özelliği bu ekranda aktif değil.'))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controllerState = ref.watch(advancedComparisonControllerProvider);
    final team1Stats = controllerState.team1Data.stats;
    final team2Stats = controllerState.team2Data.stats;
    final scrollController = PrimaryScrollController.of(context) ?? this.scrollController;
    final canCompare = controllerState.selectedLeague1 != null &&
        controllerState.selectedTeam1 != null &&
        controllerState.selectedLeague2 != null &&
        controllerState.selectedTeam2 != null &&
        !controllerState.isLoading;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controllerState.selectedSeason1 == null) {
        ref.read(advancedComparisonControllerProvider.notifier).selectSeason(1, currentSeasonApiValue);
      }
      if (controllerState.selectedSeason2 == null) {
        ref.read(advancedComparisonControllerProvider.notifier).selectSeason(2, currentSeasonApiValue);
      }
    });

    final bool showResults = team1Stats.hasValue &&
        team2Stats.hasValue &&
        team1Stats.value != null &&
        team2Stats.value != null;
    
    final bool showAiButton = showResults &&
        (controllerState.aiCommentary.asData?.value.isEmpty ?? true) &&
        !controllerState.aiCommentary.isLoading;
    
    final bool showAiCard = showResults &&
        (controllerState.aiCommentary.isLoading ||
            (controllerState.aiCommentary.hasValue &&
                controllerState.aiCommentary.asData!.value.isNotEmpty == true) ||
            controllerState.aiCommentary.hasError);
        
    final bool showExpectationsButton = showResults &&
        (controllerState.statisticalExpectations.asData?.value.isEmpty ?? true) &&
        !controllerState.statisticalExpectations.isLoading;

    final bool showExpectationsCard = showResults &&
        (controllerState.statisticalExpectations.isLoading ||
            (controllerState.statisticalExpectations.hasValue &&
                controllerState.statisticalExpectations.asData!.value.isNotEmpty == true) ||
            controllerState.statisticalExpectations.hasError);


    return PrimaryScrollController(
      controller: scrollController,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
        // Kurulum Kartları
        Card(
          elevation: 2,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TeamSetupCardWidget(
                  theme: theme,
                  cardTitle: '1. Takım Ayarları',
                  selectedLeague: controllerState.selectedLeague1,
                  selectedSeasonApiVal: controllerState.selectedSeason1,
                  currentTeamName: controllerState.selectedTeam1 ?? '',
                  globalCurrentSeasonApiValue: currentSeasonApiValue,
                  onLeagueSelectTap: () => _selectLeagueForTeam(context, ref, 1),
                  onTeamSelectTap: () => _selectTeam(context, ref, 1),
                  onSeasonIconTap: () =>
                      _showSeasonSelectionDialogForTeam(context, ref, 1),
                ),
                const Divider(height: 24),
                TeamSetupCardWidget(
                  theme: theme,
                  cardTitle: '2. Takım Ayarları',
                  selectedLeague: controllerState.selectedLeague2,
                  selectedSeasonApiVal: controllerState.selectedSeason2,
                  currentTeamName: controllerState.selectedTeam2 ?? '',
                  globalCurrentSeasonApiValue: currentSeasonApiValue,
                  onLeagueSelectTap: () => _selectLeagueForTeam(context, ref, 2),
                  onTeamSelectTap: () => _selectTeam(context, ref, 2),
                  onSeasonIconTap: () =>
                      _showSeasonSelectionDialogForTeam(context, ref, 2),
                ),
              ],
            ),
          ),
        ),
        
        // Maç Sayısı ve Analiz Butonu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _matchCountController,
                  decoration: const InputDecoration(
                    labelText: 'Maç Sayısı',
                    prefixIcon: Icon(Icons.format_list_numbered),
                    hintText: 'Örn: 7',
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  maxLength: 2,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: controllerState.isLoading
                        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    minimumSize: const Size(64, 52),
                  ),
                  icon: controllerState.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                              strokeWidth: 2.5))
                      : const Icon(Icons.insights, size: 20),
                  label: Text(controllerState.isLoading
                      ? 'Analiz...'
                      : 'Analiz Et'),
                  onPressed: !canCompare
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          HapticFeedback.mediumImpact();
                          ref
                              .read(advancedComparisonControllerProvider.notifier)
                              .performAdvancedComparison(
                                matchCount:
                                    int.tryParse(_matchCountController.text) ?? 5,
                              );
                        },
                ),
              )
            ],
          ),
        ),

        // Sonuç Bölümü
        if (controllerState.isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
        else if (controllerState.errorMessage != null)
          Center(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(controllerState.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: theme.colorScheme.error, fontSize: 16.0))))
        else if (showResults)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                if (showExpectationsButton)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bar_chart_outlined, color: theme.colorScheme.secondary, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'İstatistiksel Beklentiler',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Maçın istatistiksel beklentilerini (gol, korner, kart vb.) görmek için butona tıklayın.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.analytics_outlined),
                            label: const Text("Beklentileri Göster"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                            ),
                            onPressed: () => ref
                                .read(advancedComparisonControllerProvider.notifier)
                                .generateStatisticalExpectations(),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (showExpectationsCard)
                  StatisticalExpectationsCard(
                    expectations: controllerState.statisticalExpectations,
                  ),
                if (showExpectationsCard) const SizedBox(height: 16),
                if (showAiButton)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 24),
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
                          const SizedBox(height: 16),
                          Text(
                            "Detaylı bir maç yorumu ve öngörüleri için butona tıklayın.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.psychology_outlined),
                            label: const Text("Analiz Oluştur"),
                            onPressed: () => ref
                                .read(advancedComparisonControllerProvider.notifier)
                                .generateAiAnalysis(),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (showAiCard)
                  AiAnalysisCard(
                    aiCommentary: controllerState.aiCommentary,
                  ),
                if (controllerState.h2hStats.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  H2HSummaryCard(
                      theme: theme,
                      h2hStats: controllerState.h2hStats,
                      team1Data: team1Stats.value!,
                      team2Data: team2Stats.value!,
                      lastMatch: controllerState.h2hMatches.isNotEmpty
                          ? controllerState.h2hMatches.first
                          : null,
                      onShowDetails: () =>
                          _showH2HMatchesPopup(context, ref)),
                ],
                const SizedBox(height: 16),
                _buildAdvancedResults(context, ref), // YENİ WIDGET KULLANIMI
              ],
            ),
          )
        else
          _buildEmptyState(context),
        ],
      ),
    );
  }
}

// --- YARDIMCI WIDGET'LAR ---

/// Takım logosunu ve adını gösteren widget.
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
            CachedNetworkImage(imageUrl: localLogoUrl, height: 60, width: 60, fit: BoxFit.contain)
          else
            Icon(Icons.shield_outlined, size: 60, color: theme.colorScheme.onSurfaceVariant),
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
