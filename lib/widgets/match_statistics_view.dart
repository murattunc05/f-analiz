// lib/widgets/match_statistics_view.dart
import 'package:flutter/material.dart';

class MatchStatisticsView extends StatelessWidget {
  final List<dynamic> stats;
  const MatchStatisticsView({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Center(child: Text("Maç için istatistik verisi bulunmuyor."));
    }
    final homeStats = stats[0];
    final awayStats = stats[1];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: (homeStats['statistics'] as List<dynamic>).map<Widget>((stat) {
          final awayStat = (awayStats['statistics'] as List<dynamic>).firstWhere(
            (s) => s['type'] == stat['type'],
            orElse: () => {'value': 0}
          );
          return _StatComparisonBar(
            label: stat['type'],
            homeValue: stat['value'],
            awayValue: awayStat['value'],
          );
        }).toList(),
      ),
    );
  }
}

class _StatComparisonBar extends StatelessWidget {
  final String label;
  final dynamic homeValue;
  final dynamic awayValue;

  const _StatComparisonBar({
    required this.label,
    required this.homeValue,
    required this.awayValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final int homeInt = _parseValue(homeValue);
    final int awayInt = _parseValue(awayValue);
    final total = homeInt + awayInt;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final double homeFlex = (homeInt / total);
    final double awayFlex = (awayInt / total);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                homeInt.toString(),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                awayInt.toString(),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                flex: (homeFlex * 100).toInt(),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: (awayFlex * 100).toInt(),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                     borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _parseValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value.replaceAll('%', '')) ?? 0;
    }
    return 0;
  }
}