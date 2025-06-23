// lib/services/logo_service.dart
import 'dart:core';

class LogoService {
  static const String _baseUrl = "https://raw.githubusercontent.com/luukhopman/football-logos/master/logos";

  // Anahtar: Bizim uygulamadaki (DataService) lig adı
  // Değer: GitHub reposundaki klasör adı
  static const Map<String, String> _leagueFolderMap = {
    "Türkiye - Süper Lig": "Türkiye - Süper Lig",
    "İngiltere - Premier Lig": "England - Premier League",
    "İspanya - La Liga": "Spain - LaLiga",
    "Almanya - Bundesliga": "Germany - Bundesliga",
    "İtalya - Serie A": "Italy - Serie A",
    "Fransa - Ligue 1": "France - Ligue 1",
    "Hollanda - Eredivisie": "Netherlands - Eredivisie",
    "Portekiz - Premier Lig": "Portugal - Primeira Liga",
    "Belçika - Pro Lig": "Belgium - Jupiler Pro League",
    "İskoçya - Premiership": "Scotland - Scottish Premiership",
    "Yunanistan - Süper Lig": "Greece - Super League",
    "İngiltere - Championship": "England - Championship",
    "İtalya - Serie B": "Italy - Serie B",
    "Almanya - Bundesliga 2": "Germany - 2. Bundesliga",
  };

  // Anahtar: CSV'den gelen ORİJİNAL takım adı
  // Değer: GitHub'daki dosya adı (uzantısız)
  static const Map<String, String> _teamFileNameMap = {
    // Türkiye
    'Fenerbahce': 'Fenerbahce', 'Galatasaray': 'Galatasaray', 'Besiktas': 'Besiktas JK',
    'Trabzonspor': 'Trabzonspor', 'Basaksehir': 'Basaksehir FK', 'Istanbulspor': 'Istanbulspor',
    'Buyuksehyr': 'Basaksehir FK', 'Ankaragucu': 'Ankaragucu', 'Sivasspor': 'Sivasspor',
    'Antalyaspor': 'Antalyaspor', 'Gaziantep': 'Gaziantep FK', 'Alanyaspor': 'Alanyaspor',
    'Karagumruk': 'Karagumruk', 'Kasimpasa': 'Kasimpasa', 'Konyaspor': 'Konyaspor',
    'Rizespor': 'Caykur Rizespor', 'Samsunspor': 'Samsunspor', 'Pendikspor': 'Pendikspor', 'Hatayspor': 'Hatayspor',
    'Kayserispor': 'Kayserispor', 'Goztep': 'Göztepe', 'Eyupspor': 'Eyüpspor', 'Bodrumspor': 'Bodrum FK',
     'Ad. Demirspor': 'Adana Demirspor',

    // İngiltere
    'Man City': 'Manchester City', 'Man United': 'Manchester United', 'Arsenal': 'Arsenal FC',
    'Liverpool': 'Liverpool FC', 'Chelsea': 'Chelsea FC', 'Tottenham': 'Tottenham Hotspur',
    'Newcastle': 'Newcastle United', 'West Ham': 'West Ham United', 'Wolves': 'Wolverhampton Wanderers',
    'Brighton': 'Brighton & Hove Albion', 'Aston Villa': 'Aston Villa', 'Crystal Palace': 'Crystal Palace',
    'Fulham': 'Fulham FC', 'Bournemouth': 'AFC Bournemouth', 'Brentford': 'Brentford FC', 'Everton': 'Everton FC',
    'Nott\'m Forest': 'Nottingham Forest', 'Leicester': 'Leicester City', 'Ipswich': 'Ipswich Town', 'Southampton': 'Southampton FC',

    // İspanya
    'Barcelona': 'FC Barcelona', 'Real Madrid': 'Real Madrid', 'Ath Madrid': 'Atlético de Madrid', 'Atletico Madrid': 'Atletico Madrid',
    'Ath Bilbao': 'Athletic Bilbao', 'Sevilla': 'Sevilla FC', 'Real Sociedad': 'Real Sociedad',
    'Betis': 'Real Betis Balompié', 'Villarreal': 'Villarreal CF', 'Valencia': 'Valencia CF', 'Celta': 'Celta de Vigo', 'Girona': 'Girona FC',
    'Osasuna': 'CA Osasuna', 'Vallecano': 'Rayo Vallecano', 'Mallorca': 'RCD Mallorca', 'Sociedad': 'Real Sociedad', 'Alaves': 'Deportivo Alavés',
    'Espanol': 'RCD Espanyol Barcelona', 'Getafe': 'Getafe CF', 'Leganes': 'CD Leganés', 'Las Palmas': 'UD Las Palmas', 'Valladolid': 'Real Valladolid CF',

    // Almanya
    'Bayern Munich': 'Bayern Munich', 'Dortmund': 'Borussia Dortmund', 'Leverkusen': 'Bayer 04 Leverkusen',
    'RB Leipzig': 'RB Leipzig', 'Stuttgart': 'VfB Stuttgart', 'Ein Frankfurt': 'Eintracht Frankfurt',
    'Freiburg': 'SC Freiburg', 'Hoffenheim': 'TSG 1899 Hoffenheim', 'Wolfsburg': 'VfL Wolfsburg',
    'M\'gladbach': 'Borussia Mönchengladbach', "Monchengladbach": 'Borussia Monchengladbach',
    'Union Berlin': '1.FC Union Berlin', 'Mainz': '1.FSV Mainz 05', 'Werder Bremen': 'SV Werder Bremen', 'Augsburg': 'FC Augsburg',
    'St Pauli': 'FC St. Pauli', 'Heidenheim': '1.FC Heidenheim 1846', 'Bochum': 'VfL Bochum', 'Holstein Kiel': 'Holstein Kiel',


    // İtalya
    'Inter': 'Inter Milan', 'Milan': 'AC Milan', 'Juventus': 'Juventus FC', 'Bologna': 'Bologna FC 1909',
    'Roma': 'AS Roma', 'Lazio': 'SS Lazio', 'Atalanta': 'Atalanta BC', 'Napoli': 'SSC Napoli', 'Fiorentina': 'ACF Fiorentina',
    'Torino': 'Torino FC', 'Monza': 'AC Monza', 'Genoa': 'Genoa CFC', 'Como': 'Como 1907', 'Udinese': 'Udinese Calcio', 'Verona': 'Hellas Verona',
    'Cagliari': 'Cagliari Calcio', 'Parma': 'Parma Calcio 1913', 'Lecce': 'US Lecce', 'Empoli': 'FC Empoli', 'Venezia': 'Venezia FC',

    // Fransa
    'Paris SG': 'Paris Saint-Germain', 'Monaco': 'AS Monaco', 'Lille': 'LOSC Lille', 'Nice': 'OGC Nice',
    'Marseille': 'Olympique Marseille', 'Lyon': 'Olympique Lyon', 'Lens': 'RC Lens', 'Reims': 'Stade Reims',
    'Rennes': 'Stade Rennais FC', 'Toulouse': 'FC Toulouse', 'Strasbourg': 'RC Strasbourg Alsace', 'Nantes': 'FC Nantes',
    'Auxerre': 'AJ Auxerre', 'Angers': 'Angers SCO', 'Le Havre': 'Le Havre AC', 'St Etienne': 'AS Saint-Étienne',
    'Brest': 'Stade Brestois 29', 'Montpellier': 'Montpellier HSC', 


    // Hollanda
    'PSV': 'PSV Eindhoven', 'Feyenoord': 'Feyenoord Rotterdam', 'Ajax': 'Ajax Amsterdam',
    'AZ': 'AZ Alkmaar', 'Utrecht': 'FC Utrecht', 'Almere City': 'Almere City FC', 'Twente': 'Twente Enschede FC',
    'For Sittard': 'Fortuna Sittard', 'Go Ahead Eagles': 'Go Ahead Eagles', 'Groningen': 'FC Groningen', 'Heerenveen': 'SC Heerenveen',
    'Heracles': 'Heracles Almelo', 'NAC Breda': 'NAC Breda', 'Nijmegen': 'NEC Nijmegen', 'Sparta Rotterdam': 'Sparta Rotterdam',
    'Waalwijk': 'RKC Waalwijk', 'Willem II': 'Willem II Tilburg', 'Zwolle': 'PEC Zwolle',

    // Portekiz
    'Sporting': 'Sporting CP', 'Benfica': 'Benfica', 'Porto': 'FC Porto', 'Braga': 'SC Braga',

    // Belçika
    'Anderlecht': 'RSC Anderlecht', 'Club Brugge': 'Club Brugge KV', 'St. Gilloise': 'Union Saint-Gilloise',
    'Genk': 'KRC Genk', 'Antwerp': 'Royal Antwerp FC',  'Beerschot VA': 'Beerschot VA', 'Charleroi': 'R Charleroi SC',
    'Cercle Brugge': 'Cercle Brugge', 'Gent': 'KAA Gent', 'Mechelen': 'KV Mechelen', 'Standard': 'Standard Liège', 'Oud-Heverlee Leuven': 'Oud-Heverlee Leuven', 
    'Dender': 'FCV Dender EH',  'St Truiden': 'Sint-Truidense VV', 'Kortrijk': 'KV Kortrijk', 'Westerlo': 'KVC Westerlo',

    // İskoçya
    'Celtic': 'Celtic', 'Rangers': 'Rangers', 'Hearts': 'Heart of Midlothian',
    
    // Yunanistan
    'PAOK': 'PAOK', 'AEK': 'AEK Athens', 'Olympiakos': 'Olympiakos', 'Panathinaikos': 'Panathinaikos'
  };

  static String? getTeamLogoUrl(String originalCsvTeamName, String appLeagueName) {
    final String? leagueFolder = _leagueFolderMap[appLeagueName];
    if (leagueFolder == null) return null;

    String? teamFileName = _teamFileNameMap[originalCsvTeamName];
    
    // Linter uyarısına göre null-aware atama operatörü (??=) kullanımı
    teamFileName ??= _teamFileNameMap[originalCsvTeamName.toLowerCase()];
    
    // Diğer kontrol (forEach yerine daha verimli bir arama)
    teamFileName ??= _findPartialMatch(originalCsvTeamName);


    // DÜZELTME: teamFileName hala null ise URL oluşturmadan çık
    if (teamFileName == null) {
      // print("LogoService: Eşleşen takım dosyası bulunamadı: $originalCsvTeamName");
      return null;
    }
    
    // Artık leagueFolder ve teamFileName null değil, güvenle encode edebiliriz.
    final encodedLeagueFolder = Uri.encodeComponent(leagueFolder);
    final encodedTeamFileName = Uri.encodeComponent(teamFileName);

    return '$_baseUrl/$encodedLeagueFolder/$encodedTeamFileName.png';
  }

  // forEach yerine daha verimli bir helper fonksiyon
  static String? _findPartialMatch(String originalCsvTeamName) {
    for (var entry in _teamFileNameMap.entries) {
      if (originalCsvTeamName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }
}