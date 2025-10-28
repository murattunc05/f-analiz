// lib/services/user_service.dart
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';


class UserService {
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userBioKey = 'user_bio';
  static const String _userLocationKey = 'user_location';
  static const String _userJoinDateKey = 'user_join_date';
  static const String _profileImagePathKey = 'profile_image_path';
  static const String _totalAnalysisKey = 'total_analysis';
  static const String _totalComparisonsKey = 'total_comparisons';
  static const String _lastActivityKey = 'last_activity';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  // Kullanıcı bilgilerini kaydet
  static Future<void> saveUserInfo({
    String? name,
    String? email,
    String? bio,
    String? location,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (name != null) await prefs.setString(_userNameKey, name);
    if (email != null) await prefs.setString(_userEmailKey, email);
    if (bio != null) await prefs.setString(_userBioKey, bio);
    if (location != null) await prefs.setString(_userLocationKey, location);
  }

  // Kullanıcı bilgilerini al
  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'name': prefs.getString(_userNameKey) ?? 'Futbol Analiz Kullanıcısı',
      'email': prefs.getString(_userEmailKey) ?? 'goalitycs@example.com',
      'bio': prefs.getString(_userBioKey),
      'location': prefs.getString(_userLocationKey),
      'joinDate': prefs.getString(_userJoinDateKey) ?? DateTime.now().toIso8601String(),
    };
  }

  // Profil fotoğrafını kaydet (önbelleğe alınır) - XFile versiyonu
  static Future<String?> saveProfileImage(XFile imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/profile');
      
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }
      
      // Eski profil fotoğrafını sil
      await _deleteOldProfileImage();
      
      final fileName = 'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${profileDir.path}/$fileName');
      
      // Dosyayı kopyala
      await File(imageFile.path).copy(savedImage.path);
      
      // Dosyanın gerçekten oluşturulduğunu kontrol et
      if (await savedImage.exists()) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileImagePathKey, savedImage.path);
        print('Profil fotoğrafı başarıyla kaydedildi: ${savedImage.path}');
        return savedImage.path;
      } else {
        print('Profil fotoğrafı dosyası oluşturulamadı');
        return null;
      }
    } catch (e) {
      print('Profil fotoğrafı kaydedilirken hata: $e');
      return null;
    }
  }

  // Profil fotoğrafını kaydet (önbelleğe alınır) - String path versiyonu
  static Future<String?> saveProfileImageFromPath(String imagePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/profile');
      
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }
      
      // Eski profil fotoğrafını sil
      await _deleteOldProfileImage();
      
      final fileName = 'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${profileDir.path}/$fileName');
      
      // Dosyayı kopyala
      await File(imagePath).copy(savedImage.path);
      
      // Dosyanın gerçekten oluşturulduğunu kontrol et
      if (await savedImage.exists()) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileImagePathKey, savedImage.path);
        print('Profil fotoğrafı başarıyla kaydedildi: ${savedImage.path}');
        return savedImage.path;
      } else {
        print('Profil fotoğrafı dosyası oluşturulamadı');
        return null;
      }
    } catch (e) {
      print('Profil fotoğrafı kaydedilirken hata: $e');
      return null;
    }
  }

  // Eski profil fotoğrafını sil
  static Future<void> _deleteOldProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final oldImagePath = prefs.getString(_profileImagePathKey);
    
    if (oldImagePath != null) {
      final oldFile = File(oldImagePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }
  }

  // Profil fotoğrafını al
  static Future<String?> getProfileImagePath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString(_profileImagePathKey);
      
      if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          print('Profil fotoğrafı bulundu: $imagePath');
          return imagePath;
        } else {
          print('Profil fotoğrafı dosyası bulunamadı: $imagePath');
          // Geçersiz yolu temizle
          await prefs.remove(_profileImagePathKey);
        }
      }
      
      return null;
    } catch (e) {
      print('Profil fotoğrafı alınırken hata: $e');
      return null;
    }
  }

  // Profil fotoğrafını sil
  static Future<void> deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString(_profileImagePathKey);
    
    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      await prefs.remove(_profileImagePathKey);
    }
  }

  // İstatistikleri güncelle
  static Future<void> updateStats({
    int? totalAnalysis,
    int? totalComparisons,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (totalAnalysis != null) {
      final current = prefs.getInt(_totalAnalysisKey) ?? 0;
      await prefs.setInt(_totalAnalysisKey, current + totalAnalysis);
    }
    
    if (totalComparisons != null) {
      final current = prefs.getInt(_totalComparisonsKey) ?? 0;
      await prefs.setInt(_totalComparisonsKey, current + totalComparisons);
    }
  }

  // İstatistikleri al
  static Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'totalAnalysis': prefs.getInt(_totalAnalysisKey) ?? 47,
      'totalComparisons': prefs.getInt(_totalComparisonsKey) ?? 23,
    };
  }

  // Son aktiviteyi kaydet
  static Future<void> addActivity(String activity) async {
    final prefs = await SharedPreferences.getInstance();
    final activities = prefs.getStringList(_lastActivityKey) ?? [];
    
    activities.insert(0, '${DateTime.now().toIso8601String()}|$activity');
    
    // Son 10 aktiviteyi sakla
    if (activities.length > 10) {
      activities.removeRange(10, activities.length);
    }
    
    await prefs.setStringList(_lastActivityKey, activities);
  }

  // Test aktiviteleri ekle (geliştirme amaçlı)
  static Future<void> addTestActivities() async {
    final testActivities = [
      'Barcelona takımını analiz etti',
      'Real Madrid vs Barcelona karşılaştırması yaptı',
      'Manchester City takımını favorilere ekledi',
      'Premier League maçlarını inceledi',
      'Liverpool takım istatistiklerini görüntüledi',
      'Chelsea vs Arsenal karşılaştırması yaptı',
      'Bayern Munich takımını analiz etti',
    ];

    for (int i = 0; i < testActivities.length; i++) {
      final activity = testActivities[i];
      final time = DateTime.now().subtract(Duration(hours: i + 1));
      
      final prefs = await SharedPreferences.getInstance();
      final activities = prefs.getStringList(_lastActivityKey) ?? [];
      
      activities.insert(0, '${time.toIso8601String()}|$activity');
      
      if (activities.length > 10) {
        activities.removeRange(10, activities.length);
      }
      
      await prefs.setStringList(_lastActivityKey, activities);
    }
  }

  // Son aktiviteleri al (en fazla 10 aktivite)
  static Future<List<Map<String, String>>> getRecentActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final activities = prefs.getStringList(_lastActivityKey) ?? [];
    
    // En fazla 10 aktivite döndür
    final limitedActivities = activities.take(10).toList();
    
    return limitedActivities.map((activity) {
      final parts = activity.split('|');
      if (parts.length >= 2) {
        final dateTime = DateTime.parse(parts[0]);
        final description = parts.sublist(1).join('|');
        
        return {
          'description': description,
          'time': _formatTimeAgo(dateTime),
          'timestamp': dateTime.toIso8601String(),
        };
      }
      return {
        'description': activity,
        'time': 'Bilinmiyor',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }).toList();
  }

  // Bildirim ayarları
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  // Kullanıcı verilerini sıfırla
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await deleteProfileImage();
    
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userBioKey);
    await prefs.remove(_userLocationKey);
    await prefs.remove(_totalAnalysisKey);
    await prefs.remove(_totalComparisonsKey);
    await prefs.remove(_lastActivityKey);
    await prefs.remove(_notificationsEnabledKey);
  }

  // Zaman formatı
  static String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${(difference.inDays / 7).floor()} hafta önce';
    }
  }

  // Profil fotoğrafı seç
  static Future<String?> pickAndSaveProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        return await saveProfileImage(image);
      }
      
      return null;
    } on Exception catch (e) {
      // Plugin hatalarını yakala
      if (e.toString().contains('MissingPluginException')) {
        throw Exception('Galeri özelliği bu cihazda desteklenmiyor. Lütfen uygulamayı yeniden başlatın.');
      } else if (e.toString().contains('permission')) {
        throw Exception('Galeri erişim izni gerekli. Lütfen uygulama ayarlarından izin verin.');
      } else {
        throw Exception('Galeri açılırken hata oluştu: ${e.toString()}');
      }
    } catch (e) {
      print('Profil fotoğrafı seçilirken hata: $e');
      throw Exception('Beklenmeyen hata: ${e.toString()}');
    }
  }

  // Kameradan profil fotoğrafı çek
  static Future<String?> takeAndSaveProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        return await saveProfileImage(image);
      }
      
      return null;
    } on Exception catch (e) {
      // Plugin hatalarını yakala
      if (e.toString().contains('MissingPluginException')) {
        throw Exception('Kamera özelliği bu cihazda desteklenmiyor. Lütfen uygulamayı yeniden başlatın.');
      } else if (e.toString().contains('permission')) {
        throw Exception('Kamera erişim izni gerekli. Lütfen uygulama ayarlarından izin verin.');
      } else {
        throw Exception('Kamera açılırken hata oluştu: ${e.toString()}');
      }
    } catch (e) {
      print('Profil fotoğrafı çekilirken hata: $e');
      throw Exception('Beklenmeyen hata: ${e.toString()}');
    }
  }
}