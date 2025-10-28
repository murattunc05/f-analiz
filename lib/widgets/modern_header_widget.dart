import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../design_system/widgets/modern_button.dart';
import '../services/user_service.dart';
import '../services/profile_update_service.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../screens/profile_screen.dart';

class ModernHeaderWidget extends StatefulWidget {
  final VoidCallback onSettingsTap;
  final VoidCallback onSearchTap;
  final VoidCallback? onThemeSettingsTap;
  final VoidCallback? onStatsSettingsTap;
  final VoidCallback? onAboutTap;
  final Function(String)? onBrightnessChanged;
  final String? currentBrightness;

  const ModernHeaderWidget({
    super.key,
    required this.onSettingsTap,
    required this.onSearchTap,
    this.onThemeSettingsTap,
    this.onStatsSettingsTap,
    this.onAboutTap,
    this.onBrightnessChanged,
    this.currentBrightness,
  });

  @override
  State<ModernHeaderWidget> createState() => _ModernHeaderWidgetState();
}

class _ModernHeaderWidgetState extends State<ModernHeaderWidget> {
  String? _profileImagePath;
  StreamSubscription<ProfileUpdateEvent>? _profileUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _setupProfileUpdateListener();
  }

  void _setupProfileUpdateListener() {
    _profileUpdateSubscription = ProfileUpdateService.updates.listen((event) {
      if (event.type == ProfileUpdateType.profileImage) {
        setState(() {
          _profileImagePath = event.data['imagePath'];
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Profil fotoğrafı değişikliklerini dinlemek için
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      String? imagePath;
      
      // Kullanıcı giriş yapmışsa UserProfileService'ten de kontrol et
      if (AuthService.isSignedIn) {
        final userProfileService = UserProfileService();
        final profile = await userProfileService.loadUserProfile();
        imagePath = profile?.photoURL;
      }
      
      // Eğer UserProfileService'ten alamadıysak UserService'ten dene
      if (imagePath == null || imagePath.isEmpty) {
        imagePath = await UserService.getProfileImagePath();
      }
      
      if (mounted) {
        setState(() {
          _profileImagePath = imagePath;
        });
      }
    } catch (e) {
      print('Header profil fotoğrafı yüklenirken hata: $e');
      // Hata durumunda UserService'ten dene
      final imagePath = await UserService.getProfileImagePath();
      if (mounted) {
        setState(() {
          _profileImagePath = imagePath;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.03),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top row with settings and search - more compact
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  // Settings/Profile button
                  _buildProfileButton(),
                  
                  const Spacer(),
                  
                  // Search button
                  ModernIconButton(
                    icon: const Icon(Icons.search, size: 20),
                    onPressed: widget.onSearchTap,
                    variant: ModernButtonVariant.ghost,
                    tooltip: 'Takım Ara',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Logo and title - more compact
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Smaller, cleaner logo design
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: AppSpacing.sm),
                
                // Smaller app title
                Text(
                  'GOALITYCS',
                  style: AppTypography.headlineLarge.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: AppTypography.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xs),
            
            // Smaller subtitle
            Text(
              'Futbol Analiz Platformu',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    if (_profileImagePath != null && File(_profileImagePath!).existsSync()) {
      // Profil fotoğrafı varsa onu göster
      return GestureDetector(
        onTap: () => _showPremiumSettingsMenu(context),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.file(
              File(_profileImagePath!),
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultSettingsButton();
              },
            ),
          ),
        ),
      );
    } else {
      // Profil fotoğrafı yoksa ayarlar iconunu göster
      return _buildDefaultSettingsButton();
    }
  }

  Widget _buildDefaultSettingsButton() {
    return ModernIconButton(
      icon: const Icon(Icons.settings_outlined, size: 20),
      onPressed: () => _showPremiumSettingsMenu(context),
      variant: ModernButtonVariant.ghost,
      tooltip: 'Ayarlar',
    );
  }

  void _showPremiumSettingsMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      
                      const SizedBox(width: AppSpacing.md),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ayarlar',
                              style: AppTypography.headlineSmall.copyWith(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            Text(
                              'Uygulamayı kişiselleştirin',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Menu items
                _buildPremiumMenuItem(
                  context,
                  'Profil',
                  'Kişisel bilgilerinizi düzenleyin',
                  Icons.person_outline,
                  AppColors.primary,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    ).then((_) {
                      // Profil ekranından döndükten sonra profil fotoğrafını yenile
                      _loadProfileImage();
                    });
                  },
                ),
                
                _buildPremiumMenuItem(
                  context,
                  'Tema',
                  'Görünümü kişiselleştirin',
                  Icons.palette_outlined,
                  AppColors.secondary,
                  () {
                    Navigator.pop(context);
                    _showModernThemeSettings(context);
                  },
                ),
                
                _buildPremiumMenuItem(
                  context,
                  'Bildirimler',
                  'Bildirim tercihlerinizi ayarlayın',
                  Icons.notifications_outlined,
                  AppColors.accent,
                  () {
                    Navigator.pop(context);
                    _showNotificationSettings(context);
                  },
                ),
                
                _buildPremiumMenuItem(
                  context,
                  'İstatistikler ve Sezon',
                  'Analiz ayarları ve aktif sezon yönetimi',
                  Icons.analytics_outlined,
                  AppColors.success,
                  () {
                    Navigator.pop(context);
                    widget.onStatsSettingsTap?.call();
                  },
                ),
                
                _buildPremiumMenuItem(
                  context,
                  'Hakkında',
                  'Uygulama bilgileri',
                  Icons.info_outline,
                  AppColors.info,
                  () {
                    Navigator.pop(context);
                    widget.onAboutTap?.call();
                  },
                ),
                
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundSecondaryDark : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
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
        title: Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: AppTypography.semiBold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          size: 20,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Bildirimler',
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bildirim ayarları yakında eklenecek.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Şu anda profil ayarlarından bildirimler açılıp kapatılabilir.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tamam',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showModernThemeSettings(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.secondary, AppColors.secondary.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      
                      const SizedBox(width: AppSpacing.md),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tema Ayarları',
                              style: AppTypography.headlineSmall.copyWith(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            Text(
                              'Görünümü kişiselleştirin',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Brightness Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Görünüm Modu',
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      _buildBrightnessOption(
                        context,
                        'Açık Mod',
                        'Her zaman açık tema kullan',
                        Icons.light_mode,
                        'light',
                        widget.currentBrightness == 'light',
                      ),
                      
                      const SizedBox(height: AppSpacing.sm),
                      
                      _buildBrightnessOption(
                        context,
                        'Koyu Mod',
                        'Her zaman koyu tema kullan',
                        Icons.dark_mode,
                        'dark',
                        widget.currentBrightness == 'dark',
                      ),
                      
                      const SizedBox(height: AppSpacing.sm),
                      
                      _buildBrightnessOption(
                        context,
                        'Sistem Varsayılanı',
                        'Cihaz ayarlarını takip et',
                        Icons.settings_system_daydream,
                        'system',
                        widget.currentBrightness == 'system',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Theme Palette Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _buildPremiumMenuItem(
                    context,
                    'Renk Paleti',
                    'Uygulama renklerini değiştir',
                    Icons.color_lens,
                    AppColors.accent,
                    () {
                      Navigator.pop(context);
                      widget.onThemeSettingsTap?.call();
                    },
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrightnessOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String value,
    bool isSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        widget.onBrightnessChanged?.call(value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.secondary.withOpacity(0.1)
              : (isDark ? AppColors.backgroundSecondaryDark : AppColors.backgroundSecondary),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected 
                ? AppColors.secondary.withOpacity(0.3)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.secondary.withOpacity(0.2)
                    : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? AppColors.secondary
                    : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                size: 20,
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: isSelected 
                          ? AppColors.secondary
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                      fontWeight: isSelected ? AppTypography.semiBold : AppTypography.regular,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.secondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _profileUpdateSubscription?.cancel();
    super.dispose();
  }
}