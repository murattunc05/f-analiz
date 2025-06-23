// lib/features/team_comparison/comparison_controller.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data_service.dart';
import '../../services/team_name_service.dart';
import '../single_team_analysis/single_team_controller.dart';

class ComparisonState {
  final String? selectedLeague;
  final String? originalTeam1;
  final String? originalTeam2;
  
  final AsyncValue<Map<String, dynamic>?> team1Stats;
  final AsyncValue<Map<String, dynamic>?> team2Stats;
  final AsyncValue<Map<String, dynamic>?> comparisonResult;
  final List<String> availableTeams;
  final bool isLoadingTeams;
  final String? errorMessage;

  const ComparisonState({
    this.selectedLeague,
    this.originalTeam1,
    this.originalTeam2,
    this.team1Stats = const AsyncValue.data(null),
    this.team2Stats = const AsyncValue.data(null),
    this.comparisonResult = const AsyncValue.data(null),
    this.availableTeams = const [],
    this.isLoadingTeams = false,
    this.errorMessage,
  });

  // DÜZELTME: copyWith metodu sadeleştirildi ve ValueGetter kaldırıldı.
  ComparisonState copyWith({
    String? selectedLeague,
    String? originalTeam1,
    String? originalTeam2,
    bool setToNull = false, // Hangi alanların null yapılacağını kontrol etmek için flag'ler
    bool team1ToNull = false,
    bool team2ToNull = false,
    AsyncValue<Map<String, dynamic>?>? team1Stats,
    AsyncValue<Map<String, dynamic>?>? team2Stats,
    AsyncValue<Map<String, dynamic>?>? comparisonResult,
    List<String>? availableTeams,
    bool? isLoadingTeams,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ComparisonState(
      selectedLeague: setToNull ? null : selectedLeague ?? this.selectedLeague,
      originalTeam1: team1ToNull ? null : originalTeam1 ?? this.originalTeam1,
      originalTeam2: team2ToNull ? null : originalTeam2 ?? this.originalTeam2,
      team1Stats: team1Stats ?? this.team1Stats,
      team2Stats: team2Stats ?? this.team2Stats,
      comparisonResult: comparisonResult ?? this.comparisonResult,
      availableTeams: availableTeams ?? this.availableTeams,
      isLoadingTeams: isLoadingTeams ?? this.isLoadingTeams,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// Controller sınıfı
class ComparisonController extends StateNotifier<ComparisonState> {
  ComparisonController(this._dataService) : super(const ComparisonState());

  final DataService _dataService;

  // DÜZELTME: Controller metotları yeni copyWith yapısına göre güncellendi.
  void selectLeague(String? league) {
    if (league != state.selectedLeague) {
      state = state.copyWith(
        selectedLeague: league,
        setToNull: league == null, // Eğer gelen lig null ise, state'i de null yap.
        team1ToNull: true, // Lig değişince takımlar sıfırlanır
        team2ToNull: true,
        availableTeams: [],
        team1Stats: const AsyncValue.data(null),
        team2Stats: const AsyncValue.data(null),
        comparisonResult: const AsyncValue.data(null),
      );
    }
  }

  void selectTeam({required int teamNumber, required String? teamName}) {
    if (teamNumber == 1) {
      state = state.copyWith(
        originalTeam1: teamName, 
        team1ToNull: teamName == null,
        team1Stats: const AsyncValue.data(null), 
        comparisonResult: const AsyncValue.data(null)
      );
    } else {
      state = state.copyWith(
        originalTeam2: teamName, 
        team2ToNull: teamName == null,
        team2Stats: const AsyncValue.data(null), 
        comparisonResult: const AsyncValue.data(null)
      );
    }
  }

  // Geri kalan metotlar aynı, çünkü copyWith'e değil, state'in kendisine güveniyorlar.
  Future<void> fetchAvailableTeams(String league, String season) async {
    state = state.copyWith(isLoadingTeams: true, availableTeams: [], clearErrorMessage: true);
    try {
      final leagueUrl = DataService.getLeagueUrl(league, season);
      if (leagueUrl == null) throw Exception("Lig URL'si bulunamadı.");

      final csvData = await _dataService.fetchData(leagueUrl);
      if (csvData == null) throw Exception("Lig verisi alınamadı.");

      final parsedData = _dataService.parseCsv(csvData);
      final headers = _dataService.getCsvHeaders(parsedData);
      final teams = _dataService.getAllOriginalTeamNames(parsedData, headers);
      
      state = state.copyWith(availableTeams: teams, isLoadingTeams: false);
    } catch (e) {
      state = state.copyWith(isLoadingTeams: false, errorMessage: "Takım listesi alınamadı: ${e.toString()}");
    }
  }
  
  Future<void> fetchComparisonStats(String season) async {
    if (state.selectedLeague == null || state.originalTeam1 == null || state.originalTeam2 == null) {
      state = state.copyWith(errorMessage: "Lütfen lig ve iki takımı da seçin.");
      return;
    }
    
    state = state.copyWith(
      team1Stats: const AsyncValue.loading(),
      team2Stats: const AsyncValue.loading(),
      comparisonResult: const AsyncValue.loading(),
      clearErrorMessage: true,
    );

    try {
      final leagueUrl = DataService.getLeagueUrl(state.selectedLeague!, season);
      if (leagueUrl == null) throw Exception("Lig URL'si oluşturulamadı.");
      
      final csvData = await _dataService.fetchData(leagueUrl);
      if (csvData == null) throw Exception("${state.selectedLeague!} verisi çekilemedi.");

      final parsedData = _dataService.parseCsv(csvData);
      final headers = _dataService.getCsvHeaders(parsedData);

      final team1Matches = _dataService.filterMatchesByTeam(parsedData, headers, state.originalTeam1!);
      final team2Matches = _dataService.filterMatchesByTeam(parsedData, headers, state.originalTeam2!);

      if (team1Matches.isEmpty || team2Matches.isEmpty) {
        throw Exception("Takımlardan biri veya her ikisi için maç verisi bulunamadı.");
      }

      final stats1 = _dataService.analyzeTeamStats(team1Matches, state.originalTeam1!);
      final stats2 = _dataService.analyzeTeamStats(team2Matches, state.originalTeam2!);

      if (stats1['oynananMacSayisi'] == 0 || stats2['oynananMacSayisi'] == 0) {
        throw Exception("Analiz için yeterli maç verisi yok.");
      }

      final result = _calculateComparison(stats1, stats2, state.originalTeam1!, state.originalTeam2!);
      
      state = state.copyWith(
        team1Stats: AsyncValue.data(stats1),
        team2Stats: AsyncValue.data(stats2),
        comparisonResult: AsyncValue.data(result),
      );

    } catch (e, st) {
      state = state.copyWith(
        team1Stats: AsyncValue.error(e, st),
        team2Stats: AsyncValue.error(e, st),
        comparisonResult: AsyncValue.error(e, st),
        errorMessage: e.toString(),
      );
    }
  }

  Map<String, dynamic> _calculateComparison(Map<String, dynamic> stats1, Map<String, dynamic> stats2, String team1Name, String team2Name) {
      String takim1DisplayAdi = stats1['displayTeamName'] as String? ?? TeamNameService.getCorrectedTeamName(team1Name);
      String takim2DisplayAdi = stats2['displayTeamName'] as String? ?? TeamNameService.getCorrectedTeamName(team2Name);
      double skor1 = ((stats1['attigi'] as num?)?.toDouble() ?? 0.0) + (((stats1['galibiyet'] as num?)?.toDouble() ?? 0.0) * 2) - ((stats1['maglubiyet'] as num?)?.toDouble() ?? 0.0);
      double skor2 = ((stats2['attigi'] as num?)?.toDouble() ?? 0.0) + (((stats2['galibiyet'] as num?)?.toDouble() ?? 0.0) * 2) - ((stats2['maglubiyet'] as num?)?.toDouble() ?? 0.0);
      double beklenenGol = (((stats1['maclardaOrtalamaToplamGol'] as num?)?.toDouble() ?? 0.0) + ((stats2['maclardaOrtalamaToplamGol'] as num?)?.toDouble() ?? 0.0)) / 2;
      double gol2PlusOlasilik = (((stats1['gol2UstuOlasilik'] as num?)?.toDouble() ?? 0.0) + ((stats2['gol2UstuOlasilik'] as num?)?.toDouble() ?? 0.0)) / 2;
      return { "kazanan": skor1 > skor2 ? takim1DisplayAdi : (skor2 > skor1 ? takim2DisplayAdi : "Berabere"), "beklenenToplamGol": double.parse(beklenenGol.toStringAsFixed(2)), "gol2PlusOlasilik": double.parse(gol2PlusOlasilik.toStringAsFixed(1)) };
  }
}

final comparisonControllerProvider = StateNotifierProvider<ComparisonController, ComparisonState>(
  (ref) {
    return ComparisonController(ref.watch(dataServiceProvider));
  },
);