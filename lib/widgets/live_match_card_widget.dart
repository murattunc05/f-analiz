// lib/widgets/live_match_card_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Referans görsele göre tamamen yeniden tasarlanmış,
/// dikey ve kompakt canlı maç kartı.
class LiveMatchCardWidget extends StatelessWidget {
  final Map<String, dynamic> matchData;
  final VoidCallback onTap;
  final List<Color> gradientColors;

  const LiveMatchCardWidget({
    super.key,
    required this.matchData,
    required this.onTap,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    // Arka plan ve metin renklerini belirle
    final List<Color> finalGradient =
        gradientColors.length >= 2 ? gradientColors : [const Color(0xffe53935), const Color(0xffc62828)];
    final averageLuminance = (finalGradient[0].computeLuminance() + finalGradient.last.computeLuminance()) / 2;
    final textColor = averageLuminance > 0.4 ? Colors.black87 : Colors.white;

    final league = matchData['league'];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: finalGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Lig Adı
              Text(
                league['name'] ?? 'Lig Bilgisi Yok',
                style: TextStyle(
                  color: textColor.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // 2. Takımlar (Logolar, İsimler ve Skorlar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TeamDisplay(
                    team: matchData['teams']['home'],
                    score: matchData['goals']['home'],
                    textColor: textColor,
                  ),
                  _TeamDisplay(
                    team: matchData['teams']['away'],
                    score: matchData['goals']['away'],
                    textColor: textColor,
                  ),
                ],
              ),

              // 3. Canlı Etiketi
              _buildLiveBadge(context, finalGradient.first),
            ],
          ),
        ),
      ),
    );
  }

  // 'Canlı' etiketini oluşturan bölüm
  Widget _buildLiveBadge(BuildContext context, Color badgeTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        "Canlı",
        style: TextStyle(
          color: badgeTextColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Takım logosunu, adını ve skorunu dikey olarak gösteren yardımcı widget.
class _TeamDisplay extends StatelessWidget {
  final Map<String, dynamic> team;
  final dynamic score;
  final Color textColor;

  const _TeamDisplay({
    required this.team,
    required this.score,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // HATA DÜZELTMESİ: API'den gelen logo URL'sinin null olup olmadığını kontrol et
    final String? logoUrl = team['logo'];

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Takım Logosu
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: SizedBox(
              height: 32,
              width: 32,
              child: logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: logoUrl, // Hata bu satırdaydı, null kontrolü eklendi
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const SizedBox(),
                      errorWidget: (context, url, error) => Icon(Icons.shield, size: 32, color: textColor),
                    )
                  : Icon(Icons.shield, size: 32, color: textColor),
            ),
          ),
          const SizedBox(height: 8),

          // Takım Adı
          Text(
            team['name'] ?? 'Takım',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          
          // Skor
          Text(
            (score ?? 0).toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
