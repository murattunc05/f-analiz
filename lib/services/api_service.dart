// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  final String _baseUrl = 'https://v3.football.api-sports.io';
  // API Token'ınızı buraya girin. Güvenlik için bu token'ı koddan ayırmak (örn: environment variables) daha iyidir.
  final String _apiToken = '2573c2e78a906e703f9e8fd1862686e0'; 

  Map<String, String> get _headers => {
        'x-rapidapi-host': 'v3.football.api-sports.io',
        'x-rapidapi-key': _apiToken,
      };

  // DEĞİŞİKLİK: Metot public yapıldı (_get -> get)
  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['errors'] != null && data['errors'].isNotEmpty && data['errors'] is! List) {
        if (data['errors']['requests'] != null) {
          throw Exception('API Limit Hatası: ${data['errors']['requests']}');
        }
        throw Exception('API Hatası: ${data['errors']}');
      }
      if (data['response'] == null || data['response'] is! List) {
        throw Exception("API'den beklenen formatta veri gelmedi.");
      }
      return data['response'];
    } else {
      debugPrint('API Hatası: ${response.statusCode} - ${response.body}');
      throw Exception('Veri alınamadı. Hata Kodu: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getMatchesForDate(DateTime date) async {
    // Tarih formatlamasının UTC'ye göre yapıldığından emin olalım
    final String dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return await get('fixtures?date=$dateString');
  }

  Future<List<dynamic>> getAvailableCompetitions() async {
    final allCompetitions = await get('leagues');
    
    return (allCompetitions as List)
        .map((item) {
          if (item is Map && 
              item.containsKey('league') && item['league'] is Map &&
              item.containsKey('country') && item['country'] is Map) {
            return {
              'id': item['league']['id'],
              'name': item['league']['name'],
              'country': {
                'name': item['country']['name'],
                'flag': item['country']['flag']
              },
              'logo': item['league']['logo'],
            };
          }
          return null;
        })
        .where((item) => item != null)
        .toList()
        .cast<Map<String, dynamic>>();
  }

  Future<List<dynamic>> getFullFixtureDetails(int fixtureId) async {
    return await get('fixtures?id=$fixtureId');
  }
}