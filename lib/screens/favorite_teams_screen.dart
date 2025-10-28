// lib/screens/favorite_teams_screen.dart
import 'package:flutter/material.dart';
import 'package:futbol_analiz_app/models/user_profile_model.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../design_system/widgets/modern_card.dart';
import '../design_system/widgets/modern_button.dart';
import '../design_system/widgets/modern_app_bar.dart';
import '../services/favorites_service.dart';
import '../services/logo_service.dart';
import '../services/team_name_service.dart';
import '../team_profile_screen.dart';
import '../team_search_screen.dart';

class FavoriteTeamsScreen extends StatefulWidget {
  const FavoriteTeamsScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteTeamsScreen> createState() => _FavoriteTeamsScreenState();
}

class _FavoriteTeamsScreenState extends State<FavoriteTeamsScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  List<FavoriteTeam> _favoriteTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteTeams();
  }

  Future<void> _loadFavoriteTeams() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final favorites = await _favoritesService.getFavoriteTeams();
      if (mounted) {
        setState(() {
          _favoriteTeams = favorites;
        });
      }
    } catch (e) {
      // Hata mesajı göster
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Favori Takımlar',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToTeamSearch,
            tooltip: 'Yeni Takım Ekle',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteTeams.isEmpty
              ? _buildEmptyState(context)
              : _buildFavoritesList(isDark),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 80, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            const Text('Henüz Favori Takımınız Yok', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Takımları favorilerinize ekleyerek analizlerinize hızlıca erişin.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            ModernButton(
              text: 'Hemen Takım Ekle',
              onPressed: _navigateToTeamSearch,
              icon: const Icon(Icons.search),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _favoriteTeams.length,
      itemBuilder: (context, index) {
        final team = _favoriteTeams[index];
        return _buildFavoriteTeamCard(context, team, isDark);
      },
    );
  }

  Widget _buildFavoriteTeamCard(BuildContext context, FavoriteTeam team, bool isDark) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: () => _openTeamProfile(team),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: LogoService.getTeamLogo(team.name, team.league) ?? const Icon(Icons.sports_soccer),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TeamNameService.getCorrectedTeamName(team.name),
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${team.league} • ${team.season}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _removeFavoriteTeam(team),
            tooltip: 'Favorilerden Kaldır',
          ),
        ],
      ),
    );
  }

  void _openTeamProfile(FavoriteTeam team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamProfileScreen(
          originalTeamName: team.name,
          leagueName: team.league,
          currentSeasonApiValue: team.season,
        ),
      ),
    );
  }

  Future<void> _removeFavoriteTeam(FavoriteTeam team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Favorilerden Kaldır'),
        content: Text('${TeamNameService.getCorrectedTeamName(team.name)} takımını kaldırmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaldır', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _favoritesService.removeFavoriteTeam(team.name);
      _loadFavoriteTeams(); // Listeyi yenile
    }
  }

  void _navigateToTeamSearch() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TeamSearchScreen(),
      ),
    );

    // TeamSearchScreen'den bir takım seçilip favorilere eklendiyse,
    // bu ekran geri döndüğünde listeyi yeniliyoruz.
    if (result == true) {
      _loadFavoriteTeams();
    }
  }
}
