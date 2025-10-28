// lib/services/league_logo_service.dart
import 'logo_service.dart';

class LeagueLogoService {
  /// Lig adından logo URL'sini döndürür
  /// LogoService'den lig logosu URL'sini çeker
  /// Eğer lig bulunamazsa null döndürür
  static String? getLeagueLogo(String leagueName) {
    return LogoService.getLeagueLogoUrl(leagueName);
  }

  /// Tüm mevcut ligleri döndürür
  /// DataService'deki mevcut liglerle uyumlu
  static List<String> getAvailableLeagues() {
    return [
      "Türkiye - Süper Lig",
      "İngiltere - Premier Lig", 
      "İspanya - La Liga",
      "Almanya - Bundesliga",
      "İtalya - Serie A",
      "Fransa - Ligue 1",
      "Hollanda - Eredivisie",
      "Belçika - Pro Lig",
      "Portekiz - Premier Lig",
      "İskoçya - Premiership",
      "Yunanistan - Süper Lig",
      "İngiltere - Championship",
      "İtalya - Serie B",
      "Almanya - Bundesliga 2",
    ];
  }

  /// Lig adının logo URL'si olup olmadığını kontrol eder
  static bool hasLogo(String leagueName) {
    return getLeagueLogo(leagueName) != null;
  }
}