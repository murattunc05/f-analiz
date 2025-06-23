// lib/features/single_team_analysis/single_team_controller.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data_service.dart';

// DÜZELTME: State sınıfı UI seçimlerini de içerecek şekilde güncellendi
class SingleTeamState {
  final AsyncValue<Map<String, dynamic>> teamStats;
  final List<String> availableTeams;
  final bool isLoadingTeams;
  final String? selectedLeague;
  final String? selectedTeam; // Takım seçimi de eklendi

  const SingleTeamState({
    this.teamStats = const AsyncValue.data(const {}),
    this.availableTeams = const [],
    this.isLoadingTeams = false,
    this.selectedLeague,
    this.selectedTeam,
  });

  // DÜZELTME: copyWith metodu sadeleştirildi
  SingleTeamState copyWith({
    AsyncValue<Map<String, dynamic>>? teamStats,
    List<String>? availableTeams,
    bool? isLoadingTeams,
    String? selectedLeague,
    String? selectedTeam,
    bool leagueToNull = false,
    bool teamToNull = false,
  }) {
    return SingleTeamState(
      teamStats: teamStats ?? this.teamStats,
      availableTeams: availableTeams ?? this.availableTeams,
      isLoadingTeams: isLoadingTeams ?? this.isLoadingTeams,
      selectedLeague: leagueToNull ? null : selectedLeague ?? this.selectedLeague,
      selectedTeam: teamToNull ? null : selectedTeam ?? this.selectedTeam,
    );
  }
}

class SingleTeamController extends StateNotifier<SingleTeamState> {
  SingleTeamController(this._dataService) : super(const SingleTeamState());
  final DataService _dataService;

  // DÜZELTME: Controller metotları yeni state yapısına göre güncellendi
  void selectLeague(String league) {
    state = state.copyWith(
      selectedLeague: league,
      teamToNull: true, // Lig değişince takım sıfırlanır
      availableTeams: [],
      teamStats: const AsyncValue.data({}),
    );
  }
  
  void selectTeam(String team) {
    state = state.copyWith(selectedTeam: team, teamStats: const AsyncValue.data({}));
  }

  Future<void> fetchAvailableTeams(String league, String season) async {
    state = state.copyWith(isLoadingTeams: true, availableTeams: [], teamStats: const AsyncValue.data({}));
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
      state = state.copyWith(isLoadingTeams: false);
      print("Takım listesi hatası: $e");
    }
  }

  Future<void> fetchTeamStats(String season) async {
    if (state.selectedLeague == null || state.selectedTeam == null) return;
    state = state.copyWith(teamStats: const AsyncValue.loading());
    try {
      final leagueUrl = DataService.getLeagueUrl(state.selectedLeague!, season);
      if (leagueUrl == null) throw Exception("Lig URL'si bulunamadı.");
      final csvData = await _dataService.fetchData(leagueUrl);
      if (csvData == null) throw Exception("Lig verisi çekilemedi.");
      final parsedData = _dataService.parseCsv(csvData);
      final headers = _dataService.getCsvHeaders(parsedData);
      final teamMatches = _dataService.filterMatchesByTeam(parsedData, headers, state.selectedTeam!);
      if (teamMatches.isEmpty) throw Exception("${state.selectedTeam} için maç bulunamadı.");
      final stats = _dataService.analyzeTeamStats(teamMatches, state.selectedTeam!);
      state = state.copyWith(teamStats: AsyncValue.data(stats));
    } catch (e, st) {
      state = state.copyWith(teamStats: AsyncValue.error(e, st));
    }
  }
}

final dataServiceProvider = Provider<DataService>((ref) => DataService());
final singleTeamControllerProvider = StateNotifierProvider<SingleTeamController, SingleTeamState>(
  (ref) {
    return SingleTeamController(ref.watch(dataServiceProvider));
  },
);