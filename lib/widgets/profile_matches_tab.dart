// lib/widgets/profile_matches_tab.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:futbol_analiz_app/services/team_name_service.dart';

class ProfileMatchesTab extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  final String teamName;

  const ProfileMatchesTab({
    super.key,
    required this.matches,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(child: Text("Gösterilecek maç bulunmuyor."));
    }
    
    // Maçları tarihe göre sırala (en yeni en üstte)
    matches.sort((a, b) {
      try {
        return (b['_parsedDate'] as DateTime).compareTo(a['_parsedDate'] as DateTime);
      } catch (e) {
        return 0;
      }
    });

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: matches.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _MatchResultCard(match: matches[index], teamName: teamName);
      },
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
      resultColor = Colors.green.withOpacity(0.2); // Galibiyet
    } else if (result == 'D') {
      resultColor = Colors.orange.withOpacity(0.2); // Beraberlik
    } else {
      resultColor = Colors.red.withOpacity(0.2); // Mağlubiyet
    }

    return Card(
      elevation: 0,
      color: resultColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: resultColor.withOpacity(0.5))
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
      ),
    );
  }
}