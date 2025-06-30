// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// YENİ: Önbellek verisini ve zaman damgasını tutacak bir sınıf
class _ApiCacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _ApiCacheEntry({required this.data, required this.timestamp});
}

class ApiService {
  final String _baseUrl = 'https://v3.football.api-sports.io';
  final String _apiToken = '2573c2e78a906e703f9e8fd1862686e0'; 

  // --- YENİ: ÖNBELLEKLEME MEKANİZMASI ---
  final Map<String, _ApiCacheEntry> _cache = {};
  // Statik veriler için önbellek süresi (örn: ligler, fikstür detayları)
  // 6 saat makul bir süre.
  static const Duration _cacheDuration = Duration(hours: 6);
  // ------------------------------------

  Map<String, String> get _headers => {
        'x-rapidapi-host': 'v3.football.api-sports.io',
        'x-rapidapi-key': _apiToken,
      };

  // DEĞİŞİKLİK: Metot imzasına isteğe bağlı 'enableCache' parametresi eklendi.
  // Bu sayede canlı maçlar gibi verileri önbelleğe almadan çekebileceğiz.
  Future<dynamic> get(String endpoint, {bool enableCache = true}) async {
    // --- YENİ: ÖNBELLEK KONTROLÜ ---
    if (enableCache && _cache.containsKey(endpoint)) {
      final cacheEntry = _cache[endpoint]!;
      if (DateTime.now().difference(cacheEntry.timestamp) < _cacheDuration) {
        debugPrint('CACHE HIT: Veri önbellekten alındı - Endpoint: $endpoint');
        return cacheEntry.data; // Veri taze, doğrudan önbellekten döndür.
      } else {
        _cache.remove(endpoint); // Veri eski, önbellekten sil.
        debugPrint('CACHE EXPIRED: Eski veri önbellekten silindi - Endpoint: $endpoint');
      }
    }
    debugPrint('CACHE MISS: Veri ağdan çekiliyor - Endpoint: $endpoint');
    // --------------------------------

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
      final responseData = data['response'];

      // --- YENİ: BAŞARILI İSTEĞİ ÖNBELLEĞE KAYDETME ---
      if (enableCache) {
        _cache[endpoint] = _ApiCacheEntry(data: responseData, timestamp: DateTime.now());
      }
      // ---------------------------------------------
      
      return responseData;
    } else {
      debugPrint('API Hatası: ${response.statusCode} - ${response.body}');
      throw Exception('Veri alınamadı. Hata Kodu: ${response.statusCode}');
    }
  }

  // Bu metotlarda değişiklik yok, hepsi alttaki 'get' metodunu kullanıyor.
  // Önbellekleme mantığı 'get' içinde hallediliyor.
  Future<List<dynamic>> getMatchesForDate(DateTime date) async {
    final String dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    // Tarihe göre maçlar önbelleğe alınabilir.
    return await get('fixtures?date=$dateString');
  }

  Future<List<dynamic>> getAvailableCompetitions() async {
    // Lig listesi gibi statik veriler kesinlikle önbelleğe alınmalı.
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
    // Belirli bir maçın detayı da önbelleğe alınabilir.
    return await get('fixtures?id=$fixtureId');
  }
}
