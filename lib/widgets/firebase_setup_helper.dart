// lib/widgets/firebase_setup_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/widgets/modern_button.dart';
import '../design_system/app_colors.dart';

class FirebaseSetupHelper extends StatelessWidget {
  const FirebaseSetupHelper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Kurulum'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Firebase Console Kurulumu',
              [
                '1. https://console.firebase.google.com adresine gidin',
                '2. Projenizi seçin',
                '3. Sol menüden "Authentication" seçin',
                '4. "Get started" butonuna tıklayın',
                '5. "Sign-in method" sekmesine gidin',
                '6. "Email/Password" seçeneğini etkinleştirin',
                '7. "Google" seçeneğini etkinleştirin',
                '8. Google için proje destek e-postasını ayarlayın',
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              'Android SHA-1 Fingerprint',
              [
                'Google Sign-In için SHA-1 fingerprint gerekli:',
                '',
                'Debug için:',
                'keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android',
                '',
                'Windows için:',
                'keytool -list -v -keystore %USERPROFILE%\\.android\\debug.keystore -alias androiddebugkey -storepass android -keypass android',
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              'SHA-1 Ekleme Adımları',
              [
                '1. Firebase Console\'da projenizi açın',
                '2. Project Settings (⚙️) > General sekmesi',
                '3. "Your apps" bölümünde Android uygulamanızı seçin',
                '4. "SHA certificate fingerprints" bölümüne SHA-1\'i ekleyin',
                '5. Yeni google-services.json dosyasını indirin',
                '6. android/app/ klasörüne kopyalayın',
              ],
            ),
            
            const SizedBox(height: 24),
            
            ModernButton(
              text: 'SHA-1 Komutunu Kopyala (Windows)',
              onPressed: () {
                Clipboard.setData(
                  const ClipboardData(
                    text: 'keytool -list -v -keystore %USERPROFILE%\\.android\\debug.keystore -alias androiddebugkey -storepass android -keypass android',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Komut panoya kopyalandı!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              variant: ModernButtonVariant.outline,
              isFullWidth: true,
              icon: const Icon(Icons.copy),
            ),
            
            const SizedBox(height: 12),
            
            ModernButton(
              text: 'Firebase Console\'u Aç',
              onPressed: () {
                // URL launcher ile Firebase Console açılabilir
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('https://console.firebase.google.com adresine gidin'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              isFullWidth: true,
              icon: const Icon(Icons.open_in_browser),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: const TextStyle(fontSize: 14),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}