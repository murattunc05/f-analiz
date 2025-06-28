// lib/features/advanced_comparison/advanced_comparison_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futbol_analiz_app/features/single_team_analysis/single_team_controller.dart';
import 'package:http/http.dart' as http;
import '../../data_service.dart';
import '../../services/team_name_service.dart';

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

  const AdvancedComparisonState({
    this.selectedLeague1, this.selectedSeason1, this.selectedTeam1,
    this.selectedLeague2, this.selectedSeason2, this.selectedTeam2,
    this.team1Data = const TeamComparisonData(),
    this.team2Data = const TeamComparisonData(),
    this.comparisonResult = const AsyncValue.data(null),
    this.errorMessage,
    this.isLoading = false,
    this.h2hMatches = const [],
    this.h2hStats = const {},
    this.aiCommentary = const AsyncValue.data(''),
  });

  AdvancedComparisonState copyWith({
    String? selectedLeague1, String? selectedSeason1, String? selectedTeam1,
    String? selectedLeague2, String? selectedSeason2, String? selectedTeam2,
    bool league1ToNull = false, bool season1ToNull = false, bool team1ToNull = false,
    bool league2ToNull = false, bool season2ToNull = false, bool team2ToNull = false,
    TeamComparisonData? team1Data,
    TeamComparisonData? team2Data,
    AsyncValue<Map<String, dynamic>?>? comparisonResult,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
    List<Map<String, dynamic>>? h2hMatches,
    Map<String, int>? h2hStats,
    AsyncValue<String>? aiCommentary,
  }) {
    return AdvancedComparisonState(
      selectedLeague1: league1ToNull ? null : selectedLeague1 ?? this.selectedLeague1,
      selectedSeason1: season1ToNull ? null : selectedSeason1 ?? this.selectedSeason1,
      selectedTeam1: team1ToNull ? null : selectedTeam1 ?? this.selectedTeam1,
      selectedLeague2: league2ToNull ? null : selectedLeague2 ?? this.selectedLeague2,
      selectedSeason2: season2ToNull ? null : selectedSeason2 ?? this.selectedSeason2,
      selectedTeam2: team2ToNull ? null : selectedTeam2 ?? this.selectedTeam2,
      team1Data: team1Data ?? this.team1Data,
      team2Data: team2Data ?? this.team2Data,
      comparisonResult: comparisonResult ?? this.comparisonResult,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      h2hMatches: h2hMatches ?? this.h2hMatches,
      h2hStats: h2hStats ?? this.h2hStats,
      aiCommentary: aiCommentary ?? this.aiCommentary,
    );
  }
}

class AdvancedComparisonController extends StateNotifier<AdvancedComparisonState> {
  AdvancedComparisonController(this._dataService) : super(const AdvancedComparisonState());

  final DataService _dataService;
  
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=';
  // DEĞİŞİKLİK: Kullanıcı tarafından sağlanan API anahtarı eklendi.
  static const String _apiKey = "AIzaSyBKRuCBnHwZW6Qd4bFnz7ClmrCokb0LKFk"; 

  void _clearH2HData() {
    if (state.h2hMatches.isNotEmpty || state.h2hStats.isNotEmpty) {
      state = state.copyWith(h2hMatches: [], h2hStats: {});
    }
  }

  void selectLeague(int teamNumber, String league) {
    if (teamNumber == 1) {
      if (league != state.selectedLeague1) { state = state.copyWith(selectedLeague1: league, team1ToNull: true, team1Data: const TeamComparisonData()); }
    } else {
      if (league != state.selectedLeague2) { state = state.copyWith(selectedLeague2: league, team2ToNull: true, team2Data: const TeamComparisonData()); }
    }
    clearComparison();
  }
  
  void selectSeason(int teamNumber, String season) {
    if (teamNumber == 1) {
       if (season != state.selectedSeason1) { state = state.copyWith(selectedSeason1: season, team1ToNull: true, team1Data: const TeamComparisonData()); }
    } else {
       if (season != state.selectedSeason2) { state = state.copyWith(selectedSeason2: season, team2ToNull: true, team2Data: const TeamComparisonData()); }
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
      clearError: true
    );
    _clearH2HData();
  }
  
  Future<void> fetchAvailableTeams({required int teamNumber, required String league, required String season}) async {
    _updateTeamData(teamNumber, (data) => data.copyWith(isLoadingTeams: true, availableTeams: []));
    try {
      final leagueUrl = DataService.getLeagueUrl(league, season);
      if (leagueUrl == null) throw Exception("Lig URL'si bulunamadı.");

      final csvData = await _dataService.fetchData(leagueUrl);
      if (csvData == null) throw Exception("Lig verisi alınamadı.");

      final parsedData = _dataService.parseCsv(csvData);
      final headers = _dataService.getCsvHeaders(parsedData);
      final teams = _dataService.getAllOriginalTeamNames(parsedData, headers);

      _updateTeamData(teamNumber, (data) => data.copyWith(isLoadingTeams: false, availableTeams: teams));
    } catch (e) {
      _updateTeamData(teamNumber, (data) => data.copyWith(isLoadingTeams: false));
      state = state.copyWith(errorMessage: "Takım listesi alınamadı: $e");
    }
  }

  Future<void> performAdvancedComparison({required int matchCount}) async {
    if (state.selectedLeague1 == null || state.selectedSeason1 == null || state.selectedTeam1 == null ||
        state.selectedLeague2 == null || state.selectedSeason2 == null || state.selectedTeam2 == null) {
      state = state.copyWith(errorMessage: "Tüm seçimlerin yapıldığından emin olun.");
      return;
    }
    
    state = state.copyWith(
      isLoading: true, 
      clearError: true, 
      comparisonResult: const AsyncValue.data(null),
      aiCommentary: const AsyncValue.loading()
    );
    _clearH2HData();

    try {
      final stats1Future = _fetchSingleTeamStats(league: state.selectedLeague1!, season: state.selectedSeason1!, teamName: state.selectedTeam1!, matchCount: matchCount);
      final stats2Future = _fetchSingleTeamStats(league: state.selectedLeague2!, season: state.selectedSeason2!, teamName: state.selectedTeam2!, matchCount: matchCount);
      
      final Set<String> uniqueUrls = {
        DataService.getLeagueUrl(state.selectedLeague1!, state.selectedSeason1!)!,
        DataService.getLeagueUrl(state.selectedLeague2!, state.selectedSeason2!)!,
      };

      final csvFutures = uniqueUrls.map((url) => _dataService.fetchData(url)).toList();
      final csvResults = await Future.wait(csvFutures);
      
      List<List<dynamic>> combinedCsvData = [];
      List<String> combinedHeaders = [];
      for (final csvString in csvResults) {
        if (csvString != null) {
          final parsed = _dataService.parseCsv(csvString);
          if (parsed.length > 1) {
            if (combinedHeaders.isEmpty) { combinedHeaders = _dataService.getCsvHeaders(parsed); }
            combinedCsvData.addAll(parsed.sublist(1));
          }
        }
      }
      if (combinedHeaders.isNotEmpty) { combinedCsvData.insert(0, combinedHeaders); }

      final h2hMatches = _dataService.getH2HMatches(combinedCsvData, combinedHeaders, state.selectedTeam1!, state.selectedTeam2!);
      final h2hStats = _calculateH2HStats(h2hMatches, state.selectedTeam1!);
      
      final results = await Future.wait([stats1Future, stats2Future]);
      final stats1 = results[0]..['leagueNameForLogo'] = state.selectedLeague1!;
      final stats2 = results[1]..['leagueNameForLogo'] = state.selectedLeague2!;
      
      final aiCommentaryFuture = _generateAiCommentary(stats1, stats2, h2hStats);

      final aiResult = await aiCommentaryFuture;

      state = state.copyWith(
        team1Data: state.team1Data.copyWith(stats: AsyncValue.data(stats1)),
        team2Data: state.team2Data.copyWith(stats: AsyncValue.data(stats2)),
        comparisonResult: AsyncValue.data(_calculateComparison(stats1, stats2)),
        h2hMatches: h2hMatches,
        h2hStats: h2hStats,
        aiCommentary: AsyncValue.data(aiResult),
        isLoading: false
      );
    } catch (e, st) {
      state = state.copyWith(
        errorMessage: e.toString(), 
        isLoading: false, 
        team1Data: state.team1Data.copyWith(stats: AsyncValue.error(e, st)), 
        team2Data: state.team2Data.copyWith(stats: AsyncValue.error(e,st)),
        aiCommentary: AsyncValue.error(e, st)
      );
    }
  }

  Map<String, int> _calculateH2HStats(List<Map<String, dynamic>> h2hMatches, String team1OriginalName) {
    if (h2hMatches.isEmpty) return {};
    int team1Wins = 0;
    int team2Wins = 0;
    int draws = 0;
    final normalizedTeam1 = TeamNameService.normalize(team1OriginalName);

    for (var match in h2hMatches) {
      final result = match['FTR']?.toString();
      final homeTeam = TeamNameService.normalize(match['HomeTeam']?.toString() ?? '');
      
      if (result == 'H') {
        if (homeTeam == normalizedTeam1) { team1Wins++; } 
        else { team2Wins++; }
      } else if (result == 'A') {
        if (homeTeam == normalizedTeam1) { team2Wins++; } 
        else { team1Wins++; }
      } else if (result == 'D') {
        draws++;
      }
    }
    return {'team1Wins': team1Wins, 'team2Wins': team2Wins, 'draws': draws};
  }

  Future<Map<String, dynamic>> _fetchSingleTeamStats({required String league, required String season, required String teamName, required int matchCount}) async {
    final leagueUrl = DataService.getLeagueUrl(league, season);
    if (leagueUrl == null) throw Exception("$league için URL oluşturulamadı.");
    final csvData = await _dataService.fetchData(leagueUrl);
    if (csvData == null) throw Exception("$league verisi çekilemedi.");
    final parsedData = _dataService.parseCsv(csvData);
    final headers = _dataService.getCsvHeaders(parsedData);
    final teamMatches = _dataService.filterMatchesByTeam(parsedData, headers, teamName);
    if (teamMatches.isEmpty) throw Exception("$teamName için maç bulunamadı.");
    final stats = _dataService.analyzeTeamStats(teamMatches, teamName, lastNMatches: matchCount);
    if (stats['oynananMacSayisi'] == 0) throw Exception("$teamName için analiz edilecek maç yok.");
    return stats;
  }
  
  Map<String, dynamic> _calculateComparison(Map<String, dynamic> stats1, Map<String, dynamic> stats2) {
    String team1Display = stats1['displayTeamName'] as String? ?? "Takım 1";
    String team2Display = stats2['displayTeamName'] as String? ?? "Takım 2";
    String winnerDisplayName;
    String? winnerOriginalName;
    
    double skor1 = ((stats1['attigi'] as num?)?.toDouble() ?? 0.0) + ((stats1['galibiyet'] as num?)?.toDouble() ?? 0.0) * 2 - ((stats1['maglubiyet'] as num?)?.toDouble() ?? 0.0);
    double skor2 = ((stats2['attigi'] as num?)?.toDouble() ?? 0.0) + ((stats2['galibiyet'] as num?)?.toDouble() ?? 0.0) * 2 - ((stats2['maglubiyet'] as num?)?.toDouble() ?? 0.0);
    
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

    double ortGol = (((stats1['maclardaOrtalamaToplamGol'] as num?)?.toDouble() ?? 0.0) + ((stats2['maclardaOrtalamaToplamGol'] as num?)?.toDouble() ?? 0.0)) / 2;
    double kgVarYuzde = (((stats1['kgVarYuzdesi'] as num?)?.toDouble() ?? 0.0) + ((stats2['kgVarYuzdesi'] as num?)?.toDouble() ?? 0.0)) / 2;
    double iyToplamGol = (((stats1['iyAttigiOrt'] as num?)?.toDouble() ?? 0.0) + ((stats1['iyYedigiOrt'] as num?)?.toDouble() ?? 0.0) + ((stats2['iyAttigiOrt'] as num?)?.toDouble() ?? 0.0) + ((stats2['iyYedigiOrt'] as num?)?.toDouble() ?? 0.0)) / 2;
    double beklenenToplamKorner = ((stats1['ortalamaKorner'] as num?)?.toDouble() ?? 0.0) + ((stats2['ortalamaKorner'] as num?)?.toDouble() ?? 0.0);
    double beklenenToplamSut = ((stats1['ortalamaSut'] as num?)?.toDouble() ?? 0.0) + ((stats2['ortalamaSut'] as num?)?.toDouble() ?? 0.0);
    double beklenenToplamIsabetliSut = ((stats1['ortalamaIsabetliSut'] as num?)?.toDouble() ?? 0.0) + ((stats2['ortalamaIsabetliSut'] as num?)?.toDouble() ?? 0.0);
    double beklenenToplamFaul = ((stats1['ortalamaFaul'] as num?)?.toDouble() ?? 0.0) + ((stats2['ortalamaFaul'] as num?)?.toDouble() ?? 0.0);
    double beklenenToplamSariKart = ((stats1['ortalamaSariKart'] as num?)?.toDouble() ?? 0.0) + ((stats2['ortalamaSariKart'] as num?)?.toDouble() ?? 0.0);
    double beklenenToplamKirmiziKart = ((stats1['ortalamaKirmiziKart'] as num?)?.toDouble() ?? 0.0) + ((stats2['ortalamaKirmiziKart'] as num?)?.toDouble() ?? 0.0);
    double gol2PlusOlasilik = (((stats1['gol2UstuOlasilik'] as num?)?.toDouble() ?? 0.0) + ((stats2['gol2UstuOlasilik'] as num?)?.toDouble() ?? 0.0)) / 2;

    return { 
      "kazanan": winnerDisplayName, 
      "kazananOriginalName": winnerOriginalName,
      "formYorumu": formPrediction,
      "beklenenToplamGol": ortGol > 0 ? double.parse(ortGol.toStringAsFixed(1)) : null,
      "gol2PlusOlasilik": gol2PlusOlasilik > 0 ? double.parse(gol2PlusOlasilik.toStringAsFixed(1)) : null,
      "kgVarYuzdesi": kgVarYuzde > 0 ? double.parse(kgVarYuzde.toStringAsFixed(1)) : null,
      "beklenenIyToplamGol": iyToplamGol > 0 ? double.parse(iyToplamGol.toStringAsFixed(1)) : null,
      "beklenenToplamKorner": beklenenToplamKorner > 0 ? double.parse(beklenenToplamKorner.toStringAsFixed(1)) : null,
      "beklenenToplamSut": beklenenToplamSut > 0 ? double.parse(beklenenToplamSut.toStringAsFixed(1)) : null,
      "beklenenToplamIsabetliSut": beklenenToplamIsabetliSut > 0 ? double.parse(beklenenToplamIsabetliSut.toStringAsFixed(1)) : null,
      "beklenenToplamFaul": beklenenToplamFaul > 0 ? double.parse(beklenenToplamFaul.toStringAsFixed(1)) : null,
      "beklenenToplamSariKart": beklenenToplamSariKart > 0 ? double.parse(beklenenToplamSariKart.toStringAsFixed(1)) : null,
      "beklenenToplamKirmiziKart": beklenenToplamKirmiziKart > 0 ? double.parse(beklenenToplamKirmiziKart.toStringAsFixed(2)) : null,
    };
  }
  
  void _updateTeamData(int teamNumber, TeamComparisonData Function(TeamComparisonData) update) {
    if (teamNumber == 1) {
      state = state.copyWith(team1Data: update(state.team1Data));
    } else {
      state = state.copyWith(team2Data: update(state.team2Data));
    }
  }

  Future<String> _generateAiCommentary(Map<String, dynamic> stats1, Map<String, dynamic> stats2, Map<String, int> h2hStats) async {
    if (_apiKey == "YOUR_API_KEY_HERE" || _apiKey.isEmpty) {
      return "## API Anahtarı Eksik\nLütfen AI analiz özelliğini kullanmak için bir API anahtarı sağlayın.";
    }

    final String team1Name = stats1['displayTeamName'] ?? 'Takım 1';
    final String team2Name = stats2['displayTeamName'] ?? 'Takım 2';
    final int matchCount1 = stats1['oynananMacSayisi'];
    final int matchCount2 = stats2['oynananMacSayisi'];

    final int team1H2HWins = h2hStats['team1Wins'] ?? 0;
    final int team2H2HWins = h2hStats['team2Wins'] ?? 0;
    final int h2hDraws = h2hStats['draws'] ?? 0;
    final int totalH2HMatches = team1H2HWins + team2H2HWins + h2hDraws;


    String prompt = """
    Sen profesyonel bir futbol analistisin. Birazdan sana vereceğim istatistiklere dayanarak, yaklaşan $team1Name - $team2Name maçı için detaylı ve tarafsız bir analiz yap. Yorumlarını Markdown formatında, başlıklar ve listeler kullanarak structure et. Cevabının sonunda, bunun sadece istatistiksel bir yorum olduğunu ve bir yatırım tavsiyesi olmadığını belirten kısa bir not ekle.

    Analizini şu başlıklar altında topla:
    1.  **Genel Form ve Momentum:** Takımların son maçlardaki galibiyet/mağlubiyet serilerini ve form puanlarını karşılaştır.
    2.  **Hücum Gücü:** Hangi takımın hücum hattı daha etkili? Attıkları goller, maç başına gol ortalamaları, şut ve isabetli şut sayılarını karşılaştırarak yorumla.
    3.  **Savunma Performansı:** Hangi takım savunmada daha sağlam? Yedikleri goller, maç başına yedikleri gol ortalamaları ve clean sheet (gol yememe) yüzdelerini değerlendir.
    4.  **Aralarındaki Maçlar (H2H):** Geçmiş maç verileri bir takım için psikolojik bir üstünlük sağlıyor mu?
    5.  **Oyun Tarzı İpuçları:** Korner, faul ve kart istatistikleri maçın gidişatı hakkında ne gibi ipuçları veriyor? (Örn: "A Takımının yüksek faul ortalaması, maçın sık sık durabileceğini ve duran top tehlikeleri yaratabileceğini gösteriyor.")
    6.  **Maç Özeti ve Tahmin:** Tüm bu verilere dayanarak, maçın genel gidişatı hakkında (örn: gollü, temposu düşük, taktiksel bir mücadele vb.) bir özet sun.

    İşte veriler:

    **$team1Name İstatistikleri (Son $matchCount1 Maç):**
    - Galibiyet/Beraberlik/Mağlubiyet: ${stats1['galibiyet']}/${stats1['beraberlik']}/${stats1['maglubiyet']}
    - Atılan Gol: ${stats1['attigi']} (Ort: ${stats1['macBasiOrtalamaGol']})
    - Yenilen Gol: ${stats1['yedigi']} (Ort: ${((stats1['yedigi'] as num)/matchCount1).toStringAsFixed(2)})
    - KG Var Yüzdesi: %${stats1['kgVarYuzdesi']}
    - Clean Sheet Yüzdesi: %${stats1['cleanSheetYuzdesi']}
    - Ortalama Şut/İsabetli Şut: ${stats1['ortalamaSut']}/${stats1['ortalamaIsabetliSut']}
    - Ortalama Korner: ${stats1['ortalamaKorner']}
    - Ortalama Faul/Sarı Kart: ${stats1['ortalamaFaul']}/${stats1['ortalamaSariKart']}
    
    **$team2Name İstatistikleri (Son $matchCount2 Maç):**
    - Galibiyet/Beraberlik/Mağlubiyet: ${stats2['galibiyet']}/${stats2['beraberlik']}/${stats2['maglubiyet']}
    - Atılan Gol: ${stats2['attigi']} (Ort: ${stats2['macBasiOrtalamaGol']})
    - Yenilen Gol: ${stats2['yedigi']} (Ort: ${((stats2['yedigi'] as num)/matchCount2).toStringAsFixed(2)})
    - KG Var Yüzdesi: %${stats2['kgVarYuzdesi']}
    - Clean Sheet Yüzdesi: %${stats2['cleanSheetYuzdesi']}
    - Ortalama Şut/İsabetli Şut: ${stats2['ortalamaSut']}/${stats2['ortalamaIsabetliSut']}
    - Ortalama Korner: ${stats2['ortalamaKorner']}
    - Ortalama Faul/Sarı Kart: ${stats2['ortalamaFaul']}/${stats2['ortalamaSariKart']}

    **Aralarındaki Maçlar (H2H):**
    - Toplam Maç: $totalH2HMatches
    - $team1Name Galibiyeti: $team1H2HWins
    - $team2Name Galibiyeti: $team2H2HWins
    - Beraberlik: $h2hDraws
    """;
    
    try {
      final response = await http.post(
        Uri.parse('$_geminiApiUrl$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [{'parts': [{'text': prompt}]}],
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE',
            },
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
              return body['candidates'][0]['content']['parts'][0]['text'];
        } else {
          return "Yapay zeka bir yanıt üretemedi. Bunun nedeni API güvenlik ayarları veya geçici bir sorun olabilir. Lütfen daha sonra tekrar deneyin.";
        }
      } else {
        throw Exception('API isteği başarısız oldu: ${response.body}');
      }
    } catch (e) {
      throw Exception('Yapay zeka analizi alınırken hata oluştu: $e');
    }
  }
}

final advancedComparisonControllerProvider = StateNotifierProvider<AdvancedComparisonController, AdvancedComparisonState>(
  (ref) {
    return AdvancedComparisonController(ref.watch(dataServiceProvider));
  },
);
