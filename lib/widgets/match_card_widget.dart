// lib/widgets/match_card_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MatchCardWidget extends StatelessWidget {
  final Map<String, dynamic> matchData;
  final VoidCallback onTap;
  final Color cardColor;

  const MatchCardWidget({
    super.key,
    required this.matchData,
    required this.onTap,
    this.cardColor = const Color(0xFF4A0D66),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final homeTeam = matchData['teams']['home'];
    final awayTeam = matchData['teams']['away'];
    final goals = matchData['goals'];
    final fixture = matchData['fixture'];
    final league = matchData['league'];
    final status = fixture['status']['short'];
    final minute = fixture['status']['elapsed'];
    
    final textColor = cardColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    final scoreColor = cardColor.computeLuminance() > 0.5 ? theme.colorScheme.primary : Colors.pinkAccent.shade100;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          if (league['logo'] != null)
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.08,
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: CachedNetworkImage(
                      color: textColor.withOpacity(0.5),
                      imageUrl: league['logo'],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          
          InkWell(
            onTap: onTap,
            child: Padding(
              // DEĞİŞİKLİK: Dikey padding azaltıldı
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
              child: Column(
                children: [
                  Text(league['name'], style: theme.textTheme.bodyLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                  if (league['round'] != null)
                     Padding(
                       // DEĞİŞİKLİK: Dikey boşluk azaltıldı
                       padding: const EdgeInsets.only(top: 2.0, bottom: 8.0),
                       child: Text(
                         league['round'].replaceAll('Regular Season - ',''), 
                         style: theme.textTheme.bodyMedium?.copyWith(color: textColor.withOpacity(0.8))
                        ),
                     ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _TeamDisplay(team: homeTeam, textColor: textColor, alignment: CrossAxisAlignment.start, homeOrAway: "Home"),
                      _ScoreDisplay(status: status, goals: goals, minute: minute, textColor: textColor, scoreColor: scoreColor),
                      _TeamDisplay(team: awayTeam, textColor: textColor, alignment: CrossAxisAlignment.end, homeOrAway: "Away"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamDisplay extends StatelessWidget {
  final Map<String, dynamic> team;
  final Color textColor;
  final CrossAxisAlignment alignment;
  final String homeOrAway;

  const _TeamDisplay({
    required this.team, 
    required this.textColor, 
    required this.alignment, 
    required this.homeOrAway
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (team['logo'] != null)
            CachedNetworkImage(
              imageUrl: team['logo'], height: 60, width: 60, fit: BoxFit.contain,
              placeholder: (context, url) => const SizedBox(height: 60, width: 60),
              errorWidget: (context, url, error) => Icon(Icons.shield_outlined, size: 60, color: textColor.withOpacity(0.6)),
            )
          else
            Icon(Icons.shield_outlined, size: 60, color: textColor.withOpacity(0.6)),
          const SizedBox(height: 4),
          Text(
            team['name'] ?? 'Bilinmiyor',
            textAlign: alignment == CrossAxisAlignment.start ? TextAlign.left : TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(homeOrAway, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13)),
        ],
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  final String status;
  final Map<String, dynamic> goals;
  final int? minute;
  final Color textColor;
  final Color scoreColor;

  const _ScoreDisplay({required this.status, required this.goals, this.minute, required this.textColor, required this.scoreColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Expanded(
      flex: 2,
      child: Column(
        children: [
          Text(
            "${goals['home'] ?? '-'} - ${goals['away'] ?? '-'}",
            style: theme.textTheme.displaySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: scoreColor.withOpacity(0.8), width: 1.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _getStatusText(),
              style: TextStyle(color: scoreColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (['1H', '2H', 'ET', 'P', 'LIVE'].contains(status)) return "$minute'";
    if (status == 'HT') return "Devre Arası";
    if (status == 'FT' || status == 'AET' || status == 'PEN') return "Maç Sonu";
    return status;
  }
}
