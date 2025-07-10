// lib/widgets/match_lineups_view.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class MatchLineupsView extends StatelessWidget {
  final List<dynamic> lineups;

  const MatchLineupsView({super.key, required this.lineups});

  @override
  Widget build(BuildContext context) {
    if (lineups.isEmpty || lineups.length < 2) {
       return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Kadro bilgileri mevcut değil.', textAlign: TextAlign.center),
        ),
      );
    }
    
    final homeTeam = lineups[0] as Map<String, dynamic>;
    final awayTeam = lineups[1] as Map<String, dynamic>;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildFormationHeader(
              context,
              homeTeam['team']?['name'] ?? 'Ev Sahibi',
              awayTeam['team']?['name'] ?? 'Deplasman',
              homeTeam['formation'] ?? 'N/A',
              awayTeam['formation'] ?? 'N/A',
            ),
            const SizedBox(height: 16),
            _buildFootballPitch(context, homeTeam, awayTeam),
            const SizedBox(height: 24),
            _buildSubstitutes(context, homeTeam, awayTeam),
          ],
        ),
      ),
    );
  }

  Widget _buildFormationHeader(BuildContext context, String homeTeam,
      String awayTeam, String homeFormation, String awayFormation) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              "Kadro Dizilişleri",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(homeTeam, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis)),
                Expanded(child: Text(awayTeam, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(homeFormation, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.blueAccent)),
                Text(awayFormation, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.redAccent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFootballPitch(BuildContext context, Map<String, dynamic> homeTeam, Map<String, dynamic> awayTeam) {
    final homeStarters = (homeTeam['startXI'] as List<dynamic>?) ?? [];
    final awayStarters = (awayTeam['startXI'] as List<dynamic>?) ?? [];
    
    if (homeStarters.isEmpty || awayStarters.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.green[800],
          borderRadius: BorderRadius.circular(12.0)
        ),
        child: const Text('İlk 11 bilgisi mevcut değil.', style: TextStyle(color: Colors.white)),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final pitchWidth = constraints.maxWidth;
        // Referans görsele daha uygun bir saha oranı
        final pitchHeight = pitchWidth * 1.5;

        return ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: pitchWidth,
            height: pitchHeight,
            color: Colors.green[800],
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: PitchPainter(),
                ),
                // Home team players (bottom half)
                ..._buildPlayerWidgetsFromGrid(
                  players: homeStarters,
                  pitchWidth: pitchWidth,
                  pitchHeight: pitchHeight,
                  isHomeTeam: true,
                ),
                // Away team players (top half)
                ..._buildPlayerWidgetsFromGrid(
                  players: awayStarters,
                  pitchWidth: pitchWidth,
                  pitchHeight: pitchHeight,
                  isHomeTeam: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // GÜNCELLEME: Oyuncu yerleşim mantığı, formasyona göre dinamik ve orantılı
  // yerleşim yapacak şekilde tamamen yeniden yazıldı.
  List<Widget> _buildPlayerWidgetsFromGrid({
    required List<dynamic> players,
    required double pitchWidth,
    required double pitchHeight,
    required bool isHomeTeam,
  }) {
    final List<Widget> playerWidgets = [];

    // 1. Kaleciyi ve saha oyuncularını ayır
    final goalkeeper = players.firstWhere((p) => p['player']?['pos'] == 'G', orElse: () => null);
    final outfieldPlayers = players.where((p) =>
        p['player']?['pos'] != 'G' &&
        p['player']?['grid'] != null &&
        (p['player']['grid'] as String).contains(':')).toList();
    
    // 2. Sadece kaleci varsa veya saha oyuncusu bilgisi yoksa, kaleciyi yerleştirip bitir.
    if (outfieldPlayers.isEmpty) {
        if (goalkeeper != null) {
          playerWidgets.add(
            _buildPlayer(
              player: goalkeeper['player'],
              left: pitchWidth / 2,
              top: isHomeTeam ? pitchHeight * 0.95 : pitchHeight * 0.05, // Home alta, Away üste
              isHome: isHomeTeam,
            ),
          );
        }
      return playerWidgets; // Sadece kaleciyi (veya boş listeyi) döndür.
    }
    
    // 3. Oyuncuları API'den gelen 'grid' verisindeki satır numarasına göre grupla.
    final Map<int, List<Map<String, dynamic>>> playersByRow = {};
    int maxRow = 0;

    for (var p in outfieldPlayers) {
      final parts = (p['player']['grid'] as String).split(':');
      final row = int.tryParse(parts[0]) ?? 0;
      
      if (row > 0) {
        if (!playersByRow.containsKey(row)) playersByRow[row] = [];
        playersByRow[row]!.add(p['player']);
        if (row > maxRow) maxRow = row;
      }
    }
    
    // Herhangi bir sıradaki maksimum oyuncu sayısını bul (formasyonun en geniş hattı, örn: 5-4-1 için 5).
    final int maxPlayersPerLine = playersByRow.values.map((line) => line.length).reduce(math.max);

    // 4. Kaleciyi her zaman standart pozisyonuna yerleştir.
    if (goalkeeper != null) {
      playerWidgets.add(
        _buildPlayer(
          player: goalkeeper['player'],
          left: pitchWidth / 2,
          top: isHomeTeam ? pitchHeight * 0.95 : pitchHeight * 0.05,
          isHome: isHomeTeam,
        ),
      );
    }
    
    // 5. Oynanabilir alanın sınırlarını ve dikey mesafeleri tanımla.
    const double horizontalPadding = 0.05; // Kenarlardan %5 boşluk.
    const double verticalPadding = 0.12;   // Kale arkasından %12 boşluk.
    const double midFieldBuffer = 0.05;    // Orta saha çizgisinden %5 tampon.

    final playableWidth = pitchWidth * (1 - 2 * horizontalPadding);
    final startX = pitchWidth * horizontalPadding;
    
    // 6. Her bir sırayı (defans, orta saha vb.) sahanın üzerine çiz.
    final sortedRows = playersByRow.keys.toList()..sort();

    for (var rowKey in sortedRows) {
      final playersInRow = playersByRow[rowKey]!;
      // Oyuncuları sütun numarasına göre soldan sağa sırala, bu yerleşimin tutarlı olmasını sağlar.
      playersInRow.sort((a, b) {
          final colA = int.tryParse((a['grid'] as String).split(':')[1]) ?? 0;
          final colB = int.tryParse((b['grid'] as String).split(':')[1]) ?? 0;
          return colA.compareTo(colB);
      });
      
      final int numPlayersInRow = playersInRow.length;

      // Dikey pozisyonu (Y ekseni) hesapla.
      final double verticalRatio = (rowKey - 1) / (maxRow > 1 ? maxRow - 1 : 1);
      final double y;
      if (isHomeTeam) { // Ev Sahibi Takım (Alt Yarı Saha)
        final defensiveY = pitchHeight * (1 - verticalPadding);
        final offensiveY = (pitchHeight / 2) + (pitchHeight * midFieldBuffer);
        y = defensiveY - (verticalRatio * (defensiveY - offensiveY));
      } else { // Deplasman Takımı (Üst Yarı Saha)
        final defensiveY = pitchHeight * verticalPadding;
        final offensiveY = (pitchHeight / 2) - (pitchHeight * midFieldBuffer);
        y = defensiveY + (verticalRatio * (offensiveY - defensiveY));
      }

      // Yatay pozisyonu (X ekseni) DİNAMİK olarak hesapla.
      // Sıradaki oyuncu sayısına göre hattın genişliğini ve başlangıç noktasını ayarla.
      // Bu sayede 3'lü orta saha, 5'li defanstan daha dar ve merkezi olur.
      final double lineIndent = (1 - (numPlayersInRow / maxPlayersPerLine)) * playableWidth / 2.0;
      final double currentStartX = startX + lineIndent;
      final double currentPlayableWidth = playableWidth - (2 * lineIndent);
      
      for (int i = 0; i < numPlayersInRow; i++) {
        final player = playersInRow[i];
        
        // Oyuncuları bulundukları hatta eşit aralıklarla dağıt.
        final double horizontalRatio = (numPlayersInRow > 1) ? i / (numPlayersInRow - 1) : 0.5;
        final double x = currentStartX + (horizontalRatio * currentPlayableWidth);
        
        playerWidgets.add(
          _buildPlayer(player: player, left: x, top: y, isHome: isHomeTeam),
        );
      }
    }

    return playerWidgets;
  }

  // Oyuncu widget'ını oluşturan metot (Stil iyileştirmeleri yapıldı).
  Widget _buildPlayer({
    required dynamic player,
    required double left,
    required double top,
    required bool isHome,
  }) {
    final playerName = player['name'] as String? ?? 'Bilinmiyor';
    final playerWidgetWidth = 80.0;
    final playerWidgetHeight = 65.0; // Yüksekliği biraz azalttık.
    
    return Positioned(
      left: left - (playerWidgetWidth / 2),
      top: top - (playerWidgetHeight / 2),
      child: SizedBox(
        width: playerWidgetWidth,
        height: playerWidgetHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Numarayı biraz daha büyük göstermek için
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isHome 
                    ? [Colors.blue.shade700, Colors.blue.shade900]
                    : [Colors.red.shade700, Colors.red.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)
                ]
              ),
              child: Text(
                player['number']?.toString() ?? '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                playerName.split(' ').last,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubstitutes(BuildContext context, Map<String, dynamic> homeTeam, Map<String, dynamic> awayTeam) {
    final homeSubstitutes = (homeTeam['substitutes'] as List<dynamic>?) ?? [];
    final awaySubstitutes = (awayTeam['substitutes'] as List<dynamic>?) ?? [];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              "Yedekler",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubstituteList(context, homeTeam['team']?['name'] ?? 'Ev Sahibi', homeSubstitutes),
                const SizedBox(width: 8),
                _buildSubstituteList(context, awayTeam['team']?['name'] ?? 'Deplasman', awaySubstitutes),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubstituteList(BuildContext context, String teamName, List<dynamic> substitutes) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(teamName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(),
          if (substitutes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Text('Yedek oyuncu yok.'),
            )
          else
            ...substitutes.map((sub) {
              final player = sub['player'];
              if (player == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  "${player['number'] ?? '-'} - ${player['name'] ?? 'Bilinmiyor'}",
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
        ],
      ),
    );
  }
}

// Saha çizgilerini çizen CustomPainter (Değişiklik yok)
class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final width = size.width;
    final height = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
    canvas.drawLine(Offset(0, height / 2), Offset(width, height / 2), paint);
    
    canvas.drawCircle(Offset(width / 2, height / 2), width / 8, paint);
    canvas.drawCircle(Offset(width / 2, height / 2), 3, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;

    final penaltyAreaHeight = height * 0.18;
    final penaltyAreaWidth = width * 0.65;
    canvas.drawRect(Rect.fromCenter(center: Offset(width / 2, height - penaltyAreaHeight / 2), width: penaltyAreaWidth, height: penaltyAreaHeight), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(width / 2, penaltyAreaHeight / 2), width: penaltyAreaWidth, height: penaltyAreaHeight), paint);

    final goalAreaHeight = height * 0.07;
    final goalAreaWidth = width * 0.3;
    canvas.drawRect(Rect.fromCenter(center: Offset(width / 2, height - goalAreaHeight / 2), width: goalAreaWidth, height: goalAreaHeight), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(width / 2, goalAreaHeight / 2), width: goalAreaWidth, height: goalAreaHeight), paint);

    final penaltyArcRadius = width * 0.15;
    canvas.drawArc(Rect.fromCenter(center: Offset(width / 2, height - penaltyAreaHeight), width: penaltyArcRadius * 2, height: penaltyArcRadius * 2), math.pi * 0.2, math.pi * 0.6, false, paint);
    canvas.drawArc(Rect.fromCenter(center: Offset(width / 2, penaltyAreaHeight), width: penaltyArcRadius * 2, height: penaltyArcRadius * 2), math.pi * 1.2, math.pi * 0.6, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}