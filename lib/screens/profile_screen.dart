// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:futbol_analiz_app/services/analytics_service.dart';
import 'package:futbol_analiz_app/services/favorites_service.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../design_system/widgets/modern_card.dart';
import '../design_system/widgets/modern_button.dart';
import '../services/league_logo_service.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/user_service.dart';
import '../services/profile_update_service.dart';
import '../models/user_profile_model.dart';
import '../widgets/profile_image_picker.dart';
import 'edit_profile_screen.dart';
import 'favorite_teams_screen.dart';
import 'auth_screen.dart';
import 'profile_completion_screen.dart';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // AuthService static sınıf olduğu için instance oluşturmaya gerek yok
  final UserProfileService _userProfileService = UserProfileService();
  final FavoritesService _favoritesService = FavoritesService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _showAllActivities = false;
  List<Map<String, String>> _recentActivities = [];
  int _favoriteTeamsCount = 0;
  Map<String, int> _userStats = {};
  late StreamSubscription _profileUpdateSubscription;

  @override
  void initState() {
    super.initState();
    AuthService.authStateChanges.listen((_) {
      _loadProfileData();
    });
    
    // Profil güncellemelerini dinle
    _profileUpdateSubscription = ProfileUpdateService.updates.listen((event) {
      if (event.type == ProfileUpdateType.profileImage) {
        // Profil fotoğrafı güncellendiğinde sadece UI'ı yenile
        if (mounted) {
          setState(() {
            // Profil fotoğrafı güncellendiğini UI'a bildir
          });
        }
      } else if (event.type == ProfileUpdateType.profile) {
        // Profil bilgileri güncellendiğinde tüm veriyi yenile
        _loadProfileData();
      }
    });
    
    _loadProfileData();
  }

  @override
  void dispose() {
    _profileUpdateSubscription.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await _loadProfileData();
  }



  Future<void> _loadProfileData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      print('Profile Screen: Giriş durumu - ${AuthService.isSignedIn ? "GİRİŞ YAPMIŞ" : "MİSAFİR"}');
      
      if (AuthService.isSignedIn) {
        final profile = await _userProfileService.loadUserProfile();
        final favCount = await _favoritesService.getFavoriteTeamsCount();
        final analytics = await AnalyticsService.getAnalytics();
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _favoriteTeamsCount = favCount;
            _userStats = {
              'totalAnalysis': analytics['totalAnalysis'] ?? 0,
              'totalComparisons': analytics['totalComparisons'] ?? 0,
            };
          });
        }

        // Aktiviteleri ayrı bir try-catch ile yükle
        try {
          final activities = await AnalyticsService.getRecentActivities();
          final userServiceActivities = await UserService.getRecentActivities();
          
          print('Profile Screen: AnalyticsService aktivite sayısı: ${activities.length}');
          print('Profile Screen: UserService aktivite sayısı: ${userServiceActivities.length}');
          print('Profile Screen: AnalyticsService aktiviteler: $activities');
          print('Profile Screen: UserService aktiviteler: $userServiceActivities');
          
          if (mounted) {
            setState(() {
              // AnalyticsService ve UserService aktivitelerini birleştir
              final allActivities = <Map<String, String>>[];
              
              // AnalyticsService aktivitelerini ekle
              for (final activity in activities) {
                allActivities.add({
                  'description': (activity['description'] ?? '').toString(),
                  'time': (activity['timestamp'] ?? '').toString(),
                });
              }
              
              // UserService aktivitelerini ekle - DÜZELTME: timestamp kullan
              for (final activity in userServiceActivities) {
                allActivities.add({
                  'description': (activity['description'] ?? '').toString(),
                  'time': (activity['timestamp'] ?? '').toString(),
                });
              }
              
              // Zaman damgasına göre sırala (en yeni önce)
              allActivities.sort((a, b) {
                try {
                  DateTime timeA, timeB;
                  
                  // AnalyticsService'ten gelen timestamp (millisecondsSinceEpoch)
                  final timeStrA = a['time'] ?? '';
                  if (timeStrA.contains('T')) {
                    // ISO string format (UserService)
                    timeA = DateTime.tryParse(timeStrA) ?? DateTime.now();
                  } else {
                    // Milliseconds format (AnalyticsService)
                    final millis = int.tryParse(timeStrA);
                    timeA = millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : DateTime.now();
                  }
                  
                  final timeStrB = b['time'] ?? '';
                  if (timeStrB.contains('T')) {
                    // ISO string format (UserService)
                    timeB = DateTime.tryParse(timeStrB) ?? DateTime.now();
                  } else {
                    // Milliseconds format (AnalyticsService)
                    final millis = int.tryParse(timeStrB);
                    timeB = millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : DateTime.now();
                  }
                  
                  return timeB.compareTo(timeA); // En yeni önce
                } catch (e) {
                  return 0;
                }
              });
              
              _recentActivities = allActivities.take(10).toList();
              
              print('Profile Screen: Birleştirilmiş aktivite sayısı: ${_recentActivities.length}');
              print('Profile Screen: Final aktiviteler: $_recentActivities');
            });
          }
        } catch (e) {
          print("Aktiviteler yüklenirken hata: $e");
          if (mounted) {
            setState(() {
              _recentActivities = [];
            });
          }
        }
      } else {
        // Misafir kullanıcı için veri yükle
        print('Profile Screen: Misafir kullanıcı için veri yükleniyor...');
        
        final favCount = await _favoritesService.getFavoriteTeamsCount();
        final analytics = await AnalyticsService.getAnalytics();
        
        if (mounted) {
          setState(() {
            _userProfile = null;
            _favoriteTeamsCount = favCount;
            _userStats = {
              'totalAnalysis': analytics['totalAnalysis'] ?? 0,
              'totalComparisons': analytics['totalComparisons'] ?? 0,
            };
          });
        }

        // Misafir kullanıcı için aktiviteleri yükle
        try {
          final activities = await AnalyticsService.getRecentActivities();
          final userServiceActivities = await UserService.getRecentActivities();
          
          print('Profile Screen (Misafir): AnalyticsService aktivite sayısı: ${activities.length}');
          print('Profile Screen (Misafir): UserService aktivite sayısı: ${userServiceActivities.length}');
          print('Profile Screen (Misafir): AnalyticsService aktiviteler: $activities');
          print('Profile Screen (Misafir): UserService aktiviteler: $userServiceActivities');
          
          if (mounted) {
            setState(() {
              // AnalyticsService ve UserService aktivitelerini birleştir
              final allActivities = <Map<String, String>>[];
              
              // AnalyticsService aktivitelerini ekle
              for (final activity in activities) {
                allActivities.add({
                  'description': (activity['description'] ?? '').toString(),
                  'time': (activity['timestamp'] ?? '').toString(),
                });
              }
              
              // UserService aktivitelerini ekle - DÜZELTME: timestamp kullan
              for (final activity in userServiceActivities) {
                allActivities.add({
                  'description': (activity['description'] ?? '').toString(),
                  'time': (activity['timestamp'] ?? '').toString(),
                });
              }
              
              // Zaman damgasına göre sırala (en yeni önce)
              allActivities.sort((a, b) {
                try {
                  DateTime timeA, timeB;
                  
                  // AnalyticsService'ten gelen timestamp (millisecondsSinceEpoch)
                  final timeStrA = a['time'] ?? '';
                  if (timeStrA.contains('T')) {
                    // ISO string format (UserService)
                    timeA = DateTime.tryParse(timeStrA) ?? DateTime.now();
                  } else {
                    // Milliseconds format (AnalyticsService)
                    final millis = int.tryParse(timeStrA);
                    timeA = millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : DateTime.now();
                  }
                  
                  final timeStrB = b['time'] ?? '';
                  if (timeStrB.contains('T')) {
                    // ISO string format (UserService)
                    timeB = DateTime.tryParse(timeStrB) ?? DateTime.now();
                  } else {
                    // Milliseconds format (AnalyticsService)
                    final millis = int.tryParse(timeStrB);
                    timeB = millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : DateTime.now();
                  }
                  
                  return timeB.compareTo(timeA); // En yeni önce
                } catch (e) {
                  return 0;
                }
              });
              
              _recentActivities = allActivities.take(10).toList();
              
              print('Profile Screen (Misafir): Birleştirilmiş aktivite sayısı: ${_recentActivities.length}');
              print('Profile Screen (Misafir): Final aktiviteler: $_recentActivities');
            });
          }
        } catch (e) {
          print("Misafir kullanıcı aktiviteleri yüklenirken hata: $e");
          if (mounted) {
            setState(() {
              _recentActivities = [];
            });
          }
        }
      }
    } catch (e, stackTrace) {
      print("Profil verileri yüklenirken hata: $e");
      print("Stack trace: $stackTrace");
      if (mounted) {
        setState(() {
          _userProfile = null;
          _favoriteTeamsCount = 0;
          _userStats = {};
          _recentActivities = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil verileri yüklenirken bir hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isSignedIn = _userProfile != null;
    final isProfileComplete = _userProfile?.isProfileComplete ?? false;

    if (isSignedIn && !isProfileComplete) {
      return ProfileCompletionScreen(
        onCompleted: () {
          setState(() {
            // Profile tamamlandı, sayfayı yenile
          });
          _refreshData();
        },
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            isSignedIn ? _buildAuthenticatedHeader(isDark) : _buildGuestHeader(isDark),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: isSignedIn ? _buildAuthenticatedContent(isDark) : _buildGuestContent(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedHeader(bool isDark) {
    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.surface,
      elevation: 0,
      actions: [
        if (AuthService.isSignedIn)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditProfile(context),
            tooltip: 'Profili Düzenle',
          )
        else
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            child: _buildExpandedAuthenticatedProfileHeader(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestHeader(bool isDark) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Profil',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: AppTypography.semiBold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            child: _buildGuestProfileHeader(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsSection(context, isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildPreferencesSection(context, isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildActivitySection(context, isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildSettingsSection(context, isDark),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildGuestContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGuestStats(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildGuestFavoriteTeams(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildGuestRecentActivities(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildLoginEncouragement(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildGuestSettings(isDark),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildExpandedAuthenticatedProfileHeader(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ProfileImagePicker(
            networkImageUrl: _userProfile?.photoURL,
            initialImagePath: _userProfile?.photoURL,
            size: 100,
            onImageChanged: (imagePath) async {
              // Profil fotoğrafı değiştiğinde profil bilgilerini yenile
              await _loadProfileData();
            },
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?.displayName ?? 'Kullanıcı Adı',
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _userProfile?.email ?? '',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_userProfile?.bio != null && _userProfile!.bio!.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Text(
                _userProfile!.bio!,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İstatistikler',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: AppTypography.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Analiz Sayısı',
                _userStats['totalAnalysis']?.toString() ?? '0',
                Icons.analytics_outlined,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                context,
                'Karşılaştırma',
                _userStats['totalComparisons']?.toString() ?? '0',
                Icons.compare_arrows,
                AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                context,
                'Favori Takım',
                _favoriteTeamsCount.toString(),
                Icons.favorite_outline,
                AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(color: color, fontWeight: AppTypography.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tercihler',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: AppTypography.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ModernCard(
          child: Column(
            children: [
              _buildPreferenceItemWithLeagueLogo(
                context,
                'Favori Lig',
                _userProfile?.favoriteLeague ?? 'Seçilmedi',
                _userProfile?.favoriteLeague,
                Icons.emoji_events_outlined,
                () => _editProfile(context),
              ),
              const Divider(height: 1),
              _buildPreferenceItem(
                context,
                'Tuttuğu Takım',
                _userProfile?.supportedTeam?.name ?? 'Seçilmedi',
                Icons.sports_soccer_outlined,
                () => _editProfile(context),
              ),
              const Divider(height: 1),
              _buildFavoriteTeamsItem(
                context,
                'Favori Takımlar',
                '$_favoriteTeamsCount takım',
                Icons.favorite_outline,
                () => _openFavoriteTeams(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(BuildContext context, String title, String value, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        value,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
    );
  }

  Widget _buildPreferenceItemWithLeagueLogo(BuildContext context, String title, String value, String? leagueName, IconData fallbackIcon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoUrl = leagueName != null ? LeagueLogoService.getLeagueLogo(leagueName) : null;
    return ListTile(
      leading: logoUrl != null
          ? Image.network(logoUrl, width: 24, height: 24, fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: AppColors.primary),
            )
          : Icon(fallbackIcon, color: AppColors.primary),
      title: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        value,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
    );
  }

  Widget _buildFavoriteTeamsItem(BuildContext context, String title, String value, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        value,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildActivitySection(BuildContext context, bool isDark) {
    final displayActivities = _showAllActivities
        ? _recentActivities
        : _recentActivities.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Son Aktiviteler',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: AppTypography.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ModernCard(
          child: _recentActivities.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Henüz aktivite yok',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    ...displayActivities.asMap().entries.map((entry) {
                      final index = entry.key;
                      final activity = entry.value;
                      return Column(
                        children: [
                          _buildActivityItem(
                            context,
                            activity['description'] ?? '',
                            activity['time'] ?? '',
                            _getActivityIcon(activity['description'] ?? ''),
                            _getActivityColor(activity['description'] ?? ''),
                          ),
                          if (index < displayActivities.length - 1)
                            const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                    if (_recentActivities.length > 3) ...[
                      const Divider(height: 1),
                      ListTile(
                        title: Text(
                          _showAllActivities ? 'Daha az göster' : 'Daha fazla göster',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: AppTypography.medium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {
                          setState(() {
                            _showAllActivities = !_showAllActivities;
                          });
                        },
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
  
  IconData _getActivityIcon(String description) {
    if (description.contains('analiz')) return Icons.analytics_outlined;
    if (description.contains('karşılaştır')) return Icons.compare_arrows;
    if (description.contains('favori')) return Icons.favorite;
    return Icons.timeline;
  }

  Color _getActivityColor(String description) {
    if (description.contains('analiz')) return AppColors.primary;
    if (description.contains('karşılaştır')) return AppColors.secondary;
    if (description.contains('favori')) return AppColors.accent;
    return AppColors.primary;
  }

  Widget _buildActivityItem(BuildContext context, String title, String time, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        _formatActivityTime(time),
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ayarlar',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: AppTypography.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ModernCard(
          child: Column(
            children: [
              _buildSettingItem(
                context,
                'Profili Düzenle',
                Icons.edit_outlined,
                () => _editProfile(context),
              ),
              const Divider(height: 1),
              _buildSettingItem(
                context,
                'Yardım & Destek',
                Icons.help_outline,
                () {},
              ),
              const Divider(height: 1),
              _buildSettingItem(
                context,
                'Çıkış Yap',
                Icons.logout,
                () => _showLogoutConfirmation(context),
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildSettingItem(BuildContext context, String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive ? AppColors.error : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;
    
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: AppTypography.titleMedium.copyWith(color: color),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userProfile: _userProfile,
          onProfileUpdated: () {
            _refreshData();
          },
        ),
      ),
    );
  }

  Widget _buildGuestProfileHeader(bool isDark) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Misafir Kullanıcı',
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daha fazla özellik için giriş yapın',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestStats(bool isDark) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İstatistikler',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Analiz',
                  '${_userStats['totalAnalysis'] ?? 0}',
                  Icons.analytics,
                  isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatItem(
                  'Karşılaştırma',
                  '${_userStats['totalComparisons'] ?? 0}',
                  Icons.compare_arrows,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestFavoriteTeams(bool isDark) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favori Takımlar',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FavoriteTeamsScreen(),
                    ),
                  );
                },
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$_favoriteTeamsCount takım',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestRecentActivities(bool isDark) {
    final displayActivities = _recentActivities.take(3).toList();

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son Aktiviteler',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (displayActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Henüz aktivite yok',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: displayActivities.map<Widget>((activity) {
                return _buildSimpleActivityItem(activity, isDark);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark.withOpacity(0.5) : AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleActivityItem(Map<String, String> activity, bool isDark) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Icon(
          Icons.history,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        activity['description'] ?? '',
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        _formatActivityTime(activity['time'] ?? ''),
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }

  String _formatActivityTime(String timeStr) {
    try {
      DateTime time;
      if (timeStr.contains('T')) {
        // ISO string format
        time = DateTime.parse(timeStr);
      } else {
        // Milliseconds format
        final millis = int.tryParse(timeStr);
        time = millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : DateTime.now();
      }
      
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inMinutes < 1) {
        return 'Az önce';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} dakika önce';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} saat önce';
      } else {
        return '${difference.inDays} gün önce';
      }
    } catch (e) {
      return 'Bilinmiyor';
    }
  }

  void _showMoreOptions(BuildContext context) {
    // Guest kullanıcılar için seçenekler
  }

  void _editProfile(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  void _openFavoriteTeams(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoriteTeamsScreen()),
    );
    _refreshData();
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout();
              },
              child: Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Başarıyla çıkış yapıldı.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılırken hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildLoginEncouragement(bool isDark) {
    return ModernCard(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.login, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Hesabınla Daha Fazlası',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Giriş yaparak verilerini senkronize et, özel analizlere eriş ve kişiselleştirilmiş deneyimin keyfini çıkar.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ModernButton(
                  text: 'Giriş Yap',
                  onPressed: () => _showAuthScreen(false),
                  variant: ModernButtonVariant.primary,
                  icon: const Icon(Icons.login),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ModernButton(
                  text: 'Üye Ol',
                  onPressed: () => _showAuthScreen(true),
                  variant: ModernButtonVariant.outline,
                  icon: const Icon(Icons.person_add),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestSettings(bool isDark) {
    return ModernCard(
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
          const SizedBox(height: AppSpacing.lg),
          _buildSettingItem(context, 'Yardım & Destek', Icons.help_outline, () {}),
        ],
      ),
    );
  }

  void _showAuthScreen(bool isSignUp) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuthScreen(
          initialIsSignUp: isSignUp,
          onAuthSuccess: () {
            Navigator.of(context).pop();
            _refreshData();
          },
          onSkip: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}