// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'user_profile_service.dart';
import 'user_service.dart';
import 'profile_update_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.updateDisplayName(displayName);
      await result.user?.reload();

      if (result.user != null) {
        await _handleSuccessfulSignIn(isNewUser: true);
      }
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Beklenmeyen bir hata oluştu: $e';
    }
  }

  static Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await _handleSuccessfulSignIn();
      }
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Beklenmeyen bir hata oluştu: $e';
    }
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);

      if (result.user != null) {
        await _handleSuccessfulSignIn(isNewUser: result.additionalUserInfo?.isNewUser ?? false);
      }
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google ile giriş yapılırken hata oluştu: $e';
    }
  }

  static Future<void> _handleSuccessfulSignIn({bool isNewUser = false}) async {
    try {
      final userProfileService = UserProfileService();
      final existingProfile = await userProfileService.loadUserProfile();
      if (isNewUser || existingProfile == null) {
        await userProfileService.createProfileForNewUser();
      }
    } catch (e) {
      // Bu hata giriş işlemini engellememeli
      print('Giriş sonrası profil işleminde hata: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      // Çıkış yapmadan önce profil fotoğrafını temizle
      final userProfileService = UserProfileService();
      await userProfileService.clearProfileImageOnSignOut();
      
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      // Çıkış yapınca lokal önbelleği temizle
      await userProfileService.clearLocalCache();
      
      // UserService'teki lokal verileri de temizle
      await UserService.deleteProfileImage();
      await UserService.clearUserData();
      
      // Çıkış yapıldığını bildir
      ProfileUpdateService.notifySignOut();
    } catch (e) {
      throw 'Çıkış yapılırken hata oluştu: $e';
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Beklenmeyen bir hata oluştu: $e';
    }
  }

  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalıdır.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izin verilmiyor.';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri.';
      case 'network-request-failed':
        return 'Ağ bağlantısı hatası. İnternet bağlantınızı kontrol edin.';
      default:
        return 'Bir kimlik doğrulama hatası oluştu. (${e.code})';
    }
  }

  static bool get isSignedIn => currentUser != null;
}