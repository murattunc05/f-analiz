// lib/services/logo_service.dart
import 'dart:core';

class LogoService {
  // YENİ: Temel URL güncellendi.
  static const String _baseUrl = "https://football-logos.cc/logos";

  // YENİ: Uygulamadaki lig adını, URL'deki ülke adına eşleştiren harita.
  static const Map<String, String> _leagueCountryMap = {
    "Türkiye - Süper Lig": "turkey",
    "İngiltere - Premier Lig": "england",
    "İspanya - La Liga": "spain",
    "Almanya - Bundesliga": "germany",
    "İtalya - Serie A": "italy",
    "Fransa - Ligue 1": "france",
    "Hollanda - Eredivisie": "netherlands",
    "Portekiz - Premier Lig": "portugal",
    "Belçika - Pro Lig": "belgium",
    "İskoçya - Premiership": "scotland",
    "Yunanistan - Süper Lig": "greece",
    "İngiltere - Championship": "england", // Championship için de 'england' kullanılıyor
    "İtalya - Serie B": "italy",
    "Almanya - Bundesliga 2": "germany",
  };

  // YENİ: CSV'den gelen orijinal takım adını, yeni URL'deki dosya adına eşleştiren harita.
  // Dosya adları küçük harf ve boşluk yerine tire (-) içerecek şekilde güncellendi.
  static const Map<String, String> _teamFileNameMap = {
    // Türkiye
    'Fenerbahce': 'fenerbahce', 'Galatasaray': 'galatasaray', 'Besiktas': 'besiktas',
    'Trabzonspor': 'trabzonspor', 'Basaksehir': 'istanbul-basaksehir', 'Istanbulspor': 'istanbulspor',
    'Buyuksehyr': 'basaksehir', 'Ankaragucu': 'ankaragucu', 'Sivasspor': 'sivasspor',
    'Antalyaspor': 'antalyaspor', 'Gaziantep': 'gaziantep', 'Alanyaspor': 'alanyaspor',
    'Karagumruk': 'fatih-karagumruk', 'Kasimpasa': 'kasimpasa', 'Konyaspor': 'konyaspor',
    'Rizespor': 'rizespor', 'Samsunspor': 'samsunspor', 'Pendikspor': 'pendikspor', 'Hatayspor': 'hatayspor',
    'Kayserispor': 'kayserispor', 'Goztep': 'goztepe-izmir', 'Eyupspor': 'eyupspor', 'Bodrumspor': 'bodrum-fk',
    'Ad. Demirspor': 'adana-demirspor',

    // İngiltere
    'Man City': 'manchester-city', 'Man United': 'manchester-united', 'Arsenal': 'arsenal',
    'Liverpool': 'liverpool', 'Chelsea': 'chelsea', 'Tottenham': 'tottenham',
    'Newcastle': 'newcastle', 'West Ham': 'west-ham', 'Wolves': 'wolves',
    'Brighton': 'brighton', 'Aston Villa': 'aston-villa', 'Crystal Palace': 'crystal-palace',
    'Fulham': 'fulham', 'Bournemouth': 'bournemouth', 'Brentford': 'brentford', 'Everton': 'everton',
    'Nott\'m Forest': 'nottingham-forest', 'Leicester': 'leicester', 'Ipswich': 'ipswich', 'Southampton': 'southampton',

    // İspanya
    'Barcelona': 'barcelona', 'Real Madrid': 'real-madrid', 'Ath Madrid': 'atletico-madrid', 'Atletico Madrid': 'atletico-madrid',
    'Ath Bilbao': 'athletic-club-bilbao', 'Sevilla': 'sevilla-fc', 'Real Sociedad': 'real-sociedad',
    'Betis': 'real-betis', 'Villarreal': 'villarreal', 'Valencia': 'valencia', 'Celta': 'celta-vigo', 'Girona': 'girona',
    'Osasuna': 'ca-osasuna', 'Vallecano': 'rayo-vallecano', 'Mallorca': 'rcd-mallorca', 'Sociedad': 'real-sociedad', 'Alaves': 'deportivo-alaves',
    'Espanol': 'rcd-espanyol', 'Getafe': 'getafe', 'Leganes': 'cd-leganes', 'Las Palmas': 'ud-las-palmas', 'Valladolid': 'real-valladolid',

    // Almanya
    'Bayern Munich': 'bayern-munchen', 'Dortmund': 'borussia-dortmund', 'Leverkusen': 'bayer-leverkusen',
    'RB Leipzig': 'rb-leipzig', 'Stuttgart': 'vfb-stuttgart', 'Ein Frankfurt': 'eintracht-frankfurt',
    'Freiburg': 'freiburg', 'Hoffenheim': 'hoffenheim', 'Wolfsburg': 'wolfsburg',
    'M\'gladbach': 'borussia-monchengladbach', "Monchengladbach": 'borussia-monchengladbach',
    'Union Berlin': 'union-berlin', 'Mainz': 'mainz-05', 'Werder Bremen': 'werder-bremen', 'Augsburg': 'augsburg',
    'St Pauli': 'st-pauli', 'Heidenheim': 'fc-heidenheim', 'Bochum': 'vfl-bochum', 'Holstein Kiel': 'holstein-kiel',

    // İtalya
    'Inter': 'inter', 'Milan': 'milan', 'Juventus': 'juventus', 'Bologna': 'bologna',
    'Roma': 'roma', 'Lazio': 'lazio', 'Atalanta': 'atalanta', 'Napoli': 'napoli', 'Fiorentina': 'fiorentina',
    'Torino': 'torino', 'Monza': 'monza', 'Genoa': 'genoa', 'Como': 'como-1907', 'Udinese': 'udinese', 'Verona': 'verona',
    'Cagliari': 'cagliari', 'Parma': 'parma', 'Lecce': 'lecce', 'Empoli': 'empoli', 'Venezia': 'venezia',

    // Fransa
    'Paris SG': 'paris-saint-germain', 'Monaco': 'as-monaco', 'Lille': 'lille', 'Nice': 'nice',
    'Marseille': 'marseille', 'Lyon': 'lyon', 'Lens': 'rc-lens', 'Reims': 'stade-de-reims',
    'Rennes': 'rennes', 'Toulouse': 'toulouse', 'Strasbourg': 'rc-strasbourg-alsace', 'Nantes': 'nantes',
    'Auxerre': 'auxerre', 'Angers': 'angers', 'Le Havre': 'le-havre-ac', 'St Etienne': 'as-saint-etienne',
    'Brest': 'brest', 'Montpellier': 'montpellier',

    // Hollanda
    'PSV': 'psv', 'Feyenoord': 'feyenoord', 'Ajax': 'ajax',
    'AZ': 'az-alkmaar', 'Utrecht': 'fc-utrecht', 'Almere City': 'almere-city-fc', 'Twente': 'twente',
    'For Sittard': 'fortuna-sittard', 'Go Ahead Eagles': 'go-ahead-eagles', 'Groningen': 'fc-groningen', 'Heerenveen': 'sc-heerenveen',
    'Heracles': 'heracles-almelo', 'NAC Breda': 'nac-breda', 'Nijmegen': 'nec-nijmegen', 'Sparta Rotterdam': 'sparta-rotterdam',
    'Waalwijk': 'rkc-waalwijk', 'Willem II': 'willem-ii', 'Zwolle': 'pec-zwolle',

    // Portekiz
    'Sporting': 'sporting-cp', 'Benfica': 'benfica', 'Porto': 'fc-porto', 'Braga': 'sc-braga',

    // Belçika
    'Anderlecht': 'anderlecht', 'Club Brugge': 'club-brugge', 'St. Gilloise': 'union-saint-gilloise',
    'Genk': 'genk', 'Antwerp': 'antwerp',  'Beerschot VA': 'beerschot', 'Charleroi': 'charleroi',
    'Cercle Brugge': 'cercle-brugge', 'Gent': 'gent', 'Mechelen': 'mechelen', 'Standard': 'standard-liege', 'Oud-Heverlee Leuven': 'oud-heverlee-leuven',
    'Dender': 'fcv-dender-eh',  'St Truiden': 'sint-truiden', 'Kortrijk': 'kortrijk', 'Westerlo': 'westerlo',

    // İskoçya
    'Celtic': 'celtic', 'Rangers': 'rangers', 'Hearts': 'heart-of-midlothian',

    // Yunanistan
    'PAOK': 'paok', 'AEK': 'aek-athens', 'Olympiakos': 'olympiacos', 'Panathinaikos': 'panathinaikos'
  };

  // YENİ: URL oluşturma mantığı yeni yapıya göre güncellendi.
  static String? getTeamLogoUrl(String originalCsvTeamName, String appLeagueName) {
    // 1. Lig adından ülke adını al.
    final String? country = _leagueCountryMap[appLeagueName];
    if (country == null) {
      // print("LogoService: Eşleşen ülke bulunamadı: $appLeagueName");
      return null;
    }

    // 2. CSV'den gelen takım adından dosya adını al.
    String? teamFileName = _teamFileNameMap[originalCsvTeamName];
    
    // 3. Eğer doğrudan eşleşme yoksa, harita üzerinde kısmi bir eşleşme ara.
    teamFileName ??= _findPartialMatch(originalCsvTeamName);

    // 4. Hala dosya adı bulunamadıysa, URL oluşturma.
    if (teamFileName == null) {
      // print("LogoService: Eşleşen takım dosyası bulunamadı: $originalCsvTeamName");
      return null;
    }
    
    // 5. URL'yi oluştur. URL'de özel karakterler olmaması için encode et.
    final encodedCountry = Uri.encodeComponent(country);
    final encodedTeamFileName = Uri.encodeComponent(teamFileName);

    // Örnek URL: https://football-logos.cc/logos/spain/700x700/real-madrid.png
    return '$_baseUrl/$encodedCountry/700x700/$encodedTeamFileName.png';
  }

  // Yardımcı fonksiyon: CSV adının, haritadaki anahtarların bir parçası olup olmadığını kontrol eder.
  static String? _findPartialMatch(String originalCsvTeamName) {
    // Daha güvenilir bir eşleşme için küçük harfe çevir
    final searchName = originalCsvTeamName.toLowerCase();
    for (var entry in _teamFileNameMap.entries) {
      // Haritadaki anahtarı da küçük harfe çevirerek karşılaştır
      if (searchName.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }
}
