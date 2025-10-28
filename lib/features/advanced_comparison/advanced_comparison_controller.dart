// lib/features/advanced_comparison/advanced_comparison_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data_service.dart';
import '../../services/team_name_service.dart';
import '../../utils/activity_logger.dart';

// Liglerin genel kalitesini ve rekabet seviyesini belirten basit bir harita.
// Gelişmiş lig kalitesi haritası - UEFA katsayıları ve analiz verilerine dayalı
const Map<String, Map<String, dynamic>> _leagueQualityMap = {
  "İngiltere - Premier Lig": {
    "name": "Top Seviye (UEFA #1)",
    "coefficient": 95.0,
    "tempo": "Çok Yüksek",
    "physicality": "Yüksek",
    "technical": "Çok Yüksek"
  },
  "İspanya - La Liga": {
    "name": "Top Seviye (UEFA #2)", 
    "coefficient": 92.0,
    "tempo": "Yüksek",
    "physicality": "Orta",
    "technical": "Çok Yüksek"
  },
  "Almanya - Bundesliga": {
    "name": "Top Seviye (UEFA #3)",
    "coefficient": 88.0,
    "tempo": "Yüksek", 
    "physicality": "Yüksek",
    "technical": "Yüksek"
  },
  "İtalya - Serie A": {
    "name": "Top Seviye (UEFA #4)",
    "coefficient": 85.0,
    "tempo": "Orta-Yüksek",
    "physicality": "Orta",
    "technical": "Yüksek"
  },
  "Fransa - Ligue 1": {
    "name": "Yüksek Seviye (UEFA #5)",
    "coefficient": 78.0,
    "tempo": "Yüksek",
    "physicality": "Yüksek", 
    "technical": "Yüksek"
  },
  "Hollanda - Eredivisie": {
    "name": "Yüksek Seviye",
    "coefficient": 72.0,
    "tempo": "Yüksek",
    "physicality": "Orta",
    "technical": "Yüksek"
  },
  "Portekiz - Premier Lig": {
    "name": "Yüksek Seviye",
    "coefficient": 70.0,
    "tempo": "Orta-Yüksek",
    "physicality": "Orta",
    "technical": "Yüksek"
  },
  "Türkiye - Süper Lig": {
    "name": "Rekabetçi Orta Düzey",
    "coefficient": 62.0,
    "tempo": "Orta-Yüksek",
    "physicality": "Yüksek",
    "technical": "Orta"
  },
  "Belçika - Pro Lig": {
    "name": "Rekabetçi Orta Düzey", 
    "coefficient": 65.0,
    "tempo": "Orta",
    "physicality": "Orta",
    "technical": "Orta-Yüksek"
  },
  "İngiltere - Championship": {
    "name": "Rekabetçi Üst Düzey",
    "coefficient": 68.0,
    "tempo": "Çok Yüksek",
    "physicality": "Çok Yüksek", 
    "technical": "Orta"
  },
  "Almanya - Bundesliga 2": {
    "name": "Rekabetçi Üst Düzey",
    "coefficient": 64.0,
    "tempo": "Yüksek",
    "physicality": "Yüksek",
    "technical": "Orta-Yüksek"
  },
  "İtalya - Serie B": {
    "name": "Rekabetçi Üst Düzey",
    "coefficient": 60.0,
    "tempo": "Orta",
    "physicality": "Orta",
    "technical": "Orta-Yüksek"
  },
  "İskoçya - Premiership": {
    "name": "Orta Düzey",
    "coefficient": 55.0,
    "tempo": "Orta",
    "physicality": "Yüksek",
    "technical": "Orta"
  },
  "Yunanistan - Süper Lig": {
    "name": "Orta Düzey",
    "coefficient": 52.0,
    "tempo": "Orta",
    "physicality": "Orta",
    "technical": "Orta"
  },
};


class TeamComparisonData {
  final List<String> availableTeams;
  final bool isLoadingTeams;
  final AsyncValue<Map<String, dynamic>?> stats;

  const TeamComparisonData({
    this.availableTeams = const [],
    this.isLoadingTeams = false,
    this.stats = const AsyncValue.data(null),
  });

  TeamComparisonData copyWith({
    List<String>? availableTeams,
    bool? isLoadingTeams,
    AsyncValue<Map<String, dynamic>?>? stats,
  }) {
    return TeamComparisonData(
      availableTeams: availableTeams ?? this.availableTeams,
      isLoadingTeams: isLoadingTeams ?? this.isLoadingTeams,
      stats: stats ?? this.stats,
    );
  }
}

class AdvancedComparisonState {
  final String? selectedLeague1;
  final String? selectedSeason1;
  final String? selectedTeam1;
  final String? selectedLeague2;
  final String? selectedSeason2;
  final String? selectedTeam2;

  final TeamComparisonData team1Data;
  final TeamComparisonData team2Data;
  final AsyncValue<Map<String, dynamic>?> comparisonResult;
  final String? errorMessage;
  final bool isLoading;

  final List<Map<String, dynamic>> h2hMatches;
  final Map<String, int> h2hStats;

  final AsyncValue<String> aiCommentary;
  final AsyncValue<Map<String, dynamic>> statisticalExpectations;

  const AdvancedComparisonState({
    this.selectedLeague1,
    this.selectedSeason1,
    this.selectedTeam1,
    this.selectedLeague2,
    this.selectedSeason2,
    this.selectedTeam2,
    this.team1Data = const TeamComparisonData(),
    this.team2Data = const TeamComparisonData(),
    this.comparisonResult = const AsyncValue.data(null),
    this.errorMessage,
    this.isLoading = false,
    this.h2hMatches = const [],
    this.h2hStats = const {},
    this.aiCommentary = const AsyncValue.data(''),
    this.statisticalExpectations = const AsyncValue.data({}),
  });

  AdvancedComparisonState copyWith({
    String? selectedLeague1,
    String? selectedSeason1,
    String? selectedTeam1,
    String? selectedLeague2,
    String? selectedSeason2,
    String? selectedTeam2,
    bool league1ToNull = false,
    bool season1ToNull = false,
    bool team1ToNull = false,
    bool league2ToNull = false,
    bool season2ToNull = false,
    bool team2ToNull = false,
    TeamComparisonData? team1Data,
    TeamComparisonData? team2Data,
    AsyncValue<Map<String, dynamic>?>? comparisonResult,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
    List<Map<String, dynamic>>? h2hMatches,
    Map<String, int>? h2hStats,
    AsyncValue<String>? aiCommentary,
    AsyncValue<Map<String, dynamic>>? statisticalExpectations,
  }) {
    return AdvancedComparisonState(
      selectedLeague1:
          league1ToNull ? null : selectedLeague1 ?? this.selectedLeague1,
      selectedSeason1:
          season1ToNull ? null : selectedSeason1 ?? this.selectedSeason1,
      selectedTeam1: team1ToNull ? null : selectedTeam1 ?? this.selectedTeam1,
      selectedLeague2:
          league2ToNull ? null : selectedLeague2 ?? this.selectedLeague2,
      selectedSeason2:
          season2ToNull ? null : selectedSeason2 ?? this.selectedSeason2,
      selectedTeam2: team2ToNull ? null : selectedTeam2 ?? this.selectedTeam2,
      team1Data: team1Data ?? this.team1Data,
      team2Data: team2Data ?? this.team2Data,
      comparisonResult: comparisonResult ?? this.comparisonResult,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      h2hMatches: h2hMatches ?? this.h2hMatches,
      h2hStats: h2hStats ?? this.h2hStats,
      aiCommentary: aiCommentary ?? this.aiCommentary,
      statisticalExpectations:
          statisticalExpectations ?? this.statisticalExpectations,
    );
  }
}

class AdvancedComparisonController
    extends StateNotifier<AdvancedComparisonState> {
  AdvancedComparisonController(this._dataService)
      : super(const AdvancedComparisonState());

  final DataService _dataService;

  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=';
  static const String _apiKey = "AIzaSyDjJYKa2_W31jkdzBSNWWUXMYy1yqM-pP0";

  void _clearH2HData() {
    if (state.h2hMatches.isNotEmpty || state.h2hStats.isNotEmpty) {
      state = state.copyWith(h2hMatches: [], h2hStats: {});
    }
  }

  void selectLeague(int teamNumber, String league) {
    if (teamNumber == 1) {
      if (league != state.selectedLeague1) {
        state = state.copyWith(
            selectedLeague1: league,
            team1ToNull: true,
            team1Data: const TeamComparisonData());
      }
    } else {
      if (league != state.selectedLeague2) {
        state = state.copyWith(
            selectedLeague2: league,
            team2ToNull: true,
            team2Data: const TeamComparisonData());
      }
    }
    clearComparison();
  }

  void selectSeason(int teamNumber, String season) {
    if (teamNumber == 1) {
      if (season != state.selectedSeason1) {
        state = state.copyWith(
            selectedSeason1: season,
            team1ToNull: true,
            team1Data: const TeamComparisonData());
      }
    } else {
      if (season != state.selectedSeason2) {
        state = state.copyWith(
            selectedSeason2: season,
            team2ToNull: true,
            team2Data: const TeamComparisonData());
      }
    }
    clearComparison();
  }

  void selectTeam(int teamNumber, String teamName) {
    if (teamNumber == 1) {
      state = state.copyWith(selectedTeam1: teamName);
    } else {
      state = state.copyWith(selectedTeam2: teamName);
    }
    clearComparison();
  }

  void clearComparison() {
    state = state.copyWith(
        comparisonResult: const AsyncValue.data(null),
        aiCommentary: const AsyncValue.data(''),
        statisticalExpectations: const AsyncValue.data({}),
        clearError: true);
    _clearH2HData();
  }

  Future<void> fetchAvailableTeams(
      {required int teamNumber,
      required String league,
      required String season}) async {
    _updateTeamData(teamNumber,
        (data) => data.copyWith(isLoadingTeams: true, availableTeams: []));
    try {
      final leagueUrl = DataService.getLeagueUrl(league, season);
      if (leagueUrl == null) throw Exception("Lig URL'si bulunamadı.");

      final csvData = await _dataService.fetchData(leagueUrl);
      if (csvData == null) throw Exception("Lig verisi alınamadı.");

      final parsedData = _dataService.parseCsv(csvData);
      final headers = _dataService.getCsvHeaders(parsedData);
      final teams = _dataService.getAllOriginalTeamNames(parsedData, headers);

      _updateTeamData(teamNumber,
          (data) => data.copyWith(isLoadingTeams: false, availableTeams: teams));
    } catch (e) {
      _updateTeamData(
          teamNumber, (data) => data.copyWith(isLoadingTeams: false));
      state = state.copyWith(errorMessage: "Takım listesi alınamadı: $e");
    }
  }

  Future<void> performAdvancedComparison({required int matchCount}) async {
    if (state.selectedLeague1 == null ||
        state.selectedSeason1 == null ||
        state.selectedTeam1 == null ||
        state.selectedLeague2 == null ||
        state.selectedSeason2 == null ||
        state.selectedTeam2 == null) {
      state = state.copyWith(errorMessage: "Tüm seçimlerin yapıldığından emin olun.");
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      comparisonResult: const AsyncValue.data(null),
      aiCommentary: const AsyncValue.data(''),
    );
    _clearH2HData();

    try {
      final stats1Future = _fetchSingleTeamStats(
          league: state.selectedLeague1!,
          season: state.selectedSeason1!,
          teamName: state.selectedTeam1!,
          matchCount: matchCount);
      final stats2Future = _fetchSingleTeamStats(
          league: state.selectedLeague2!,
          season: state.selectedSeason2!,
          teamName: state.selectedTeam2!,
          matchCount: matchCount);

      final Set<String> uniqueUrls = {
        DataService.getLeagueUrl(state.selectedLeague1!, state.selectedSeason1!)!,
        DataService.getLeagueUrl(state.selectedLeague2!, state.selectedSeason2!)!,
      };

      final csvFutures =
          uniqueUrls.map((url) => _dataService.fetchData(url)).toList();
      final csvResults = await Future.wait(csvFutures);

      List<List<dynamic>> combinedCsvData = [];
      List<String> combinedHeaders = [];
      for (final csvString in csvResults) {
        if (csvString != null) {
          final parsed = _dataService.parseCsv(csvString);
          if (parsed.length > 1) {
            if (combinedHeaders.isEmpty) {
              combinedHeaders = _dataService.getCsvHeaders(parsed);
            }
            combinedCsvData.addAll(parsed.sublist(1));
          }
        }
      }
      if (combinedHeaders.isNotEmpty) {
        combinedCsvData.insert(0, combinedHeaders);
      }

      final h2hMatches = _dataService.getH2HMatches(
          combinedCsvData, combinedHeaders, state.selectedTeam1!, state.selectedTeam2!);
      final h2hStats = _calculateH2HStats(h2hMatches, state.selectedTeam1!);

      final results = await Future.wait([stats1Future, stats2Future]);
      final stats1 = results[0]..['leagueNameForLogo'] = state.selectedLeague1!;
      final stats2 = results[1]..['leagueNameForLogo'] = state.selectedLeague2!;

      state = state.copyWith(
        team1Data: state.team1Data.copyWith(stats: AsyncValue.data(stats1)),
        team2Data: state.team2Data.copyWith(stats: AsyncValue.data(stats2)),
        comparisonResult: AsyncValue.data(_calculateComparison(stats1, stats2)),
        h2hMatches: h2hMatches,
        h2hStats: h2hStats,
        isLoading: false,
      );

      // Aktivite ve istatistik güncelleme
      await ActivityLogger.logTeamComparison(
        state.selectedTeam1!,
        state.selectedTeam2!,
        '${state.selectedLeague1!} vs ${state.selectedLeague2!}',
      );
    } catch (e, st) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
        team1Data: state.team1Data.copyWith(stats: AsyncValue.error(e, st)),
        team2Data: state.team2Data.copyWith(stats: AsyncValue.error(e, st)),
        aiCommentary: const AsyncValue.data(''),
        statisticalExpectations: const AsyncValue.data({}),
      );
    }
  }

  Future<void> generateStatisticalExpectations() async {
    final team1StatsValue = state.team1Data.stats.value;
    final team2StatsValue = state.team2Data.stats.value;

    if (team1StatsValue == null || team2StatsValue == null) {
      state = state.copyWith(
          statisticalExpectations: AsyncValue.error(
              "Önce takımları karşılaştırın.", StackTrace.current));
      return;
    }

    state = state.copyWith(statisticalExpectations: const AsyncValue.loading());

    try {
      final comparisonData =
          _calculateComparison(team1StatsValue, team2StatsValue);

      // Simüle edilmiş bir gecikme
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(
          statisticalExpectations: AsyncValue.data(comparisonData));
    } catch (e, st) {
      state = state.copyWith(statisticalExpectations: AsyncValue.error(e, st));
    }
  }

  Future<void> generateAiAnalysis() async {
    final team1StatsValue = state.team1Data.stats.value;
    final team2StatsValue = state.team2Data.stats.value;

    if (team1StatsValue == null || team2StatsValue == null) {
      state = state.copyWith(
          aiCommentary: AsyncValue.error(
              "AI analizi için önce takımları karşılaştırın.",
              StackTrace.current));
      return;
    }

    state = state.copyWith(aiCommentary: const AsyncValue.loading());

    try {
      final String commentary = await _generateAiCommentary(
        stats1: team1StatsValue,
        stats2: team2StatsValue,
        h2hStats: state.h2hStats,
        league1: state.selectedLeague1!,
        league2: state.selectedLeague2!,
      );
      state = state.copyWith(aiCommentary: AsyncValue.data(commentary));
    } catch (e, st) {
      state = state.copyWith(aiCommentary: AsyncValue.error(e, st));
    }
  }

  Map<String, int> _calculateH2HStats(
      List<Map<String, dynamic>> h2hMatches, String team1OriginalName) {
    if (h2hMatches.isEmpty) return {};
    int team1Wins = 0;
    int team2Wins = 0;
    int draws = 0;
    final normalizedTeam1 = TeamNameService.normalize(team1OriginalName);

    for (var match in h2hMatches) {
      final result = match['FTR']?.toString();
      final homeTeam =
          TeamNameService.normalize(match['HomeTeam']?.toString() ?? '');

      if (result == 'H') {
        if (homeTeam == normalizedTeam1) {
          team1Wins++;
        } else {
          team2Wins++;
        }
      } else if (result == 'A') {
        if (homeTeam == normalizedTeam1) {
          team2Wins++;
        } else {
          team1Wins++;
        }
      } else if (result == 'D') {
        draws++;
      }
    }
    return {'team1Wins': team1Wins, 'team2Wins': team2Wins, 'draws': draws};
  }

  Future<Map<String, dynamic>> _fetchSingleTeamStats(
      {required String league,
      required String season,
      required String teamName,
      required int matchCount}) async {
    final leagueUrl = DataService.getLeagueUrl(league, season);
    if (leagueUrl == null) throw Exception("$league için URL oluşturulamadı.");
    final csvData = await _dataService.fetchData(leagueUrl);
    if (csvData == null) throw Exception("$league verisi çekilemedi.");
    final parsedData = _dataService.parseCsv(csvData);
    final headers = _dataService.getCsvHeaders(parsedData);
    final teamMatches =
        _dataService.filterMatchesByTeam(parsedData, headers, teamName);
    if (teamMatches.isEmpty) throw Exception("$teamName için maç bulunamadı.");
    final stats = _dataService.analyzeTeamStats(teamMatches, teamName,
        lastNMatches: matchCount);
    if (stats['oynananMacSayisi'] == 0) {
      throw Exception("$teamName için analiz edilecek maç yok.");
    }
    return stats;
  }

  Map<String, dynamic> _calculateComparison(
      Map<String, dynamic> stats1, Map<String, dynamic> stats2) {
    String team1Display = stats1['displayTeamName'] as String? ?? "Takım 1";
    String team2Display = stats2['displayTeamName'] as String? ?? "Takım 2";
    String winnerDisplayName;
    String? winnerOriginalName;

    double skor1 = ((stats1['attigi'] as num?)?.toDouble() ?? 0.0) +
        ((stats1['galibiyet'] as num?)?.toDouble() ?? 0.0) * 2 -
        ((stats1['maglubiyet'] as num?)?.toDouble() ?? 0.0);
    double skor2 = ((stats2['attigi'] as num?)?.toDouble() ?? 0.0) +
        ((stats2['galibiyet'] as num?)?.toDouble() ?? 0.0) * 2 -
        ((stats2['maglubiyet'] as num?)?.toDouble() ?? 0.0);

    if (skor1 > skor2) {
      winnerDisplayName = team1Display;
      winnerOriginalName = stats1['takim'] as String?;
    } else if (skor2 > skor1) {
      winnerDisplayName = team2Display;
      winnerOriginalName = stats2['takim'] as String?;
    } else {
      winnerDisplayName = "Berabere (Skor Analizi)";
      winnerOriginalName = null;
    }

    double form1 = (stats1['formPuani'] as num?)?.toDouble() ?? 0.0;
    double form2 = (stats2['formPuani'] as num?)?.toDouble() ?? 0.0;
    String formPrediction = "Formlar yakın, dengeli bir maç olabilir.";
    const double formDifferenceThreshold = 2.5;
    if (form1 > form2 + formDifferenceThreshold) {
      formPrediction = "$team1Display form olarak daha avantajlı görünüyor.";
    } else if (form2 > form1 + formDifferenceThreshold) {
      formPrediction = "$team2Display form olarak daha avantajlı görünüyor.";
    }

    double ortGol =
        (((stats1['maclardaOrtalamaToplamGol'] as num?)?.toDouble() ?? 0.0) +
                ((stats2['maclardaOrtalamaToplamGol'] as num?)?.toDouble() ??
                    0.0)) /
            2;
    double kgVarYuzde =
        (((stats1['kgVarYuzdesi'] as num?)?.toDouble() ?? 0.0) +
                ((stats2['kgVarYuzdesi'] as num?)?.toDouble() ?? 0.0)) /
            2;
    double iyToplamGol =
        (((stats1['iyAttigiOrt'] as num?)?.toDouble() ?? 0.0) +
                ((stats1['iyYedigiOrt'] as num?)?.toDouble() ?? 0.0) +
                ((stats2['iyAttigiOrt'] as num?)?.toDouble() ?? 0.0) +
                ((stats2['iyYedigiOrt'] as num?)?.toDouble() ?? 0.0)) /
            2;
    double beklenenToplamKorner =
        ((stats1['ortalamaKorner'] as num?)?.toDouble() ?? 0.0) +
            ((stats2['ortalamaKorner'] as num?)?.toDouble() ?? 0.0);
    double beklenenToplamSut =
        ((stats1['ortalamaSut'] as num?)?.toDouble() ?? 0.0) +
            ((stats2['ortalamaSut'] as num?)?.toDouble() ?? 0.0);
    double beklenenToplamIsabetliSut =
        ((stats1['ortalamaIsabetliSut'] as num?)?.toDouble() ?? 0.0) +
            ((stats2['ortalamaIsabetliSut'] as num?)?.toDouble() ?? 0.0);
    double beklenenToplamFaul =
        ((stats1['ortalamaFaul'] as num?)?.toDouble() ?? 0.0) +
            ((stats2['ortalamaFaul'] as num?)?.toDouble() ?? 0.0);
    double beklenenToplamSariKart =
        ((stats1['ortalamaSariKart'] as num?)?.toDouble() ?? 0.0) +
            ((stats2['ortalamaSariKart'] as num?)?.toDouble() ?? 0.0);
    double beklenenToplamKirmiziKart =
        ((stats1['ortalamaKirmiziKart'] as num?)?.toDouble() ?? 0.0) +
            ((stats2['ortalamaKirmiziKart'] as num?)?.toDouble() ?? 0.0);
    double gol2PlusOlasilik =
        (((stats1['gol2UstuOlasilik'] as num?)?.toDouble() ?? 0.0) +
                ((stats2['gol2UstuOlasilik'] as num?)?.toDouble() ?? 0.0)) /
            2;

    return {
      "kazanan": winnerDisplayName,
      "kazananOriginalName": winnerOriginalName,
      "formYorumu": formPrediction,
      "beklenenToplamGol":
          ortGol > 0 ? double.parse(ortGol.toStringAsFixed(1)) : null,
      "gol2PlusOlasilik": gol2PlusOlasilik > 0
          ? double.parse(gol2PlusOlasilik.toStringAsFixed(1))
          : null,
      "kgVarYuzdesi": kgVarYuzde > 0
          ? double.parse(kgVarYuzde.toStringAsFixed(1))
          : null,
      "beklenenIyToplamGol": iyToplamGol > 0
          ? double.parse(iyToplamGol.toStringAsFixed(1))
          : null,
      // Sayısal değerler - orijinal double değerleri saklıyoruz
      "beklenenToplamKorner": beklenenToplamKorner > 0
          ? double.parse(beklenenToplamKorner.toStringAsFixed(1))
          : null,
      "beklenenToplamSut": beklenenToplamSut > 0
          ? double.parse(beklenenToplamSut.toStringAsFixed(1))
          : null,
      "beklenenToplamIsabetliSut": beklenenToplamIsabetliSut > 0
          ? double.parse(beklenenToplamIsabetliSut.toStringAsFixed(1))
          : null,
      "beklenenToplamFaul": beklenenToplamFaul > 0
          ? double.parse(beklenenToplamFaul.toStringAsFixed(1))
          : null,
      "beklenenToplamSariKart": beklenenToplamSariKart > 0
          ? double.parse(beklenenToplamSariKart.toStringAsFixed(1))
          : null,
      "beklenenToplamKirmiziKart": beklenenToplamKirmiziKart > 0
          ? double.parse(beklenenToplamKirmiziKart.toStringAsFixed(1))
          : null,
    };
  }

  void _updateTeamData(
      int teamNumber, TeamComparisonData Function(TeamComparisonData) update) {
    if (teamNumber == 1) {
      state = state.copyWith(team1Data: update(state.team1Data));
    } else {
      state = state.copyWith(team2Data: update(state.team2Data));
    }
  }

  Future<String> _generateAiCommentary({
    required Map<String, dynamic> stats1,
    required Map<String, dynamic> stats2,
    required Map<String, int> h2hStats,
    required String league1,
    required String league2,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
          "API Anahtarı Eksik. Lütfen controller dosyasında _apiKey değişkenini ayarlayın.");
    }

    // Yeniden deneme mekanizması
    int maxRetries = 3;
    int retryDelay = 2; // saniye
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await _makeAiApiRequest(stats1, stats2, h2hStats, league1, league2);
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow; // Son denemede hatayı fırlat
        }
        
        // 503 (overloaded) veya 429 (rate limit) hatalarında yeniden dene
        if (e.toString().contains('503') || e.toString().contains('429') || 
            e.toString().contains('overloaded') || e.toString().contains('aşırı yüklenmiş')) {
          debugPrint("AI Analizi - Deneme $attempt/$maxRetries başarısız. $retryDelay saniye sonra tekrar denenecek...");
          await Future.delayed(Duration(seconds: retryDelay));
          retryDelay *= 2; // Exponential backoff
        } else {
          rethrow; // Diğer hatalar için hemen fırlat
        }
      }
    }
    
    throw Exception('Maksimum deneme sayısına ulaşıldı');
  }

  Future<String> _makeAiApiRequest(
    Map<String, dynamic> stats1,
    Map<String, dynamic> stats2,
    Map<String, int> h2hStats,
    String league1,
    String league2,
  ) async {

    final String team1Name = stats1['displayTeamName'] ?? 'Takım 1';
    final String team2Name = stats2['displayTeamName'] ?? 'Takım 2';
    
    final int team1H2HWins = h2hStats['team1Wins'] ?? 0;
    final int team2H2HWins = h2hStats['team2Wins'] ?? 0;
    final int h2hDraws = h2hStats['draws'] ?? 0;
    final int totalH2HMatches = team1H2HWins + team2H2HWins + h2hDraws;

    final Map<String, dynamic> league1Data = _leagueQualityMap[league1] ?? {
      "name": "Bilinmiyor", "coefficient": 50.0, "tempo": "Orta", "physicality": "Orta", "technical": "Orta"
    };
    final Map<String, dynamic> league2Data = _leagueQualityMap[league2] ?? {
      "name": "Bilinmiyor", "coefficient": 50.0, "tempo": "Orta", "physicality": "Orta", "technical": "Orta"
    };
    final String league1Quality = league1Data["name"];
    final String league2Quality = league2Data["name"];
    
    final String avgGoalsAgainst1 = (stats1['oynananMacSayisi'] > 0 ? (stats1['yedigi'] as num) / stats1['oynananMacSayisi'] : 0).toStringAsFixed(2);
    final String avgGoalsAgainst2 = (stats2['oynananMacSayisi'] > 0 ? (stats2['yedigi'] as num) / stats2['oynananMacSayisi'] : 0).toStringAsFixed(2);

    // Gelişmiş istatistiksel hesaplamalar
    final double team1WinRate = stats1['oynananMacSayisi'] > 0 ? (stats1['galibiyet'] as num) / stats1['oynananMacSayisi'] * 100 : 0;
    final double team2WinRate = stats2['oynananMacSayisi'] > 0 ? (stats2['galibiyet'] as num) / stats2['oynananMacSayisi'] * 100 : 0;
    final double team1Form = (stats1['formPuani'] as num?)?.toDouble() ?? 0;
    final double team2Form = (stats2['formPuani'] as num?)?.toDouble() ?? 0;
    final double team1AttackStrength = (stats1['macBasiOrtalamaGol'] as num?)?.toDouble() ?? 0;
    final double team2AttackStrength = (stats2['macBasiOrtalamaGol'] as num?)?.toDouble() ?? 0;
    final double team1DefenseStrength = 3.0 - double.parse(avgGoalsAgainst1); // 3'ten çıkararak savunma gücü
    final double team2DefenseStrength = 3.0 - double.parse(avgGoalsAgainst2);
    final double team1CleanSheetRate = (stats1['cleanSheetYuzdesi'] as num?)?.toDouble() ?? 0;
    final double team2CleanSheetRate = (stats2['cleanSheetYuzdesi'] as num?)?.toDouble() ?? 0;
    
    // H2H avantajı hesaplama
    String h2hAdvantage = "Dengeli";
    if (totalH2HMatches >= 3) {
      if (team1H2HWins > team2H2HWins + 1) {
        h2hAdvantage = "$team1Name avantajlı";
      } else if (team2H2HWins > team1H2HWins + 1) {
        h2hAdvantage = "$team2Name avantajlı";
      }
    }

    // Gelişmiş AI prompt'u - Gerçek maç analizi yaklaşımı
    String prompt = """
    Sen deneyimli bir futbol analisti ve bahis uzmanısın. Sağlanan detaylı istatistiklere dayanarak $team1Name vs $team2Name maçı için profesyonel bir analiz yap. Gerçek maç sonuçlarını etkileyen faktörleri göz önünde bulundur.

    ## DETAYLI VERİ ANALİZİ:

    **$team1Name Profili:**
    - Lig: $league1 (Kalite: $league1Quality, Katsayı: ${league1Data["coefficient"]})
    - Lig Karakteristiği: Tempo ${league1Data["tempo"]}, Fiziksellik ${league1Data["physicality"]}, Teknik ${league1Data["technical"]}
    - Son ${stats1['oynananMacSayisi'] ?? 'N/A'} Maç: ${stats1['galibiyet'] ?? 0}G-${stats1['beraberlik'] ?? 0}B-${stats1['maglubiyet'] ?? 0}M
    - Kazanma Oranı: ${team1WinRate.toStringAsFixed(1)}%
    - Form Puanı: ${team1Form.toStringAsFixed(1)}/15
    - Hücum Gücü: ${team1AttackStrength.toStringAsFixed(2)} gol/maç
    - Savunma Gücü: ${team1DefenseStrength.toStringAsFixed(2)} (3.0 üzerinden)
    - Clean Sheet: ${team1CleanSheetRate.toStringAsFixed(1)}%
    - Ortalama Şut: ${stats1['ortalamaSut'] ?? 'N/A'}/maç
    - İsabetli Şut: ${stats1['ortalamaIsabetliSut'] ?? 'N/A'}/maç
    - Ortalama Korner: ${stats1['ortalamaKorner'] ?? 'N/A'}/maç
    - KG Var Oranı: ${stats1['kgVarYuzdesi'] ?? 'N/A'}%

    **$team2Name Profili:**
    - Lig: $league2 (Kalite: $league2Quality, Katsayı: ${league2Data["coefficient"]})
    - Lig Karakteristiği: Tempo ${league2Data["tempo"]}, Fiziksellik ${league2Data["physicality"]}, Teknik ${league2Data["technical"]}
    - Son ${stats2['oynananMacSayisi'] ?? 'N/A'} Maç: ${stats2['galibiyet'] ?? 0}G-${stats2['beraberlik'] ?? 0}B-${stats2['maglubiyet'] ?? 0}M
    - Kazanma Oranı: ${team2WinRate.toStringAsFixed(1)}%
    - Form Puanı: ${team2Form.toStringAsFixed(1)}/15
    - Hücum Gücü: ${team2AttackStrength.toStringAsFixed(2)} gol/maç
    - Savunma Gücü: ${team2DefenseStrength.toStringAsFixed(2)} (3.0 üzerinden)
    - Clean Sheet: ${team2CleanSheetRate.toStringAsFixed(1)}%
    - Ortalama Şut: ${stats2['ortalamaSut'] ?? 'N/A'}/maç
    - İsabetli Şut: ${stats2['ortalamaIsabetliSut'] ?? 'N/A'}/maç
    - Ortalama Korner: ${stats2['ortalamaKorner'] ?? 'N/A'}/maç
    - KG Var Oranı: ${stats2['kgVarYuzdesi'] ?? 'N/A'}%

    **Kafa Kafaya (H2H):** $totalH2HMatches maç - $h2hAdvantage ($team1Name: $team1H2HWins, $team2Name: $team2H2HWins, Beraberlik: $h2hDraws)

    ## ANALİZ ÇIKTI FORMATI:

    ### Maç Tahmini
    - **Sonuç Beklentisi:** [En olası sonuç: "$team1Name Galibiyeti", "$team2Name Galibiyeti", veya "Beraberlik"]
    - **Güven Oranı:** [Tahminin güvenilirliği: "Yüksek (%75+)", "Orta (%50-75)", "Düşük (%25-50)"]
    - **Skor Tahmini:** [Muhtemel skor aralığı, örn: "2-1 veya 1-0"]

    ### Taktiksel Analiz
    - **Hücum vs Savunma:** [Hangi takımın hücumu, diğerinin savunmasına karşı daha etkili olacak]
    - **Oyun Temposu:** [Maçın genel temposunu etkileyen faktörler]
    - **Set Piece Avantajı:** [Korner, frikik gibi duran toplarda hangi takım avantajlı]

    ### Kritik Faktörler
    - **Maç Belirleyici:** [Sonucu en çok etkileyecek tek faktör]
    - **Form Durumu:** [Hangi takım daha iyi formda ve neden]
    - **Lig Farkı Etkisi:** [Farklı liglerden geliyorlarsa bu nasıl etki eder]

    ### Bahis Önerileri
    - **Ana Bahis:** [En güvenilir bahis seçeneği]
    - **Gol Beklentisi:** [2.5 Üst/Alt, KG Var/Yok tahmini]
    - **Alternatif Bahisler:** [Korner, kart sayısı gibi yan bahisler]

    ### Öne Çıkan Tahmin
    - [Tüm analizi özetleyen, en güvendiğin net tahmin. Örnek: "**$team1Name'ın üstün hücum gücü ve $team2Name'ın savunma zafiyeti göz önüne alındığında, 2-1 veya 3-1 gibi bir $team1Name galibiyeti bekleniyor.**"]

    ÖNEMLI: Gerçekçi ol, abartma. İstatistikleri objektif değerlendir ve profesyonel bir analist gibi yaz.""";
    
    try {
      final response = await http.post(
        Uri.parse('$_geminiApiUrl$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
          ]
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint("API Response Status: ${response.statusCode}");
      debugPrint("API Response Body: ${response.body}");
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        
        // API yanıtında hata var mı kontrol et
        if (body['error'] != null) {
          final errorMessage = body['error']['message'] ?? 'Bilinmeyen API hatası';
          throw Exception('API Hatası: $errorMessage');
        }
        
        if (body['candidates'] != null &&
            (body['candidates'] as List).isNotEmpty &&
            body['candidates'][0]['content'] != null &&
            body['candidates'][0]['content']['parts'] != null &&
            (body['candidates'][0]['content']['parts'] as List).isNotEmpty) {
          
          return body['candidates'][0]['content']['parts'][0]['text'] as String;

        } else {
          final errorReason =
              body['promptFeedback']?['blockReason'] ?? 'Bilinmeyen bir sebep';
          throw Exception("Yapay zeka bir yanıt üretemedi. Sebep: $errorReason. Yanıt: ${response.body}");
        }
      } else if (response.statusCode == 400) {
        final body = json.decode(response.body);
        final errorMessage = body['error']?['message'] ?? 'Geçersiz istek';
        throw Exception('API İsteği Hatası (400): $errorMessage');
      } else if (response.statusCode == 403) {
        throw Exception('API Anahtarı geçersiz veya yetkisiz erişim (403)');
      } else if (response.statusCode == 429) {
        throw Exception('API kullanım limiti aşıldı. Lütfen daha sonra tekrar deneyin (429)');
      } else if (response.statusCode == 503) {
        throw Exception('Yapay zeka servisi şu anda aşırı yüklenmiş durumda. Lütfen birkaç dakika sonra tekrar deneyin.');
      } else {
        throw Exception('API isteği başarısız oldu (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint("AI Analiz Hatası: $e");
      if (e.toString().contains('SocketException')) {
        throw Exception('İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edin.');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
      } else if (e.toString().contains('API isteği başarısız')) {
        throw Exception('API servisi şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.');
      } else {
        throw Exception('Yapay zeka analizi alınırken hata oluştu: ${e.toString()}');
      }
    }
  }
}

final advancedComparisonControllerProvider = StateNotifierProvider<
    AdvancedComparisonController, AdvancedComparisonState>(
  (ref) {
    return AdvancedComparisonController(ref.watch(dataServiceProvider));
  },
);
