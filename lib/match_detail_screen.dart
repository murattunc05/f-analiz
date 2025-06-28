// lib/match_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:futbol_analiz_app/features/matches/matches_controller.dart';

// Bu import'lar kendi projenizin yoluna göre düzenlenmelidir.
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          final awayTeamId = details['teams']['away']['id'];
          final homeGoals = events.where((e) => e['team']['id'] == homeTeamId && e['type'] == 'Goal').toList();
          final awayGoals = events.where((e) => e['team']['id'] == awayTeamId && e['type'] == 'Goal').toList();

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 280.0,
                  pinned: true,
                  floating: true,
                  elevation: innerBoxIsScrolled ? 0.5 : 0.0,
                  backgroundColor: theme.cardColor,
                  iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    // Bu kısmı yorum satırı yapmaya devam ediyoruz
                    // titlePadding: const EdgeInsets.only(bottom: 50),
                    title: innerBoxIsScrolled ? _buildCollapsedAppBarTitle(details) : null,
                    background: _buildExpandedHeader(context, details, homeGoals, awayGoals),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    tabs: const [
                      Tab(text: 'Ayrıntılar'),
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
                MatchEventTimeline(events: events),
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
  
  Widget _buildExpandedHeader(BuildContext context, Map<String, dynamic> details, List<dynamic> homeGoals, List<dynamic> awayGoals) {
    final theme = Theme.of(context);
    final fixture = details['fixture'];
    
    return Container(
      // Bu padding'i kontrol altında tutalım. Safe Area'yı hesaba katarak.
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10, // Safe Area ve biraz daha boşluk
        bottom: 65, // TabBar için sabit boşluk
        left: 16,
        right: 16,
      ),
      width: double.infinity,
      color: theme.cardColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Tüm içeriği dikeyde ortala
        children: [
          // Takımlar ve Skor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center, // Logoların ve skorun aynı hizada olması için
            children: [
              _buildTeamDisplay(details['teams']['home']),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0), // Skorun etrafında boşluk
                child: _buildScoreDisplay(details['goals'], fixture),
              ),
              _buildTeamDisplay(details['teams']['away']),
            ],
          ),
          
          // Gol atanlar sadece gol varsa gösterilir
          if (homeGoals.isNotEmpty || awayGoals.isNotEmpty) ...[
            const SizedBox(height: 12), // Skor ile golcüler arasına daha az boşluk
            _buildGoalScorers(homeGoals, awayGoals, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedAppBarTitle(Map<String, dynamic> details) {
    final theme = Theme.of(context);
    final homeTeam = details['teams']['home'];
    final awayTeam = details['teams']['away'];
    final goals = details['goals'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CachedNetworkImage(imageUrl: homeTeam['logo'], width: 22, height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            "${goals['home'] ?? '-'} - ${goals['away'] ?? '-'}",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
        ),
        CachedNetworkImage(imageUrl: awayTeam['logo'], width: 22, height: 22),
      ],
    );
  }

  Widget _buildTeamDisplay(Map<String, dynamic> team) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CachedNetworkImage(
            imageUrl: team['logo'], height: 60, width: 60,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox(height: 60, width: 60),
            errorWidget: (context, url, error) => const Icon(Icons.shield_outlined, size: 60),
          ),
          const SizedBox(height: 10),
          Text(
            team['name'] ?? 'Bilinmiyor',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(Map<String, dynamic> goals, Map<String, dynamic> fixture) {
    final theme = Theme.of(context);
    final statusText = _getStatusText(fixture['status']['short'], fixture['status']['elapsed']);
    
    return Column(
      mainAxisSize: MainAxisSize.min, // Ekranı kaplamamasını sağla
      children: [
        Text(
          "${goals['home'] ?? '0'} - ${goals['away'] ?? '0'}",
          style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface, fontSize: 42)
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText, 
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary, 
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildGoalScorers(List<dynamic> homeGoals, List<dynamic> awayGoals, ThemeData theme) {
    Widget goalEntry(String playerName, int time) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2.0),
        child: Text(
          "${playerName.contains(' ') ? playerName.substring(playerName.indexOf(' ') + 1) : playerName} ${time}'", 
          style: theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: homeGoals.map((event) => goalEntry(event['player']['name'] ?? '?', event['time']['elapsed'] ?? 0)).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Icon(Icons.sports_soccer, size: 16, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: awayGoals.map((event) => goalEntry(event['player']['name'] ?? '?', event['time']['elapsed'] ?? 0)).toList(),
          ),
        ),
      ],
    );
  }
}