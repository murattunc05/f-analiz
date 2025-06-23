// lib/features/team_profile/team_profile_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futbol_analiz_app/data_service.dart';

enum TeamStatFilter { genel, icSaha, disSaha }

class TeamProfileData {
  final Map<String, dynamic> overallStats;
  final Map<String, dynamic> homeStats;
  final Map<String, dynamic> awayStats;
  final List<Map<String, dynamic>> allMatches;

  TeamProfileData({
    required this.overallStats,
    required this.homeStats,
    required this.awayStats,
    required this.allMatches,
  });
}

class TeamProfileState {
  final AsyncValue<TeamProfileData> profileData;
  final TeamStatFilter selectedFilter;

  const TeamProfileState({
    this.profileData = const AsyncValue.loading(),
    this.selectedFilter = TeamStatFilter.genel,
  });

  TeamProfileState copyWith({
    AsyncValue<TeamProfileData>? profileData,
    TeamStatFilter? selectedFilter,
  }) {
    return TeamProfileState(
      profileData: profileData ?? this.profileData,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class TeamProfileController extends StateNotifier<TeamProfileState> {
  final DataService _dataService;
  final String teamName;
  final String leagueName;
  final String season;

  TeamProfileController(this._dataService, {required this.teamName, required this.leagueName, required this.season})
      : super(const TeamProfileState()) {
    _fetchTeamData();
  }

  Future<void> _fetchTeamData() async {
    state = state.copyWith(profileData: const AsyncValue.loading());
    try {
      final leagueUrl = DataService.getLeagueUrl(leagueName, season);
      if (leagueUrl == null) throw Exception("Lig URL'si bulunamadı.");

      final csvData = await _dataService.fetchData(leagueUrl);
      if (csvData == null) throw Exception("Lig verisi çekilemedi.");

      final parsedData = _dataService.parseCsv(csvData);
      final headers = _dataService.getCsvHeaders(parsedData);
      if(headers.isEmpty || parsedData.length < 2) throw Exception("CSV verisi hatalı veya boş.");

      final allMatches = _dataService.filterMatchesByTeam(parsedData, headers, teamName);
      if (allMatches.isEmpty) throw Exception("Bu takım için maç verisi bulunamadı.");
      
      final homeMatches = allMatches.where((m) => m['HomeTeam'] == teamName).toList();
      final awayMatches = allMatches.where((m) => m['AwayTeam'] == teamName).toList();
      
      final overallStats = _dataService.analyzeTeamStats(allMatches, teamName, lastNMatches: null);
      final homeStats = homeMatches.isNotEmpty 
          ? _dataService.analyzeTeamStats(homeMatches, teamName, lastNMatches: null) 
          : _createEmptyStats(overallStats);
      final awayStats = awayMatches.isNotEmpty 
          ? _dataService.analyzeTeamStats(awayMatches, teamName, lastNMatches: null)
          : _createEmptyStats(overallStats);

      final data = TeamProfileData(
        overallStats: overallStats, 
        homeStats: homeStats, 
        awayStats: awayStats,
        allMatches: allMatches
      );

      state = state.copyWith(profileData: AsyncValue.data(data));
    } catch (e, st) {
      state = state.copyWith(profileData: AsyncValue.error(e, st));
    }
  }

  Map<String, dynamic> _createEmptyStats(Map<String, dynamic> referenceStats) {
      return {
        ...referenceStats,
        "attigi": 0, "yedigi": 0, "galibiyet": 0, "beraberlik": 0, "maglubiyet": 0,
        "oynananMacSayisi": 0
      };
  }

  void setFilter(TeamStatFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }
}

final teamProfileProvider = StateNotifierProvider.autoDispose
    .family<TeamProfileController, TeamProfileState, ({String teamName, String leagueName, String season})>(
  (ref, params) {
    final dataService = ref.watch(dataServiceProvider); 
    return TeamProfileController(dataService, teamName: params.teamName, leagueName: params.leagueName, season: params.season);
  },
);

final dataServiceProvider = Provider<DataService>((ref) => DataService());