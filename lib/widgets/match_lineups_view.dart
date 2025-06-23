// lib/widgets/match_lineups_view.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MatchLineupsView extends StatelessWidget {
  final List<dynamic> lineups;
  const MatchLineupsView({super.key, required this.lineups});

  @override
  Widget build(BuildContext context) {
    if (lineups.isEmpty || lineups.length < 2) {
      return const Center(child: Text("Maç için kadro verisi bulunmuyor."));
    }
    final homeLineup = lineups[0];
    final awayLineup = lineups[1];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildTeamLineup(context, homeLineup),
          const SizedBox(height: 24),
          _buildTeamLineup(context, awayLineup),
        ],
      ),
    );
  }

  Widget _buildTeamLineup(BuildContext context, Map<String, dynamic> lineupData) {
    final theme = Theme.of(context);
    final team = lineupData['team'];
    final formation = lineupData['formation'];
    final startXI = lineupData['startXI'] as List<dynamic>;
    final substitutes = lineupData['substitutes'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (team['logo'] != null)
              CachedNetworkImage(imageUrl: team['logo'], width: 32, height: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                team['name'] ?? 'Bilinmiyor',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (formation != null)
              Text(
                "($formation)",
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
              ),
          ],
        ),
        const Divider(height: 24),

        Text("İlk 11", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...startXI.map((playerData) => _buildPlayerTile(playerData['player'])),

        const SizedBox(height: 24),

        Text("Yedekler", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...substitutes.map((playerData) => _buildPlayerTile(playerData['player'])),
      ],
    );
  }

  Widget _buildPlayerTile(Map<String, dynamic> player) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            (player['number'] ?? '-').toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(player['name'] ?? 'Bilinmiyor')),
          if (player['pos'] != null)
            Text(
              _getPositionAbbreviation(player['pos']),
              style: TextStyle(color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  String _getPositionAbbreviation(String position) {
    switch (position) {
      case 'G': return 'KL';
      case 'D': return 'DF';
      case 'M': return 'OS';
      case 'F': return 'FV';
      default: return position;
    }
  }
}