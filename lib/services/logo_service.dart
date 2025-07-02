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

  // YENİ EKLENEN HARİTA: Uygulamadaki lig adını, URL'deki lig logosu dosya adına eşleştirir.
  static const Map<String, String> _leagueLogoFileNameMap = {
    "Türkiye - Süper Lig": "super-lig",
    // GÜNCELLEME: Premier Lig dosya adı düzeltildi.
    "İngiltere - Premier Lig": "english-premier-league-v2",
    "İspanya - La Liga": "la-liga",
    "Almanya - Bundesliga": "bundesliga",
    "İtalya - Serie A": "serie-a",
    "Fransa - Ligue 1": "ligue-1",
    "Hollanda - Eredivisie": "eredivisie",
    "Portekiz - Premier Lig": "primeira-liga",
    // GÜNCELLEME: Belçika Pro Lig dosya adı düzeltildi.
    "Belçika - Pro Lig": "belgian-pro-league",
    "İskoçya - Premiership": "scottish-premiership-v2",
    "Yunanistan - Süper Lig": "super-league-greece",
    "İngiltere - Championship": "championship",
    "İtalya - Serie B": "serie-b",
    "Almanya - Bundesliga 2": "2-bundesliga",
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

    // İngiltere - Championship (E1.csv)
    'Blackburn': 'blackburn-rovers', 'Bristol City': 'bristol-city', 'Burnley': 'burnley-fc', 'Cardiff': 'cardiff-city',
    'Coventry': 'coventry-city', 'Huddersfield': 'huddersfield-town', 'Hull': 'hull-city', 'Luton': 'luton-town',
    'Middlesbrough': 'middlesbrough-fc', 'Millwall': 'millwall-fc', 'Norwich': 'norwich-city', 'Preston': 'preston-north-end',
    'QPR': 'queens-park-rangers', 'Reading': 'reading-fc', 'Rotherham': 'rotherham-united', 'Sheffield United': 'sheffield-united',
    'Stoke': 'stoke-city', 'Sunderland': 'sunderland-afc', 'Swansea': 'swansea-city', 'Watford': 'watford-fc',
    'West Brom': 'west-bromwich-albion', 'Wigan': 'wigan-athletic',

    // İspanya
    'Barcelona': 'barcelona', 'Real Madrid': 'real-madrid', 'Ath Madrid': 'atletico-madrid', 'Atletico Madrid': 'atletico-madrid',
    'Ath Bilbao': 'athletic-club', 'Sevilla': 'sevilla', 'Real Sociedad': 'real-sociedad',
    'Betis': 'real-betis', 'Villarreal': 'villarreal', 'Valencia': 'valencia', 'Celta': 'celta', 'Girona': 'girona',
    'Osasuna': 'osasuna', 'Vallecano': 'rayo-vallecano', 'Mallorca': 'mallorca', 'Sociedad': 'real-sociedad', 'Alaves': 'deportivo',
    'Espanol': 'espanyol', 'Getafe': 'getafe', 'Leganes': 'leganes', 'Las Palmas': 'las-palmas', 'Valladolid': 'valladolid',

    // Almanya
    'Bayern Munich': 'bayern-munchen', 'Dortmund': 'borussia-dortmund', 'Leverkusen': 'bayer-leverkusen',
    'RB Leipzig': 'rb-leipzig', 'Stuttgart': 'vfb-stuttgart', 'Ein Frankfurt': 'eintracht-frankfurt',
    'Freiburg': 'freiburg', 'Hoffenheim': 'hoffenheim', 'Wolfsburg': 'wolfsburg',
    'M\'gladbach': 'borussia-monchengladbach', "Monchengladbach": 'borussia-monchengladbach',
    'Union Berlin': 'union-berlin', 'Mainz': 'mainz-05', 'Werder Bremen': 'werder-bremen', 'Augsburg': 'augsburg',
    'St Pauli': 'st-pauli', 'Heidenheim': 'fc-heidenheim', 'Bochum': 'vfl-bochum', 'Holstein Kiel': 'holstein-kiel',

    // Almanya - Bundesliga 2 (D2.csv)
    'Arminia Bielefeld': 'arminia-bielefeld', 'Braunschweig': 'eintracht-braunschweig', 'Darmstadt': 'sv-darmstadt-98',
    'Dusseldorf': 'fortuna-dusseldorf', 'Greuther Furth': 'spvgg-greuther-furth', 'Hamburg': 'hamburger-sv',
    'Hannover': 'hannover-96', 'Hansa Rostock': 'hansa-rostock', 'Kaiserslautern': '1-fc-kaiserslautern',
    'Karlsruher': 'karlsruher-sc', 'Magdeburg': '1-fc-magdeburg', 'Nurnberg': '1-fc-nurnberg',
    'Paderborn': 'sc-paderborn-07', 'Regensburg': 'jahn-regensburg', 'Sandhausen': 'sv-sandhausen',

    // İtalya
    'Inter': 'inter', 'Milan': 'milan', 'Juventus': 'juventus', 'Bologna': 'bologna',
    'Roma': 'roma', 'Lazio': 'lazio', 'Atalanta': 'atalanta', 'Napoli': 'napoli', 'Fiorentina': 'fiorentina',
    'Torino': 'torino', 'Monza': 'monza', 'Genoa': 'genoa', 'Como': 'como-1907', 'Udinese': 'udinese', 'Verona': 'verona',
    'Cagliari': 'cagliari', 'Parma': 'parma', 'Lecce': 'lecce', 'Empoli': 'empoli', 'Venezia': 'venezia',

    // İtalya - Serie B (I2.csv)
    'Ascoli': 'ascoli-calcio-1898', 'Bari': 'ssc-bari', 'Benevento': 'benevento-calcio', 'Brescia': 'brescia-calcio',
    'Cittadella': 'as-cittadella', 'Cosenza': 'cosenza-calcio', 'Frosinone': 'frosinone-calcio', 'Modena': 'modena-fc-2018',
    'Palermo': 'palermo-fc', 'Perugia': 'ac-perugia-calcio', 'Pisa': 'pisa-sc', 'Reggina': 'reggina-1914',
    'Spal': 'spal', 'Sudtirol': 'fc-sudtirol', 'Ternana': 'ternana-calcio',

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

    // Portekiz (P1.csv)
    'Sp Lisbon': 'sporting-cp', 'Benfica': 'benfica', 'Porto': 'fc-porto', 'Braga': 'sc-braga',
    'Arouca': 'arouca', 'Boavista': 'boavista', 'Casa Pia': 'casa-pia-ac', 'Chaves': 'gd-chaves',
    'Estoril': 'estoril', 'Famalicao': 'famalicao', 'Gil Vicente': 'gil-vicente', 'Guimaraes': 'vitoria-de-guimaraes',
    'Moreirense': 'moreirense', 'Portimonense': 'portimonense-sc', 'Rio Ave': 'rio-ave', 'Santa Clara': 'santa-clara',
    'Vizela': 'vizela', 'Farense': 'farense', 'AVS': 'avs-futebol-sad', 'Estrela': 'estrela-da-amadora',

    // Belçika
    'Anderlecht': 'anderlecht', 'Club Brugge': 'club-brugge', 'St. Gilloise': 'union-saint-gilloise',
    'Genk': 'genk', 'Antwerp': 'antwerp',  'Beerschot VA': 'beerschot', 'Charleroi': 'charleroi',
    'Cercle Brugge': 'cercle-brugge', 'Gent': 'gent', 'Mechelen': 'mechelen', 'Standard': 'standard-liege', 'Oud-Heverlee Leuven': 'oud-heverlee-leuven',
    'Dender': 'fcv-dender-eh',  'St Truiden': 'sint-truiden', 'Kortrijk': 'kortrijk', 'Westerlo': 'westerlo',

    // İskoçya (SC0.csv)
    'Celtic': 'celtic', 'Rangers': 'rangers', 'Hearts': 'hearts',
    'Aberdeen': 'aberdeen', 'Dundee': 'dundee', 'Dundee United': 'dundee-united', 'Hibernian': 'hibernian',
    'Kilmarnock': 'kilmarnock', 'Livingston': 'livingstonc', 'Motherwell': 'motherwell', 'Ross County': 'ross-county',
    'St Johnstone': 'st-johnstone', 'St Mirren': 'st-mirren',

    // Yunanistan (G1.csv)
    'PAOK': 'paok', 'AEK': 'aek-athens', 'Olympiakos': 'olympiacos', 'Panathinaikos': 'panathinaikos',
    'Aris': 'aris-thessaloniki', 'Asteras Tripolis': 'asteras-tripolis', 'Atromitos': 'atromitos',
    'Ionikos': 'ionikos', 'Lamia-': 'pas-lamia-1964', '-Levadeiakos': 'levadeiakos', 'OFI Crete': 'ofi',
    'Panetolikos': 'panetolikos', 'PAS Giannina': 'pas-giannina', 'Volos': 'volos'
  };

  // YENİ EKLENEN FONKSİYON: Lig logosu URL'sini oluşturur.
  static String? getLeagueLogoUrl(String appLeagueName) {
    final String? country = _leagueCountryMap[appLeagueName];
    final String? leagueFileName = _leagueLogoFileNameMap[appLeagueName];

    if (country == null || leagueFileName == null) {
      return null; // Eşleşme bulunamazsa null döndür.
    }

    final encodedCountry = Uri.encodeComponent(country);
    final encodedLeagueFileName = Uri.encodeComponent(leagueFileName);

    return '$_baseUrl/$encodedCountry/700x700/$encodedLeagueFileName.png';
  }

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
