// lib/widgets/detailed_match_list_content.dart
import 'package:flutter/material.dart';

class DetailedMatchListContent extends StatelessWidget {
  final ThemeData theme;
  final List<Map<String, dynamic>> matches;
  final String teamName; // Bu kaldırıldı çünkü dialog başlığında kullanılıyor.
  final int numberOfMatchesToCompare; // Bu da kaldırıldı, 'matches.length' kullanılacak.

  const DetailedMatchListContent({
    super.key,
    required this.theme,
    required this.matches,
    required this.teamName,
    required this.numberOfMatchesToCompare,
  });

  Widget _buildMatchRowForDetailPopup(Map<String, dynamic> match, ThemeData theme) {
    String homeTeam = match['homeTeam']?.toString() ?? 'Ev';
    String awayTeam = match['awayTeam']?.toString() ?? 'Dep';
    String homeGoals = match['homeGoals']?.toString() ?? '?';
    String awayGoals = match['awayGoals']?.toString() ?? '?';
    String date = match['date']?.toString() ?? '';
    String resultText = match['result']?.toString() ?? '';

    String htHomeGoals = match['htHomeGoals']?.toString() ?? '-';
    String htAwayGoals = match['htAwayGoals']?.toString() ?? '-';
    String htResultDescription = match['htResultText']?.toString() ?? '';

    TextStyle scoreStyle = theme.textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
    );
    TextStyle teamNameStyle = theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500);
    TextStyle dateStyle = theme.textTheme.labelSmall!.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7));
    TextStyle halfTimeStyle = theme.textTheme.labelSmall!.copyWith(
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.85),
        fontStyle: FontStyle.italic);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (date.isNotEmpty) ...[
            Text(
              date,
              style: dateStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
          ],
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  homeTeam,
                  style: teamNameStyle,
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '$homeGoals - $awayGoals',
                  style: scoreStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  awayTeam,
                  style: teamNameStyle,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (htHomeGoals != '-' || htAwayGoals != '-' || htResultDescription.isNotEmpty)
            Text(
              "(İY: $htHomeGoals-$htAwayGoals${htResultDescription.isNotEmpty ? ', ${htResultDescription.replaceFirst('İY: ', '')}' : ''}) MS: $resultText",
              style: halfTimeStyle,
              textAlign: TextAlign.center,
            )
          else
            Text(
              "MS: $resultText",
              style: halfTimeStyle.copyWith(fontStyle: FontStyle.normal, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dialog başlığı zaten _showDetailedMatchListPopup içinde ayarlanacak.
    // String popupTitleText = matches.isNotEmpty
    //     ? '$teamName - Son ${matches.length} Maç'
    //     : '$teamName - Maç Detayı Yok';

    return SizedBox(
      width: double.maxFinite,
      child: matches.isEmpty
          ? Center(
              child: Text(
              "Bu takım için son ${matches.isNotEmpty ? matches.length : numberOfMatchesToCompare} maç detayı bulunamadı.",
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ))
          : Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                shrinkWrap: true, // Önemli! Flexible içinde olduğu için
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  return _buildMatchRowForDetailPopup(matches[index], theme);
                },
                separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.3, indent: 16, endIndent: 16),
              ),
            ),
    );
  }
}