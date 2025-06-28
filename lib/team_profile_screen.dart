// lib/team_profile_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:fl_chart/fl_chart.dart';
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
    final logoUrl = LogoService.getTeamLogoUrl(widget.originalTeamName, widget.leagueName);
    if (logoUrl == null) {
      if (mounted) setState(() {});
      return;
    }
    try {
      final provider = CachedNetworkImageProvider(logoUrl);
      final palette = await PaletteGenerator.fromImageProvider(provider);
      if (mounted) setState(() => _palette = palette);
    } catch (e) {
      // Hata durumunda palet null kalacak ve varsayılan renkler kullanılacak
      if (mounted) setState(() {});
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
    final theme = Theme.of(context);
    
    // Palette'den renkleri al veya varsayılan renkleri kullan
    final dominantColor = _palette?.dominantColor?.color ?? theme.colorScheme.surface;
    final vibrantColor = _palette?.vibrantColor?.color ?? theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: profileDataAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: vibrantColor)),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 50),
                const SizedBox(height: 16),
                Text("Bir Hata Oluştu", style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(err.toString(), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        data: (data) => _buildProfilePage(context, data, ref, dominantColor, vibrantColor),
      ),
    );
  }

  Widget _buildProfilePage(BuildContext context, TeamProfileData data, WidgetRef ref, Color dominantColor, Color vibrantColor) {
    final provider = teamProfileProvider((
      teamName: widget.originalTeamName,
      leagueName: widget.leagueName,
      season: widget.currentSeasonApiValue
    ));
    final profileState = ref.watch(provider);
    final displayName = TeamNameService.getCorrectedTeamName(widget.originalTeamName);
    final logoUrl = LogoService.getTeamLogoUrl(widget.originalTeamName, widget.leagueName);
    final textColor = dominantColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: dominantColor,
            iconTheme: IconThemeData(color: textColor),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(left: 48, right: 48, bottom: 16),
              title: Text(
                displayName,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [dominantColor, dominantColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (logoUrl != null)
                        Hero(
                          tag: logoUrl,
                          child: CachedNetworkImage(
                            imageUrl: logoUrl,
                            height: 100,
                            width: 100,
                            placeholder: (context, url) => const SizedBox(height: 100, width: 100),
                            errorWidget: (context, url, error) => Icon(Icons.shield, size: 100, color: textColor.withOpacity(0.8)),
                          ),
                        )
                      else
                        Icon(Icons.shield_outlined, size: 100, color: textColor.withOpacity(0.8)),
                      const SizedBox(height: 16),
                      Text(
                        widget.leagueName,
                        style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 48), // Title için boşluk
                    ],
                  ),
                ),
              ),
              stretchModes: const [StretchMode.zoomBackground],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: CupertinoSlidingSegmentedControl<TeamStatFilter>(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                thumbColor: vibrantColor,
                groupValue: profileState.selectedFilter,
                onValueChanged: (value) {
                  if (value != null) ref.read(provider.notifier).setFilter(value);
                },
                children: const {
                  TeamStatFilter.genel: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("Genel")),
                  TeamStatFilter.icSaha: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("İç Saha")),
                  TeamStatFilter.disSaha: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("Dış Saha")),
                },
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: vibrantColor,
                labelColor: vibrantColor,
                unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
                tabs: const [
                  Tab(icon: Icon(Icons.show_chart), text: "Genel Bakış"),
                  Tab(icon: Icon(Icons.analytics_outlined), text: "Detaylar"),
                  Tab(icon: Icon(Icons.sports_soccer_outlined), text: "Fikstür"),
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
          _buildOverviewTab(data, profileState.selectedFilter, vibrantColor),
          _buildDetailedStatsTab(data, profileState.selectedFilter, vibrantColor),
          _buildMatchesTab(data.allMatches, widget.originalTeamName),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(TeamProfileData data, TeamStatFilter filter, Color chartColor) {
    final stats = _getStatsForFilter(data, filter);
    final galibiyet = (stats['galibiyet'] as num?)?.toDouble() ?? 0;
    final beraberlik = (stats['beraberlik'] as num?)?.toDouble() ?? 0;
    final maglubiyet = (stats['maglubiyet'] as num?)?.toDouble() ?? 0;
    final toplamMac = galibiyet + beraberlik + maglubiyet;

    if (toplamMac == 0) return const Center(child: Text("Bu filtre için veri bulunamadı."));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModernStatCard(
            title: "Sezon Performansı",
            child: SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(value: galibiyet, color: Colors.green.shade400, title: 'G', radius: 50, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          PieChartSectionData(value: beraberlik, color: Colors.orange.shade400, title: 'B', radius: 50, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          PieChartSectionData(value: maglubiyet, color: Colors.red.shade400, title: 'M', radius: 50, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendItem(color: Colors.green.shade400, text: "Galibiyet", value: galibiyet.toInt().toString()),
                        _LegendItem(color: Colors.orange.shade400, text: "Beraberlik", value: beraberlik.toInt().toString()),
                        _LegendItem(color: Colors.red.shade400, text: "Mağlubiyet", value: maglubiyet.toInt().toString()),
                        const Divider(height: 20),
                        _LegendItem(color: Theme.of(context).textTheme.bodyLarge!.color!, text: "Toplam Maç", value: toplamMac.toInt().toString()),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ModernStatCard(
            title: "Gol İstatistikleri",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _IconStat(icon: Icons.sports_soccer, label: "Atılan", value: stats['attigi']?.toString() ?? "-", color: Colors.green.shade600),
                _IconStat(icon: Icons.shield_outlined, label: "Yenilen", value: stats['yedigi']?.toString() ?? "-", color: Colors.red.shade600),
                _IconStat(icon: Icons.calculate_outlined, label: "Averaj", value: ((stats['attigi'] ?? 0) - (stats['yedigi'] ?? 0)).toString(), color: chartColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatsTab(TeamProfileData data, TeamStatFilter filter, Color barColor) {
    final stats = _getStatsForFilter(data, filter);
    if ((stats['oynananMacSayisi'] as num?)?.toInt() == 0) return const Center(child: Text("Bu filtre için veri bulunamadı."));
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ModernStatCard(
            title: "Maç Başına Ortalamalar",
            child: Column(
              children: [
                _DetailStatRow(icon: Icons.show_chart, label: "Gol Ortalaması", value: (stats['macBasiOrtalamaGol'] as num?)?.toStringAsFixed(2) ?? "-"),
                _DetailStatRow(icon: Icons.all_inclusive, label: "Maçlarda Toplam Gol Ort.", value: (stats['maclardaOrtalamaToplamGol'] as num?)?.toStringAsFixed(2) ?? "-"),
                _DetailStatRow(icon: Icons.compare_arrows, label: "KG Var Yüzdesi", value: "%${(stats['kgVarYuzdesi'] as num?)?.toStringAsFixed(1) ?? "-"}"),
                _DetailStatRow(icon: Icons.task_alt, label: "Clean Sheet Yüzdesi", value: "%${(stats['cleanSheetYuzdesi'] as num?)?.toStringAsFixed(1) ?? "-"}"),
              ],
            )),
        const SizedBox(height: 16),
        _ModernStatCard(
          title: "Hücum İstatistikleri",
          child: Column(
            children: [
              _DetailStatRow(icon: Icons.adjust, label: "Ortalama Şut", value: (stats['ortalamaSut'] as num?)?.toStringAsFixed(1) ?? "N/A"),
              _DetailStatRow(icon: Icons.gps_fixed, label: "Ortalama İsabetli Şut", value: (stats['ortalamaIsabetliSut'] as num?)?.toStringAsFixed(1) ?? "N/A"),
              _DetailStatRow(icon: Icons.flag_outlined, label: "Ortalama Korner", value: (stats['ortalamaKorner'] as num?)?.toStringAsFixed(1) ?? "N/A"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesTab(List<Map<String, dynamic>> matches, String teamName) {
    if (matches.isEmpty) return const Center(child: Text("Maç bulunamadı."));

    matches.sort((a, b) {
      final dateA = a['_parsedDate'] as DateTime?;
      final dateB = b['_parsedDate'] as DateTime?;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

// YENİ WIDGET'LAR

class _ModernStatCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ModernStatCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _IconStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _IconStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  final String value;
  const _LegendItem({required this.color, required this.text, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DetailStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailStatRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

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
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1)),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
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
    final bool isWin = (isHomeTeam && result == 'H') || (!isHomeTeam && result == 'A');
    final bool isDraw = result == 'D';

    final Color resultColor = isWin ? Colors.green.shade400 : (isDraw ? Colors.orange.shade400 : Colors.red.shade400);
    final String resultLetter = isWin ? "G" : (isDraw ? "B" : "M");
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 45,
              decoration: BoxDecoration(
                color: resultColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(resultLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        TeamNameService.getCorrectedTeamName(homeTeam),
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: isHomeTeam ? FontWeight.bold : FontWeight.normal),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "$homeGoals - $awayGoals",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        TeamNameService.getCorrectedTeamName(awayTeam),
                        textAlign: TextAlign.left,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: !isHomeTeam ? FontWeight.bold : FontWeight.normal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
