// lib/design_system/widgets/modern_button.dart
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

enum ModernButtonSize { small, medium, large }
enum ModernButtonVariant { primary, secondary, outline, ghost, danger }

class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ModernButtonSize size;
  final ModernButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final BorderRadius? borderRadius;
  final Gradient? gradient;

  const ModernButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.size = ModernButtonSize.medium,
    this.variant = ModernButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.borderRadius,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Size configurations
    EdgeInsetsGeometry padding;
    double height;
    TextStyle textStyle;
    double iconSize;
    
    switch (size) {
      case ModernButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm);
        height = 36;
        textStyle = AppTypography.buttonSmall;
        iconSize = 16;
        break;
      case ModernButtonSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md);
        height = 48;
        textStyle = AppTypography.buttonMedium;
        iconSize = 20;
        break;
      case ModernButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg);
        height = 56;
        textStyle = AppTypography.buttonLarge;
        iconSize = 24;
        break;
    }
    
    // Variant configurations
    Color backgroundColor;
    Color foregroundColor;
    Color? borderColor;
    double elevation;
    
    switch (variant) {
      case ModernButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = Colors.white;
        borderColor = null;
        elevation = AppSpacing.elevationSm;
        break;
      case ModernButtonVariant.secondary:
        backgroundColor = AppColors.secondary;
        foregroundColor = Colors.white;
        borderColor = null;
        elevation = AppSpacing.elevationSm;
        break;
      case ModernButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primary;
        borderColor = AppColors.primary;
        elevation = 0;
        break;
      case ModernButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primary;
        borderColor = null;
        elevation = 0;
        break;
      case ModernButtonVariant.danger:
        backgroundColor = AppColors.error;
        foregroundColor = Colors.white;
        borderColor = null;
        elevation = AppSpacing.elevationSm;
        break;
    }
    
    // Disabled state
    if (onPressed == null || isLoading) {
      backgroundColor = backgroundColor.withOpacity(0.5);
      foregroundColor = foregroundColor.withOpacity(0.5);
      borderColor = borderColor?.withOpacity(0.5);
    }
    
    Widget buttonChild;
    
    if (isLoading) {
      buttonChild = SizedBox(
        width: iconSize,
        height: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: icon,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: textStyle.copyWith(color: foregroundColor)),
        ],
      );
    } else {
      buttonChild = Text(text, style: textStyle.copyWith(color: foregroundColor));
    }
    
    if (gradient != null) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: elevation > 0 ? [
              BoxShadow(
                color: (isDark ? AppColors.shadowDark : AppColors.shadow).withOpacity(0.3),
                blurRadius: elevation * 2,
                offset: Offset(0, elevation),
              ),
            ] : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                padding: padding,
                child: Center(child: buttonChild),
              ),
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: elevation,
          shadowColor: isDark ? AppColors.shadowDark : AppColors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
            side: borderColor != null 
                ? BorderSide(color: borderColor!, width: 1)
                : BorderSide.none,
          ),
          padding: padding,
        ),
        child: buttonChild,
      ),
    );
  }
}

class ModernIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final ModernButtonSize size;
  final ModernButtonVariant variant;
  final String? tooltip;
  final BorderRadius? borderRadius;

  const ModernIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.size = ModernButtonSize.medium,
    this.variant = ModernButtonVariant.ghost,
    this.tooltip,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Size configurations
    double buttonSize;
    double iconSize;
    
    switch (size) {
      case ModernButtonSize.small:
        buttonSize = 36;
        iconSize = 16;
        break;
      case ModernButtonSize.medium:
        buttonSize = 48;
        iconSize = 20;
        break;
      case ModernButtonSize.large:
        buttonSize = 56;
        iconSize = 24;
        break;
    }
    
    // Variant configurations
    Color backgroundColor;
    Color foregroundColor;
    Color? borderColor;
    
    switch (variant) {
      case ModernButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = Colors.white;
        borderColor = null;
        break;
      case ModernButtonVariant.secondary:
        backgroundColor = AppColors.secondary;
        foregroundColor = Colors.white;
        borderColor = null;
        break;
      case ModernButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primary;
        borderColor = AppColors.primary;
        break;
      case ModernButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
        borderColor = null;
        break;
      case ModernButtonVariant.danger:
        backgroundColor = AppColors.error;
        foregroundColor = Colors.white;
        borderColor = null;
        break;
    }
    
    Widget button = Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
        border: borderColor != null 
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
          child: Center(
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: IconTheme(
                data: IconThemeData(
                  color: foregroundColor,
                  size: iconSize,
                ),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
    
    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    
    return button;
  }
}