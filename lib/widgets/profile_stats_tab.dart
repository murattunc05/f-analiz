// lib/widgets/profile_stats_tab.dart
import 'package:flutter/material.dart';
import '../design_system/widgets/modern_stats_card.dart';
import '../design_system/widgets/modern_card.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';

class ProfileStatsTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  const ProfileStatsTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if ((stats['oynananMacSayisi'] as num?)?.toInt() == 0) {
      return Center(
        child: ModernCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Bu filtre için istatistik verisi yok",
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Temel istatistikleri hesapla
    final int wins = (stats['galibiyet'] as num?)?.toInt() ?? 0;
    final int draws = (stats['beraberlik'] as num?)?.toInt() ?? 0;
    final int goalsFor = (stats['attigi'] as num?)?.toInt() ?? 0;
    final int goalsAgainst = (stats['yedigi'] as num?)?.toInt() ?? 0;
    final int goalDiff = (stats['golFarki'] as num?)?.toInt() ?? 0;
    final int points = (wins * 3) + draws;
    final double winRate = (stats['oynananMacSayisi'] as num?)?.toInt() != 0 
        ? (wins / (stats['oynananMacSayisi'] as num).toInt()) * 100 
        : 0;

    // Gösterilecek istatistikleri kategorilere ayır
    final List<Map<String, dynamic>> basicStats = [
      {
        'label': 'Toplam Puan',
        'value': points.toString(),
        'icon': Icons.emoji_events,
        'color': AppColors.accent,
        'subtitle': '${points}/${(stats['oynananMacSayisi'] as num?)?.toInt() ?? 0 * 3} puan',
      },
      {
        'label': 'Galibiyet Oranı',
        'value': '${winRate.toStringAsFixed(1)}%',
        'icon': Icons.trending_up,
        'color': AppColors.success,
        'subtitle': '$wins galibiyet',
      },
      {
        'label': 'Gol Averajı',
        'value': goalDiff >= 0 ? '+$goalDiff' : goalDiff.toString(),
        'icon': Icons.compare_arrows,
        'color': goalDiff >= 0 ? AppColors.success : AppColors.error,
        'subtitle': '$goalsFor - $goalsAgainst',
      },
      {
        'label': 'Oynanan Maç',
        'value': ((stats['oynananMacSayisi'] as num?)?.toInt() ?? 0).toString(),
        'icon': Icons.sports_soccer,
        'color': AppColors.primary,
        'subtitle': 'Toplam maç',
      },
    ];

    final List<Map<String, dynamic>> goalStats = [
      {
        'label': 'Maç Başına Ortalama Gol',
        'key': 'macBasiOrtalamaGol',
        'icon': Icons.sports_soccer,
        'color': AppColors.success,
      },
      {
        'label': 'Maçlarda Ortalama Toplam Gol',
        'key': 'maclardaOrtalamaToplamGol',
        'icon': Icons.public,
        'color': AppColors.info,
      },
    ];

    final List<Map<String, dynamic>> performanceStats = [
      {
        'label': 'Karşılıklı Gol Var',
        'key': 'kgVarYuzdesi',
        'icon': Icons.swap_horiz,
        'suffix': '%',
        'color': AppColors.accent,
      },
      {
        'label': 'Clean Sheet',
        'key': 'cleanSheetYuzdesi',
        'icon': Icons.shield,
        'suffix': '%',
        'color': AppColors.primary,
      },
    ];

    final List<Map<String, dynamic>> gameplayStats = [
      {
        'label': 'Ortalama Şut',
        'key': 'ortalamaSut',
        'icon': Icons.gps_fixed,
        'color': AppColors.warning,
      },
      {
        'label': 'Ortalama İsabetli Şut',
        'key': 'ortalamaIsabetliSut',
        'icon': Icons.my_location,
        'color': AppColors.success,
      },
      {
        'label': 'Ortalama Korner',
        'key': 'ortalamaKorner',
        'icon': Icons.flag,
        'color': AppColors.info,
      },
      {
        'label': 'Ortalama Faul',
        'key': 'ortalamaFaul',
        'icon': Icons.sports_kabaddi,
        'color': AppColors.error,
      },
      {
        'label': 'Ortalama Sarı Kart',
        'key': 'ortalamaSariKart',
        'icon': Icons.style,
        'color': AppColors.warning,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Temel İstatistikler
          _buildSectionHeader(context, "Temel İstatistikler", Icons.dashboard),
          const SizedBox(height: AppSpacing.md),
          
          ModernStatsGrid(
            cards: basicStats.map((stat) {
              return ModernStatsCard(
                title: stat['label'],
                value: stat['value'],
                icon: Icon(stat['icon']),
                valueColor: stat['color'],
                subtitle: stat['subtitle'],
              );
            }).toList(),
            crossAxisCount: 2,
            childAspectRatio: 1.1, // Kartları daha da yüksek yaptık
          ),
          
          const SizedBox(height: AppSpacing.xs), // Çok daha az boşluk (4px)
          
          // Gol İstatistikleri
          _buildSectionHeader(context, "Gol İstatistikleri", Icons.sports_soccer),
          const SizedBox(height: AppSpacing.md),
          
          ModernStatsGrid(
            cards: goalStats.where((stat) => stats[stat['key']] != null).map((stat) {
              final value = stats[stat['key']];
              return ModernStatsCard(
                title: stat['label'],
                value: _formatValue(value, stat['suffix']),
                icon: Icon(stat['icon']),
                valueColor: stat['color'],
              );
            }).toList(),
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            mainAxisSpacing: AppSpacing.xs, // Çok minimal spacing (4px)
          ),
          
          const SizedBox(height: AppSpacing.lg), // Tüm bölümler arası eşit spacing
          
          // Performans İstatistikleri
          _buildSectionHeader(context, "Performans İstatistikleri", Icons.trending_up),
          const SizedBox(height: AppSpacing.md),
          
          ModernStatsGrid(
            cards: performanceStats.where((stat) => stats[stat['key']] != null).map((stat) {
              final value = stats[stat['key']];
              return ModernStatsCard(
                title: stat['label'],
                value: _formatValue(value, stat['suffix']),
                icon: Icon(stat['icon']),
                valueColor: stat['color'],
                subtitle: _getPerformanceSubtitle(stat['key'], value),
              );
            }).toList(),
            crossAxisCount: 2,
            childAspectRatio: 1.1, // Grid formatına çevirdik ve boyutu ayarladık
          ),
          
          const SizedBox(height: AppSpacing.lg), // Tüm bölümler arası eşit spacing
          
          // Oyun İstatistikleri
          _buildSectionHeader(context, "Oyun İstatistikleri", Icons.analytics),
          const SizedBox(height: AppSpacing.md),
          
          ModernStatsGrid(
            cards: gameplayStats.where((stat) => stats[stat['key']] != null).map((stat) {
              final value = stats[stat['key']];
              return ModernStatsCard(
                title: stat['label'],
                value: _formatValue(value, stat['suffix']),
                icon: Icon(stat['icon']),
                valueColor: stat['color'],
                subtitle: _getGameplaySubtitle(stat['key'], value),
              );
            }).toList(),
            crossAxisCount: 2,
            childAspectRatio: 1.1, // Boyutu diğerleriyle tutarlı hale getirdik
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          title,
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: AppTypography.semiBold,
          ),
        ),
      ],
    );
  }

  String _formatValue(dynamic value, String? suffix) {
    if (value is num) {
      if (value == value.toInt()) {
        return "${value.toInt()}${suffix ?? ''}";
      } else {
        return "${value.toStringAsFixed(1)}${suffix ?? ''}";
      }
    }
    return "${value.toString()}${suffix ?? ''}";
  }

  String? _getPerformanceSubtitle(String key, dynamic value) {
    switch (key) {
      case 'kgVarYuzdesi':
        final percentage = (value as num).toDouble();
        if (percentage >= 70) return "Çok yüksek";
        if (percentage >= 50) return "Yüksek";
        if (percentage >= 30) return "Orta";
        return "Düşük";
      case 'cleanSheetYuzdesi':
        final percentage = (value as num).toDouble();
        if (percentage >= 50) return "Mükemmel savunma";
        if (percentage >= 30) return "İyi savunma";
        if (percentage >= 15) return "Orta savunma";
        return "Zayıf savunma";
      default:
        return null;
    }
  }

  String? _getGameplaySubtitle(String key, dynamic value) {
    switch (key) {
      case 'ortalamaSut':
        final shots = (value as num).toDouble();
        if (shots >= 15) return "Çok aktif";
        if (shots >= 10) return "Aktif";
        if (shots >= 7) return "Orta";
        return "Pasif";
      case 'ortalamaIsabetliSut':
        final shots = (value as num).toDouble();
        if (shots >= 6) return "Çok etkili";
        if (shots >= 4) return "Etkili";
        if (shots >= 2) return "Orta";
        return "Düşük";
      case 'ortalamaKorner':
        final corners = (value as num).toDouble();
        if (corners >= 8) return "Çok yüksek";
        if (corners >= 5) return "Yüksek";
        if (corners >= 3) return "Orta";
        return "Düşük";
      case 'ortalamaFaul':
        final fouls = (value as num).toDouble();
        if (fouls >= 15) return "Agresif";
        if (fouls >= 12) return "Orta";
        if (fouls >= 8) return "Disiplinli";
        return "Çok disiplinli";
      case 'ortalamaSariKart':
        final cards = (value as num).toDouble();
        if (cards >= 3) return "Çok fazla";
        if (cards >= 2) return "Fazla";
        if (cards >= 1) return "Normal";
        return "Az";
      default:
        return null;
    }
  }
}