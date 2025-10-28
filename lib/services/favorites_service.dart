// lib/services/favorites_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile_service.dart';
import '../models/user_profile_model.dart';
import '../utils/activity_logger.dart';
import 'auth_service.dart';

// NOT: Bu servis artık doğrudan veri yazmaz.
// Tüm işlemler UserProfileService üzerinden yapılır.

class FavoritesService {
  final UserProfileService _userProfileService = UserProfileService();
  static const String _localFavoritesKey = 'local_favorite_teams';
  static const String _localSupportedTeamKey = 'local_supported_team';

  // Favori takımları getirir (giriş yapmış kullanıcılar için Firebase, yapmamış için local)
  Future<List<FavoriteTeam>> getFavoriteTeams() async {
    if (AuthService.isSignedIn) {
      // Giriş yapmış kullanıcı - Firebase'den çek
      final profile = await _userProfileService.loadUserProfile();
      return profile?.favoriteTeams ?? [];
    } else {
      // Giriş yapmamış kullanıcı - local'den çek
      return await _getLocalFavoriteTeams();
    }
  }

  // Local favori takımları getirir
  Future<List<FavoriteTeam>> _getLocalFavoriteTeams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_localFavoritesKey);
      if (favoritesJson != null) {
        final favoritesList = json.decode(favoritesJson) as List;
        return favoritesList.map((item) => FavoriteTeam.fromMap(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('Local favori takımlar yüklenirken hata: $e');
    }
    return [];
  }

  // Local favori takımları kaydeder
  Future<void> _saveLocalFavoriteTeams(List<FavoriteTeam> teams) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teamsJson = json.encode(teams.map((team) => team.toMap()).toList());
      await prefs.setString(_localFavoritesKey, teamsJson);
    } catch (e) {
      print('Local favori takımlar kaydedilirken hata: $e');
    }
  }

  // Favori takım ekler
  Future<void> addFavoriteTeam(String teamName, String league, String season) async {
    final team = FavoriteTeam(name: teamName, league: league, season: season, logoUrl: '');
    
    if (AuthService.isSignedIn) {
      // Giriş yapmış kullanıcı - Firebase'e kaydet
      await _userProfileService.addFavoriteTeam(team);
    } else {
      // Giriş yapmamış kullanıcı - local'e kaydet
      final currentFavorites = await _getLocalFavoriteTeams();
      if (!currentFavorites.any((t) => t.name == teamName)) {
        currentFavorites.add(team);
        await _saveLocalFavoriteTeams(currentFavorites);
      }
    }
    
    await ActivityLogger.logFavoriteTeamAdded(teamName, league);
  }

  // Favori takımı kaldırır
  Future<void> removeFavoriteTeam(String teamName) async {
    // Önce takım bilgilerini al
    final favorites = await getFavoriteTeams();
    final team = favorites.firstWhere((t) => t.name == teamName, orElse: () => FavoriteTeam(name: teamName, league: 'Bilinmiyor', season: '2024-25'));
    
    if (AuthService.isSignedIn) {
      // Giriş yapmış kullanıcı - Firebase'den kaldır
      await _userProfileService.removeFavoriteTeam(teamName);
    } else {
      // Giriş yapmamış kullanıcı - local'den kaldır
      final currentFavorites = await _getLocalFavoriteTeams();
      final updatedFavorites = currentFavorites.where((t) => t.name != teamName).toList();
      await _saveLocalFavoriteTeams(updatedFavorites);
    }
    
    await ActivityLogger.logFavoriteTeamRemoved(teamName, team.league);
  }

  // Bir takımın favori olup olmadığını kontrol eder.
  Future<bool> isFavoriteTeam(String teamName) async {
    final favorites = await getFavoriteTeams();
    return favorites.any((team) => team.name == teamName);
  }

  // Desteklenen takımı ayarlar
  Future<void> setSupportedTeam(FavoriteTeam? team) async {
    if (AuthService.isSignedIn) {
      // Giriş yapmış kullanıcı - Firebase'e kaydet
      await _userProfileService.setSupportedTeam(team);
    } else {
      // Giriş yapmamış kullanıcı - local'e kaydet
      final prefs = await SharedPreferences.getInstance();
      if (team != null) {
        await prefs.setString(_localSupportedTeamKey, json.encode(team.toMap()));
      } else {
        await prefs.remove(_localSupportedTeamKey);
      }
    }
    
    if (team != null) {
      await ActivityLogger.logSupportedTeamSelected(team.name, team.league);
    }
  }

  // Desteklenen takımı getirir
  Future<FavoriteTeam?> getSupportedTeam() async {
    if (AuthService.isSignedIn) {
      // Giriş yapmış kullanıcı - Firebase'den çek
      final profile = await _userProfileService.loadUserProfile();
      return profile?.supportedTeam;
    } else {
      // Giriş yapmamış kullanıcı - local'den çek
      try {
        final prefs = await SharedPreferences.getInstance();
        final teamJson = prefs.getString(_localSupportedTeamKey);
        if (teamJson != null) {
          return FavoriteTeam.fromMap(json.decode(teamJson) as Map<String, dynamic>);
        }
      } catch (e) {
        print('Local desteklenen takım yüklenirken hata: $e');
      }
      return null;
    }
  }

  // Favori takım sayısını getirir.
  Future<int> getFavoriteTeamsCount() async {
    final favorites = await getFavoriteTeams();
    return favorites.length;
  }

  // Favori ligi ayarlamak için UserProfileService'i kullanır.
  Future<void> setFavoriteLeague(String league) async {
    await _userProfileService.setFavoriteLeague(league);
  }

  // Favori ligi merkezi profilden getirir.
  Future<String?> getFavoriteLeague() async {
    final profile = await _userProfileService.loadUserProfile();
    return profile?.favoriteLeague;
  }

  // Static method'lar - geriye dönük uyumluluk için
  static Future<FavoriteTeam?> getStaticSupportedTeam() async {
    final service = FavoritesService();
    return await service.getSupportedTeam();
  }

  static Future<void> setStaticSupportedTeam(FavoriteTeam? team) async {
    final service = FavoritesService();
    await service.setSupportedTeam(team);
  }

  static Future<int> getStaticFavoriteTeamsCount() async {
    final service = FavoritesService();
    return await service.getFavoriteTeamsCount();
  }
}
