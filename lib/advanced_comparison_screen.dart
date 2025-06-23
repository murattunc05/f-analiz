// lib/advanced_comparison_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data_service.dart';
import 'widgets/league_selection_dialog_content.dart';
import 'widgets/team_selection_dialog_content.dart';
import 'main.dart'; 
import 'utils/dialog_utils.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'widgets/team_setup_card_widget.dart';
import 'widgets/comparison_stats_card_widget.dart';
import 'widgets/comparison_result_card_widget.dart';
import 'widgets/detailed_match_list_content.dart';
import 'widgets/full_comparison_expectations_content.dart';
import 'features/advanced_comparison/advanced_comparison_controller.dart'; 
import 'widgets/h2h_summary_card.dart';
import 'widgets/h2h_popup_content.dart';
import 'widgets/modern_header_widget.dart';

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

  Future<void> _selectLeagueForTeam(BuildContext context, WidgetRef ref, int teamNumber) async {
    final controller = ref.read(advancedComparisonControllerProvider.notifier);
    final controllerState = ref.read(advancedComparisonControllerProvider);
    final currentLeague = teamNumber == 1 ? controllerState.selectedLeague1 : controllerState.selectedLeague2;
    final currentSeason = teamNumber == 1 ? controllerState.selectedSeason1 : controllerState.selectedSeason2;
    final displaySeason = DataService.getDisplaySeasonFromApiValue(currentSeason ?? currentSeasonApiValue);

    final selectedLeagueName = await showAnimatedDialog<String>(
      context: context,
      titleWidget: Text("$teamNumber. Takım İçin Lig Seçin\n(Sezon: $displaySeason)", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18), textAlign: TextAlign.center),
      contentWidget: LeagueSelectionDialogContent(availableLeagues: DataService.leagueDisplayNames, currentSelectedLeague: currentLeague),
    );

    if (selectedLeagueName != null) {
      controller.selectLeague(teamNumber, selectedLeagueName);
      controller.fetchAvailableTeams(teamNumber: teamNumber, league: selectedLeagueName, season: currentSeason ?? currentSeasonApiValue);
    }
  }

  Future<void> _selectTeam(BuildContext context, WidgetRef ref, int teamNumber) async {
    final controller = ref.read(advancedComparisonControllerProvider.notifier);
    final controllerState = ref.read(advancedComparisonControllerProvider);
    final teamData = teamNumber == 1 ? controllerState.team1Data : controllerState.team2Data;
    final league = teamNumber == 1 ? controllerState.selectedLeague1 : controllerState.selectedLeague2;
    final season = teamNumber == 1 ? controllerState.selectedSeason1 : controllerState.selectedSeason2;

    if (league == null || season == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$teamNumber. takım için önce lig ve sezon seçin.')));
      return;
    }
    if (teamData.isLoadingTeams) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Takım listesi yükleniyor...')));
      return;
    }

    HapticFeedback.lightImpact();
    final displaySeason = DataService.getDisplaySeasonFromApiValue(season);
    final dialogTitleText = "$teamNumber. Takım Seç\n($league - $displaySeason)";

    final selectedName = await showAnimatedDialog<String>(
      context: context,
      titleWidget: Text(dialogTitleText, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18), textAlign: TextAlign.center),
      contentWidget: TeamSelectionDialogContent(availableOriginalTeamNames: teamData.availableTeams, leagueName: league),
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
          children: DataService.AVAILABLE_SEASONS_DISPLAY.entries.map((entry) => 
            RadioListTile<String>(
              title: Text(entry.key), value: entry.value, groupValue: currentSeason ?? currentSeasonApiValue,
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.selectSeason(teamNumber, newValue);
                  final league = teamNumber == 1 ? controllerState.selectedLeague1 : controllerState.selectedLeague2;
                  if (league != null) {
                    controller.fetchAvailableTeams(teamNumber: teamNumber, league: league, season: newValue);
                  }
                  Navigator.of(context).pop();
                }
              },
            )).toList(),
        ),
      ),
      actionsWidget: [TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop())],
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
        h2hStats: controllerState.h2hStats
      ),
      actionsWidget: [
        TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop())
      ],
      maxHeightFactor: 0.8
    );
  }

  void _showDetailedMatchListPopup(BuildContext context, List<Map<String, dynamic>> matches, String teamDisplayName) {
    ThemeData theme = Theme.of(context);
    String popupTitleText = matches.isNotEmpty ? '$teamDisplayName - Son ${matches.length} Maç' : '$teamDisplayName - Maç Detayı Yok';
    showAnimatedDialog(
      context: context,
      titleWidget: Text(popupTitleText, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary), textAlign: TextAlign.center),
      dialogPadding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      contentWidget: DetailedMatchListContent(
        theme: theme, matches: matches, teamName: teamDisplayName, numberOfMatchesToCompare: int.tryParse(_matchCountController.text) ?? 5,
      ),
      actionsWidget: [TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop(),)],
      maxHeightFactor: 0.55,
    );
  }
  
  void _showFullComparisonDialog(BuildContext context, Map<String, dynamic> team1Stats, Map<String, dynamic> team2Stats, Map<String, dynamic> comparisonResult) {
    ThemeData theme = Theme.of(context);
    showAnimatedDialog(
        context: context,
        titleWidget: Text('Detaylı Maç Beklentileri', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary), textAlign: TextAlign.center),
        dialogPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentWidget: FullComparisonExpectationsContent( 
            theme: theme, team1Stats: team1Stats, team2Stats: team2Stats,
            comparisonResult: comparisonResult, statsSettings: statsSettings,
        ),
        actionsWidget: [TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop())],
        maxHeightFactor: 0.8,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controllerState = ref.watch(advancedComparisonControllerProvider);
    final team1Stats = controllerState.team1Data.stats;
    final team2Stats = controllerState.team2Data.stats;
    final comparisonResult = controllerState.comparisonResult;
    final canCompare = controllerState.selectedLeague1 != null && controllerState.selectedTeam1 != null &&
                        controllerState.selectedLeague2 != null && controllerState.selectedTeam2 != null &&
                        !controllerState.isLoading;
                        
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controllerState.selectedSeason1 == null) {
        ref.read(advancedComparisonControllerProvider.notifier).selectSeason(1, currentSeasonApiValue);
      }
      if (controllerState.selectedSeason2 == null) {
        ref.read(advancedComparisonControllerProvider.notifier).selectSeason(2, currentSeasonApiValue);
      }
    });

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
                    theme: theme, cardTitle: '1. Takım Ayarları',
                    selectedLeague: controllerState.selectedLeague1,
                    selectedSeasonApiVal: controllerState.selectedSeason1,
                    currentTeamName: controllerState.selectedTeam1 ?? '',
                    globalCurrentSeasonApiValue: currentSeasonApiValue,
                    onLeagueSelectTap: () => _selectLeagueForTeam(context, ref, 1),
                    onTeamSelectTap: () => _selectTeam(context, ref, 1),
                    onSeasonIconTap: () => _showSeasonSelectionDialogForTeam(context, ref, 1),
                  ),
                  TeamSetupCardWidget(
                    theme: theme, cardTitle: '2. Takım Ayarları',
                    selectedLeague: controllerState.selectedLeague2,
                    selectedSeasonApiVal: controllerState.selectedSeason2,
                    currentTeamName: controllerState.selectedTeam2 ?? '',
                    globalCurrentSeasonApiValue: currentSeasonApiValue,
                    onLeagueSelectTap: () => _selectLeagueForTeam(context, ref, 2),
                    onTeamSelectTap: () => _selectTeam(context, ref, 2),
                    onSeasonIconTap: () => _showSeasonSelectionDialogForTeam(context, ref, 2),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(
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
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                            maxLength: 2,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: controllerState.isLoading
                                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                                : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            minimumSize: const Size(64, 48),
                          ),
                          icon: controllerState.isLoading
                              ? SpinKitThreeBounce(color: theme.colorScheme.onPrimary, size: 18.0)
                              : const Icon(Icons.insights, size: 20),
                          label: Text(controllerState.isLoading ? 'Analiz Ediliyor...' : 'Karşılaştır'),
                          onPressed: !canCompare
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  HapticFeedback.mediumImpact();
                                  ref.read(advancedComparisonControllerProvider.notifier).performAdvancedComparison(
                                        matchCount: int.tryParse(_matchCountController.text) ?? 5
                                      );
                                },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            if (controllerState.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: SpinKitPouringHourGlassRefined(color: Colors.deepOrange, size: 50.0)))
            else if (controllerState.errorMessage != null)
              Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(controllerState.errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error, fontSize: 16.0))))
            
            else if (team1Stats.hasValue && team2Stats.hasValue && team1Stats.value != null && team2Stats.value != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    if (comparisonResult.hasValue && comparisonResult.value != null) ...[
                      ComparisonResultCardWidget(
                        theme: theme,
                        comparisonResult: comparisonResult.value!,
                        team1Stats: team1Stats.value,
                        team2Stats: team2Stats.value,
                        statsSettings: statsSettings,
                        numberOfMatchesToCompare: int.tryParse(_matchCountController.text) ?? 5,
                        onFullComparisonTap: () => _showFullComparisonDialog(context, team1Stats.value!, team2Stats.value!, comparisonResult.value!),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (controllerState.h2hStats.isNotEmpty)
                      H2HSummaryCard(
                         theme: theme, 
                         h2hStats: controllerState.h2hStats,
                         team1Data: team1Stats.value!,
                         team2Data: team2Stats.value!,
                         lastMatch: controllerState.h2hMatches.isNotEmpty ? controllerState.h2hMatches.first : null,
                         onShowDetails: () => _showH2HMatchesPopup(context, ref)
                       )
                    else
                      Card(
                        elevation: 1.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.dividerColor, width: 0.5)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Şu anda aralarındaki maçlar özelliği yalnızca aynı sezon takımlarının karşılaşmalarında görünebilir durumdadır.\nYakında daha kapsamlı veriler sunmak için çalışıyoruz.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ComparisonStatsCardWidget( 
                      theme: theme,
                      team1Data: team1Stats.value!,
                      team2Data: team2Stats.value!,
                      statsSettings: statsSettings,
                      numberOfMatchesToCompare: int.tryParse(_matchCountController.text) ?? 5,
                      onShowDetailedMatchList: (ctx, matches, name) => _showDetailedMatchListPopup(ctx, matches, name),
                      onShowTeamGraphs: (ctx, teamData) => ScaffoldMessenger.of(ctx).showSnackBar( const SnackBar(content: Text('Grafik özelliği bu ekranda aktif değil.'))),
                    ),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 32.0, bottom: 32.0),
                child: Center(child: Text('Gelişmiş karşılaştırma için seçimleri yapın.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
              ),
          ],
        ),
      ),
    );
  }
}