// lib/design_system/widgets/modern_stats_card.dart
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import 'modern_card.dart';

class ModernStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Widget? icon;
  final Color? valueColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showTrend;
  final double? trendValue;
  final bool isPositiveTrend;

  const ModernStatsCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.valueColor,
    this.backgroundColor,
    this.onTap,
    this.showTrend = false,
    this.trendValue,
    this.isPositiveTrend = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ModernCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.all(18.0), // Padding optimize edildi
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between olarak değiştirildi
        children: [
          // Header row with icon and title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (valueColor ?? AppColors.primary).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: IconTheme(
                      data: IconThemeData(
                        color: valueColor ?? AppColors.primary,
                        size: 20,
                      ),
                      child: icon!,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontSize: title.length > 20 ? 13 : 15, // Uzun başlıklar için küçük font
                    fontWeight: AppTypography.semiBold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          // Value - Ortada konumlandırıldı
          Center(
            child: Text(
              value,
              style: AppTypography.headlineMedium.copyWith(
                color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                fontWeight: AppTypography.bold,
                fontSize: 32, // Font boyutu artırıldı
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Subtitle - Alt kısımda
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                fontSize: 13, // Font boyutu artırıldı: 11 → 13
                height: 1.3, // Line height artırıldı
                fontWeight: AppTypography.medium, // Font weight eklendi
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            )
          else
            const SizedBox(height: 16), // Subtitle yoksa boşluk bırak
          
          // Trend indicator (eğer varsa)
          if (showTrend && trendValue != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: (isPositiveTrend ? AppColors.success : AppColors.error).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: isPositiveTrend ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${trendValue!.abs().toStringAsFixed(1)}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: isPositiveTrend ? AppColors.success : AppColors.error,
                        fontWeight: AppTypography.semiBold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ModernComparisonStatsCard extends StatelessWidget {
  final String title;
  final String team1Name;
  final String team2Name;
  final String team1Value;
  final String team2Value;
  final double team1Percentage;
  final double team2Percentage;
  final Color? team1Color;
  final Color? team2Color;
  final VoidCallback? onTap;

  const ModernComparisonStatsCard({
    Key? key,
    required this.title,
    required this.team1Name,
    required this.team2Name,
    required this.team1Value,
    required this.team2Value,
    required this.team1Percentage,
    required this.team2Percentage,
    this.team1Color,
    this.team2Color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final defaultTeam1Color = team1Color ?? AppColors.primary;
    final defaultTeam2Color = team2Color ?? AppColors.secondary;
    
    return ModernCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Team 1
          Row(
            children: [
              Expanded(
                child: Text(
                  team1Name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                team1Value,
                style: AppTypography.titleMedium.copyWith(
                  color: defaultTeam1Color,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Team 1 progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.border,
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: team1Percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: defaultTeam1Color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Team 2
          Row(
            children: [
              Expanded(
                child: Text(
                  team2Name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                team2Value,
                style: AppTypography.titleMedium.copyWith(
                  color: defaultTeam2Color,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Team 2 progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.border,
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: team2Percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: defaultTeam2Color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ModernStatsGrid extends StatelessWidget {
  final List<ModernStatsCard> cards;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final double? mainAxisSpacing;

  const ModernStatsGrid({
    Key? key,
    required this.cards,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.8,
    this.padding,
    this.mainAxisSpacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: mainAxisSpacing ?? AppSpacing.md,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}