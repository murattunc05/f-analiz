// lib/utils/activity_logger.dart
import '../services/user_service.dart';
import '../services/analytics_service.dart';

class ActivityLogger {
  // Takım analizi aktivitesi
  static Future<void> logTeamAnalysis(String teamName, String league) async {
    try {
      await UserService.addActivity('$teamName ($league) takımı analiz edildi');
      await UserService.updateStats(totalAnalysis: 1);
      await AnalyticsService.incrementTeamAnalysis(teamName, league);
    } catch (e) {
      print('Aktivite kaydedilirken hata: $e');
    }
  }

  // Takım karşılaştırması aktivitesi
  static Future<void> logTeamComparison(String team1, String team2, String league) async {
    try {
      print('ActivityLogger: Karşılaştırma kaydediliyor - $team1 vs $team2 ($league)');
      await UserService.addActivity('$team1 vs $team2 ($league) karşılaştırıldı');
      await UserService.updateStats(totalComparisons: 1);
      await AnalyticsService.incrementComparison(team1, team2);
      print('ActivityLogger: Karşılaştırma başarıyla kaydedildi');
    } catch (e) {
      print('Aktivite kaydedilirken hata: $e');
    }
  }

  // Favori takım ekleme aktivitesi
  static Future<void> logFavoriteTeamAdded(String teamName, String league) async {
    try {
      await UserService.addActivity('$teamName ($league) favorilere eklendi');
    } catch (e) {
      print('Aktivite kaydedilirken hata: $e');
    }
  }

  // Favori takım kaldırma aktivitesi
  static Future<void> logFavoriteTeamRemoved(String teamName, String league) async {
    try {
      await UserService.addActivity('$teamName ($league) favorilerden kaldırıldı');
    } catch (e) {
      print('Aktivite kaydedilirken hata: $e');
    }
  }

  // Tuttuğu takım seçme aktivitesi
  static Future<void> logSupportedTeamSelected(String teamName, String league) async {
    try {
      await UserService.addActivity('$teamName ($league) tuttuğu takım olarak seçildi');
    } catch (e) {
      print('Aktivite kaydedilirken hata: $e');
    }
  }

  // Favori lig seçme aktivitesi
  static Future<void> logFavoriteLeagueSelected(String league) async {
    try {
      await UserService.addActivity('$league favori lig olarak seçildi');
    } catch (e) {
      print('Aktivite kaydedilirken hata: $e');
    }
  }

  // Genel aktivite ekleme
  static Future<void> logActivity(String activity) async {
    try {
      await UserService.addActivity(activity);
    } catch (e) {
      print('Aktivite kaydedilirken hata: $e');
    }
  }
}