// lib/features/matches/matches_controller.dart
import 'package:flutter/material.dart'; // foundation.dart yerine bunu kullanmak yeterli
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../match_detail_screen.dart';

// MatchDetailState ve MatchesState sınıfları aynı kalıyor...
class MatchDetailState {
  final AsyncValue<Map<String, dynamic>> fixtureDetails;
  const MatchDetailState({ this.fixtureDetails = const AsyncValue.loading() });

  MatchDetailState copyWith({ AsyncValue<Map<String, dynamic>>? fixtureDetails }) {
    return MatchDetailState(fixtureDetails: fixtureDetails ?? this.fixtureDetails);
  }
}

class MatchesState {
  final AsyncValue<List<dynamic>> liveMatches;
  final AsyncValue<List<dynamic>> selectedDateMatches;
  final Set<int> activeLeagueIds;
  final DateTime selectedDate;
  final List<dynamic> availableCompetitions;
  final Set<int> selectedCompetitionIds;
  final bool isLoadingCompetitions;

  const MatchesState({
    this.liveMatches = const AsyncValue.loading(),
    this.selectedDateMatches = const AsyncValue.loading(),
    this.activeLeagueIds = const {},
    required this.selectedDate,
    this.availableCompetitions = const [],
    this.selectedCompetitionIds = const {},
    this.isLoadingCompetitions = true,
  });

  MatchesState copyWith({
    AsyncValue<List<dynamic>>? liveMatches,
    AsyncValue<List<dynamic>>? selectedDateMatches,
    Set<int>? activeLeagueIds,
    DateTime? selectedDate,
    List<dynamic>? availableCompetitions,
    Set<int>? selectedCompetitionIds,
    bool? isLoadingCompetitions,
  }) {
    return MatchesState(
      liveMatches: liveMatches ?? this.liveMatches,
      selectedDateMatches: selectedDateMatches ?? this.selectedDateMatches,
      activeLeagueIds: activeLeagueIds ?? this.activeLeagueIds,
      selectedDate: selectedDate ?? this.selectedDate,
      availableCompetitions: availableCompetitions ?? this.availableCompetitions,
      selectedCompetitionIds: selectedCompetitionIds ?? this.selectedCompetitionIds,
      isLoadingCompetitions: isLoadingCompetitions ?? this.isLoadingCompetitions,
    );
  }
}


class MatchesController extends StateNotifier<MatchesState> {
  MatchesController(this._apiService, this._prefs) : super(MatchesState(selectedDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))) {
    _initialize();
  }

  final ApiService _apiService;
  final SharedPreferences _prefs;
  static const String _kSelectedLeaguesKey = 'selected_league_ids_v4';

  Future<void> _initialize() async {
    final competitionsFuture = fetchAvailableCompetitions();
    final initialFetchFuture = fetchMatches(isInitialLoad: true);
    await Future.wait([competitionsFuture, initialFetchFuture]);
  }

  Future<void> fetchAvailableCompetitions() async {
    state = state.copyWith(isLoadingCompetitions: true);
    try {
      final competitionsRaw = await _apiService.getAvailableCompetitions();
      final cleanCompetitions = competitionsRaw.where((c) => c['id'] != null && c['country']?['name'] != null).toList();
      final groupedAndSorted = _groupAndSortCompetitions(cleanCompetitions);
      
      final savedIds = _prefs.getStringList(_kSelectedLeaguesKey)?.map(int.parse).toSet();
      const Set<int> defaultSelection = { 203, 39, 140, 78, 135, 61, 2, 3 };

      state = state.copyWith(
        availableCompetitions: groupedAndSorted,
        isLoadingCompetitions: false,
        selectedCompetitionIds: savedIds ?? defaultSelection,
        activeLeagueIds: {},
      );
    } catch (e) {
      state = state.copyWith(isLoadingCompetitions: false);
      debugPrint("Lig listesi alınamadı: $e");
    }
  }

  Future<void> fetchMatches({bool isInitialLoad = false, bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(liveMatches: const AsyncValue.loading());
    } else {
      state = state.copyWith(selectedDateMatches: const AsyncValue.loading());
    }

    try {
      if (isRefresh || isInitialLoad) {
        // DEĞİŞİKLİK: _get -> get
        final liveMatchesData = await _apiService.get('fixtures?live=all');
        state = state.copyWith(liveMatches: AsyncValue.data(liveMatchesData));
      }
      
      if (isInitialLoad || !isRefresh) {
        final selectedDateMatchesData = await _apiService.getMatchesForDate(state.selectedDate);
        state = state.copyWith(selectedDateMatches: AsyncValue.data(selectedDateMatchesData));
      }

    } catch (e, st) {
       if (isRefresh) {
         state = state.copyWith(liveMatches: AsyncValue.error(e, st));
       } else {
         state = state.copyWith(
           liveMatches: isInitialLoad ? AsyncValue.error(e, st) : state.liveMatches,
           selectedDateMatches: AsyncValue.error(e, st)
         );
       }
    }
  }
  
  void changeDate(DateTime newDate) {
    final newDateWithoutTime = DateTime(newDate.year, newDate.month, newDate.day);
    if(newDateWithoutTime.isAtSameMomentAs(state.selectedDate)) return;
    
    state = state.copyWith(selectedDate: newDateWithoutTime);
    fetchMatches();
  }

  List<Map<String, dynamic>> _groupAndSortCompetitions(List<dynamic> competitions) {
    final Map<String, List<dynamic>> leaguesByCountry = {};
    final List<dynamic> internationalCups = [];
    
    const Set<int> topLeaguesIds = {203, 39, 140, 78, 135, 61};
    const Set<int> internationalCupIds = {1, 2, 3, 4, 15, 848};
    
    for (var comp in competitions) {
      final countryName = comp['country']['name'];
      if (internationalCupIds.contains(comp['id'])) {
        internationalCups.add(comp);
      } else if (countryName != null) {
        if (!leaguesByCountry.containsKey(countryName)) {
          leaguesByCountry[countryName] = [];
        }
        leaguesByCountry[countryName]!.add(comp);
      }
    }
    
    final List<Map<String, dynamic>> result = [];
    
    final List<dynamic> allPopularLeagues = competitions.where((c) => topLeaguesIds.contains(c['id'])).toList();
    if(allPopularLeagues.isNotEmpty) {
       result.add({
        'groupName': 'Popüler Ligler',
        'icon': Icons.star,
        'leagues': allPopularLeagues,
      });
    }

    if (internationalCups.isNotEmpty) {
      result.add({
        'groupName': 'Uluslararası Kupalar',
        'icon': Icons.public,
        'leagues': internationalCups,
      });
    }
    
    final allCountryKeys = leaguesByCountry.keys.toList()..sort();
    for (var country in allCountryKeys) {
       result.add({
        'groupName': country,
        'countryFlag': leaguesByCountry[country]!.first['country']['flag'],
        'leagues': leaguesByCountry[country]!,
      });
    }
    
    return result;
  }
  
  Future<void> updateSelectedCompetitions(Set<int> newIds) async {
    await _prefs.setStringList(_kSelectedLeaguesKey, newIds.map((id) => id.toString()).toList());
    state = state.copyWith(
      selectedCompetitionIds: newIds,
      activeLeagueIds: {},
    );
    // Yeni ligler seçildiğinde maçları yeniden çek
    fetchMatches();
  }

  void setActiveLeagueFilter(Set<int> leagueIds) {
    state = state.copyWith(activeLeagueIds: leagueIds);
  }

  void toggleActiveLeagueFilter(int leagueId) {
    final currentSelection = Set<int>.from(state.activeLeagueIds);
    if (currentSelection.contains(leagueId)) {
      currentSelection.remove(leagueId);
    } else {
      currentSelection.add(leagueId);
    }
    state = state.copyWith(activeLeagueIds: currentSelection);
  }
  
  void onViewMatchDetails(BuildContext context, Map<String, dynamic> matchData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailScreen(matchData: matchData),
      ),
    );
  }
}

class MatchDetailController extends StateNotifier<MatchDetailState> {
  MatchDetailController(this._apiService, this.fixtureId) : super(const MatchDetailState());
  
  final ApiService _apiService;
  final int fixtureId;

  Future<void> fetchDetails() async {
    state = const MatchDetailState();
    try {
      final results = await _apiService.getFullFixtureDetails(fixtureId);
      if (results.isNotEmpty) {
        state = state.copyWith(fixtureDetails: AsyncValue.data(results.first));
      } else {
        throw Exception("Bu maç için detay bulunamadı.");
      }
    } catch (e, st) {
      state = state.copyWith(fixtureDetails: AsyncValue.error(e, st));
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async => await SharedPreferences.getInstance());

final matchesControllerProvider = StateNotifierProvider<MatchesController, MatchesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider).asData!.value;
  return MatchesController(apiService, prefs);
});

final matchDetailProvider = StateNotifierProvider.autoDispose.family<MatchDetailController, MatchDetailState, int>(
  (ref, fixtureId) {
    return MatchDetailController(ref.watch(apiServiceProvider), fixtureId);
  },
);