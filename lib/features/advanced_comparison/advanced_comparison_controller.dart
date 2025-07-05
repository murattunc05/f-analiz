// lib/features/advanced_comparison/advanced_comparison_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data_service.dart';
import '../../services/team_name_service.dart';

// Liglerin genel kalitesini ve rekabet seviyesini belirten basit bir harita.
const Map<String, String> _leagueQualityMap = {
  "İngiltere - Premier Lig": "Top Seviye",
  "İspanya - La Liga": "Top Seviye",
  "Almanya - Bundesliga": "Top Seviye",
  "İtalya - Serie A": "Top Seviye",
  "Fransa - Ligue 1": "Yüksek Seviye",
  "Hollanda - Eredivisie": "Yüksek Seviye",
  "Portekiz - Premier Lig": "Yüksek Seviye",
  "Türkiye - Süper Lig": "Rekabetçi Orta Düzey",
  "Belçika - Pro Lig": "Rekabetçi Orta Düzey",
  "İngiltere - Championship": "Rekabetçi Üst Düzey",
  "Almanya - Bundesliga 2": "Rekabetçi Üst Düzey",
  "İtalya - Serie B": "Rekabetçi Üst Düzey",
  "İskoçya - Premiership": "Orta Düzey",
  "Yunanistan - Süper Lig": "Orta Düzey",
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
  static const String _apiKey = "AIzaSyBKRuCBnHwZW6Qd4bFnz7ClmrCokb0LKFk";

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
          ? double.parse(beklenenToplamKirmiziKart.toStringAsFixed(2))
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

    final String team1Name = stats1['displayTeamName'] ?? 'Takım 1';
    final String team2Name = stats2['displayTeamName'] ?? 'Takım 2';
    
    final int team1H2HWins = h2hStats['team1Wins'] ?? 0;
    final int team2H2HWins = h2hStats['team2Wins'] ?? 0;
    final int h2hDraws = h2hStats['draws'] ?? 0;
    final int totalH2HMatches = team1H2HWins + team2H2HWins + h2hDraws;

    final String league1Quality = _leagueQualityMap[league1] ?? "Bilinmiyor";
    final String league2Quality = _leagueQualityMap[league2] ?? "Bilinmiyor";
    
    final String avgGoalsAgainst1 = (stats1['oynananMacSayisi'] > 0 ? (stats1['yedigi'] as num) / stats1['oynananMacSayisi'] : 0).toStringAsFixed(2);
    final String avgGoalsAgainst2 = (stats2['oynananMacSayisi'] > 0 ? (stats2['yedigi'] as num) / stats2['oynananMacSayisi'] : 0).toStringAsFixed(2);

    // YENİ: Daha yapısal ve kullanıcı dostu bir yorum isteyen prompt.
    String prompt = """
    Bir uzman futbol analisti ve veri bilimcisi olarak, sağlanan istatistiklere dayanarak $team1Name ve $team2Name arasındaki maç için detaylı, profesyonel ve modern bir Markdown formatında analiz oluştur. Analiz, aşağıdaki bölümleri içermelidir ve dil akıcı, net ve maddeler halinde olmalıdır.

    Veriler:
    - Takım 1: **$team1Name** (Lig: $league1, Lig Kalitesi: **$league1Quality**)
      - Son Maçlar: ${stats1['oynananMacSayisi'] ?? 'N/A'}, G/B/M: ${stats1['galibiyet'] ?? 0}/${stats1['beraberlik'] ?? 0}/${stats1['maglubiyet'] ?? 0}, Gol Ort: ${stats1['macBasiOrtalamaGol'] ?? 'N/A'}, Yediği Gol Ort: $avgGoalsAgainst1
    - Takım 2: **$team2Name** (Lig: $league2, Lig Kalitesi: **$league2Quality**)
      - Son Maçlar: ${stats2['oynananMacSayisi'] ?? 'N/A'}, G/B/M: ${stats2['galibiyet'] ?? 0}/${stats2['beraberlik'] ?? 0}/${stats2['maglubiyet'] ?? 0}, Gol Ort: ${stats2['macBasiOrtalamaGol'] ?? 'N/A'}, Yediği Gol Ort: $avgGoalsAgainst2
    - Aralarındaki Maçlar (H2H): Toplam $totalH2HMatches maç, $team1Name Galibiyeti: $team1H2HWins, $team2Name Galibiyeti: $team2H2HWins, Beraberlik: $h2hDraws

    İstenen Çıktı Formatı (Markdown):
    ### Temel Beklentiler
    - **Maç Sonucu:** (Net tahminin: "$team1Name Kazanır", "$team2Name Kazanır" veya "Beraberlik")
    - **Güven Seviyesi:** (Tahminine olan güvenin: "Düşük", "Orta", "Yüksek")

    ### İstatistiksel Beklentiler
    - **Toplam Gol:** (Net beklentin: "2.5 Gol Altı", "2.5 Gol Üstü", veya "2-3 Gol Arası" gibi)
    - **Karşılıklı Gol (KG):** (Net beklentin: "KG Var" veya "KG Yok")

    ### Detaylı Yorum
    - **Oyun Stilleri:** (Takımların genel oyun stillerini (örn: baskılı, kontra atak, topa sahip olma) 1-2 cümleyle karşılaştır.)
    - **Kilit Faktör:** (Maçın sonucunu en çok etkilemesi beklenen faktör nedir? (örn: $team1Name'ın hücum gücü, $team2Name'in savunma direnci, orta saha mücadelesi vb.))
    - **Lig Kalitesi Etkisi:** (EĞER LİGLER FARKLIYSA, bu faktörün maça nasıl etki edeceğini 1-2 cümleyle belirt. Örneğin, '$league1Quality' liginin temposu ile '$league2Quality' liginin fiziksel mücadelesi arasındaki fark.)

    ### Öne Çıkan Tahmin
    - (Tüm analizi özetleyen, en güvendiğin tek ve net bir tahmin. Örneğin: "**Maçın 9.5 Korner Üstü bitmesi bekleniyor.**" veya "**$team1Name galibiyetine daha yakın görünüyor.**")
    """;
    
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
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['candidates'] != null &&
            (body['candidates'] as List).isNotEmpty &&
            body['candidates'][0]['content'] != null &&
            body['candidates'][0]['content']['parts'] != null &&
            (body['candidates'][0]['content']['parts'] as List).isNotEmpty) {
          
          return body['candidates'][0]['content']['parts'][0]['text'] as String;

        } else {
          final errorReason =
              body['promptFeedback']?['blockReason'] ?? 'Bilinmeyen bir sebep';
          throw Exception("Yapay zeka bir yanıt üretemedi. Sebep: $errorReason.");
        }
      } else {
        throw Exception('API isteği başarısız oldu: ${response.body}');
      }
    } catch (e) {
      debugPrint("AI Analiz Hatası: $e");
      throw Exception('Yapay zeka analizi alınırken hata oluştu.');
    }
  }
}

final advancedComparisonControllerProvider = StateNotifierProvider<
    AdvancedComparisonController, AdvancedComparisonState>(
  (ref) {
    return AdvancedComparisonController(ref.watch(dataServiceProvider));
  },
);
