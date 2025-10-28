// lib/services/analytics_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'auth_service.dart';
import 'firebase_sync_service.dart';

class AnalyticsService {
  static const String _analyticsKey = 'user_analytics';
  
  // Analytics data structure
  static const String _totalAnalysisKey = 'totalAnalysis';
  static const String _totalComparisonsKey = 'totalComparisons';
  static const String _recentActivitiesKey = 'recentActivities';
  
  // Get current analytics data
  static Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = AuthService.currentUser?.uid;
      
      if (userId == null) {
        // Guest user - use local storage
        print('Loading analytics for GUEST user with key: $_analyticsKey');
        final analyticsJson = prefs.getString(_analyticsKey);
        if (analyticsJson != null) {
          final data = json.decode(analyticsJson) as Map<String, dynamic>;
          print('Guest analytics loaded: ${data[_recentActivitiesKey]}');
          return data;
        }
      } else {
        // Authenticated user - use user-specific key
        final userAnalyticsKey = '${_analyticsKey}_$userId';
        print('Loading analytics for AUTHENTICATED user with key: $userAnalyticsKey');
        final analyticsJson = prefs.getString(userAnalyticsKey);
        if (analyticsJson != null) {
          final data = json.decode(analyticsJson) as Map<String, dynamic>;
          print('Authenticated analytics loaded: ${data[_recentActivitiesKey]}');
          return data;
        }
      }
      
      // Return default values
      return {
        _totalAnalysisKey: 0,
        _totalComparisonsKey: 0,
        _recentActivitiesKey: <Map<String, dynamic>>[],
      };
    } catch (e) {
      print('Error getting analytics: $e');
      return {
        _totalAnalysisKey: 0,
        _totalComparisonsKey: 0,
        _recentActivitiesKey: <Map<String, dynamic>>[],
      };
    }
  }
  
  // Save analytics data
  static Future<void> _saveAnalytics(Map<String, dynamic> analytics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = AuthService.currentUser?.uid;
      
      final analyticsJson = json.encode(analytics);
      
      if (userId == null) {
        // Guest user
        await prefs.setString(_analyticsKey, analyticsJson);
        print('Analytics saved for GUEST user with key: $_analyticsKey');
      } else {
        // Authenticated user
        final userAnalyticsKey = '${_analyticsKey}_$userId';
        await prefs.setString(userAnalyticsKey, analyticsJson);
        print('Analytics saved for AUTHENTICATED user with key: $userAnalyticsKey');
      }
      
      print('Analytics saved successfully');
      print('Analytics data: ${analytics[_recentActivitiesKey]}');
    } catch (e) {
      print('Error saving analytics: $e');
    }
  }
  
  // Increment team analysis count
  static Future<void> incrementTeamAnalysis(String teamName, String league) async {
    try {
      final analytics = await getAnalytics();
      
      // Increment total analysis count
      analytics[_totalAnalysisKey] = (analytics[_totalAnalysisKey] ?? 0) + 1;
      
      // Add to recent activities
      final activities = List<Map<String, dynamic>>.from(analytics[_recentActivitiesKey] ?? []);
      activities.insert(0, {
        'type': 'analysis',
        'title': 'Takım Analizi',
        'description': '$teamName analiz edildi',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'league': league,
        'team': teamName,
      });
      
      // Keep only last 10 activities
      if (activities.length > 10) {
        activities.removeRange(10, activities.length);
      }
      
      analytics[_recentActivitiesKey] = activities;
      
      await _saveAnalytics(analytics);
      
      // Firebase'e senkronize et - deprecated
      // if (AuthService.isSignedIn) {
      //   await FirebaseSyncService.syncAnalytics();
      // }
    } catch (e) {
      print('Error incrementing team analysis: $e');
    }
  }
  
  // Increment comparison count
  static Future<void> incrementComparison(String team1, String team2) async {
    try {
      final analytics = await getAnalytics();
      
      // Increment total comparison count
      analytics[_totalComparisonsKey] = (analytics[_totalComparisonsKey] ?? 0) + 1;
      
      // Add to recent activities
      final activities = List<Map<String, dynamic>>.from(analytics[_recentActivitiesKey] ?? []);
      activities.insert(0, {
        'type': 'comparison',
        'title': 'Takım Karşılaştırması',
        'description': '$team1 vs $team2',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'team1': team1,
        'team2': team2,
      });
      
      // Keep only last 10 activities
      if (activities.length > 10) {
        activities.removeRange(10, activities.length);
      }
      
      analytics[_recentActivitiesKey] = activities;
      
      await _saveAnalytics(analytics);
      
      print('AnalyticsService: Karşılaştırma aktivitesi kaydedildi - $team1 vs $team2');
      print('AnalyticsService: Toplam aktivite sayısı: ${activities.length}');
      
      // Firebase'e senkronize et - deprecated
      // if (AuthService.isSignedIn) {
      //   await FirebaseSyncService.syncAnalytics();
      // }
    } catch (e) {
      print('Error incrementing comparison: $e');
    }
  }
  
  // Get total analysis count
  static Future<int> getTotalAnalysisCount() async {
    final analytics = await getAnalytics();
    return analytics[_totalAnalysisKey] ?? 0;
  }
  
  // Get total comparison count
  static Future<int> getTotalComparisonCount() async {
    final analytics = await getAnalytics();
    return analytics[_totalComparisonsKey] ?? 0;
  }
  
  // Get recent activities
  static Future<List<Map<String, String>>> getRecentActivities() async {
    final analytics = await getAnalytics();
    final rawActivities = analytics[_recentActivitiesKey] ?? [];
    
    return (rawActivities as List).map<Map<String, String>>((activity) {
      final activityMap = activity as Map<String, dynamic>;
      return {
        'description': (activityMap['description'] ?? '').toString(),
        'timestamp': (activityMap['timestamp'] ?? '').toString(),
        'type': (activityMap['type'] ?? '').toString(),
        'title': (activityMap['title'] ?? '').toString(),
      };
    }).toList();
  }
  
  // Clear analytics (for logout)
  static Future<void> clearAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = AuthService.currentUser?.uid;
      
      if (userId == null) {
        await prefs.remove(_analyticsKey);
      } else {
        final userAnalyticsKey = '${_analyticsKey}_$userId';
        await prefs.remove(userAnalyticsKey);
      }
      
      print('Analytics cleared');
    } catch (e) {
      print('Error clearing analytics: $e');
    }
  }
  
  // Migrate guest analytics to authenticated user
  static Future<void> migrateGuestAnalytics() async {
    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final guestAnalyticsJson = prefs.getString(_analyticsKey);
      
      if (guestAnalyticsJson != null) {
        // Move guest analytics to user-specific key
        final userAnalyticsKey = '${_analyticsKey}_$userId';
        await prefs.setString(userAnalyticsKey, guestAnalyticsJson);
        await prefs.remove(_analyticsKey);
        
        print('Guest analytics migrated to user account');
      }
    } catch (e) {
      print('Error migrating guest analytics: $e');
    }
  }
}