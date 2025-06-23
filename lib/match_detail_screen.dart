// lib/match_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:futbol_analiz_app/features/matches/matches_controller.dart';
import 'package:intl/intl.dart';

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
    if (shortStatus == 'NS') return "Başlamadı";
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
          final events = details['events'] ?? [];
          final homeTeam = details['teams']['home'];
          final awayTeam = details['teams']['away'];
          final homeGoals = events.where((e) => e['team']['id'] == homeTeam['id'] && e['type'] == 'Goal').toList();
          final awayGoals = events.where((e) => e['team']['id'] == awayTeam['id'] && e['type'] == 'Goal').toList();

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 280.0,
                  pinned: true,
                  elevation: innerBoxIsScrolled ? 0.5 : 0.0,
                  backgroundColor: theme.cardColor,
                  iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    titlePadding: const EdgeInsets.only(bottom: 14),
                    title: innerBoxIsScrolled 
                        ? _buildCollapsedAppBarTitle(details) 
                        : null,
                    background: _buildExpandedHeader(context, details, homeGoals, awayGoals),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: const [ Tab(text: 'Ayrıntılar'), Tab(text: 'Kadrolar'), Tab(text: 'İstatistik'), ],
                    ),
  
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
        loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
        error: (e, st) => Scaffold(appBar: AppBar(), body: Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Hata: ${e.toString().split(':').last.trim()}"),
        ))),
      ),
    );
  }

  Widget _buildExpandedHeader(BuildContext context, Map<String, dynamic> details, List<dynamic> homeGoals, List<dynamic> awayGoals) {
    final theme = Theme.of(context);
    final fixture = details['fixture'];
    final date = DateTime.parse(fixture['date']).toLocal();

    return Container(
      padding: const EdgeInsets.only(top: kToolbarHeight, bottom: 60),
      width: double.infinity,
      color: theme.cardColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${DateFormat.yMMMEd('tr_TR').format(date)} - ${DateFormat.Hm().format(date)}",
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.star_border_outlined), color: Colors.grey.shade400),
              _buildTeamDisplay(details['teams']['home']),
              _buildScoreDisplay(details['goals'], fixture),
              _buildTeamDisplay(details['teams']['away']),
              IconButton(onPressed: () {}, icon: const Icon(Icons.star_border_outlined), color: Colors.grey.shade400),
            ],
          ),
          if (homeGoals.isNotEmpty || awayGoals.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildGoalScorers(homeGoals, awayGoals, theme),
          ]
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
        CachedNetworkImage(imageUrl: homeTeam['logo'], width: 22, height: 22), // Boyut büyütüldü
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            "${goals['home'] ?? '-'} - ${goals['away'] ?? '-'}", // ":" yerine "-" kullanıldı
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
        ),
        CachedNetworkImage(imageUrl: awayTeam['logo'], width: 22, height: 22), // Boyut büyütüldü
      ],
    );
  }

  Widget _buildTeamDisplay(Map<String, dynamic> team) {
    return Expanded(
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: team['logo'], height: 60, width: 60, // Logo küçültüldü
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox(height: 60, width: 60),
            errorWidget: (context, url, error) => const Icon(Icons.shield_outlined, size: 60),
          ),
          const SizedBox(height: 8),
          Text(
            team['name'] ?? 'Bilinmiyor',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(Map<String, dynamic> goals, Map<String, dynamic> fixture) {
    final theme = Theme.of(context);
    final statusText = _getStatusText(fixture['status']['short'], fixture['status']['elapsed']);
    
    return Column(
      children: [
        Text(
          "${goals['home'] ?? '-'} - ${goals['away'] ?? '-'}",
          style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, fontSize: 44) // Font küçültüldü
        ),
        const SizedBox(height: 4),
        Text(statusText, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
      ],
    );
  }

  Widget _buildGoalScorers(List<dynamic> homeGoals, List<dynamic> awayGoals, ThemeData theme) {
    Widget goalEntry(String playerName, int time, {bool alignRight = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alignRight) ...[
              Text("$playerName ${time}'", style: theme.textTheme.bodySmall),
              const SizedBox(width: 4),
            ],
            Icon(Icons.sports_soccer, size: 14, color: theme.textTheme.bodySmall?.color),
            if (!alignRight) ...[
              const SizedBox(width: 4),
              Text("${time}' $playerName", style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 4,
                children: homeGoals.map((event) => goalEntry(event['player']['name'], event['time']['elapsed'], alignRight: true)).toList(),
              ),
              if (homeGoals.isNotEmpty && awayGoals.isNotEmpty)
                const SizedBox(width: 24),
              Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 4,
                children: awayGoals.map((event) => goalEntry(event['player']['name'], event['time']['elapsed'])).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).cardColor, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}