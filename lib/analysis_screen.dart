// lib/analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:futbol_analiz_app/main.dart'; // For StatsDisplaySettings
import 'package:futbol_analiz_app/widgets/modern_header_widget.dart';
import 'comparison_screen.dart';
import 'single_team_screen.dart';
import 'advanced_comparison_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final StatsDisplaySettings statsSettings;
  final String currentSeasonApiValue;
  final ScrollController scrollController;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onSearchTap;

  const AnalysisScreen({
    super.key,
    required this.statsSettings,
    required this.currentSeasonApiValue,
    required this.scrollController,
    required this.scaffoldKey,
    required this.onSearchTap,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Gelişmiş sekmesi ortada olacak şekilde 3 sekme oluşturuluyor
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    Tab(text: "Karşılaştır"),
                    Tab(text: "Gelişmiş"),
                    Tab(text: "Tek Takım"),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Her bir analiz ekranına kendi iç scroll controller'ı veriliyor
            ComparisonScreen(
              statsSettings: widget.statsSettings,
              currentSeasonApiValue: widget.currentSeasonApiValue,
              scrollController: ScrollController(), 
              scaffoldKey: widget.scaffoldKey,
              onSearchTap: widget.onSearchTap,
            ),
            AdvancedComparisonScreen(
              statsSettings: widget.statsSettings,
              currentSeasonApiValue: widget.currentSeasonApiValue,
              scrollController: ScrollController(),
              scaffoldKey: widget.scaffoldKey,
              onSearchTap: widget.onSearchTap,
            ),
            SingleTeamScreen(
              statsSettings: widget.statsSettings,
              currentSeasonApiValue: widget.currentSeasonApiValue,
              scrollController: ScrollController(),
              scaffoldKey: widget.scaffoldKey,
              onSearchTap: widget.onSearchTap,
            ),
          ],
        ),
      ),
    );
  }
}

// TabBar'ı sabitlemek için yardımcı Sliver delegate sınıfı
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
