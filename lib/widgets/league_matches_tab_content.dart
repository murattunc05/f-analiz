// lib/widgets/league_matches_tab_content.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// home_feed_screen'den _buildMatchRow ve _showMatchDetailsPopup metodlarını buraya taşıyacağız veya
// bu widget'a callback olarak vereceğiz. Şimdilik callback daha temiz.

class LeagueMatchesTabContent extends StatelessWidget {
  final ThemeData theme;
  final String leagueName;
  final List<Map<String, dynamic>> matches;
  final Function(BuildContext, Map<String, dynamic>, String) onMatchTap; // Maça tıklanınca detayları göstermek için callback
  final Widget Function(Map<String, dynamic> match, ThemeData theme, {bool isPopup}) buildMatchRowWidget;


  const LeagueMatchesTabContent({
    super.key,
    required this.theme,
    required this.leagueName,
    required this.matches,
    required this.onMatchTap,
    required this.buildMatchRowWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Bu lig için son maç bulunamadı.",
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: ListView.separated(
        // shrinkWrap: true, // Dialog içinde TabBarView ile kullanıldığında gerekli olabilir, test edilecek.
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        itemCount: matches.length,
        itemBuilder: (BuildContext itemContext, int index) {
          final match = matches[index];
          return InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onMatchTap(context, match, leagueName); // Ana ekrandaki _showMatchDetailsPopup'ı çağır
            },
            child: buildMatchRowWidget(match, theme, isPopup: true),
          );
        },
        separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.2, indent: 8, endIndent: 8),
      ),
    );
  }
}