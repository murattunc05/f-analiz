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
    final homeTeam = matchData['teams']['home'];
    final awayTeam = matchData['teams']['away'];
    final fixture = matchData['fixture'];

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
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Column(
            // DEĞİŞİKLİK: Elemanlar arası boşluğu artırmak için spaceEvenly kullanıldı.
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

              // 2. Logolar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TeamLogo(team: homeTeam, textColor: textColor),
                  _TeamLogo(team: awayTeam, textColor: textColor),
                ],
              ),
              
              // 3. Takım İsimleri ve Skorlar
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TeamScoreRow(
                    team: homeTeam,
                    score: matchData['goals']['home'],
                    textColor: textColor,
                  ),
                  const SizedBox(height: 8),
                  _TeamScoreRow(
                    team: awayTeam,
                    score: matchData['goals']['away'],
                    textColor: textColor,
                  ),
                ],
              ),

              // 4. Canlı Etiketi
              _buildLiveBadge(context, fixture, finalGradient.first),
            ],
          ),
        ),
      ),
    );
  }

  // 'Canlı' etiketini oluşturan bölüm
  Widget _buildLiveBadge(BuildContext context, Map<String, dynamic> fixture, Color badgeTextColor) {
    final status = fixture['status']['short'];
    final minute = fixture['status']['elapsed'];
    String statusText;

    // DEĞİŞİKLİK: Devre arası kontrolü eklendi
    if (status == 'HT') {
      statusText = 'D.A';
    } else if (minute != null) {
      statusText = "$minute'";
    } else {
      statusText = 'Canlı';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DEĞİŞİKLİK: Canlı olduğunu belirten kırmızı nokta eklendi ve boyutu küçültüldü.
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.redAccent.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6), // Nokta ile yazı arasına boşluk
          Text(
            statusText,
            style: TextStyle(
              color: badgeTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sadece takım logosunu gösteren yardımcı widget.
class _TeamLogo extends StatelessWidget {
  final Map<String, dynamic> team;
  final Color textColor;

  const _TeamLogo({required this.team, required this.textColor});
  
  @override
  Widget build(BuildContext context) {
    final String? logoUrl = team['logo'];
    return CircleAvatar(
      radius: 26,
      // DEĞİŞİKLİK: Yarı saydam arka plan beyaza çevrildi.
      backgroundColor: Colors.white,
      child: SizedBox(
        height: 32,
        width: 32,
        child: logoUrl != null
            ? CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const SizedBox(),
                errorWidget: (context, url, error) => Icon(Icons.shield, size: 32, color: Colors.grey.shade600),
              )
            : Icon(Icons.shield, size: 32, color: Colors.grey.shade600),
      ),
    );
  }
}


/// Takım adı ve skoru tek bir satırda gösteren yardımcı widget.
class _TeamScoreRow extends StatelessWidget {
  final Map<String, dynamic> team;
  final dynamic score;
  final Color textColor;

  const _TeamScoreRow({
    required this.team,
    required this.score,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Takım Adı (Esnek alan)
        Expanded(
          child: Text(
            team['name'] ?? 'Takım',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 10), // İsim ve skor arası boşluk
        // Skor (Sabit alan)
        Text(
          (score ?? 0).toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
