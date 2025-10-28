// lib/design_system/widgets/modern_bottom_nav.dart
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

class ModernBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? badge;

  const ModernBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badge,
  });
}

class ModernBottomNav extends StatelessWidget {
  final List<ModernBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final bool showLabels;
  final double height;

  const ModernBottomNav({
    Key? key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.showLabels = false,
    this.height = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? AppColors.surfaceDark.withOpacity(0.95) : AppColors.surface.withOpacity(0.95)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;
          
          return Expanded(
            child: _ModernBottomNavItem(
              item: item,
              isSelected: isSelected,
              onTap: () => onTap(index),
              showLabel: showLabels,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ModernBottomNavItem extends StatelessWidget {
  final ModernBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showLabel;

  const _ModernBottomNavItem({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.showLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final activeColor = AppColors.primary;
    final inactiveColor = isDark 
        ? AppColors.textTertiaryDark 
        : AppColors.textTertiary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: activeColor.withOpacity(0.1),
        highlightColor: activeColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected && item.activeIcon != null 
                        ? item.activeIcon! 
                        : item.icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 24,
                  ),
                  // Badge
                  if (item.badge != null)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          item.badge!,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: AppTypography.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Label
              if (showLabel) ...[
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? activeColor : inactiveColor,
                    fontWeight: isSelected 
                        ? AppTypography.semiBold 
                        : AppTypography.medium,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ModernFloatingBottomNav extends StatelessWidget {
  final List<ModernBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry margin;

  const ModernFloatingBottomNav({
    Key? key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.margin = const EdgeInsets.all(AppSpacing.lg),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surface),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadow,
            blurRadius: AppSpacing.elevationLg,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == currentIndex;
            
            return _ModernFloatingNavItem(
              item: item,
              isSelected: isSelected,
              onTap: () => onTap(index),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ModernFloatingNavItem extends StatelessWidget {
  final ModernBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModernFloatingNavItem({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final activeColor = AppColors.primary;
    final inactiveColor = isDark 
        ? AppColors.textTertiaryDark 
        : AppColors.textTertiary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? AppSpacing.lg : AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? activeColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected && item.activeIcon != null 
                        ? item.activeIcon! 
                        : item.icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 24,
                  ),
                  if (item.badge != null)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          item.badge!,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              if (isSelected) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  item.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: activeColor,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}