// lib/widgets/h2h_summary_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/logo_service.dart';
import '../services/team_name_service.dart';

class H2HSummaryCard extends StatelessWidget {
  final ThemeData theme;
  final Map<String, int> h2hStats;
  final Map<String, dynamic> team1Data;
  final Map<String, dynamic> team2Data;
  final Map<String, dynamic>? lastMatch;
  final VoidCallback onShowDetails;

  const H2HSummaryCard({
    super.key,
    required this.theme,
    required this.h2hStats,
    required this.team1Data,
    required this.team2Data,
    this.lastMatch,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (h2hStats.isEmpty) {
      return const SizedBox.shrink(); // H2H verisi yoksa hiçbir şey gösterme
    }
    
    final team1Name = TeamNameService.getCorrectedTeamName(team1Data['takim']);
    final team2Name = TeamNameService.getCorrectedTeamName(team2Data['takim']);

    final team1Wins = h2hStats['team1Wins'] ?? 0;
    final team2Wins = h2hStats['team2Wins'] ?? 0;
    final draws = h2hStats['draws'] ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onShowDetails,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history_toggle_off, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Aralarındaki Maçlar (H2H)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.5),

              // Galibiyet/Beraberlik Özeti
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatPill(team1Name, team1Wins, theme.colorScheme.primary, theme),
                  _buildStatPill("Beraberlik", draws, Colors.grey.shade600, theme),
                  _buildStatPill(team2Name, team2Wins, theme.colorScheme.primary, theme),
                ],
              ),
              
              const SizedBox(height: 16),

              // Son Maç Bilgisi
              if (lastMatch != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Son Maç:", style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    _buildLastMatchRow(theme),
                  ],
                ),
                
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tümünü Gör >',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, int value, Color color, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4), width: 1)
          ),
          child: Text(
            value.toString(),
            style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80, // Kapsayıcı genişliği
          child: Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLastMatchRow(ThemeData theme) {
    final homeTeamName = TeamNameService.getCorrectedTeamName(lastMatch!['HomeTeam']);
    final awayTeamName = TeamNameService.getCorrectedTeamName(lastMatch!['AwayTeam']);
    final homeGoals = lastMatch!['FTHG']?.toString() ?? '?';
    final awayGoals = lastMatch!['FTAG']?.toString() ?? '?';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(homeTeamName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Text("$homeGoals - $awayGoals", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          Expanded(child: Text(awayTeamName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}