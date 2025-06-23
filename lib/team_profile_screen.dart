// lib/team_profile_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'features/team_profile/team_profile_controller.dart';
import 'services/logo_service.dart';
import 'services/team_name_service.dart';

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
  // Artık kullanılmadığı için bu satırı kaldırıyoruz.
  // bool _isLoadingPalette = true; 

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
  
  Future<void> _updatePalette() async {
    final String? logoUrl = LogoService.getTeamLogoUrl(widget.originalTeamName, widget.leagueName);
    if (logoUrl == null) {
      if(mounted) setState(() {}); // Palet yoksa bile yeniden çiz
      return;
    }
    try {
      final provider = CachedNetworkImageProvider(logoUrl);
      final palette = await PaletteGenerator.fromImageProvider(provider);
      if (mounted) setState(() { _palette = palette; });
    } catch(e) {
      if(mounted) setState(() {}); // Hata durumunda yeniden çiz
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
        error: (err, stack) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text("Hata: ${err.toString()}", textAlign: TextAlign.center))),
        data: (data) {
          // DEĞİŞİKLİK: Hatalı parametre kaldırıldı
          return _buildProfilePage(context, data, ref);
        },
      ),
    );
  }

  // DEĞİŞİKLİK: Metot imzası düzeltildi
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
    
    // DEĞİŞİKLİK: _isLoadingPalette yerine _palette'nin null olup olmadığı kontrol ediliyor
    Color gradStart = _palette?.darkVibrantColor?.color ?? theme.colorScheme.primary;
    Color gradEnd = _palette?.dominantColor?.color ?? theme.colorScheme.secondary;
    Color titleColor = (gradStart.computeLuminance() > 0.4) ? Colors.black87 : Colors.white;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            stretch: true,
            backgroundColor: gradStart,
            iconTheme: IconThemeData(color: titleColor),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(displayName, style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.5))])),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [gradStart, gradEnd], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (logoUrl != null) Hero(tag: logoUrl, child: SizedBox(height: 90, width: 90, child: CachedNetworkImage(imageUrl: logoUrl))) else Icon(Icons.shield_outlined, size: 90, color: titleColor.withOpacity(0.8)),
                    const SizedBox(height: 12),
                    Text(widget.leagueName, style: TextStyle(color: titleColor.withOpacity(0.9), fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<TeamStatFilter>(
                  groupValue: profileState.selectedFilter,
                  onValueChanged: (value) {
                    if (value != null) {
                      ref.read(provider.notifier).setFilter(value);
                    }
                  },
                  children: const {
                    TeamStatFilter.genel: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("Genel")),
                    TeamStatFilter.icSaha: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("İç Saha")),
                    TeamStatFilter.disSaha: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("Dış Saha")),
                  },
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [ Tab(text: "Genel Bakış"), Tab(text: "Detaylar"), Tab(text: "Fikstür"), ],
              ),
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(data, profileState.selectedFilter),
          _buildDetailedStatsTab(data, profileState.selectedFilter),
          _buildMatchesTab(data.allMatches, widget.originalTeamName),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(TeamProfileData data, TeamStatFilter filter) {
    final stats = _getStatsForFilter(data, filter);
    if ((stats['oynananMacSayisi'] as num?)?.toInt() == 0) return const Center(child: Text("Veri yok."));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatRow(label: "Galibiyet / Beraberlik / Mağlubiyet", value: "${stats['galibiyet']} / ${stats['beraberlik']} / ${stats['maglubiyet']}"),
          _StatRow(label: "Atılan / Yenilen Gol", value: "${stats['attigi']} / ${stats['yedigi']}"),
          _StatRow(label: "Puan", value: (((stats['galibiyet'] as int) * 3) + (stats['beraberlik'] as int)).toString()),
        ],
      ),
    );
  }

  Widget _buildDetailedStatsTab(TeamProfileData data, TeamStatFilter filter) {
    final stats = _getStatsForFilter(data, filter);
    if ((stats['oynananMacSayisi'] as num?)?.toInt() == 0) return const Center(child: Text("Veri yok."));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatRow(label: "Maç Başı Gol Ort.", value: (stats['macBasiOrtalamaGol'] as num?)?.toStringAsFixed(2) ?? "-"),
          _StatRow(label: "Maçlardaki Toplam Gol Ort.", value: (stats['maclardaOrtalamaToplamGol'] as num?)?.toStringAsFixed(2) ?? "-"),
          _StatRow(label: "KG Var Yüzdesi", value: "%${(stats['kgVarYuzdesi'] as num?)?.toStringAsFixed(1) ?? "-"}"),
          _StatRow(label: "Clean Sheet Yüzdesi", value: "%${(stats['cleanSheetYuzdesi'] as num?)?.toStringAsFixed(1) ?? "-"}"),
          _StatRow(label: "Ortalama Şut", value: (stats['ortalamaSut'] as num?)?.toStringAsFixed(1) ?? "N/A"),
          _StatRow(label: "Ortalama İsabetli Şut", value: (stats['ortalamaIsabetliSut'] as num?)?.toStringAsFixed(1) ?? "N/A"),
          _StatRow(label: "Ortalama Korner", value: (stats['ortalamaKorner'] as num?)?.toStringAsFixed(1) ?? "N/A"),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(List<Map<String, dynamic>> matches, String teamName) {
    if (matches.isEmpty) return const Center(child: Text("Maç bulunamadı."));
    
    // DEĞİŞİKLİK: Güvenli sıralama mantığı
    matches.sort((a, b) {
      final dateA = a['_parsedDate'] as DateTime?;
      final dateB = b['_parsedDate'] as DateTime?;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) => _MatchResultCard(match: matches[index], teamName: teamName),
    );
  }
  
  Map<String, dynamic> _getStatsForFilter(TeamProfileData data, TeamStatFilter filter) {
    switch (filter) {
      case TeamStatFilter.genel: return data.overallStats;
      case TeamStatFilter.icSaha: return data.homeStats;
      case TeamStatFilter.disSaha: return data.awayStats;
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MatchResultCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final String teamName;
  const _MatchResultCard({required this.match, required this.teamName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeTeam = match['HomeTeam'] as String;
    final awayTeam = match['AwayTeam'] as String;
    final homeGoals = match['FTHG'];
    final awayGoals = match['FTAG'];
    final result = match['FTR'] as String;
    final date = match['Date'] as String;
    
    final bool isHomeTeam = homeTeam == teamName;
    
    Color resultColor;
    if ((isHomeTeam && result == 'H') || (!isHomeTeam && result == 'A')) {
      resultColor = Colors.green;
    } else if (result == 'D') {
      resultColor = Colors.orange;
    } else {
      resultColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: resultColor, width: 4)),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8)
      ),
      child: Column(
        children: [
          Text(date, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(TeamNameService.getCorrectedTeamName(homeTeam), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge)),
              Text("$homeGoals - $awayGoals", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Expanded(child: Text(TeamNameService.getCorrectedTeamName(awayTeam), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge)),
            ],
          ),
        ],
      ),
    );
  }
}