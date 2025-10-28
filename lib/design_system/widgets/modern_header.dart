// lib/design_system/widgets/modern_header.dart
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import 'modern_button.dart';

class ModernHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
  final bool showSearch;
  final bool showMenu;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool hasGradient;

  const ModernHeader({
    Key? key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.actions,
    this.onMenuTap,
    this.onSearchTap,
    this.showSearch = true,
    this.showMenu = true,
    this.padding,
    this.backgroundColor,
    this.hasGradient = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: hasGradient ? null : (backgroundColor ?? Colors.transparent),
        gradient: hasGradient 
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  Colors.transparent,
                ],
              )
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with menu and actions - more compact
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  // Menu button
                  if (showMenu)
                    ModernIconButton(
                      icon: const Icon(Icons.menu, size: 20),
                      onPressed: onMenuTap,
                      variant: ModernButtonVariant.ghost,
                      tooltip: 'Menü',
                    ),
                  
                  const Spacer(),
                  
                  // Actions
                  if (actions != null) ...actions!,
                  
                  // Search button
                  if (showSearch)
                    ModernIconButton(
                      icon: const Icon(Icons.search, size: 20),
                      onPressed: onSearchTap,
                      variant: ModernButtonVariant.ghost,
                      tooltip: 'Ara',
                    ),
                ],
              ),
            ),
            
            // Title section - reduced spacing
            if (titleWidget != null || title != null) ...[
              const SizedBox(height: AppSpacing.sm),
              if (titleWidget != null)
                titleWidget!
              else if (title != null) ...[
                Text(
                  title!,
                  style: AppTypography.headlineLarge.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class ModernCompactHeader extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuTap;
  final bool showBack;
  final bool showMenu;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const ModernCompactHeader({
    Key? key,
    this.title,
    this.titleWidget,
    this.actions,
    this.onBackPressed,
    this.onMenuTap,
    this.showBack = false,
    this.showMenu = false,
    this.padding,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              // Leading button
              if (showBack)
                ModernIconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: onBackPressed ?? () => Navigator.pop(context),
                  variant: ModernButtonVariant.ghost,
                )
              else if (showMenu)
                ModernIconButton(
                  icon: const Icon(Icons.menu, size: 20),
                  onPressed: onMenuTap,
                  variant: ModernButtonVariant.ghost,
                ),
              
              if (showBack || showMenu)
                const SizedBox(width: AppSpacing.sm),
              
              // Title
              Expanded(
                child: titleWidget ?? (title != null 
                    ? Text(
                        title!,
                        style: AppTypography.headlineMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: AppTypography.semiBold,
                        ),
                      )
                    : const SizedBox.shrink()),
              ),
              
              // Actions
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

class ModernSearchHeader extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onBackPressed;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final bool autofocus;
  final EdgeInsetsGeometry? padding;

  const ModernSearchHeader({
    Key? key,
    this.hintText,
    this.onChanged,
    this.onBackPressed,
    this.onClear,
    this.controller,
    this.autofocus = true,
    this.padding,
  }) : super(key: key);

  @override
  State<ModernSearchHeader> createState() => _ModernSearchHeaderState();
}

class _ModernSearchHeaderState extends State<ModernSearchHeader> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: widget.padding ?? const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              // Back button
              ModernIconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: widget.onBackPressed ?? () => Navigator.pop(context),
                variant: ModernButtonVariant.ghost,
              ),
              
              const SizedBox(width: AppSpacing.sm),
              
              // Search field
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.backgroundSecondaryDark 
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: widget.autofocus,
                    decoration: InputDecoration(
                      hintText: widget.hintText ?? 'Ara...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _hasText
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: _onClear,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}