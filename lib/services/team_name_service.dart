// lib/services/team_name_service.dart
import 'package:unorm_dart/unorm_dart.dart' as unorm;
// utils.dart dosyasının doğru yolunu ekleyin.
// Eğer utils.dart, lib klasörünün doğrudan içindeyse:
import '../utils.dart';
// Eğer lib/utils klasöründeyse: import '../utils/utils.dart';

class TeamNameService {
  // Normalize fonksiyonu Türkçe karakterleri de hesaba katacak şekilde
  static String normalize(String text) {
    if (text.isEmpty) return "";
    try {
      String decomposed = unorm.nfkd(text);
      String removedAccents = decomposed.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
      return removedAccents.toLowerCase().trim();
    } catch (e) {
      // unorm ile ilgili bir sorun olursa basit bir fallback
      return text
          .toLowerCase()
          .replaceAll('ş', 's')
          .replaceAll('ç', 'c')
          .replaceAll('ğ', 'g')
          .replaceAll('ü', 'u')
          .replaceAll('ö', 'o')
          .replaceAll('ı', 'i')
          .trim();
    }
  }

  // Takma Adlar
  static const Map<String, String> takmaAdlar = {
    "psg": "paris saint germain", "fb": "fenerbahce", "gs": "galatasaray",
    "bjk": "besiktas", "ts": "trabzonspor", "fcb": "barcelona",
    "rma": "real madrid", "bvb": "borussia dortmund",
    // Buraya diğer yaygın kısaltmalar eklenebilir
  };

  // Takım Adı Düzeltme/Eşleştirme Map'i
  // Anahtar: Normalize edilmiş ham ad (CSV'den veya farklı kaynaklardan gelebilecek)
  // Değer: Uygulamada gösterilecek temiz ve doğru ad
  static final Map<String, String> _teamNameCorrections = {
    // Türkiye - Süper Lig Örnekleri
    'fenerbahce': 'Fenerbahçe', 'fenerbahce sk': 'Fenerbahçe', 'fenerbahce as': 'Fenerbahçe',
    'galatasaray': 'Galatasaray', 'galatasaray as': 'Galatasaray',
    'besiktas': 'Beşiktaş', 'besiktas jk': 'Beşiktaş',
    'trabzonspor': 'Trabzonspor', 'trabzonspor as': 'Trabzonspor',
    'basaksehir': 'Başakşehir', 'istanbul basaksehir': 'Başakşehir', 'ibfk': 'Başakşehir', 'buyuksehyr': 'Başakşehir', 'istanbul bb': 'Başakşehir', 'ramspark basaksehir': 'Başakşehir', 'medipol basaksehir': 'Başakşehir',
    'adana demirspor': 'Adana Demirspor', 'adanademir': 'Adana Demirspor', 'yukatel adana demirspor': 'Adana Demirspor', 'ad. demirspor': 'Adana Demirspor', 
    'konyaspor': 'Konyaspor', 'ittifak holding konyaspor': 'Konyaspor', 'atiker konyaspor': 'Konyaspor', 'arabam.com konyaspor': 'Konyaspor', 'torku konyaspor': 'Konyaspor',
    'kayserispor': 'Kayserispor', 'mondihome kayserispor': 'Kayserispor', 'hes kablo kayserispor': 'Kayserispor',
    'sivasspor': 'Sivasspor', 'demir grup sivasspor': 'Sivasspor', 'dg sivasspor': 'Sivasspor', 'ems yapasivasspor': 'Sivasspor',
    'antalyaspor': 'Antalyaspor', 'ft antalyaspor': 'Antalyaspor', 'fraport tav antalyaspor': 'Antalyaspor',
    'gaziantep': 'Gaziantep FK', 'gaziantep fk': 'Gaziantep FK', 'gaziantep bb': 'Gaziantep FK',
    'kasimpasa': 'Kasımpaşa', 'kasimpasa as': 'Kasımpaşa',
    'hatayspor': 'Hatayspor', 'atas hatayspor': 'Hatayspor', 'volkan demirel hatayspor': 'Hatayspor', // Sadece örnek
    'alanyaspor': 'Alanyaspor', 'aytemiz alanyaspor': 'Alanyaspor', 'corendon alanyaspor': 'Alanyaspor',
    'ankaragucu': 'Ankaragücü', 'mke ankaragucu': 'Ankaragücü',
    'istanbulspor': 'İstanbulspor', 'istanbulspor as': 'İstanbulspor',
    'umraniyespor': 'Ümraniyespor', 'hangikredi umraniyespor': 'Ümraniyespor',
    'giresunspor': 'Giresunspor', 'bitexen giresunspor': 'Giresunspor',
    'karagumruk': 'Karagümrük', 'fatih karagumruk': 'Karagümrük', 'vavacars fatih karagumruk': 'Karagümrük',
    'caykur rizespor': 'Çaykur Rizespor', 'rizespor': 'Çaykur Rizespor',
    'samsunspor': 'Samsunspor', 'yilport samsunspor': 'Samsunspor',
    'pendikspor': 'Pendikspor', 'siltaş yapı pendikspor': 'Pendikspor',
    'eyupspor': 'Eyüpspor',
    'goztepe': 'Göztepe', 'goztepeas': 'Göztepe', 'goztep': 'Göztepe', 'Goztep': 'Göztepe', 'Genclerbirligi': 'Gençlerbirliği',

    // İngiltere - Premier Lig Örnekleri
    'manchester city': 'Man. City', 'man city': 'Man. City', // Daha kısa
    'manchester utd': 'Man. United', 'man utd': 'Man. United', 'manchester united': 'Man. United', // Daha kısa
    'arsenal': 'Arsenal', 'arsenal fc': 'Arsenal',
    'liverpool': 'Liverpool', 'liverpool fc': 'Liverpool',
    'chelsea': 'Chelsea', 'chelsea fc': 'Chelsea',
    'tottenham': 'Tottenham', 'tottenham hotspur': 'Tottenham',
    'newcastle': 'Newcastle', 'newcastle utd': 'Newcastle', 'newcastle united': 'Newcastle',
    'brighton': 'Brighton', 'brighton & hove albion': 'Brighton', 'brighton hove albion': 'Brighton',
    'aston villa': 'Aston Villa',
    'brentford': 'Brentford',
    'fulham': 'Fulham',
    'crystal palace': 'Crystal Palace',
    'wolves': 'Wolves', 'wolverhampton wanderers': 'Wolves', 'wolverhampton': 'Wolves',
    'west ham': 'West Ham', 'west ham united': 'West Ham',
    'bournemouth': 'Bournemouth', 'afc bournemouth': 'Bournemouth',
    'nottingham forest': 'Nottm Forest', 'nottm forest': 'Nottm Forest', 'forest': 'Nottm Forest', // Kısa
    'everton': 'Everton',
    'leicester': 'Leicester', 'leicester city': 'Leicester',
    'leeds': 'Leeds', 'leeds united': 'Leeds',
    'southampton': 'Southampton',
    'burnley': 'Burnley',
    'sheffield utd': 'Sheffield Utd', 'sheffield united': 'Sheffield Utd', // Kısa
    'luton': 'Luton', 'luton town': 'Luton',

    // İspanya - La Liga Örnekleri
    'barcelona': 'Barcelona', 'fc barcelona': 'Barcelona',
    'real madrid': 'Real Madrid', 'real madrid cf': 'Real Madrid',
    'ath madrid': 'Atletico Madrid', 'atletico madrid': 'Atletico Madrid', 'atletico de madrid': 'Atletico Madrid', 
    'sevilla': 'Sevilla', 'sevilla fc': 'Sevilla',
    'real sociedad': 'Real Sociedad',
    'betis': 'Real Betis', 'real betis': 'Real Betis',
    'valencia': 'Valencia', 'valencia cf': 'Valencia',
    'ath bilbao': 'Athletic Bilbao', 'athletic club': 'Athletic Bilbao',
    'villarreal': 'Villarreal', 'villarreal cf': 'Villarreal',
    'celta vigo': 'Celta Vigo', 'rc celta': 'Celta Vigo',

    // Almanya - Bundesliga Örnekleri
    'bayern munich': 'Bayern Münih', 'bayern munchen': 'Bayern Münih', 'bayern': 'Bayern Münih', 'fc bayern munchen': 'Bayern Münih',
    'dortmund': 'Dortmund', 'borussia dortmund': 'Dortmund', 'bvb': 'Dortmund', // Kısa
    'leverkusen': 'Leverkusen', 'bayer leverkusen': 'Leverkusen', 'bayer 04 leverkusen': 'Leverkusen',
    'rb leipzig': 'RB Leipzig', 'leipzig': 'RB Leipzig',
    'eintracht frankfurt': 'E. Frankfurt', 'frankfurt': 'E. Frankfurt',
    'union berlin': 'Union Berlin', '1. fc union berlin': 'Union Berlin',
    'freiburg': 'Freiburg', 'sc freiburg': 'Freiburg',
    'wolfsburg': 'Wolfsburg', 'vfl wolfsburg': 'Wolfsburg',
    'mgladbach': 'Mönchengladbach', " Borussia Monchengladbach": 'Mönchengladbach', "m'gladbach": 'Mönchengladbach',
    'hoffenheim': 'Hoffenheim', 'tsg hoffenheim': 'Hoffenheim', '1899 hoffenheim': 'Hoffenheim',

    // İtalya - Serie A Örnekleri
    'juventus': 'Juventus', 'juventus fc': 'Juventus',
    'inter': 'Inter', 'inter milan': 'Inter', 'internazionale': 'Inter', // Kısa
    'milan': 'Milan', 'ac milan': 'Milan', // Kısa
    'roma': 'Roma', 'as roma': 'Roma', // Kısa
    'lazio': 'Lazio', 'ss lazio': 'Lazio',
    'napoli': 'Napoli', 'ssc napoli': 'Napoli',
    'atalanta': 'Atalanta', 'atalanta bc': 'Atalanta',
    'fiorentina': 'Fiorentina', 'acf fiorentina': 'Fiorentina',

    // Fransa - Ligue 1 Örnekleri
    'psg': 'PSG', 'paris sg': 'PSG', 'paris saint germain': 'PSG', 'paris saint-germain': 'PSG', // Kısa
    'marseille': 'Marseille', 'olympique de marseille': 'Marseille', 'om': 'Marseille',
    'lyon': 'Lyon', 'olympique lyonnais': 'Lyon', 'ol': 'Lyon',
    'monaco': 'Monaco', 'as monaco': 'Monaco',
    'lille': 'Lille', 'losc lille': 'Lille', 'losc': 'Lille',
    'nice': 'Nice', 'ogc nice': 'Nice',
    'rennes': 'Rennes', 'stade rennais': 'Rennes', 'stade rennais fc': 'Rennes',

    // Hollanda - Eredivisie
    'ajax': 'Ajax', 'ajax amsterdam': 'Ajax',
    'psv': 'PSV', 'psv eindhoven': 'PSV',
    'feyenoord': 'Feyenoord', 'feyenoord rotterdam': 'Feyenoord',
    'az alkmaar': 'AZ Alkmaar', 'az': 'AZ Alkmaar',
    'twente': 'FC Twente', 'fc twente': 'FC Twente',

    // Diğer ligler için de benzer şekilde genişletilebilir.
    // Önemli olan, CSV'den gelen normalize edilmiş adları buraya anahtar olarak eklemek.
  };

  static String getCorrectedTeamName(String rawTeamName) {
    if (rawTeamName.isEmpty) {
      // Eğer utils.dart'taki capitalizeFirstLetterOfWordsUtils boş stringi olduğu gibi döndürüyorsa
      // burada da boş string döndürmek mantıklı.
      return rawTeamName;
    }

    String normalizedInput = normalize(rawTeamName);

    // 1. Doğrudan _teamNameCorrections map'inde ara (normalize edilmiş ham ad ile)
    if (_teamNameCorrections.containsKey(normalizedInput)) {
      return _teamNameCorrections[normalizedInput]!;
    }

    // 2. Yaygın ekleri ve bazı sayıları temizleyip tekrar map'te ara
    String baseName = normalizedInput;
    final List<String> suffixesToRemove = [
      ' fk', ' fc', ' sk', ' as', ' cf', ' cd', ' sc', ' ac', ' jk', ' bb',
      ' 1903', ' 1905', ' 1907', ' 1908', ' 1910', ' 1912', ' 1923', ' 1899', ' 1888', ' 1886', ' 1860', ' 04', // Schalke 04 gibi
      'spor kulubu', 'futbol kulubu', 'jimnastik kulubu', 'athletic club', 'football club', 'sports club',
      ' united', ' city', ' wanderers', ' albion', ' hotspur', ' town', ' county', ' rovers', ' rangers',
      ' athletic', ' borussia', ' bayer', ' olympique', ' deportivo', ' sporting', ' stade',
      'spvgg', 'tsg', 'vfl', 'vfb', 'rwdm', 'kv', ' cercle', ' krc',
      ' belediyesi', ' buyuksehir belediyesi', ' bs',
      // Sponsor isimleri (çok değişken olduğu için dikkatli eklenmeli veya map'e tam adıyla girilmeli)
      // 'ittifak holding', 'demir grup', 'aytemiz', 'corendon', 'hes kablo', 'vavacars', 'bitexen', 'hangikredi', 'siltaş yapı', 'yilport', 'mondihome', 'ramspark', 'medipol', 'fraport tav'
    ];

    final List<String> prefixesToRemove = [
      'fc ', 'ac ', 'sc ', 'cd ', 'as ', 'afc ', 'cf ', 'rc ', '1. fc ', 'vfl ', 'vfb ', 'tsg ', 'spvgg ', 'kv ', 'kfc ', 'k ', 'rwd ',
      'real ', 'olympique ', 'borussia ', 'bayer ', 'deportivo ', 'sporting ', 'stade ', 'as '
    ];

    // Önce sonekleri temizle
    for (String suffix in suffixesToRemove) {
      if (baseName.endsWith(suffix)) {
        String tempName = baseName.substring(0, baseName.length - suffix.length).trim();
        if (_teamNameCorrections.containsKey(tempName)) {
          return _teamNameCorrections[tempName]!;
        }
        // Eğer temizlenmiş hali map'te yoksa, baseName'i bu temizlenmiş halle güncelle
        // ve sonraki prefix temizliğine bu temizlenmiş halle devam et.
        // baseName = tempName; // Bu, zincirleme temizlik yapar. Şimdilik devre dışı.
      }
    }

    // Sonra önekleri temizle (sonekler temizlendikten sonraki baseName üzerinden)
    // Ya da orijinal normalize edilmiş addan ayrı ayrı dene
    String prefixCleanedName = normalizedInput; // Orijinalden başla
    for (String prefix in prefixesToRemove) {
      if (prefixCleanedName.startsWith(prefix)) {
        String tempName = prefixCleanedName.substring(prefix.length).trim();
        if (_teamNameCorrections.containsKey(tempName)) {
          return _teamNameCorrections[tempName]!;
        }
      }
    }
    
    // Hem prefix hem suffix temizlenmiş halini de dene (eğer yukarıda zincirleme yapmadıysak)
    String fullyCleanedName = normalizedInput;
    for (String prefix in prefixesToRemove) {
        if (fullyCleanedName.startsWith(prefix)) {
            fullyCleanedName = fullyCleanedName.substring(prefix.length).trim();
        }
    }
    for (String suffix in suffixesToRemove) {
        if (fullyCleanedName.endsWith(suffix)) {
            fullyCleanedName = fullyCleanedName.substring(0, fullyCleanedName.length - suffix.length).trim();
        }
    }
    if (fullyCleanedName != normalizedInput && _teamNameCorrections.containsKey(fullyCleanedName)) {
        return _teamNameCorrections[fullyCleanedName]!;
    }


    // 3. TAKMA_ADLAR map'ini kontrol et
    if (takmaAdlar.containsKey(normalizedInput)) {
      String potentialFullName = takmaAdlar[normalizedInput]!;
      String normalizedPotentialFullName = normalize(potentialFullName);
      if (_teamNameCorrections.containsKey(normalizedPotentialFullName)) {
        return _teamNameCorrections[normalizedPotentialFullName]!;
      }
      // Takma addan dönen ismi de sadeleştirmeye çalışabiliriz.
      // Ama şimdilik direkt capitalize edip verelim.
      return capitalizeFirstLetterOfWordsUtils(potentialFullName);
    }

    // 4. Hiçbir düzeltme bulunamazsa, kelimelerin baş harflerini büyüterek orijinal ham adı döndür
    // Bu, CSV'den gelen ve map'lerimizde olmayan ama zaten düzgün olan adlar için çalışır.
    return capitalizeFirstLetterOfWordsUtils(rawTeamName);
  }
}