// lib/data_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:csv/csv.dart';
import 'services/team_name_service.dart';

// Riverpod provider'ı
final dataServiceProvider = Provider<DataService>((ref) => DataService());
class _CacheEntry {
  final String data;
  final DateTime timestamp;

  _CacheEntry({required this.data, required this.timestamp});
}

class DataService {

  // --- YENİ EKLENEN ÖNBELLEKLEME MEKANİZMASI ---
  final Map<String, _CacheEntry> _cache = {};
  // Önbelleğin ne kadar süre geçerli olacağını belirliyoruz. 1 saat makul bir başlangıç.
  static const Duration _cacheDuration = Duration(hours: 1); 
  // ---------------------------------------------

  Future<String?> fetchData(String url) async {
    // --- YENİ EKLENEN ÖNBELLEK KONTROLÜ ---
    // 1. Önbellekte bu URL için bir girdi var mı?
    if (_cache.containsKey(url)) {
      final cacheEntry = _cache[url]!;
      // 2. Girdi yeterince taze mi? (cacheDuration süresini geçmemiş mi?)
      if (DateTime.now().difference(cacheEntry.timestamp) < _cacheDuration) {
        // print('CACHE HIT: Veri önbellekten alındı - URL: $url');
        return cacheEntry.data; // Evet, taze. Ağ isteği yapmadan veriyi döndür.
      } else {
        // Veri eski, önbellekten sil.
        _cache.remove(url);
        // print('CACHE EXPIRED: Eski veri önbellekten silindi - URL: $url');
      }
    }
    // print('CACHE MISS: Veri ağdan çekiliyor - URL: $url');
    // ---------------------------------------

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // --- YENİ EKLENEN ÖNBELLEĞE KAYIT ---
        // 3. Veri ağdan başarıyla çekildi, önbelleğe kaydet.
        _cache[url] = _CacheEntry(data: response.body, timestamp: DateTime.now());
        // ------------------------------------
        return response.body;
      } else {
        print('Veri çekme hatası: ${response.statusCode} - URL: $url');
        return null;
      }
    } on http.ClientException catch (e) {
      print('HTTP İstemci Hatası: $e - URL: $url');
      return null;
    } on SocketException catch (e) {
      print('Ağ Bağlantısı Hatası: $e - URL: $url');
      return null;
    } catch (e) {
      print('Beklenmeyen Hata (fetchData): $e - URL: $url');
      return null;
    }
  }

  // --- GERİ KALAN KODDA DEĞİŞİKLİK YOK ---

  List<List<dynamic>> parseCsv(String csvString) {
    try {
      return const CsvToListConverter(eol: '\n', fieldDelimiter: ',', shouldParseNumbers: false).convert(csvString);
    } catch (e) {
      print("CSV parse etme hatası: $e");
      return [];
    }
  }

  static final Map<String, String> _LIG_URL_TEMPLATES = {
    "Türkiye - Süper Lig": "https://www.football-data.co.uk/mmz4281/{SEASON}/T1.csv",
    "İngiltere - Premier Lig": "https://www.football-data.co.uk/mmz4281/{SEASON}/E0.csv",
    "İspanya - La Liga": "https://www.football-data.co.uk/mmz4281/{SEASON}/SP1.csv",
    "Almanya - Bundesliga": "https://www.football-data.co.uk/mmz4281/{SEASON}/D1.csv",
    "İtalya - Serie A": "https://www.football-data.co.uk/mmz4281/{SEASON}/I1.csv",
    "Fransa - Ligue 1": "https://www.football-data.co.uk/mmz4281/{SEASON}/F1.csv",
    "Hollanda - Eredivisie": "https://www.football-data.co.uk/mmz4281/{SEASON}/N1.csv",
    "Belçika - Pro Lig": "https://www.football-data.co.uk/mmz4281/{SEASON}/B1.csv",
    "Portekiz - Premier Lig": "https://www.football-data.co.uk/mmz4281/{SEASON}/P1.csv",
    "İskoçya - Premiership": "https://www.football-data.co.uk/mmz4281/{SEASON}/SC0.csv",
    "Yunanistan - Süper Lig": "https://www.football-data.co.uk/mmz4281/{SEASON}/G1.csv",
    "İngiltere - Championship": "https://www.football-data.co.uk/mmz4281/{SEASON}/E1.csv",
    "İtalya - Serie B": "https://www.football-data.co.uk/mmz4281/{SEASON}/I2.csv",
    "Almanya - Bundesliga 2": "https://www.football-data.co.uk/mmz4281/{SEASON}/D2.csv",
  };

  static const List<String> AVAILABLE_SEASONS_API = [
    "2526", "2425", "2324", "2223", "2122", "2021", "1920", "1819", "1718", "1617", "1516",
    "1415", "1314", "1213", "1112", "1011", "0910", "0809", "0708", "0607", "0506",
    "0405", "0304", "0203", "0102", "0001"
  ];

  static Map<String, String> get AVAILABLE_SEASONS_DISPLAY {
    Map<String, String> dynamicSeasons = {};
    for (String apiVal in AVAILABLE_SEASONS_API) {
      if (apiVal == "2021") {
        dynamicSeasons["2020/2021"] = apiVal;
      } else if (apiVal.length == 4) {
        String startYearSuffix = apiVal.substring(0, 2);
        apiVal.substring(2);
        String startFullYear;

        int startYrInt = int.tryParse(startYearSuffix) ?? 0;

        if (startYrInt >= 0 && startYrInt < 50) {
            startFullYear = "20$startYearSuffix";
        } else {
            startFullYear = "19$startYearSuffix";
        }

        dynamicSeasons["$startFullYear/${(int.parse(startFullYear) + 1).toString().substring(2)}"] = apiVal;
      }
    }
    return dynamicSeasons;
  }


  static String? getLeagueUrl(String leagueName, String seasonApiValue) {
    if (_LIG_URL_TEMPLATES.containsKey(leagueName)) {
      String urlTemplate = _LIG_URL_TEMPLATES[leagueName]!;
      return urlTemplate.replaceFirst('{SEASON}', seasonApiValue);
    }
    return null;
  }

  static List<String> get leagueDisplayNames => _LIG_URL_TEMPLATES.keys.toList();

  // Lig bazında takımları getir (örnek veri - gerçek implementasyon API'den gelecek)
  static List<String> getTeamsForLeague(String league) {
    // Bu örnek veri - gerçek uygulamada API'den gelecek
    final Map<String, List<String>> leagueTeams = {
      'Türkiye - Süper Lig': [
        'Galatasaray', 'Fenerbahçe', 'Beşiktaş', 'Trabzonspor', 'Başakşehir',
        'Konyaspor', 'Sivasspor', 'Alanyaspor', 'Kasımpaşa', 'Antalyaspor',
        'Kayserispor', 'Gaziantep FK', 'Hatayspor', 'Pendikspor', 'Samsunspor',
        'Fatih Karagümrük', 'Adana Demirspor', 'Rizespor', 'Ankaragücü', 'İstanbulspor'
      ],
      'İngiltere - Premier Lig': [
        'Arsenal', 'Chelsea', 'Liverpool', 'Manchester City', 'Manchester United',
        'Tottenham', 'Newcastle', 'Brighton', 'Aston Villa', 'West Ham',
        'Crystal Palace', 'Fulham', 'Wolves', 'Everton', 'Brentford',
        'Nottingham Forest', 'Bournemouth', 'Sheffield United', 'Burnley', 'Luton Town'
      ],
      'İspanya - La Liga': [
        'Real Madrid', 'Barcelona', 'Atletico Madrid', 'Sevilla', 'Real Betis',
        'Real Sociedad', 'Villarreal', 'Athletic Bilbao', 'Valencia', 'Getafe',
        'Osasuna', 'Celta Vigo', 'Mallorca', 'Las Palmas', 'Girona',
        'Alaves', 'Rayo Vallecano', 'Cadiz', 'Granada', 'Almeria'
      ],
      'İtalya - Serie A': [
        'Juventus', 'Inter Milan', 'AC Milan', 'Napoli', 'Roma',
        'Lazio', 'Atalanta', 'Fiorentina', 'Bologna', 'Torino',
        'Genoa', 'Monza', 'Verona', 'Lecce', 'Udinese',
        'Cagliari', 'Empoli', 'Frosinone', 'Sassuolo', 'Salernitana'
      ],
      'Almanya - Bundesliga': [
        'Bayern Munich', 'Borussia Dortmund', 'RB Leipzig', 'Union Berlin', 'SC Freiburg',
        'Bayer Leverkusen', 'Eintracht Frankfurt', 'Wolfsburg', 'Mainz', 'Borussia Monchengladbach',
        'FC Koln', 'Hoffenheim', 'Werder Bremen', 'VfL Bochum', 'FC Augsburg',
        'Heidenheim', 'SV Darmstadt 98', 'VfB Stuttgart', 'Hertha Berlin', 'Schalke 04'
      ],
      'Fransa - Ligue 1': [
        'Paris Saint-Germain', 'Marseille', 'Monaco', 'Lille', 'Lyon',
        'Nice', 'Lens', 'Rennes', 'Montpellier', 'Toulouse',
        'Strasbourg', 'Brest', 'Reims', 'Le Havre', 'Nantes',
        'Lorient', 'Metz', 'Clermont', 'Ajaccio', 'Angers'
      ],
      'Hollanda - Eredivisie': [
        'Ajax', 'PSV Eindhoven', 'Feyenoord', 'AZ Alkmaar', 'FC Twente',
        'FC Utrecht', 'Vitesse', 'Go Ahead Eagles', 'Heerenveen', 'NEC Nijmegen',
        'Sparta Rotterdam', 'PEC Zwolle', 'Fortuna Sittard', 'RKC Waalwijk', 'Almere City',
        'FC Volendam', 'Excelsior', 'Willem II'
      ],
      'Belçika - Pro Lig': [
        'Club Brugge', 'Royal Antwerp', 'Union Saint-Gilloise', 'Genk', 'Anderlecht',
        'Gent', 'Standard Liege', 'Mechelen', 'Cercle Brugge', 'Sint-Truiden',
        'Kortrijk', 'Westerlo', 'Charleroi', 'Oostende', 'Eupen', 'Seraing'
      ],
      'Portekiz - Premier Lig': [
        'Porto', 'Benfica', 'Sporting CP', 'Braga', 'Vitoria Guimaraes',
        'Rio Ave', 'Boavista', 'Moreirense', 'Famalicao', 'Santa Clara',
        'Gil Vicente', 'Arouca', 'Estoril', 'Vizela', 'Chaves', 'Portimonense'
      ],
    };
    
    return leagueTeams[league] ?? [];
  }

  static String getDisplaySeasonFromApiValue(String apiValue) {
      final seasonsMap = AVAILABLE_SEASONS_DISPLAY;
      for (var entry in seasonsMap.entries) {
        if (entry.value == apiValue) {
          return entry.key;
        }
      }
      if (apiValue == "2021") return "2020/2021";
      if (apiValue.length == 4) {
          String start = apiValue.substring(0, 2);
          int startInt = int.tryParse(start) ?? 0;
          String startFull = (startInt < 50 && startInt >= 0) ? "20$start" : "19$start";
          String endFull = (int.parse(startFull) + 1).toString();
          return "$startFull/${endFull.substring(2)}";
      }
      return apiValue;
  }

  List<String> getCsvHeaders(List<List<dynamic>> csvData) {
    if (csvData.isEmpty) return [];
    try {
      return csvData[0].map((header) => header.toString().trim()).toList();
    } catch (e) { return []; }
  }

  List<String> getAllOriginalTeamNames(List<List<dynamic>> csvData, List<String> headers) {
    Set<String> allTeams = {};
    int homeTeamIndex = headers.indexOf("HomeTeam");
    int awayTeamIndex = headers.indexOf("AwayTeam");
    if (homeTeamIndex == -1 || awayTeamIndex == -1) return [];

    for (int i = 1; i < csvData.length; i++) {
      List<dynamic> row = csvData[i];
      if (row.length > homeTeamIndex && row[homeTeamIndex] != null && row[homeTeamIndex].toString().isNotEmpty) {
        allTeams.add(row[homeTeamIndex].toString().trim());
      }
      if (row.length > awayTeamIndex && row[awayTeamIndex] != null && row[awayTeamIndex].toString().isNotEmpty) {
        allTeams.add(row[awayTeamIndex].toString().trim());
      }
    }
    List<String> sortedTeams = allTeams.toList();
    sortedTeams.sort((a, b) => TeamNameService.normalize(a).compareTo(TeamNameService.normalize(b)));
    return sortedTeams;
  }

  List<Map<String, dynamic>> filterMatchesByTeam(List<List<dynamic>> csvData, List<String> headers, String teamNameToFilter) {
    List<Map<String, dynamic>> teamMatches = [];
    String normalizedTeamToFilter = TeamNameService.normalize(teamNameToFilter);
    int homeTeamIndex = headers.indexOf("HomeTeam");
    int awayTeamIndex = headers.indexOf("AwayTeam");
    if (homeTeamIndex == -1 || awayTeamIndex == -1) return [];

    for (int i = 1; i < csvData.length; i++) {
      List<dynamic> row = csvData[i];
      if (row.length > homeTeamIndex && row.length > awayTeamIndex && row[homeTeamIndex] != null && row[awayTeamIndex] != null) {
        String homeTeamCsv = row[homeTeamIndex].toString();
        String awayTeamCsv = row[awayTeamIndex].toString();
        if (TeamNameService.normalize(homeTeamCsv) == normalizedTeamToFilter || TeamNameService.normalize(awayTeamCsv) == normalizedTeamToFilter) {
          Map<String, dynamic> match = {};
          for (int j = 0; j < headers.length; j++) {
            if (j < row.length) { match[headers[j]] = row[j]; } else { match[headers[j]] = null; }
          }
          
          // DEĞİŞİKLİK: Tarih ayrıştırma mantığı buraya da eklendi
          try {
            String? matchDateStr = match['Date']?.toString();
            if (matchDateStr != null && matchDateStr.isNotEmpty) {
              List<String> dateParts = matchDateStr.split('/');
              if (dateParts.length == 3) {
                int day = int.tryParse(dateParts[0]) ?? 1;
                int month = int.tryParse(dateParts[1]) ?? 1;
                int year = int.tryParse(dateParts[2]) ?? 2000;
                if (year < 100) {
                  year += (year >= 0 && year <= (DateTime.now().year % 100 + 15)) ? 2000 : 1900;
                }
                match['_parsedDate'] = DateTime(year, month, day);
              } else {
                match['_parsedDate'] = null;
              }
            } else {
              match['_parsedDate'] = null;
            }
          } catch (e) {
            match['_parsedDate'] = null;
          }

          teamMatches.add(match);
        }
      }
    }
    return teamMatches;
  }

  String? findMatchingTeam(List<List<dynamic>> csvData, List<String> headers, String userInput) {
    String inputNorm = TeamNameService.normalize(userInput);
    String? teamToSearchNorm = TeamNameService.takmaAdlar[inputNorm] ?? inputNorm;
    List<String> originalTeamNames = getAllOriginalTeamNames(csvData, headers);
    for (String originalName in originalTeamNames) {
      if (TeamNameService.normalize(originalName) == teamToSearchNorm) { return originalName; }
    }
    for (String originalName in originalTeamNames) {
      if (TeamNameService.normalize(originalName).contains(teamToSearchNorm)) { return originalName; }
    }
    return null;
  }

  Map<String, dynamic> analyzeTeamStats(
      List<Map<String, dynamic>> allTeamMatchesInput,
      String teamDisplayName,
      {int? lastNMatches = 5}) {

    List<Map<String, dynamic>> relevantMatches;
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        List<String> parts = dateStr.split('/');
        if (parts.length == 3) {
          int day = int.tryParse(parts[0]) ?? 1;
          int month = int.tryParse(parts[1]) ?? 1;
          int year = int.tryParse(parts[2]) ?? 2000;
          if (year < 100) {
             year += (year >= 0 && year <= (DateTime.now().year % 100 + 15)) ? 2000 : 1900;
          }
          return DateTime(year, month, day);
        }
      } catch (e) { /* Diğer formatları dene */ }
      try {
        if (dateStr.contains('-')) {
            return DateTime.parse(dateStr);
        }
      } catch (e) { /* Hata olursa null döner */ }
      return null;
    }

    List<Map<String, dynamic>> sortedMatches = List.from(allTeamMatchesInput);
    sortedMatches.removeWhere((match) => parseDate(match['Date']?.toString()) == null);

    sortedMatches.sort((a, b) {
      DateTime? dateA = parseDate(a['Date']?.toString());
      DateTime? dateB = parseDate(b['Date']?.toString());
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    if (lastNMatches == null || lastNMatches <= 0) {
      relevantMatches = sortedMatches;
    } else {
      relevantMatches = sortedMatches.take(lastNMatches).toList();
    }

    Map<String, dynamic> defaultStats = {
      "takim": teamDisplayName,
      "displayTeamName": TeamNameService.getCorrectedTeamName(teamDisplayName),
      "attigi": 0, "yedigi": 0, "galibiyet": 0, "beraberlik": 0, "maglubiyet": 0,
      "macBasiOrtalamaGol": 0.0, "maclardaOrtalamaToplamGol": 0.0, "gol2UstuOlasilik": 0.0,
      "golFarki": 0, "kgVarYuzdesi": 0.0, "kgYokYuzdesi": 0.0,
      "cleanSheetSayisi": 0, "cleanSheetYuzdesi": 0.0,
      "formPuani": 0.0,
      "ortalamaSut": null, "ortalamaIsabetliSut": null, "ortalamaFaul": null, "ortalamaKorner": null,
      "ortalamaSariKart": null, "ortalamaKirmiziKart": null,
      "iyAttigi": 0, "iyYedigi": 0,
      "iyGalibiyet": 0, "iyBeraberlik": 0, "iyMaglubiyet": 0,
      "iyAttigiOrt": null, "iyYedigiOrt": null,
      "iyGalibiyetYuzdesi": null, "iyBeraberlikYuzdesi": null, "iyMaglubiyetYuzdesi": null,
      "oynananMacSayisi": 0,
      "lastNMatchesUsed": relevantMatches.length,
    };
    String macDetayAnahtari = "son${relevantMatches.length}MacDetaylari";
    defaultStats[macDetayAnahtari] = [];

    if (relevantMatches.isEmpty) {
      return defaultStats;
    }

    const String homeTeamKey = "HomeTeam";
    const String awayTeamKey = "AwayTeam";
    const String fullTimeHomeGoalsKey = "FTHG";
    const String fullTimeAwayGoalsKey = "FTAG";
    const String fullTimeResultKey = "FTR";
    const String dateKey = "Date";

    bool hasHalfTimeData = relevantMatches.first.containsKey("HTHG") && relevantMatches.first.containsKey("HTAG") && relevantMatches.first.containsKey("HTR");
    bool hasShotData = relevantMatches.first.containsKey("HS") && relevantMatches.first.containsKey("AS") && relevantMatches.first.containsKey("HST") && relevantMatches.first.containsKey("AST");
    bool hasFoulData = relevantMatches.first.containsKey("HF") && relevantMatches.first.containsKey("AF");
    bool hasCornerData = relevantMatches.first.containsKey("HC") && relevantMatches.first.containsKey("AC");
    bool hasCardData = relevantMatches.first.containsKey("HY") && relevantMatches.first.containsKey("AY") && relevantMatches.first.containsKey("HR") && relevantMatches.first.containsKey("AR");

    int attigi = 0; int yedigi = 0;
    int galibiyet = 0; int beraberlik = 0; int maglubiyet = 0;
    int iyAttigi = 0; int iyYedigi = 0;
    int iyGalibiyet = 0; int iyBeraberlik = 0; int iyMaglubiyet = 0;
    List<int> toplamGollerListesi = [];
    List<Map<String, dynamic>> macDetaylariListesi = [];
    int kgVarMacSayisi = 0; int cleanSheetSayisi = 0; double formPuaniHesaplama = 0.0;
    int toplamSut = 0; int toplamIsabetliSut = 0; int toplamFaul = 0; int toplamKorner = 0;
    int toplamSariKart = 0; int toplamKirmiziKart = 0;
    int macSayisiDetayliVeriIle = 0;
    int macSayisiKartVerisiIle = 0;
    int macSayisiIlkYariVerisiIle = 0;

    String teamNorm = TeamNameService.normalize(teamDisplayName);

    for (var match in relevantMatches) {
      if (match[homeTeamKey] == null || match[awayTeamKey] == null ||
          match[fullTimeHomeGoalsKey] == null || match[fullTimeAwayGoalsKey] == null ||
          match[fullTimeResultKey] == null || match[dateKey] == null ||
          match[homeTeamKey].toString().isEmpty || match[awayTeamKey].toString().isEmpty ||
          match[fullTimeHomeGoalsKey].toString().isEmpty || match[fullTimeAwayGoalsKey].toString().isEmpty ||
          match[fullTimeResultKey].toString().isEmpty || match[dateKey].toString().isEmpty) {
        continue;
      }

      int evGol = int.tryParse(match[fullTimeHomeGoalsKey].toString()) ?? 0;
      int depGol = int.tryParse(match[fullTimeAwayGoalsKey].toString()) ?? 0;
      String sonuc = match[fullTimeResultKey].toString();
      String macSonucuText = "Bilinmiyor";

      bool currentMatchHasHalfTime = hasHalfTimeData &&
                                   match["HTHG"] != null && match["HTHG"].toString().isNotEmpty &&
                                   match["HTAG"] != null && match["HTAG"].toString().isNotEmpty &&
                                   match["HTR"] != null && match["HTR"].toString().isNotEmpty;
      int iyEvGol = 0, iyDepGol = 0; String iySonuc = "", ilkYariSonucuText = "";
      if (currentMatchHasHalfTime) {
        iyEvGol = int.tryParse(match["HTHG"].toString()) ?? 0;
        iyDepGol = int.tryParse(match["HTAG"].toString()) ?? 0;
        iySonuc = match["HTR"].toString();
        macSayisiIlkYariVerisiIle++;
      }

      if (evGol > 0 && depGol > 0) kgVarMacSayisi++;
      toplamGollerListesi.add(evGol + depGol);

      bool isHomeTeam = TeamNameService.normalize(match[homeTeamKey].toString()) == teamNorm;
      bool isAwayTeam = TeamNameService.normalize(match[awayTeamKey].toString()) == teamNorm;

      int sut = 0, isabetliSut = 0, faul = 0, korner = 0, sariKart = 0, kirmiziKart = 0;
      bool currentMatchHasShotFoulCorner = hasShotData && hasFoulData && hasCornerData &&
          match["HS"] != null && match["HS"].toString().isNotEmpty && match["AS"] != null && match["AS"].toString().isNotEmpty &&
          match["HST"] != null && match["HST"].toString().isNotEmpty && match["AST"] != null && match["AST"].toString().isNotEmpty &&
          match["HF"] != null && match["HF"].toString().isNotEmpty && match["AF"] != null && match["AF"].toString().isNotEmpty &&
          match["HC"] != null && match["HC"].toString().isNotEmpty && match["AC"] != null && match["AC"].toString().isNotEmpty;

      bool currentMatchHasCards = hasCardData &&
          match["HY"] != null && match["HY"].toString().isNotEmpty && match["AY"] != null && match["AY"].toString().isNotEmpty &&
          match["HR"] != null && match["HR"].toString().isNotEmpty && match["AR"] != null && match["AR"].toString().isNotEmpty;

      if (currentMatchHasShotFoulCorner) macSayisiDetayliVeriIle++;
      if (currentMatchHasCards) macSayisiKartVerisiIle++;

      if (isHomeTeam) {
        attigi += evGol; yedigi += depGol;
        if (currentMatchHasHalfTime) { iyAttigi += iyEvGol; iyYedigi += iyDepGol; }
        if (depGol == 0) cleanSheetSayisi++;
        if (sonuc == "H") { galibiyet++; macSonucuText = "G (Ev)"; formPuaniHesaplama += 3; }
        else if (sonuc == "D") { beraberlik++; macSonucuText = "B (Ev)"; formPuaniHesaplama += 1; }
        else if (sonuc == "A") { maglubiyet++; macSonucuText = "M (Ev)"; formPuaniHesaplama -= 1; }
        if (currentMatchHasHalfTime) {
            if(iySonuc == "H") { iyGalibiyet++; ilkYariSonucuText = "İY: G"; }
            else if(iySonuc == "D") { iyBeraberlik++; ilkYariSonucuText = "İY: B"; }
            else if(iySonuc == "A") { iyMaglubiyet++; ilkYariSonucuText = "İY: M"; }
        }
        if (currentMatchHasShotFoulCorner) {
            sut = int.tryParse(match["HS"]?.toString() ?? '0') ?? 0; isabetliSut = int.tryParse(match["HST"]?.toString() ?? '0') ?? 0;
            faul = int.tryParse(match["HF"]?.toString() ?? '0') ?? 0; korner = int.tryParse(match["HC"]?.toString() ?? '0') ?? 0;
        }
        if(currentMatchHasCards){ sariKart = int.tryParse(match["HY"]?.toString() ?? '0') ?? 0; kirmiziKart = int.tryParse(match["HR"]?.toString() ?? '0') ?? 0; }
      } else if (isAwayTeam) {
        attigi += depGol; yedigi += evGol;
        if (currentMatchHasHalfTime) { iyAttigi += iyDepGol; iyYedigi += iyEvGol; }
        if (evGol == 0) cleanSheetSayisi++;
        if (sonuc == "A") { galibiyet++; macSonucuText = "G (Dep)"; formPuaniHesaplama += 3; }
        else if (sonuc == "D") { beraberlik++; macSonucuText = "B (Dep)"; formPuaniHesaplama += 1; }
        else if (sonuc == "H") { maglubiyet++; macSonucuText = "M (Dep)"; formPuaniHesaplama -= 1; }
        if (currentMatchHasHalfTime) {
            if(iySonuc == "A") { iyGalibiyet++; ilkYariSonucuText = "İY: G"; }
            else if(iySonuc == "D") { iyBeraberlik++; ilkYariSonucuText = "İY: B"; }
            else if(iySonuc == "H") { iyMaglubiyet++; ilkYariSonucuText = "İY: M"; }
        }
        if (currentMatchHasShotFoulCorner) {
            sut = int.tryParse(match["AS"]?.toString() ?? '0') ?? 0; isabetliSut = int.tryParse(match["AST"]?.toString() ?? '0') ?? 0;
            faul = int.tryParse(match["AF"]?.toString() ?? '0') ?? 0; korner = int.tryParse(match["AC"]?.toString() ?? '0') ?? 0;
        }
         if(currentMatchHasCards){ sariKart = int.tryParse(match["AY"]?.toString() ?? '0') ?? 0; kirmiziKart = int.tryParse(match["AR"]?.toString() ?? '0') ?? 0; }
      } else { continue; }

      if(currentMatchHasShotFoulCorner) { toplamSut += sut; toplamIsabetliSut += isabetliSut; toplamFaul += faul; toplamKorner += korner; }
      if(currentMatchHasCards) { toplamSariKart += sariKart; toplamKirmiziKart += kirmiziKart; }
      macDetaylariListesi.add({ "date": match[dateKey].toString(), "homeTeam": match[homeTeamKey].toString(), "awayTeam": match[awayTeamKey].toString(), "homeGoals": evGol, "awayGoals": depGol, "result": macSonucuText, "htHomeGoals": currentMatchHasHalfTime ? iyEvGol.toString() : '-', "htAwayGoals": currentMatchHasHalfTime ? iyDepGol.toString() : '-', "htResult": currentMatchHasHalfTime ? iySonuc : '-', "htResultText": ilkYariSonucuText, });
    }

    int oynananMacSayisi = relevantMatches.length;
    defaultStats["oynananMacSayisi"] = oynananMacSayisi; defaultStats["attigi"] = attigi;
    defaultStats["yedigi"] = yedigi; defaultStats["galibiyet"] = galibiyet;
    defaultStats["beraberlik"] = beraberlik; defaultStats["maglubiyet"] = maglubiyet;
    defaultStats["golFarki"] = attigi - yedigi; defaultStats[macDetayAnahtari] = List.from(macDetaylariListesi);

    if (oynananMacSayisi > 0) {
      defaultStats["macBasiOrtalamaGol"] = double.tryParse((attigi / oynananMacSayisi).toStringAsFixed(2)) ?? 0.0;
      defaultStats["maclardaOrtalamaToplamGol"] = toplamGollerListesi.isNotEmpty ? (double.tryParse((toplamGollerListesi.reduce((a, b) => a + b) / oynananMacSayisi).toStringAsFixed(2)) ?? 0.0) : 0.0;
      defaultStats["gol2UstuOlasilik"] = double.tryParse(((toplamGollerListesi.where((gol) => gol >= 2).length / oynananMacSayisi) * 100).toStringAsFixed(1)) ?? 0.0;
      defaultStats["kgVarYuzdesi"] = double.tryParse(((kgVarMacSayisi / oynananMacSayisi) * 100).toStringAsFixed(1)) ?? 0.0;
      defaultStats["kgYokYuzdesi"] = double.tryParse((100.0 - (defaultStats["kgVarYuzdesi"] as double)).toStringAsFixed(1)) ?? 0.0;
      defaultStats["cleanSheetSayisi"] = cleanSheetSayisi;
      defaultStats["cleanSheetYuzdesi"] = double.tryParse(((cleanSheetSayisi / oynananMacSayisi) * 100).toStringAsFixed(1)) ?? 0.0;
      if (lastNMatches != null && lastNMatches > 0 && lastNMatches <= oynananMacSayisi) {
         defaultStats["formPuani"] = double.tryParse(formPuaniHesaplama.toStringAsFixed(1)) ?? 0.0;
      } else { defaultStats["formPuani"] = double.tryParse(formPuaniHesaplama.toStringAsFixed(1)) ?? 0.0; }
      if (macSayisiDetayliVeriIle > 0) {
        defaultStats["ortalamaSut"] = double.tryParse((toplamSut / macSayisiDetayliVeriIle).toStringAsFixed(1)); defaultStats["ortalamaIsabetliSut"] = double.tryParse((toplamIsabetliSut / macSayisiDetayliVeriIle).toStringAsFixed(1));
        defaultStats["ortalamaFaul"] = double.tryParse((toplamFaul / macSayisiDetayliVeriIle).toStringAsFixed(1)); defaultStats["ortalamaKorner"] = double.tryParse((toplamKorner / macSayisiDetayliVeriIle).toStringAsFixed(1));
      }
      if (macSayisiKartVerisiIle > 0) {
        defaultStats["ortalamaSariKart"] = double.tryParse((toplamSariKart / macSayisiKartVerisiIle).toStringAsFixed(2)); defaultStats["ortalamaKirmiziKart"] = double.tryParse((toplamKirmiziKart / macSayisiKartVerisiIle).toStringAsFixed(2));
      }
      if (macSayisiIlkYariVerisiIle > 0) {
        defaultStats["iyAttigi"] = iyAttigi; defaultStats["iyYedigi"] = iyYedigi; defaultStats["iyGalibiyet"] = iyGalibiyet; defaultStats["iyBeraberlik"] = iyBeraberlik; defaultStats["iyMaglubiyet"] = iyMaglubiyet;
        defaultStats["iyAttigiOrt"] = double.tryParse((iyAttigi / macSayisiIlkYariVerisiIle).toStringAsFixed(2)); defaultStats["iyYedigiOrt"] = double.tryParse((iyYedigi / macSayisiIlkYariVerisiIle).toStringAsFixed(2));
        defaultStats["iyGalibiyetYuzdesi"] = double.tryParse(((iyGalibiyet / macSayisiIlkYariVerisiIle) * 100).toStringAsFixed(1));
        defaultStats["iyBeraberlikYuzdesi"] = double.tryParse(((iyBeraberlik / macSayisiIlkYariVerisiIle) * 100).toStringAsFixed(1));
        defaultStats["iyMaglubiyetYuzdesi"] = double.tryParse(((iyMaglubiyet / macSayisiIlkYariVerisiIle) * 100).toStringAsFixed(1));
      }
    }
    return defaultStats;
  }
  
  List<String> getAllOriginalTeamNamesFromMatches(List<Map<String, dynamic>> matches) {
    Set<String> allTeams = {};
    if (matches.isEmpty) return [];

    const String homeTeamKey = "HomeTeam";
    const String awayTeamKey = "AwayTeam";

    for (var match in matches) {
      if (match.containsKey(homeTeamKey) && match[homeTeamKey] != null && match[homeTeamKey].toString().isNotEmpty) {
        allTeams.add(match[homeTeamKey].toString().trim());
      }
      if (match.containsKey(awayTeamKey) && match[awayTeamKey] != null && match[awayTeamKey].toString().isNotEmpty) {
        allTeams.add(match[awayTeamKey].toString().trim());
      }
    }
    List<String> sortedTeams = allTeams.toList();
    sortedTeams.sort((a, b) => TeamNameService.normalize(a).compareTo(TeamNameService.normalize(b)));
    return sortedTeams;
  }

  List<Map<String, dynamic>> getH2HMatches(
      List<List<dynamic>> allMatchesCsv, 
      List<String> headers,
      String team1Name, 
      String team2Name) {
        
    List<Map<String, dynamic>> h2hMatches = [];
    if (headers.isEmpty || allMatchesCsv.length < 2) return [];

    final String normalizedTeam1 = TeamNameService.normalize(team1Name);
    final String normalizedTeam2 = TeamNameService.normalize(team2Name);
    
    final int homeTeamIndex = headers.indexOf("HomeTeam");
    final int awayTeamIndex = headers.indexOf("AwayTeam");
    if (homeTeamIndex == -1 || awayTeamIndex == -1) return [];

    for (int i = 1; i < allMatchesCsv.length; i++) {
      final List<dynamic> row = allMatchesCsv[i];
      if (row.length <= homeTeamIndex || row.length <= awayTeamIndex) continue;

      final String homeTeam = row[homeTeamIndex]?.toString() ?? '';
      final String awayTeam = row[awayTeamIndex]?.toString() ?? '';

      final String normalizedHome = TeamNameService.normalize(homeTeam);
      final String normalizedAway = TeamNameService.normalize(awayTeam);

      if ((normalizedHome == normalizedTeam1 && normalizedAway == normalizedTeam2) ||
          (normalizedHome == normalizedTeam2 && normalizedAway == normalizedTeam1)) {
        
        Map<String, dynamic> match = {};
        for (int j = 0; j < headers.length; j++) {
          if (j < row.length) {
            match[headers[j]] = row[j];
          } else {
            match[headers[j]] = null;
          }
        }
        h2hMatches.add(match);
      }
    }
    
    // Maçları tarihe göre sıralayalım (yeniden eskiye)
    h2hMatches.sort((a, b) {
       DateTime? dateA = _parseDate(a['Date']?.toString());
       DateTime? dateB = _parseDate(b['Date']?.toString());
       if (dateA == null) return 1;
       if (dateB == null) return -1;
       return dateB.compareTo(dateA);
    });

    return h2hMatches;
  }

  // analyzeTeamStats içindeki parseDate metodunu dışarı taşıyarak yeniden kullanılabilir hale getirelim.
  // Private olduğu için başına _ koyuyoruz.
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      List<String> parts = dateStr.split('/');
      if (parts.length == 3) {
        int day = int.tryParse(parts[0]) ?? 1;
        int month = int.tryParse(parts[1]) ?? 1;
        int year = int.tryParse(parts[2]) ?? 2000;
        if (year < 100) {
           year += (year >= 0 && year <= (DateTime.now().year % 100 + 15)) ? 2000 : 1900;
        }
        return DateTime(year, month, day);
      }
    } catch (e) { /* Diğer formatları dene */ }
    try {
      if (dateStr.contains('-')) {
          return DateTime.parse(dateStr);
      }
    } catch (e) { /* Hata olursa null döner */ }
    return null;
  }


}
