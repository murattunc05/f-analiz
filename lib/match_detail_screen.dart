// lib/match_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:futbol_analiz_app/features/matches/matches_controller.dart';
import 'package:palette_generator/palette_generator.dart';

import 'widgets/match_event_timeline.dart';
import 'widgets/match_statistics_view.dart';
import 'widgets/match_lineups_view.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> matchData;

  const MatchDetailScreen({super.key, required this.matchData});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PaletteGenerator? _palette;
  Color? _dominantColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updatePalette();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fixtureId = widget.matchData['fixture']['id'] as int;
      ref.read(matchDetailProvider(fixtureId).notifier).fetchDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updatePalette() async {
    final logoUrl = widget.matchData['league']['logo'] as String?;
    if (logoUrl == null) return;
    try {
      final provider = CachedNetworkImageProvider(logoUrl);
      final palette = await PaletteGenerator.fromImageProvider(provider, size: const Size(50, 50));
      if (mounted) {
        setState(() {
          _palette = palette;
          _dominantColor = _palette?.vibrantColor?.color ?? _palette?.dominantColor?.color;
        });
      }
    } catch(e) {
      debugPrint("Palet üretilemedi: $e");
    }
  }


  String _getStatusText(String shortStatus, int? minute) {
    if (['1H', '2H', 'ET', 'P', 'LIVE'].contains(shortStatus)) return "$minute'";
    if (shortStatus == 'HT') return "Devre Arası";
    if (['FT', 'AET', 'PEN'].contains(shortStatus)) return "Bitti";
    if (shortStatus == 'NS') {
       final date = DateTime.parse(widget.matchData['fixture']['date']).toLocal();
       return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return shortStatus;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fixtureId = widget.matchData['fixture']['id'] as int;
    final detailAsyncValue = ref.watch(matchDetailProvider(fixtureId).select((s) => s.fixtureDetails));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: detailAsyncValue.when(
        data: (details) {
          final events = details['events'] as List<dynamic>? ?? [];
          final homeTeamId = details['teams']['home']['id'];
          
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 280.0,
                  pinned: true,
                  floating: false,
                  elevation: innerBoxIsScrolled ? 2.0 : 0.0,
                  backgroundColor: _dominantColor ?? theme.colorScheme.primary,
                  iconTheme: IconThemeData(color: (_dominantColor?.computeLuminance() ?? 0.1) > 0.5 ? Colors.black : Colors.white),
                  flexibleSpace: _AnimatedHeader(
                    details: details,
                    dominantColor: _dominantColor,
                    statusText: _getStatusText(details['fixture']['status']['short'], details['fixture']['status']['elapsed']),
                  ),
                  bottom: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    controller: _tabController,
                    indicatorColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    tabs: const [
                      Tab(text: 'Maç Özeti'),
                      Tab(text: 'Kadrolar'),
                      Tab(text: 'İstatistik'),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                MatchEventTimeline(events: events, homeTeamId: homeTeamId),
                MatchLineupsView(lineups: details['lineups'] ?? []),
                MatchStatisticsView(stats: details['statistics'] ?? []),
              ],
            ),
          );
        },
        loading: () => Scaffold(appBar: AppBar(backgroundColor: Theme.of(context).cardColor), body: const Center(child: CircularProgressIndicator())),
        error: (e, st) => Scaffold(appBar: AppBar(title: const Text("Hata")), body: Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Maç detayları yüklenemedi.\n${e.toString().split(':').last.trim()}"),
        ))),
      ),
    );
  }
}

class _AnimatedHeader extends StatelessWidget {
  final Map<String, dynamic> details;
  final Color? dominantColor;
  final String statusText;

  const _AnimatedHeader({
    required this.details,
    this.dominantColor,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = (dominantColor?.computeLuminance() ?? 0.1) > 0.5 ? Colors.black87 : Colors.white;
    
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>()!;
        final double t = (settings.currentExtent - settings.minExtent) / (settings.maxExtent - settings.minExtent);
        final Curve curve = Curves.easeInOut;
        final double fadeT = curve.transform(t.clamp(0.0, 1.0));

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                dominantColor ?? theme.colorScheme.primary,
                theme.scaffoldBackgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.65, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                top: (settings.currentExtent - settings.maxExtent) * 0.5,
                child: Opacity(
                  opacity: fadeT,
                  child: Padding(
                    // TabBar ve status bar için boşluk bırak
                    padding: EdgeInsets.only(bottom: 55.0, top: settings.minExtent - 90),
                    child: _buildExpandedHeaderContent(context, details, titleColor),
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 1.0 - fadeT,
                  // AppBar ve TabBar'ı hesaba katarak dikeyde ortala
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 48.0),
                      child: _buildCollapsedAppBarTitle(context, details, titleColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildExpandedHeaderContent(BuildContext context, Map<String, dynamic> details, Color titleColor) {
     final events = details['events'] as List<dynamic>? ?? [];
     final homeTeamId = details['teams']['home']['id'];
     final homeGoals = events.where((e) => e['team']['id'] == homeTeamId && e['type'] == 'Goal').toList();
     final awayGoals = events.where((e) => e['team']['id'] != homeTeamId && e['type'] == 'Goal').toList();
     
     return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTeamDisplay(context, details['teams']['home'], titleColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
                child: _buildScoreDisplay(context, details['goals'], statusText, titleColor),
              ),
              _buildTeamDisplay(context, details['teams']['away'], titleColor),
            ],
          ),
          // DÜZELTME: Bu alanı sarmalayarak overflow hatasını engelliyoruz.
          if(homeGoals.isNotEmpty || awayGoals.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0, left: 16, right: 16),
                  child: _buildGoalScorers(context, homeGoals, awayGoals, titleColor),
                ),
              ),
            ),
        ],
      );
  }
  
  Widget _buildCollapsedAppBarTitle(BuildContext context, Map<String, dynamic> details, Color titleColor) {
    final theme = Theme.of(context);
    final homeTeam = details['teams']['home'];
    final awayTeam = details['teams']['away'];
    final goals = details['goals'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // DÜZELTME: Logo rengi kaldırıldı, orijinal logo gösterilecek.
        CachedNetworkImage(imageUrl: homeTeam['logo'], width: 24, height: 24, errorWidget: (c,u,e) => Icon(Icons.shield_outlined, color: titleColor, size: 24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            "${goals['home'] ?? '-'} - ${goals['away'] ?? '-'}",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: titleColor),
          ),
        ),
        // DÜZELTME: Logo rengi kaldırıldı, orijinal logo gösterilecek.
        CachedNetworkImage(imageUrl: awayTeam['logo'], width: 24, height: 24, errorWidget: (c,u,e) => Icon(Icons.shield_outlined, color: titleColor, size: 24)),
      ],
    );
  }

  Widget _buildTeamDisplay(BuildContext context, Map<String, dynamic> team, Color textColor) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CachedNetworkImage(
            imageUrl: team['logo'], height: 70, width: 70,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox(height: 70, width: 70),
            errorWidget: (context, url, error) => Icon(Icons.shield_outlined, size: 70, color: textColor.withOpacity(0.8)),
          ),
          const SizedBox(height: 10),
          Text(
            team['name'] ?? 'Bilinmiyor',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: textColor, shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(BuildContext context, Map<String, dynamic> goals, String statusText, Color textColor) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "${goals['home'] ?? '0'} - ${goals['away'] ?? '0'}",
          style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: textColor, fontSize: 44, shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 3)])
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText, 
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor, 
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildGoalScorers(BuildContext context, List<dynamic> homeGoals, List<dynamic> awayGoals, Color textColor) {
    
    Widget goalEntry(String playerName, int time, {bool isOwnGoal = false}) {
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 12, color: textColor.withOpacity(0.8)),
            const SizedBox(width: 4),
            Text(
              "${playerName.split(' ').last} ${time}' ${isOwnGoal ? '(K.K)' : ''}",
              style: TextStyle(color: textColor, fontSize: 11, shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 1)]),
            ),
          ],
        ),
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: homeGoals.map((g) => goalEntry(g['player']['name'] ?? '?', g['time']['elapsed'] ?? 0, isOwnGoal: g['detail'] == 'Own Goal')).toList(),
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: awayGoals.map((g) => goalEntry(g['player']['name'] ?? '?', g['time']['elapsed'] ?? 0, isOwnGoal: g['detail'] == 'Own Goal')).toList(),
          ),
        ),
      ],
    );
  }
}
