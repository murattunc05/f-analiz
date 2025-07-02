// lib/home_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data_service.dart';
import '../services/logo_service.dart';
import '../widgets/last_matches_tab.dart';
import '../widgets/standings_tab.dart';
import '../widgets/modern_header_widget.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  final String currentSeasonApiValue;
  final ScrollController scrollController;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onSearchTap;

  const HomeFeedScreen({
    super.key,
    required this.currentSeasonApiValue,
    required this.scrollController,
    required this.scaffoldKey,
    required this.onSearchTap,
  });

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  Set<String> _selectedLeagues = {}; 
  final List<String> _allAvailableLeagues = DataService.leagueDisplayNames;
  
  static const String _kLastLeagueFilterKey = 'last_league_filter_key';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _loadLastFilter();
  }
  
  Future<void> _loadLastFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFilters = prefs.getStringList(_kLastLeagueFilterKey);
    if (mounted) {
      setState(() {
        if (lastFilters == null || lastFilters.isEmpty) {
          _selectedLeagues = {'Tümü'};
        } else {
          _selectedLeagues = lastFilters.toSet();
        }
      });
    }
  }

  Future<void> _saveFilterPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kLastLeagueFilterKey, _selectedLeagues.toList());
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleLeagueSelection(String leagueName) {
    setState(() {
      if (leagueName == 'Tümü') {
        _selectedLeagues = {'Tümü'};
      } else {
        _selectedLeagues.remove('Tümü');
        if (_selectedLeagues.contains(leagueName)) {
          _selectedLeagues.remove(leagueName);
        } else {
          _selectedLeagues.add(leagueName);
        }
        if (_selectedLeagues.isEmpty) {
          _selectedLeagues.add('Tümü');
        }
      }
      _saveFilterPreference();
    });
  }
  
  Widget _buildLeagueFilterBar() {
    final theme = Theme.of(context);
    if (_selectedLeagues.isEmpty) {
      return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    List<String> filterOptions = ['Tümü', ..._allAvailableLeagues];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filterOptions.map((league) {
            final bool isSelected = _selectedLeagues.contains(league);
            // YENİ: Logo URL'si servisten alınıyor.
            final String? logoUrl = LogoService.getLeagueLogoUrl(league);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(league, style: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : null)),
                avatar: league == 'Tümü'
                    ? Icon(Icons.public, size: 18, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant)
                    // GÜNCELLEME: Image.asset yerine CachedNetworkImage kullanılıyor.
                    : SizedBox(
                        width: 20,
                        height: 20,
                        child: logoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: logoUrl,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
                                errorWidget: (context, url, error) => Icon(Icons.shield_outlined, size: 18, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant),
                                fit: BoxFit.contain,
                              )
                            : Icon(Icons.shield_outlined, size: 18, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant),
                      ),
                selected: isSelected,
                onSelected: (selected) => _handleLeagueSelection(league),
                selectedColor: theme.colorScheme.primary,
                backgroundColor: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1.0)
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final List<String> leaguesToShow = _selectedLeagues.contains('Tümü') 
        ? _allAvailableLeagues 
        : _selectedLeagues.toList();

    return SafeArea(
      bottom: false,
      child: NestedScrollView(
        controller: widget.scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: ModernHeaderWidget(
                onSettingsTap: () => widget.scaffoldKey.currentState?.openDrawer(),
                onSearchTap: widget.onSearchTap,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  tabs: const [
                    Tab(text: "Son Maçlar"),
                    Tab(text: "Puan Durumu"),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildLeagueFilterBar(),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            LastMatchesTab(
              key: ValueKey('last_matches_${widget.currentSeasonApiValue}_${leaguesToShow.join('_')}'),
              favoriteLeagues: leaguesToShow,
              currentSeasonApiValue: widget.currentSeasonApiValue,
            ),
            StandingsTab(
              key: ValueKey('standings_${widget.currentSeasonApiValue}_${leaguesToShow.join('_')}'),
              favoriteLeagues: leaguesToShow,
              currentSeasonApiValue: widget.currentSeasonApiValue,
            ),
          ],
        ),
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate._tabBar != _tabBar;
  }
}
