// lib/matches_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'features/matches/matches_controller.dart';
import 'widgets/match_card_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'widgets/modern_header_widget.dart'; // ModernHeaderWidget import edildi

// --- WIDGET'LAR VE YARDIMCI METOTLAR ---

class CompactMatchCard extends StatelessWidget {
  final Map<String, dynamic> matchData;
  final VoidCallback onTap;

  const CompactMatchCard({super.key, required this.matchData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeTeam = matchData['teams']['home'];
    final awayTeam = matchData['teams']['away'];
    final fixture = matchData['fixture'];
    final goals = matchData['goals'];
    final status = fixture['status']['short'];

    final matchDateTime = DateTime.parse(fixture['date']).toLocal();
    final matchTime = DateFormat('HH:mm').format(matchDateTime);

    Widget scoreWidget;
    if (['FT', 'AET', 'PEN'].contains(status)) {
      scoreWidget = Text("${goals['home'] ?? '-'} - ${goals['away'] ?? '-'}", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
    } else {
      scoreWidget = Text(matchTime, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold));
    }

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text(homeTeam['name'] ?? 'Ev', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
              SizedBox(width: 36, height: 36, child: CachedNetworkImage(imageUrl: homeTeam['logo'], errorWidget: (c,u,e) => const Icon(Icons.shield_outlined))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: scoreWidget,
              ),
              SizedBox(width: 36, height: 36, child: CachedNetworkImage(imageUrl: awayTeam['logo'], errorWidget: (c,u,e) => const Icon(Icons.shield_outlined))),
              Expanded(flex: 4, child: Text(awayTeam['name'] ?? 'Dep', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}

class MatchesScreen extends ConsumerWidget {
  // DEĞİŞİKLİK: Gerekli parametreler eklendi
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onSearchTap;
  final ScrollController scrollController;

  const MatchesScreen({
    super.key,
    required this.scaffoldKey,
    required this.onSearchTap,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsyncValue = ref.watch(sharedPreferencesProvider);
    return prefsAsyncValue.when(
      data: (_) => _MatchesView(
        scaffoldKey: scaffoldKey,
        onSearchTap: onSearchTap,
        scrollController: scrollController,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Uygulama başlatılamadı: $e')),
    );
  }
}

class _MatchesView extends ConsumerWidget {
  // DEĞİŞİKLİK: Gerekli parametreler eklendi
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onSearchTap;
  final ScrollController scrollController;

  const _MatchesView({
    required this.scaffoldKey,
    required this.onSearchTap,
    required this.scrollController,
  });

  static final List<Color> _liveCardColors = [
    const Color(0xFF4A0D66),
    const Color(0xFF004D40),
    const Color(0xFF011F3A),
    const Color(0xFF721B36),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchesControllerProvider);
    final controller = ref.read(matchesControllerProvider.notifier);

    // DEĞİŞİKLİK: Root widget NestedScrollView olarak değiştirildi
    return SafeArea(
      bottom: false,
      child: NestedScrollView(
        controller: scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: ModernHeaderWidget(
                onSettingsTap: () => scaffoldKey.currentState?.openDrawer(),
                onSearchTap: onSearchTap,
              ),
            ),
          ];
        },
        body: Column(
          children: [
            _buildTopFilterBar(context, ref),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.fetchMatches(isRefresh: true),
                child: CustomScrollView(
                  slivers: [
                    _buildSectionHeader(context, "Canlı Maçlar"),
                    state.liveMatches.when(
                      data: (live) {
                        final leaguesToShow = state.activeLeagueIds.isEmpty
                            ? state.selectedCompetitionIds
                            : state.activeLeagueIds;
                        final filteredLive = _filterMatches(live, leaguesToShow);
                        if (filteredLive.isEmpty) {
                          return SliverToBoxAdapter(child: _buildEmptyLiveCard(context));
                        }
                        return _buildHorizontalLiveMatches(context, filteredLive, controller, _liveCardColors);
                      },
                      loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))),
                      error: (e, st) => SliverToBoxAdapter(child: Center(child: Text("Canlı maçlar yüklenemedi: $e"))),
                    ),
                    _buildSectionHeader(context, DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(state.selectedDate)),
                    state.selectedDateMatches.when(
                      data: (matchesForDate) {
                        final leaguesToShow = state.activeLeagueIds.isEmpty
                            ? state.selectedCompetitionIds
                            : state.activeLeagueIds;
                        final filteredList = _filterMatches(matchesForDate, leaguesToShow);

                        if (filteredList.isEmpty) {
                          return const SliverToBoxAdapter(child: _EmptyStateMessage(message: "Seçili tarih ve ligler için maç bulunamadı."));
                        }
                        
                        final upcoming = filteredList.where((m) => m['fixture']['status']['short'] == 'NS').toList();
                        final finished = filteredList.where((m) => ['FT', 'AET', 'PEN'].contains(m['fixture']['status']['short'])).toList();

                        return SliverList(
                          delegate: SliverChildListDelegate([
                            if (upcoming.isNotEmpty) ...[
                              _buildInnerSectionHeader(context, "Yaklaşan Maçlar"),
                              ...upcoming.map((match) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: CompactMatchCard(matchData: match, onTap: () => controller.onViewMatchDetails(context, match)),
                                  )),
                            ],
                            if (finished.isNotEmpty) ...[
                              _buildInnerSectionHeader(context, "Biten Maçlar"),
                              ...finished.map((match) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: CompactMatchCard(matchData: match, onTap: () => controller.onViewMatchDetails(context, match)),
                                  )),
                            ],
                          ]),
                        );
                      },
                      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                      error: (e, st) => SliverToBoxAdapter(child: Center(child: Text("Maçlar yüklenemedi: $e"))),
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

// --- TÜM YARDIMCI METOTLAR VE WIDGET'LAR BURADA DOĞRU ŞEKİLDE TANIMLANDI ---

Widget _buildEmptyLiveCard(BuildContext context) {
  final theme = Theme.of(context);
  return Card(
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    color: const Color(0xFF4A0D66),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Transform.scale(
            scale: 1.8,
            child: Opacity(
              opacity: 0.05,
              child: Icon(Icons.public, size: 150, color: Colors.white),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            "Şu anda canlı karşılaşma bulunmuyor.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildHorizontalLiveMatches(BuildContext context, List<dynamic> matches, MatchesController controller, List<Color> cardColors) {
  return SliverToBoxAdapter(
    child: SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: MatchCardWidget(
              matchData: match,
              onTap: () => controller.onViewMatchDetails(context, match),
              cardColor: cardColors[index % cardColors.length],
            ),
          );
        },
      ),
    ),
  );
}

void _showLeagueFilter(BuildContext context, WidgetRef ref) {
  final controller = ref.read(matchesControllerProvider.notifier);
  final state = ref.read(matchesControllerProvider);

  final tempSelectedIds = Set<int>.from(state.selectedCompetitionIds);
  DateTime tempSelectedDate = state.selectedDate;
  final searchController = TextEditingController();

  showModalBottomSheet(
    context: context, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (modalContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));
          final tomorrow = today.add(const Duration(days: 1));
          
          final String query = searchController.text.toLowerCase();
          final List<dynamic> filteredCompetitionGroups = state.availableCompetitions.map((group) {
            final List<dynamic> filteredLeagues = (group['leagues'] as List).where((league) {
              return (league['name'] as String).toLowerCase().contains(query);
            }).toList();
            
            if (filteredLeagues.isNotEmpty) {
              return {...group, 'leagues': filteredLeagues};
            }
            return null;
          }).where((group) => group != null).toList();

          return DraggableScrollableSheet(
            expand: false, initialChildSize: 0.9, maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        TextField(
                          controller: searchController,
                          onChanged: (value) => modalSetState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Lig ara...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            filled: true,
                            contentPadding: EdgeInsets.zero,
                            suffixIcon: query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => modalSetState(() => searchController.clear())) : null
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _DateChip(label: 'Dün', date: yesterday, selectedDate: tempSelectedDate, onTap: (date) => modalSetState(() => tempSelectedDate = date)),
                            _DateChip(label: 'Bugün', date: today, selectedDate: tempSelectedDate, onTap: (date) => modalSetState(() => tempSelectedDate = date)),
                            _DateChip(label: 'Yarın', date: tomorrow, selectedDate: tempSelectedDate, onTap: (date) => modalSetState(() => tempSelectedDate = date)),
                            IconButton(
                              icon: const Icon(Icons.calendar_month_outlined),
                              tooltip: "Tarih Seç",
                              onPressed: () async {
                                final newDate = await showDatePicker(context: context, initialDate: tempSelectedDate, firstDate: DateTime(2020), lastDate: now.add(const Duration(days: 365)));
                                if (newDate != null) modalSetState(() => tempSelectedDate = newDate);
                              },
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: state.isLoadingCompetitions
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: filteredCompetitionGroups.length,
                            itemBuilder: (context, index) {
                              final group = filteredCompetitionGroups[index];
                              final String groupName = group['groupName'];
                              final List<dynamic> leagues = group['leagues'];
                              final String? flagUrl = group['countryFlag'];
                              final IconData? icon = group['icon'];
                              
                              return ExpansionTile(
                                initiallyExpanded: index < 1,
                                leading: _buildGroupLeading(flagUrl, icon, context),
                                title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                children: leagues.map<Widget>((competition) {
                                  final id = competition['id'] as int;
                                  final name = competition['name'] as String;
                                  final logo = competition['logo'] as String?;
                                  
                                  return CheckboxListTile(
                                    secondary: logo != null ? CachedNetworkImage(imageUrl: logo, width: 30, height: 30, fit: BoxFit.contain, errorWidget: (c,u,e) => const Icon(Icons.shield_outlined)) : const Icon(Icons.shield_outlined),
                                    title: Text(name),
                                    value: tempSelectedIds.contains(id),
                                    onChanged: (bool? selected) => modalSetState(() {
                                      if (selected == true) { tempSelectedIds.add(id); } else { tempSelectedIds.remove(id); }
                                    }),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(child: OutlinedButton(child: const Text("Tümünü Temizle"), onPressed: () => modalSetState(() => tempSelectedIds.clear()))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                            child: const Text("Filtrele"),
                            onPressed: () {
                              controller.updateSelectedCompetitions(tempSelectedIds);
                              controller.changeDate(tempSelectedDate);
                              Navigator.pop(modalContext);
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
          );
        },
      );
    }
  );
}

Widget _buildGroupLeading(String? flagUrl, IconData? icon, BuildContext context) {
  if (icon != null) { return SizedBox(width: 30, child: Icon(icon, size: 24, color: Theme.of(context).colorScheme.secondary)); }
  if (flagUrl != null && flagUrl.endsWith('.svg')) { return SizedBox(width: 30, child: SvgPicture.network(flagUrl, width: 30, height: 20, placeholderBuilder: (context) => const SizedBox.shrink())); } 
  else if (flagUrl != null) { return SizedBox(width: 30, child: Image.network(flagUrl, width: 30, height: 20, errorBuilder: (c,e,s) => const Icon(Icons.public))); }
  return Icon(Icons.public, size: 24, color: Theme.of(context).colorScheme.secondary);
}

Widget _buildTopFilterBar(BuildContext context, WidgetRef ref) {
  final state = ref.watch(matchesControllerProvider);
  final controller = ref.read(matchesControllerProvider.notifier);
  
  final favoriteLeagues = state.availableCompetitions
      .expand((group) => group['leagues'] as List)
      .where((league) => state.selectedCompetitionIds.contains(league['id']))
      .toList();

  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
    child: Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: "Tümü",
                  isSelected: state.activeLeagueIds.isEmpty,
                  onTap: () => controller.setActiveLeagueFilter({}),
                ),
                ...favoriteLeagues.map((league) {
                  final isSelected = state.activeLeagueIds.contains(league['id']);
                  return _FilterChip(
                    label: league['name'],
                    logoUrl: league['logo'],
                    isSelected: isSelected,
                    onTap: () => controller.toggleActiveLeagueFilter(league['id']),
                  );
                })
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_calendar_outlined),
          onPressed: state.isLoadingCompetitions ? null : () => _showLeagueFilter(context, ref),
          tooltip: "Favori Ligleri ve Tarihi Düzenle",
        ),
      ],
    ),
  );
}

Widget _buildSectionHeader(BuildContext context, String title) {
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    ),
  );
}

Widget _buildInnerSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
}

List<dynamic> _filterMatches(List<dynamic> allMatches, Set<int> activeLeagueIds) {
  if (activeLeagueIds.isEmpty) {
    return allMatches;
  }
  return allMatches.where((match) {
    return activeLeagueIds.contains(match['league']['id']);
  }).toList();
}

class _EmptyStateMessage extends StatelessWidget {
  final String message;
  const _EmptyStateMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateTime selectedDate;
  final Function(DateTime) onTap;

  const _DateChip({
    required this.label,
    required this.date,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = date.year == selectedDate.year &&
                       date.month == selectedDate.month &&
                       date.day == selectedDate.day;

    return ActionChip(
      label: Text(label),
      onPressed: () => onTap(date),
      backgroundColor: isSelected ? theme.colorScheme.primary : theme.chipTheme.backgroundColor,
      labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : theme.chipTheme.labelStyle?.color),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? logoUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, this.logoUrl, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: RawChip(
        onPressed: onTap,
        selected: isSelected,
        label: Text(label),
        avatar: logoUrl != null
            ? CachedNetworkImage(imageUrl: logoUrl!, width: 18, height: 18)
            : label == "Tümü" ? Icon(Icons.public, size: 18, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface) : null,
        shape: const StadiumBorder(),
        side: isSelected ? BorderSide.none : BorderSide(color: theme.dividerColor),
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        selectedColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
        ),
        showCheckmark: false,
      ),
    );
  }
}
