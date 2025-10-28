// lib/design_system/widgets/modern_card.dart
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool hasBorder;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;

  const ModernCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.hasBorder = false,
    this.borderColor,
    this.borderWidth = 1.0,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final defaultBackgroundColor = isDark 
        ? AppColors.surfaceDark 
        : AppColors.surface;
    
    final defaultBorderColor = isDark 
        ? AppColors.borderDark 
        : AppColors.border;

    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.xl), // Padding artırıldı
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? defaultBackgroundColor) : null,
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
        border: hasBorder 
            ? Border.all(
                color: borderColor ?? defaultBorderColor,
                width: borderWidth,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadow,
            blurRadius: elevation ?? AppSpacing.elevationMd, // Elevation artırıldı
            offset: const Offset(0, 2), // Shadow offset artırıldı
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
            child: cardContent,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}

class ModernGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double opacity;
  final double blur;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const ModernGlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.opacity = 0.1,
    this.blur = 10.0,
    this.borderRadius,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
            child: cardContent,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}