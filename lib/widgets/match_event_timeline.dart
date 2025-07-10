// lib/widgets/match_event_timeline.dart
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

class MatchEventTimeline extends StatelessWidget {
  final List<dynamic> events;
  final int homeTeamId;

  const MatchEventTimeline({
    super.key,
    required this.events,
    required this.homeTeamId,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text("Bu maç için kaydedilmiş önemli bir olay bulunmuyor.",
            textAlign: TextAlign.center),
      ));
    }

    events.sort((a, b) => (a['time']['elapsed'] as int)
        .compareTo(b['time']['elapsed'] as int));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isHomeEvent = event['team']['id'] == homeTeamId;

        return TimelineTile(
          alignment: TimelineAlign.center,
          isFirst: index == 0,
          isLast: index == events.length - 1,
          startChild:
              isHomeEvent ? _EventCard(event: event, isHome: true) : null,
          endChild:
              !isHomeEvent ? _EventCard(event: event, isHome: false) : null,
          indicatorStyle: IndicatorStyle(
            width: 50,
            height: 50,
            indicator: _TimeIndicator(
                time: event['time']['elapsed'].toString(),
                extra: event['time']['extra']?.toString()),
            padding: const EdgeInsets.all(8),
          ),
          beforeLineStyle: LineStyle(
            color: Theme.of(context).dividerColor,
            thickness: 2,
          ),
          afterLineStyle: LineStyle(
            color: Theme.of(context).dividerColor,
            thickness: 2,
          ),
        );
      },
    );
  }
}

class _TimeIndicator extends StatelessWidget {
  final String time;
  final String? extra;

  const _TimeIndicator({required this.time, this.extra});

  @override
  Widget build(BuildContext context) {
    String displayTime = "$time'";
    if (extra != null && extra != '0') {
      displayTime += "+$extra";
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          displayTime,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isHome;

  const _EventCard({required this.event, required this.isHome});

  Map<String, dynamic> _getEventVisuals(
      String type, String detail, BuildContext context) {
    switch (type) {
      case 'Goal':
        if (detail == 'Penalty') {
          return {'icon': Icons.sports_soccer, 'color': Colors.green.shade700};
        } else if (detail == 'Own Goal') {
          return {'icon': Icons.sports_soccer, 'color': Colors.red.shade800};
        }
        return {'icon': Icons.sports_soccer, 'color': Colors.green.shade600};
      case 'Card':
        if (detail == 'Yellow Card') {
          return {
            'icon': Icons.style,
            'color': Colors.yellow.shade700
          };
        }
        return {
          'icon': Icons.style,
          'color': Colors.red.shade700
        };
      case 'subst':
        return {
          'icon': Icons.swap_horiz_rounded,
          'color': Colors.blue.shade600
        };
      default:
        return {
          'icon': Icons.info_outline,
          'color': Theme.of(context).disabledColor
        };
    }
  }

  String _getDetailText(String type, String? detail) {
    switch (type) {
      case 'Goal':
        if (detail == 'Normal Goal') return 'Gol';
        if (detail == 'Penalty') return 'Penaltı Golü';
        if (detail == 'Own Goal') return 'K.K Gol';
        return 'Gol';
      case 'Card':
        return detail ?? 'Kart';
      case 'subst':
        return 'Değişiklik';
      default:
        return detail ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visuals = _getEventVisuals(
        event['type'], event['detail'] ?? '', context);
    
    // GÜNCELLENDİ: Oyuncu değişikliği için doğru verileri alıyoruz
    final isSubstitution = event['type'] == 'subst';
    final playerOut = event['player']['name'] ?? 'Bilinmiyor';
    final playerIn = event['assist']['name']; // 'assist' objesi giren oyuncuyu tutuyor.
    
    final typeText = _getDetailText(event['type'], event['detail']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment:
                isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isHome) ...[
                    Icon(visuals['icon'], color: visuals['color'], size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(typeText,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (isHome) ...[
                    const SizedBox(width: 8),
                    Icon(visuals['icon'], color: visuals['color'], size: 20),
                  ],
                ],
              ),
              const Divider(height: 10),
              // GÜNCELLENDİ: Oyuncu değişikliği ise farklı, değilse farklı gösterim
              if (isSubstitution)
                Column(
                  crossAxisAlignment: isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text("Çıkan: $playerOut", style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                    if (playerIn != null)
                      Text("Giren: $playerIn", style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                )
              else
                Text(
                  playerOut, // Değişiklik değilse ana oyuncu
                  style: theme.textTheme.bodyLarge,
                  textAlign: isHome ? TextAlign.end : TextAlign.start,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
