// lib/widgets/match_event_timeline.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MatchEventTimeline extends StatelessWidget {
  final List<dynamic> events;
  const MatchEventTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text("Maç özeti için olay verisi bulunmuyor."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _EventTile(event: events[index]);
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventTile({required this.event});

  // DEĞİŞİKLİK: Türkçeleştirme ve ikon güncellemeleri
  Widget _getEventIcon(String type, String detail) {
    switch (type) {
      case 'Goal':
        return Icon(Icons.sports_soccer, color: Colors.green.shade600, size: 28);
      case 'Card':
        if (detail == 'Yellow Card') {
          return Container(width: 16, height: 22, color: Colors.yellow.shade600,
            child: const Center(child: Text('S', style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)))
          );
        } else {
          return Container(width: 16, height: 22, color: Colors.red.shade600,
            child: const Center(child: Text('K', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)))
          );
        }
      case 'subst':
        return Icon(Icons.swap_horiz_rounded, color: Colors.blue.shade600, size: 28);
      default:
        return Icon(Icons.info_outline, color: Colors.grey.shade600, size: 28);
    }
  }

  String _getDetailText(String type, String? detail) {
    if (type == 'Goal') {
      if (detail == 'Normal Goal') return 'Gol';
      if (detail == 'Penalty') return 'Penaltı Golü';
      if (detail == 'Own Goal') return 'Kendi Kalesine Gol';
    }
    if (type == 'Card') {
      if (detail == 'Yellow Card') return 'Sarı Kart';
      if (detail == 'Red Card') return 'Kırmızı Kart';
    }
    if (type == 'subst') {
      return 'Oyuncu Değişikliği';
    }
    return detail ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = event['time']['elapsed'];
    final teamLogo = event['team']['logo'];
    final teamName = event['team']['name'];
    final playerName = event['player']['name'] ?? 'N/A';
    final assistName = event['assist']['name'];
    final type = event['type'];
    final detail = event['detail'];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 1.5, color: theme.dividerColor),
                Positioned(
                  top: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor)
                    ),
                    child: Text("$time'"),
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Card(
                elevation: 0.5,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (teamLogo != null)
                            CachedNetworkImage(imageUrl: teamLogo, width: 24, height: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              teamName,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            _getDetailText(type, detail),
                            style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                           _getEventIcon(type, detail),
                           const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(playerName, style: theme.textTheme.bodyLarge),
                              if (assistName != null)
                                Text(
                                  "Asist: $assistName",
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}