// lib/widgets/profile_overview_tab.dart
import 'package:flutter/material.dart';
import '../design_system/widgets/modern_stats_card.dart';
import '../design_system/widgets/modern_card.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';

class ProfileOverviewTab extends StatelessWidget {
  final Map<String, dynamic> teamStats;

  const ProfileOverviewTab({
    super.key,
    required this.teamStats,
  });

  Widget _buildFormIndicator(BuildContext context, String resultChar) {
    Color color;
    String displayChar;
    switch(resultChar) {
      case 'G': 
        color = AppColors.success; 
        displayChar = 'G';
        break;
      case 'B': 
        color = AppColors.warning; 
        displayChar = 'B';
        break;
      case 'M': 
        color = AppColors.error; 
        displayChar = 'M';
        break;
      default: 
        color = AppColors.textTertiary;
        displayChar = '-';
    }
    
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayChar, 
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white, 
            fontWeight: AppTypography.bold
          )
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Verileri Map'ten güvenli bir şekilde al
    final int played = (teamStats['oynananMacSayisi'] as num?)?.toInt() ?? 0;
    if (played == 0) {
      return Center(
        child: ModernCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Bu filtre için gösterilecek veri yok",
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
    
    final int wins = (teamStats['galibiyet'] as num?)?.toInt() ?? 0;
    final int draws = (teamStats['beraberlik'] as num?)?.toInt() ?? 0;
    final int losses = (teamStats['maglubiyet'] as num?)?.toInt() ?? 0;
    final int goalsFor = (teamStats['attigi'] as num?)?.toInt() ?? 0;
    final int goalsAgainst = (teamStats['yedigi'] as num?)?.toInt() ?? 0;
    final int goalDiff = (teamStats['golFarki'] as num?)?.toInt() ?? 0;
    final int points = (wins * 3) + draws;
    
    final int analyzedMatchCount = (teamStats['lastNMatchesUsed'] as num?)?.toInt() ?? played;
    final String matchDetailsKey = "son${analyzedMatchCount}MacDetaylari";
    final List<dynamic> lastMatches = teamStats[matchDetailsKey] as List<dynamic>? ?? [];
    final String formString = lastMatches.take(5).map((m) => (m['result'] as String?)?.substring(0, 1) ?? '-').join();

    // Win rate hesaplama
    final double winRate = played > 0 ? (wins / played) * 100 : 0;
    final double avgGoalsFor = played > 0 ? goalsFor / played : 0;
    final double avgGoalsAgainst = played > 0 ? goalsAgainst / played : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tüm İstatistik Kartları (6 kart tek grid'de)
          ModernStatsGrid(
            cards: [
              ModernStatsCard(
                title: "Oynanan Maç",
                value: played.toString(),
                icon: const Icon(Icons.sports_soccer),
                valueColor: AppColors.primary,
                subtitle: "Toplam maç",
              ),
              ModernStatsCard(
                title: "Toplam Puan",
                value: points.toString(),
                icon: const Icon(Icons.emoji_events),
                valueColor: AppColors.accent,
                subtitle: "${points}/${played * 3} puan",
              ),
              ModernStatsCard(
                title: "Galibiyet Oranı",
                value: "${winRate.toStringAsFixed(1)}%",
                icon: const Icon(Icons.trending_up),
                valueColor: AppColors.success,
                subtitle: "$wins galibiyet",
              ),
              ModernStatsCard(
                title: "Gol Averajı",
                value: goalDiff >= 0 ? "+$goalDiff" : goalDiff.toString(),
                icon: const Icon(Icons.compare_arrows),
                valueColor: goalDiff >= 0 ? AppColors.success : AppColors.error,
                subtitle: "$goalsFor - $goalsAgainst",
              ),
              ModernStatsCard(
                title: "Maç Başına Ortalama Gol",
                value: avgGoalsFor.toStringAsFixed(1),
                subtitle: "Attığı gol",
                icon: const Icon(Icons.sports_soccer),
                valueColor: AppColors.success,
              ),
              ModernStatsCard(
                title: "Maç Başına Ortalama Gol",
                value: avgGoalsAgainst.toStringAsFixed(1),
                subtitle: "Yediği gol",
                icon: const Icon(Icons.shield_outlined),
                valueColor: AppColors.error,
              ),
            ],
            crossAxisCount: 2, // 2 sütun halinde düzenleme
            childAspectRatio: 1.1, // Kart boyut oranı
          ),
          
          const SizedBox(height: AppSpacing.lg), // Tüm bölümler arası eşit spacing
          
          // Maç Sonuçları Dağılımı
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Maç Sonuçları Dağılımı",
                  style: AppTypography.headlineSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Galibiyet
                _buildResultRow(
                  context,
                  label: "Galibiyet",
                  value: wins,
                  total: played,
                  color: AppColors.success,
                  icon: Icons.emoji_events,
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Beraberlik
                _buildResultRow(
                  context,
                  label: "Beraberlik",
                  value: draws,
                  total: played,
                  color: AppColors.warning,
                  icon: Icons.handshake,
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Mağlubiyet
                _buildResultRow(
                  context,
                  label: "Mağlubiyet",
                  value: losses,
                  total: played,
                  color: AppColors.error,
                  icon: Icons.sentiment_dissatisfied,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),

          // Son 5 Maç Formu
          if (formString.isNotEmpty)
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timeline,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        "Son 5 Maç Formu",
                        style: AppTypography.headlineSmall.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: formString.characters.map((char) => _buildFormIndicator(context, char)).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    "G: Galibiyet • B: Beraberlik • M: Mağlubiyet",
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildResultRow(BuildContext context, {
    required String label,
    required int value,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentage = total > 0 ? (value / total) * 100 : 0;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                  Text(
                    "$value (${percentage.toStringAsFixed(1)}%)",
                    style: AppTypography.titleMedium.copyWith(
                      color: color,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}