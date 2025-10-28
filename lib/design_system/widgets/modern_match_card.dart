// lib/design_system/widgets/modern_match_card.dart
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import 'modern_card.dart';

class ModernMatchCard extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final String? homeScore;
  final String? awayScore;
  final String date;
  final String time;
  final String? status;
  final String? league;
  final VoidCallback? onTap;
  final bool isLive;
  final bool isFinished;
  final Widget? homeTeamLogo;
  final Widget? awayTeamLogo;

  const ModernMatchCard({
    Key? key,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.date,
    required this.time,
    this.status,
    this.league,
    this.onTap,
    this.isLive = false,
    this.isFinished = false,
    this.homeTeamLogo,
    this.awayTeamLogo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ModernCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // League and status row
          if (league != null || status != null)
            Row(
              children: [
                if (league != null)
                  Expanded(
                    child: Text(
                      league!,
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'CANLI',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isFinished 
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                    ),
                    child: Text(
                      status!,
                      style: AppTypography.labelSmall.copyWith(
                        color: isFinished ? AppColors.success : AppColors.info,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ),
              ],
            ),
          
          if (league != null || status != null)
            const SizedBox(height: AppSpacing.md),
          
          // Teams and score row
          Row(
            children: [
              // Home team
              Expanded(
                child: Column(
                  children: [
                    if (homeTeamLogo != null) ...[
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: homeTeamLogo!,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Text(
                      homeTeam,
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        fontWeight: AppTypography.semiBold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Score section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  children: [
                    if (homeScore != null && awayScore != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            homeScore!,
                            style: AppTypography.displaySmall.copyWith(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '-',
                            style: AppTypography.titleLarge.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            awayScore!,
                            style: AppTypography.displaySmall.copyWith(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'VS',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      time,
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Away team
              Expanded(
                child: Column(
                  children: [
                    if (awayTeamLogo != null) ...[
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: awayTeamLogo!,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Text(
                      awayTeam,
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        fontWeight: AppTypography.semiBold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Date
          Center(
            child: Text(
              date,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ModernCompactMatchCard extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final String? homeScore;
  final String? awayScore;
  final String time;
  final VoidCallback? onTap;
  final bool isLive;
  final Widget? homeTeamLogo;
  final Widget? awayTeamLogo;

  const ModernCompactMatchCard({
    Key? key,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.time,
    this.onTap,
    this.isLive = false,
    this.homeTeamLogo,
    this.awayTeamLogo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          // Home team
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (homeTeamLogo != null) ...[
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: homeTeamLogo!,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    homeTeam,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: AppTypography.medium,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Score/Time section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (homeScore != null && awayScore != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        homeScore!,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '-',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        awayScore!,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    time,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ],
                if (isLive) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                    ),
                    child: Text(
                      'CANLI',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Away team
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    awayTeam,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: AppTypography.medium,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (awayTeamLogo != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: awayTeamLogo!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}