// lib/team_profile_screen.dart (Modern Tasarım)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'features/team_profile/team_profile_controller.dart';
import 'services/logo_service.dart';
import 'services/team_name_service.dart';
import 'services/favorites_service.dart';
import 'utils/activity_logger.dart';
import 'widgets/profile_overview_tab.dart';
import 'widgets/profile_stats_tab.dart';
import 'widgets/profile_matches_tab.dart';
import 'design_system/app_colors.dart';
import 'design_system/app_spacing.dart';
import 'design_system/app_typography.dart';

class TeamProfileScreen extends ConsumerStatefulWidget {
  final String originalTeamName;
  final String leagueName;
  final String currentSeasonApiValue;

  const TeamProfileScreen({
    super.key,
    required this.originalTeamName,
    required this.leagueName,
    required this.currentSeasonApiValue,
  });

  @override
  ConsumerState<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends ConsumerState<TeamProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final FavoritesService _favoritesService = FavoritesService();
  PaletteGenerator? _palette;
  bool _isFavorite = false;
  bool _isTogglingFavorite = false; // Favori durumu değiştirilirken bekleme durumu

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updatePalette();
    _checkFavoriteStatus();
    
    // Takım analizi aktivitesini kaydet
    ActivityLogger.logTeamAnalysis(widget.originalTeamName, widget.leagueName);
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorite = await _favoritesService.isFavoriteTeam(widget.originalTeamName);
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return; // Zaten işlem yapılıyorsa tekrar tetikleme

    setState(() => _isTogglingFavorite = true);

    try {
      final teamName = widget.originalTeamName;
      final league = widget.leagueName;
      final season = widget.currentSeasonApiValue;
      String message;

      if (_isFavorite) {
        await _favoritesService.removeFavoriteTeam(teamName);
        message = '$teamName favorilerden kaldırıldı';
      } else {
        await _favoritesService.addFavoriteTeam(teamName, league, season);
        message = '$teamName favorilere eklendi';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: _isFavorite ? AppColors.warning : AppColors.success),
        );
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingFavorite = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updatePalette() async {
    final String? logoUrl = LogoService.getTeamLogoUrl(widget.originalTeamName, widget.leagueName);
    if (logoUrl == null) return;
    try {
      final provider = CachedNetworkImageProvider(logoUrl);
      final palette = await PaletteGenerator.fromImageProvider(provider, size: const Size(100, 100));
      if (mounted) {
        setState(() {
          _palette = palette;
        });
      }
    } catch (e) {
      debugPrint("Palette generation failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = teamProfileProvider((
      teamName: widget.originalTeamName,
      leagueName: widget.leagueName,
      season: widget.currentSeasonApiValue
    ));
    final profileDataAsync = ref.watch(provider.select((s) => s.profileData));

    return Scaffold(
      body: profileDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
        data: (data) => _buildProfilePage(context, data, ref),
      ),
    );
  }

  Widget _buildProfilePage(BuildContext context, TeamProfileData data, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = teamProfileProvider((
      teamName: widget.originalTeamName,
      leagueName: widget.leagueName,
      season: widget.currentSeasonApiValue
    ));
    final profileState = ref.watch(provider);
    final displayName = TeamNameService.getCorrectedTeamName(widget.originalTeamName);
    final logoUrl = LogoService.getTeamLogoUrl(widget.originalTeamName, widget.leagueName);
    final Color gradStart = _palette?.darkVibrantColor?.color ?? AppColors.primary;
    final Color gradEnd = _palette?.dominantColor?.color ?? AppColors.primaryVariant;
    final Color titleColor = gradStart.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 220.0,
                floating: true,
                pinned: true,
                backgroundColor: gradStart,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: titleColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: _isTogglingFavorite
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                        : Icon(_isFavorite ? Icons.star : Icons.star_border, color: _isFavorite ? Colors.amber : titleColor),
                    onPressed: _toggleFavorite,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [gradStart, gradEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: SafeArea(
                      child: _buildExpandedTeamHeader(context, displayName, logoUrl, titleColor),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: _SimpleFilterCard(label: "Genel", isSelected: profileState.selectedFilter == TeamStatFilter.genel, onTap: () => ref.read(provider.notifier).setFilter(TeamStatFilter.genel))),
                      const SizedBox(width: 8),
                      Expanded(child: _SimpleFilterCard(label: "İç Saha", isSelected: profileState.selectedFilter == TeamStatFilter.icSaha, onTap: () => ref.read(provider.notifier).setFilter(TeamStatFilter.icSaha))),
                      const SizedBox(width: 8),
                      Expanded(child: _SimpleFilterCard(label: "Deplasman", isSelected: profileState.selectedFilter == TeamStatFilter.disSaha, onTap: () => ref.read(provider.notifier).setFilter(TeamStatFilter.disSaha))),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _ModernTabBarDelegate(
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: const [Tab(text: "Genel Bakış"), Tab(text: "İstatistikler"), Tab(text: "Maçlar")],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              ProfileOverviewTab(teamStats: _getStatsForFilter(data, profileState.selectedFilter)),
              ProfileStatsTab(stats: _getStatsForFilter(data, profileState.selectedFilter)),
              ProfileMatchesTab(matches: _getMatchesForFilter(data, profileState.selectedFilter), teamName: widget.originalTeamName, leagueName: widget.leagueName, currentSeasonApiValue: widget.currentSeasonApiValue, filterType: profileState.selectedFilter),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatsForFilter(TeamProfileData data, TeamStatFilter filter) {
    switch (filter) {
      case TeamStatFilter.genel: return data.overallStats;
      case TeamStatFilter.icSaha: return data.homeStats;
      case TeamStatFilter.disSaha: return data.awayStats;
    }
  }

  List<Map<String, dynamic>> _getMatchesForFilter(TeamProfileData data, TeamStatFilter filter) {
    switch (filter) {
      case TeamStatFilter.genel: return data.allMatches;
      case TeamStatFilter.icSaha: return data.allMatches.where((m) => m['HomeTeam'] == widget.originalTeamName).toList();
      case TeamStatFilter.disSaha: return data.allMatches.where((m) => m['AwayTeam'] == widget.originalTeamName).toList();
    }
  }

  Widget _buildExpandedTeamHeader(BuildContext context, String displayName, String? logoUrl, Color titleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
            child: logoUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(14), child: CachedNetworkImage(imageUrl: logoUrl, fit: BoxFit.contain, errorWidget: (c, u, e) => Icon(Icons.shield_outlined, size: 36, color: titleColor)))
                : Icon(Icons.shield_outlined, size: 36, color: titleColor),
          ),
          const SizedBox(height: 12),
          Text(displayName, style: TextStyle(color: titleColor, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(widget.leagueName, style: TextStyle(color: titleColor.withOpacity(0.9), fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SimpleFilterCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SimpleFilterCard({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: 1),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
      ),
    );
  }
}

class _ModernTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _ModernTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => tabBar.preferredSize.height + 16;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: 2,
      color: isDark ? AppColors.backgroundDark : AppColors.surface,
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border, width: 0.5))),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: tabBar),
      ),
    );
  }

  @override
  bool shouldRebuild(_ModernTabBarDelegate oldDelegate) => false;
}
