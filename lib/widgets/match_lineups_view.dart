// lib/widgets/match_lineups_view.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;

/// Maç kadrolarını görsel bir futbol sahası üzerinde gösteren widget.
class MatchLineupsView extends StatelessWidget {
  final List<dynamic> lineups;
  const MatchLineupsView({super.key, required this.lineups});

  @override
  Widget build(BuildContext context) {
    // Kadro verisinin geçerli olup olmadığını kontrol et
    if (lineups.isEmpty || lineups.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "Kadrolar henüz açıklanmadı.",
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    final homeLineup = lineups[0];
    final awayLineup = lineups[1];
    
    // Takım renklerini ve logolarını al
    // API'den renk kodu gelmezse varsayılan renkler atanır
    final homeTeamColor = Color(int.parse('0xFF${homeLineup['team']['colors']?['player']?['primary'] ?? 'FF0000'}'));
    final awayTeamColor = Color(int.parse('0xFF${awayLineup['team']['colors']?['player']?['primary'] ?? 'FFFFFF'}'));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // GÜNCELLEME: Futbol sahası arka planı artık assets'ten yükleniyor
            Image.asset(
              'assets/images/football_pitch.png', // Yerel dosya yolu
              fit: BoxFit.contain,
              // GÜNCELLEME: withOpacity yerine withAlpha kullanıldı
              color: Colors.green.shade700.withAlpha(230), 
              colorBlendMode: BlendMode.color,
            ),
            // Saha üzerine oyuncuları yerleştiren katman
            AspectRatio(
              aspectRatio: 68 / 105, // Standart saha oranı
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Ev sahibi takım dizilişi
                      ..._buildFormation(
                        players: homeLineup['startXI'],
                        size: constraints.biggest,
                        isHome: true,
                        jerseyColor: homeTeamColor
                      ),
                      // Deplasman takımı dizilişi
                      ..._buildFormation(
                        players: awayLineup['startXI'],
                        size: constraints.biggest,
                        isHome: false,
                        jerseyColor: awayTeamColor
                      ),
                    ],
                  );
                },
              ),
            ),
            // En alttaki takım isimleri
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TeamLabel(team: homeLineup['team']),
                  _TeamLabel(team: awayLineup['team']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bir takımın oyuncularını saha üzerine yerleştiren metot
  List<Widget> _buildFormation({
    required List<dynamic> players,
    required Size size,
    required bool isHome,
    required Color jerseyColor,
  }) {
    if (players.isEmpty) return [];

    return players.map((playerData) {
      final player = playerData['player'];
      final gridPos = player['grid']?.toString() ?? "0:0";
      final position = _getPositionFromGrid(gridPos, size, isHome);

      return Positioned(
        left: position.dx,
        top: position.dy,
        child: _PlayerMarker(
          player: player,
          jerseyColor: jerseyColor,
        ),
      );
    }).toList();
  }

  /// API'den gelen grid pozisyonunu (örn: "4:2") ekrandaki koordinatlara çevirir.
  Offset _getPositionFromGrid(String grid, Size size, bool isHome) {
    try {
      final parts = grid.split(':');
      final yPos = int.parse(parts[0]);
      final xPos = int.parse(parts[1]);

      // Sahayı 12 dikey ve 6 yatay bölüme ayıralım (kaleci dahil)
      final double cellHeight = size.height / 12;
      final double cellWidth = size.width / 6;

      double finalX = (cellWidth * xPos) - (cellWidth / 2);
      double finalY;

      if (isHome) {
        // Ev sahibi takım (alt yarı saha)
        finalY = (cellHeight * (12 - yPos)) + (cellHeight / 2);
      } else {
        // Deplasman takımı (üst yarı saha)
        finalY = (cellHeight * yPos) - (cellHeight / 2);
      }
      
      // Oyuncu widget'ının merkezini bu koordinata getirmek için kaydırma
      return Offset(finalX - 25, finalY - 25); // Boyutlara göre ayarlandı
    } catch (e) {
      return const Offset(0, 0); // Hata durumunda varsayılan pozisyon
    }
  }
}

/// Saha üzerindeki her bir oyuncuyu temsil eden widget (forma ve isim)
class _PlayerMarker extends StatelessWidget {
  final Map<String, dynamic> player;
  final Color jerseyColor;

  const _PlayerMarker({required this.player, required this.jerseyColor});

  @override
  Widget build(BuildContext context) {
    // Forma renginin parlaklığına göre numara rengini belirle
    final numberColor = jerseyColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final name = player['name']?.toString() ?? 'Bilinmiyor';
    // Soyadı veya kısa adı göster
    final displayName = name.contains(' ') ? name.substring(name.lastIndexOf(' ') + 1) : name;

    return SizedBox(
      width: 50, // Widget genişliği
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: jerseyColor,
            child: Text(
              player['number']?.toString() ?? '?',
              style: TextStyle(color: numberColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sahanın altında takım logosunu ve ismini gösteren widget
class _TeamLabel extends StatelessWidget {
  final Map<String, dynamic> team;
  const _TeamLabel({required this.team});

  @override
  Widget build(BuildContext context) {
    final String? logoUrl = team['logo'];
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (logoUrl != null)
            CachedNetworkImage(imageUrl: logoUrl, width: 24, height: 24)
          else 
            const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              team['name'] ?? 'Takım',
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 14,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)]
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
