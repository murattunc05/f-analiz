// lib/services/user_profile_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_profile_model.dart';
import 'auth_service.dart';
import 'profile_update_service.dart';
import 'user_service.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // AuthService static sınıf olduğu için instance oluşturmaya gerek yok
  static const String _usersCollection = 'users';
  static const String _profileKey = 'user_profile_cache';

  // --- Temel Profil İşlemleri (CRUD) ---

  // Yeni kullanıcı için profil oluşturur
  Future<void> createProfileForNewUser() async {
    await createProfileFromCurrentUser();
  }

  // Lokal önbelleği temizler
  Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }

  // Profili Firestore'a ve lokal önbelleğe kaydeder.
  Future<void> _saveProfile(UserProfile profile) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    // 1. Firestore'a yaz
    await _firestore.collection(_usersCollection).doc(user.uid).set(profile.toMap());

    // 2. Lokal önbelleğe yaz
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, json.encode(profile.toMap()));
  }

  // Profili yükler (Önce önbellek, sonra Firestore)
  Future<UserProfile?> loadUserProfile() async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();

    // 1. Önce lokal önbellekten hızlıca yüklemeyi dene
    final cachedProfileJson = prefs.getString(_profileKey);
    if (cachedProfileJson != null) {
      final cachedProfile = UserProfile.fromMap(json.decode(cachedProfileJson));
      // Eğer cache'lenen profil doğru kullanıcıya aitse hemen döndür
      if (cachedProfile.uid == user.uid) {
        // UserService'ten profil fotoğrafını kontrol et ve güncelle
        final userServiceImagePath = await UserService.getProfileImagePath();
        if (userServiceImagePath != null && userServiceImagePath != cachedProfile.photoURL) {
          final updatedProfile = cachedProfile.copyWith(photoURL: userServiceImagePath);
          await prefs.setString(_profileKey, json.encode(updatedProfile.toMap()));
          // Arka planda yine de Firestore'dan güncel veriyi çek
          _syncFromFirestore(user.uid, prefs);
          return updatedProfile;
        }
        
        // Arka planda yine de Firestore'dan güncel veriyi çek
        _syncFromFirestore(user.uid, prefs);
        return cachedProfile;
      }
    }

    // 2. Önbellek yoksa veya yanlışsa, Firestore'dan çek
    return _syncFromFirestore(user.uid, prefs);
  }

  // Firestore'dan veri çeker ve önbelleği günceller
  Future<UserProfile?> _syncFromFirestore(String uid, SharedPreferences prefs) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromMap(doc.data()!);
        // Yeni veriyi lokal önbelleğe yaz
        await prefs.setString(_profileKey, json.encode(profile.toMap()));
        return profile;
      }
      return null;
    } catch (e) {
      print("Firestore'dan profil senkronizasyon hatası: $e");
      return null;
    }
  }

  // Yeni bir kullanıcı için varsayılan profil oluşturur.
  Future<UserProfile> createProfileFromCurrentUser() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('Profil oluşturmak için kullanıcı oturumu gerekli.');

    final now = DateTime.now();
    final newProfile = UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Yeni Kullanıcı',
      photoURL: user.photoURL,
      createdAt: now,
      updatedAt: now,
    );

    await _saveProfile(newProfile);
    return newProfile;
  }

  // --- Profil Alanlarını Güncelleme --- 

  // Genel profil güncelleme (isim, bio, konum vb.)
  Future<void> updateProfileDetails({
    required String displayName,
    required String bio,
    required String location,
    String? favoriteTeam,
    String? favoriteLeague,
  }) async {
    final profile = await loadUserProfile();
    if (profile == null) throw Exception('Güncellenecek profil bulunamadı.');

    final updatedProfile = profile.copyWith(
      displayName: displayName,
      bio: bio,
      location: location,
      favoriteLeague: favoriteLeague,
      isProfileComplete: true, // Profil tamamlandı olarak işaretle
      updatedAt: DateTime.now(),
    );

    await _saveProfile(updatedProfile);
  }

  // Profil fotoğrafını local olarak saklar ve yeni path'i döndürür.
  Future<String?> updateProfileImage(String sourcePath) async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      // App documents directory'sini al
      final appDir = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory('${appDir.path}/profile_images');
      
      // Klasör yoksa oluştur
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }

      // Dosyayı kopyala
      final fileName = '${user.uid}_profile.jpg';
      final targetPath = '${profileImagesDir.path}/$fileName';
      final targetFile = await sourceFile.copy(targetPath);

      // Profil dokümanını güncelle
      final profile = await loadUserProfile();
      if (profile != null) {
        await _saveProfile(profile.copyWith(
          photoURL: targetFile.path, 
          updatedAt: DateTime.now()
        ));
        
        // Profil güncellendiğini bildir
        ProfileUpdateService.notifyProfileUpdated();
      }
      
      return targetFile.path;

    } catch (e) {
      print("Profil fotoğrafı kaydetme hatası: $e");
      return null;
    }
  }

  // --- Favori ve Desteklenen Takım İşlemleri ---

  Future<void> addFavoriteTeam(FavoriteTeam team) async {
    final profile = await loadUserProfile();
    if (profile == null) return;

    final newFavorites = List<FavoriteTeam>.from(profile.favoriteTeams);
    // Eğer takım zaten favorilerde değilse ekle
    if (!newFavorites.any((t) => t.name == team.name)) {
      newFavorites.add(team);
      await _saveProfile(profile.copyWith(favoriteTeams: newFavorites, updatedAt: DateTime.now()));
    }
  }

  Future<void> removeFavoriteTeam(String teamName) async {
    final profile = await loadUserProfile();
    if (profile == null) return;

    final newFavorites = profile.favoriteTeams.where((t) => t.name != teamName).toList();
    await _saveProfile(profile.copyWith(favoriteTeams: newFavorites, updatedAt: DateTime.now()));
  }

  Future<void> setSupportedTeam(FavoriteTeam? team) async {
    final profile = await loadUserProfile();
    if (profile == null) return;

    await _saveProfile(profile.copyWith(supportedTeam: team, updatedAt: DateTime.now()));
  }

  Future<void> setFavoriteLeague(String league) async {
    final profile = await loadUserProfile();
    if (profile == null) return;

    await _saveProfile(profile.copyWith(favoriteLeague: league, updatedAt: DateTime.now()));
  }

  // --- Ayar İşlemleri ---

  Future<void> updateSettings(UserSettings newSettings) async {
    final profile = await loadUserProfile();
    if (profile == null) return;

    await _saveProfile(profile.copyWith(settings: newSettings, updatedAt: DateTime.now()));
  }

  // --- Yardımcı Fonksiyonlar ---

  Future<bool> hasUserProfile() async {
    final user = AuthService.currentUser;
    if (user == null) return false;
    final profile = await loadUserProfile();
    return profile != null;
  }

  Future<void> markProfileAsComplete() async {
    final profile = await loadUserProfile();
    if (profile == null) return;

    await _saveProfile(profile.copyWith(
      isProfileComplete: true,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> removeProfileImage() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    try {
      final profile = await loadUserProfile();
      if (profile == null) return;

      // Eski fotoğrafı sil
      if (profile.photoURL != null && profile.photoURL!.isNotEmpty) {
        final oldFile = File(profile.photoURL!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      // Profil dokümanını güncelle
      await _saveProfile(profile.copyWith(
        photoURL: null,
        updatedAt: DateTime.now(),
      ));
      
      // Profil güncellendiğini bildir
      ProfileUpdateService.notifyProfileUpdated();
    } catch (e) {
      print("Profil fotoğrafı kaldırma hatası: $e");
    }
  }

  // Çıkış sırasında profil fotoğrafını temizler (Firestore güncellemesi yapmaz)
  Future<void> clearProfileImageOnSignOut() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      // App documents directory'sini al
      final appDir = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory('${appDir.path}/profile_images');
      
      if (await profileImagesDir.exists()) {
        // Kullanıcının profil fotoğrafını sil
        final userImageFile = File('${profileImagesDir.path}/${user.uid}_profile.jpg');
        if (await userImageFile.exists()) {
          await userImageFile.delete();
          print('Kullanıcı profil fotoğrafı silindi: ${userImageFile.path}');
        }
      }
    } catch (e) {
      print("Çıkış sırasında profil fotoğrafı temizleme hatası: $e");
    }
  }

  // Tüm profil fotoğraflarını temizler (güvenlik için)
  Future<void> clearAllProfileImages() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory('${appDir.path}/profile_images');
      
      if (await profileImagesDir.exists()) {
        await profileImagesDir.delete(recursive: true);
        print('Tüm profil fotoğrafları temizlendi');
      }
    } catch (e) {
      print("Tüm profil fotoğrafları temizleme hatası: $e");
    }
  }

  // Duplicate method removed
}
