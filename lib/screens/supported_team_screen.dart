// lib/screens/supported_team_screen.dart
import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../design_system/widgets/modern_card.dart';
import '../design_system/widgets/modern_button.dart';
import '../design_system/widgets/modern_app_bar.dart';
import '../services/favorites_service.dart';
import '../models/user_profile_model.dart';
import '../services/logo_service.dart';
import '../services/team_name_service.dart';
import '../data_service.dart';

class SupportedTeamScreen extends StatefulWidget {
  const SupportedTeamScreen({Key? key}) : super(key: key);

  @override
  State<SupportedTeamScreen> createState() => _SupportedTeamScreenState();
}

class _SupportedTeamScreenState extends State<SupportedTeamScreen> {
  String? _selectedLeague;
  String? _selectedTeam;
  FavoriteTeam? _currentSupportedTeam;
  List<String> _availableTeams = [];
  bool _isLoading = true;
  bool _isLoadingTeams = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSupportedTeam();
  }

  Future<void> _loadCurrentSupportedTeam() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supportedTeam = await FavoritesService.getStaticSupportedTeam();
      setState(() {
        _currentSupportedTeam = supportedTeam;
        _selectedLeague = supportedTeam?.league;
        _selectedTeam = supportedTeam?.name;
        _isLoading = false;
      });

      if (_selectedLeague != null) {
        await _loadTeamsForLeague(_selectedLeague!);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeamsForLeague(String league) async {
    setState(() {
      _isLoadingTeams = true;
    });

    try {
      // DataService'den takımları al (mevcut sezon için)
      final teams = DataService.getTeamsForLeague(league);
      setState(() {
        _availableTeams = teams;
        _isLoadingTeams = false;
      });
    } catch (e) {
      setState(() {
        _availableTeams = [];
        _isLoadingTeams = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Tuttuğu Takım',
        actions: [
          if (_currentSupportedTeam != null)
            ModernIconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSupportedTeam,
              variant: ModernButtonVariant.ghost,
              tooltip: 'Temizle',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Supported Team
                  if (_currentSupportedTeam != null) ...[
                    _buildCurrentSupportedTeam(context, isDark),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // League Selection
                  _buildLeagueSelection(context, isDark),

                  const SizedBox(height: AppSpacing.lg),

                  // Team Selection
                  if (_selectedLeague != null) ...[
                    _buildTeamSelection(context, isDark),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Save Button
                  if (_selectedLeague != null && _selectedTeam != null)
                    ModernButton(
                      text: 'Kaydet',
                      onPressed: _saveSupportedTeam,
                      isFullWidth: true,
                      variant: ModernButtonVariant.primary,
                      icon: const Icon(Icons.save),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentSupportedTeam(BuildContext context, bool isDark) {
    final team = _currentSupportedTeam!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mevcut Tuttuğu Takım',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: AppTypography.bold,
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        ModernCard(
          backgroundColor: AppColors.primary.withOpacity(0.05),
          hasBorder: true,
          borderColor: AppColors.primary.withOpacity(0.2),
          child: Row(
            children: [
              // Team Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: LogoService.getTeamLogo(team.name, team.league) ??
                      Icon(
                        Icons.sports_soccer,
                        color: AppColors.primary,
                        size: 30,
                      ),
                ),
              ),
              
              const SizedBox(width: AppSpacing.lg),
              
              // Team Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TeamNameService.getCorrectedTeamName(team.name),
                      style: AppTypography.titleLarge.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xs),
                    
                    Text(
                      team.league,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Heart Icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.favorite,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueSelection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lig Seçin',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: AppTypography.bold,
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        ModernCard(
          child: Column(
            children: DataService.leagueDisplayNames.asMap().entries.map((entry) {
              final index = entry.key;
              final leagueName = entry.value;
              final isSelected = _selectedLeague == leagueName;
              
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      leagueName,
                      style: AppTypography.titleMedium.copyWith(
                        color: isSelected 
                            ? AppColors.primary 
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        fontWeight: isSelected ? AppTypography.semiBold : AppTypography.regular,
                      ),
                    ),
                    trailing: isSelected 
                        ? Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () => _selectLeague(leagueName),
                  ),
                  if (index < DataService.leagueDisplayNames.length - 1)
                    const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSelection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Takım Seçin',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: AppTypography.bold,
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        if (_isLoadingTeams)
          const Center(child: CircularProgressIndicator())
        else if (_availableTeams.isEmpty)
          ModernCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Bu lig için takım bulunamadı',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          )
        else
          ModernCard(
            child: Column(
              children: _availableTeams.asMap().entries.map((entry) {
                final index = entry.key;
                final teamName = entry.value;
                final isSelected = _selectedTeam == teamName;
                
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          child: LogoService.getTeamLogo(teamName, _selectedLeague!) ??
                              Icon(
                                Icons.sports_soccer,
                                color: isSelected ? AppColors.primary : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                                size: 20,
                              ),
                        ),
                      ),
                      title: Text(
                        TeamNameService.getCorrectedTeamName(teamName),
                        style: AppTypography.titleMedium.copyWith(
                          color: isSelected 
                              ? AppColors.primary 
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                          fontWeight: isSelected ? AppTypography.semiBold : AppTypography.regular,
                        ),
                      ),
                      trailing: isSelected 
                          ? Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                      onTap: () => _selectTeam(teamName),
                    ),
                    if (index < _availableTeams.length - 1)
                      const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _selectLeague(String league) {
    setState(() {
      _selectedLeague = league;
      _selectedTeam = null;
    });
    _loadTeamsForLeague(league);
  }

  void _selectTeam(String team) {
    setState(() {
      _selectedTeam = team;
    });
  }

  Future<void> _saveSupportedTeam() async {
    if (_selectedLeague != null && _selectedTeam != null) {
      await FavoritesService.setStaticSupportedTeam(FavoriteTeam(
        name: _selectedTeam!, 
        league: _selectedLeague!, 
        season: '2024-2025',
        logoUrl: ''
      ));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tuttuğu takım ${TeamNameService.getCorrectedTeamName(_selectedTeam!)} olarak ayarlandı'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
        );
        
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _clearSupportedTeam() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tuttuğu Takımı Temizle'),
        content: const Text('Tuttuğu takım ayarını kaldırmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ModernButton(
            text: 'Temizle',
            onPressed: () => Navigator.pop(context, true),
            variant: ModernButtonVariant.danger,
            size: ModernButtonSize.small,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FavoritesService.setStaticSupportedTeam(null);
      await _loadCurrentSupportedTeam();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tuttuğu takım ayarı temizlendi'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
