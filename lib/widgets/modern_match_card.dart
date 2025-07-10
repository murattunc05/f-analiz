import 'package:flutter/material.dart';

/// Modern, estetik ve yeniden kullanılabilir maç kartı widget'ı.
///
/// Bu widget, maç bilgilerini (takımlar, skor, durum) görsel olarak zengin bir şekilde sunar.
/// Gölge, yuvarlatılmış köşeler ve daha iyi bir layout ile kullanıcı deneyimini iyileştirir.
/// Tıklandığında dışarıdan verilen `onTap` fonksiyonunu çalıştırır.
class ModernMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final VoidCallback? onTap; // Tıklama fonksiyonu dışarıdan alınacak.

  const ModernMatchCard({
    super.key,
    required this.match,
    this.onTap, // onTap artık isteğe bağlı.
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeTeam = match['teams']['home'];
    final awayTeam = match['teams']['away'];
    final score = match['goals'];
    final status = match['fixture']['status']['short'];

    // Maç skoru null ise '-' olarak göster
    final homeScore = score['home']?.toString() ?? '-';
    final awayScore = score['away']?.toString() ?? '-';

    return GestureDetector(
      onTap: onTap, // Mevcut MatchDetailScreen yönlendirmesi yerine bunu kullanıyoruz.
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _buildStatusIndicator(context, status),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTeamInfo(context, team: homeTeam, alignment: CrossAxisAlignment.start),
                      _buildScoreInfo(context, homeScore: homeScore, awayScore: awayScore, status: status),
                      _buildTeamInfo(context, team: awayTeam, alignment: CrossAxisAlignment.end),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Diğer yardımcı metodlar (_buildTeamInfo, _buildScoreInfo, vb.) aynı kalıyor ---

  Widget _buildTeamInfo(BuildContext context, {required Map<String, dynamic> team, required CrossAxisAlignment alignment}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            team['logo'],
            height: 40,
            width: 40,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_soccer, size: 40),
          ),
          const SizedBox(height: 8),
          Text(
            team['name'],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInfo(BuildContext context, {required String homeScore, required String awayScore, required String status}) {
    bool isFinished = status == 'FT';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$homeScore - $awayScore',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isFinished ? theme.colorScheme.onSurface : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, String status) {
    Color indicatorColor;
    switch (status) {
      case 'FT':
        indicatorColor = Colors.grey;
        break;
      case 'HT':
      case '1H':
      case '2H':
        indicatorColor = Colors.orange;
        break;
      case 'NS':
        indicatorColor = Colors.blue;
        break;
      default:
        indicatorColor = Theme.of(context).colorScheme.primary;
    }

    return Container(
      width: 6,
      decoration: BoxDecoration(
        color: indicatorColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          bottomLeft: Radius.circular(16.0),
        ),
      ),
    );
  }
}
