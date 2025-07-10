// lib/team_profile_screen.dart (Yeniden Tasarlandı)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'features/team_profile/team_profile_controller.dart';
import 'services/logo_service.dart';
import 'services/team_name_service.dart';
import 'widgets/profile_overview_tab.dart';
import 'widgets/profile_stats_tab.dart';
import 'widgets/profile_matches_tab.dart';
import 'widgets/profile_stat_filter_card.dart';

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
  PaletteGenerator? _palette;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updatePalette();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Takım logosundan baskın renkleri çıkaran asenkron metot.
  Future<void> _updatePalette() async {
    final String? logoUrl = LogoService.getTeamLogoUrl(widget.originalTeamName, widget.leagueName);
    if (logoUrl == null) {
      if (mounted) setState(() {}); // Palet yoksa bile yeniden çiz
      return;
    }
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
      if (mounted) setState(() {}); // Hata durumunda yeniden çiz
    }
  }

  @override
  Widget build(BuildContext context) {
    // Riverpod provider'ını oluşturuyoruz.
    // family modifier'ı sayesinde provider'a parametre geçebiliyoruz.
    final provider = teamProfileProvider((
      teamName: widget.originalTeamName,
      leagueName: widget.leagueName,
      season: widget.currentSeasonApiValue
    ));

    // Veri durumunu izliyoruz (loading, error, data).
    final profileDataAsync = ref.watch(provider.select((s) => s.profileData));

    return Scaffold(
      body: profileDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text("Hata: ${err.toString()}", textAlign: TextAlign.center),
          ),
        ),
        data: (data) {
          // Veri başarıyla geldiğinde ana sayfayı oluştur.
          return _buildProfilePage(context, data, ref);
        },
      ),
    );
  }

  /// Ana profil sayfasını oluşturan ana widget.
  Widget _buildProfilePage(BuildContext context, TeamProfileData data, WidgetRef ref) {
    final theme = Theme.of(context);
    final provider = teamProfileProvider((
      teamName: widget.originalTeamName,
      leagueName: widget.leagueName,
      season: widget.currentSeasonApiValue
    ));
    final profileState = ref.watch(provider);

    final displayName = TeamNameService.getCorrectedTeamName(widget.originalTeamName);
    final logoUrl = LogoService.getTeamLogoUrl(widget.originalTeamName, widget.leagueName);

    // Palette'den dinamik renkleri alıyoruz. Eğer renk yoksa tema renklerini kullan.
    final Color gradStart = _palette?.darkVibrantColor?.color ?? _palette?.darkMutedColor?.color ?? theme.colorScheme.primary;
    final Color gradEnd = _palette?.dominantColor?.color ?? theme.colorScheme.secondary;
    // Başlık ve ikon rengini, arka planın parlaklığına göre belirliyoruz (kontrast için).
    final Color titleColor = gradStart.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return <Widget>[
          // Dinamik ve estetik SliverAppBar
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            stretch: true,
            backgroundColor: gradStart,
            iconTheme: IconThemeData(color: titleColor),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                displayName,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.5))]
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradStart, gradEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (logoUrl != null)
                      Hero(
                        tag: 'team_logo_${widget.originalTeamName}', // Animasyon için benzersiz tag
                        child: CachedNetworkImage(
                          imageUrl: logoUrl,
                          height: 90,
                          width: 90,
                          fit: BoxFit.contain,
                        ),
                      )
                    else
                      Icon(Icons.shield_outlined, size: 90, color: titleColor.withOpacity(0.8)),
                    const SizedBox(height: 12),
                    Text(
                      widget.leagueName,
                      style: TextStyle(color: titleColor.withOpacity(0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Genel / İç Saha / Dış Saha filtresi
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  ProfileStatFilterCard(
                    label: "Genel",
                    icon: Icons.public,
                    isSelected: profileState.selectedFilter == TeamStatFilter.genel,
                    onTap: () => ref.read(provider.notifier).setFilter(TeamStatFilter.genel),
                  ),
                  const SizedBox(width: 8),
                  ProfileStatFilterCard(
                    label: "İç Saha",
                    icon: Icons.home_filled,
                    isSelected: profileState.selectedFilter == TeamStatFilter.icSaha,
                    onTap: () => ref.read(provider.notifier).setFilter(TeamStatFilter.icSaha),
                  ),
                   const SizedBox(width: 8),
                  ProfileStatFilterCard(
                    label: "Dış Saha",
                    icon: Icons.directions_bus_filled,
                    isSelected: profileState.selectedFilter == TeamStatFilter.disSaha,
                    onTap: () => ref.read(provider.notifier).setFilter(TeamStatFilter.disSaha),
                  ),
                ],
              ),
            ),
          ),
          // Sabitlenen TabBar
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: "Genel Bakış"),
                  Tab(text: "İstatistikler"),
                  Tab(text: "Fikstür"),
                ],
              ),
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          ProfileOverviewTab(teamStats: _getStatsForFilter(data, profileState.selectedFilter)),
          ProfileStatsTab(stats: _getStatsForFilter(data, profileState.selectedFilter)),
          ProfileMatchesTab(matches: data.allMatches, teamName: widget.originalTeamName),
        ],
      ),
    );
  }

  /// Seçilen filtreye göre doğru istatistik verisini döndürür.
  Map<String, dynamic> _getStatsForFilter(TeamProfileData data, TeamStatFilter filter) {
    switch (filter) {
      case TeamStatFilter.genel:
        return data.overallStats;
      case TeamStatFilter.icSaha:
        return data.homeStats;
      case TeamStatFilter.disSaha:
        return data.awayStats;
    }
  }
}

/// TabBar'ı SliverAppBar'ın altına sabitlemek için kullanılan yardımcı sınıf.
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
