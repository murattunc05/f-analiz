// lib/models/onboarding_page_model.dart
import 'package:flutter/material.dart';

class OnboardingPageModel {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> gradientColors;
  
  const OnboardingPageModel({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gradientColors,
  });
}

class OnboardingData {
  static List<OnboardingPageModel> getPages() {
    return [
      OnboardingPageModel(
        title: "GOALITYCS'e",
        subtitle: "Hoş Geldiniz",
        description: "Futbol analizlerinin geleceği burada! Takımları analiz edin, karşılaştırın ve profesyonel istatistiklere ulaşın.",
        icon: Icons.sports_soccer,
        primaryColor: const Color(0xFF4CAF50),
        secondaryColor: const Color(0xFF45A049),
        gradientColors: [
          const Color(0xFF4CAF50),
          const Color(0xFF45A049),
          const Color(0xFF388E3C),
        ],
      ),
      OnboardingPageModel(
        title: "Detaylı",
        subtitle: "Takım Analizleri",
        description: "Takımların performansını derinlemesine inceleyin. Son maçlar, istatistikler ve form analizi ile takımları keşfedin.",
        icon: Icons.analytics,
        primaryColor: const Color(0xFF2196F3),
        secondaryColor: const Color(0xFF1976D2),
        gradientColors: [
          const Color(0xFF2196F3),
          const Color(0xFF1976D2),
          const Color(0xFF1565C0),
        ],
      ),
      OnboardingPageModel(
        title: "Akıllı",
        subtitle: "Karşılaştırmalar",
        description: "İki takımı yan yana karşılaştırın. AI destekli analizler ile maç öncesi tahminlere ulaşın.",
        icon: Icons.compare_arrows,
        primaryColor: const Color(0xFF9C27B0),
        secondaryColor: const Color(0xFF7B1FA2),
        gradientColors: [
          const Color(0xFF9C27B0),
          const Color(0xFF7B1FA2),
          const Color(0xFF6A1B9A),
        ],
      ),
      OnboardingPageModel(
        title: "Kişisel",
        subtitle: "Deneyim",
        description: "Favori takımlarınızı takip edin, kişisel istatistiklerinizi görün ve uygulamayı kendinize göre özelleştirin.",
        icon: Icons.favorite,
        primaryColor: const Color(0xFFFF5722),
        secondaryColor: const Color(0xFFE64A19),
        gradientColors: [
          const Color(0xFFFF5722),
          const Color(0xFFE64A19),
          const Color(0xFFD84315),
        ],
      ),
      OnboardingPageModel(
        title: "Canlı",
        subtitle: "Maç Takibi",
        description: "Maçları canlı takip edin, anlık skorları görün ve maç istatistiklerini gerçek zamanlı olarak inceleyin.",
        icon: Icons.live_tv,
        primaryColor: const Color(0xFFE91E63),
        secondaryColor: const Color(0xFFC2185B),
        gradientColors: [
          const Color(0xFFE91E63),
          const Color(0xFFC2185B),
          const Color(0xFFAD1457),
        ],
      ),
      OnboardingPageModel(
        title: "Gelişmiş",
        subtitle: "İstatistikler",
        description: "Detaylı performans metrikleri, heat map'ler ve gelişmiş analiz araçları ile takımları derinlemesine keşfedin.",
        icon: Icons.insights,
        primaryColor: const Color(0xFF00BCD4),
        secondaryColor: const Color(0xFF0097A7),
        gradientColors: [
          const Color(0xFF00BCD4),
          const Color(0xFF0097A7),
          const Color(0xFF00838F),
        ],
      ),
      OnboardingPageModel(
        title: "Hesabınızla",
        subtitle: "Daha Fazlası",
        description: "Hesap oluşturarak verilerinizi senkronize edin, özel analizlere erişin ve kişiselleştirilmiş deneyimin keyfini çıkarın.",
        icon: Icons.account_circle,
        primaryColor: const Color(0xFF673AB7),
        secondaryColor: const Color(0xFF512DA8),
        gradientColors: [
          const Color(0xFF673AB7),
          const Color(0xFF512DA8),
          const Color(0xFF4527A0),
        ],
      ),
    ];
  }
}