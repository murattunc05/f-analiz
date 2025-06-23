// lib/widgets/profile_overview_tab.dart
import 'package:flutter/material.dart';

class ProfileOverviewTab extends StatelessWidget {
  final Map<String, dynamic> teamStats;

  const ProfileOverviewTab({
    super.key,
    required this.teamStats,
  });

  Widget _buildStatRow(BuildContext context, {required String label, required String value, IconData? icon}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
              ],
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
          Text(
            value, 
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _buildFormIndicator(BuildContext context, String resultChar) {
    Color color;
    switch(resultChar) {
      case 'G': color = Colors.green; break;
      case 'B': color = Colors.grey; break;
      case 'M': color = Colors.red; break;
      default: color = Colors.transparent;
    }
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(resultChar, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Verileri Map'ten güvenli bir şekilde al
    final int played = (teamStats['oynananMacSayisi'] as num?)?.toInt() ?? 0;
    if (played == 0) {
      return const Center(child: Text("Bu filtre için gösterilecek veri yok."));
    }
    final int wins = (teamStats['galibiyet'] as num?)?.toInt() ?? 0;
    final int draws = (teamStats['beraberlik'] as num?)?.toInt() ?? 0;
    final int losses = (teamStats['maglubiyet'] as num?)?.toInt() ?? 0;
    final int goalsFor = (teamStats['attigi'] as num?)?.toInt() ?? 0;
    final int goalsAgainst = (teamStats['yedigi'] as num?)?.toInt() ?? 0;
    final int goalDiff = (teamStats['golFarki'] as num?)?.toInt() ?? 0;
    final int points = (wins * 3) + draws;
    
    final int analyzedMatchCount = (teamStats['lastNMatchesUsed'] as num?)?.toInt() ?? played;
    final String matchDetailsKey = "son${analyzedMatchCount}MacDetaylari";
    final List<dynamic> lastMatches = teamStats[matchDetailsKey] as List<dynamic>? ?? [];
    final String formString = lastMatches.take(5).map((m) => (m['result'] as String?)?.substring(0, 1) ?? '-').join();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("LİG PERFORMANSI", style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  _buildStatRow(context, label: "Oynanan Maç", value: '$played', icon: Icons.sports_esports_outlined),
                  _buildStatRow(context, label: "Galibiyet", value: '$wins', icon: Icons.emoji_events_outlined),
                  _buildStatRow(context, label: "Beraberlik", value: '$draws', icon: Icons.handshake_outlined),
                  _buildStatRow(context, label: "Mağlubiyet", value: '$losses', icon: Icons.sentiment_very_dissatisfied_outlined),
                  _buildStatRow(context, label: "Puan", value: '$points', icon: Icons.calculate_outlined),
                  const Divider(height: 20, indent: 30, endIndent: 30),
                  _buildStatRow(context, label: "Attığı Gol", value: '$goalsFor', icon: Icons.sports_soccer),
                  _buildStatRow(context, label: "Yediği Gol", value: '$goalsAgainst', icon: Icons.shield_outlined),
                  _buildStatRow(context, label: "Averaj", value: '$goalDiff', icon: Icons.swap_horiz_outlined),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (formString.isNotEmpty)
            Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SON 5 MAÇ FORMU", style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: formString.characters.map((char) => _buildFormIndicator(context, char)).toList(),
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}