// lib/widgets/match_lineups_view.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class MatchLineupsView extends StatelessWidget {
  final List<dynamic> lineups;

  const MatchLineupsView({Key? key, required this.lineups}) : super(key: key);

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
        final pitchHeight = pitchWidth * 1.65;

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
                ..._buildPlayerWidgetsFromGrid(
                  players: homeStarters,
                  pitchWidth: pitchWidth,
                  pitchHeight: pitchHeight,
                  isHomeTeam: true,
                ),
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

  // GÜNCELLEME: Oyuncu yerleşim mantığı, referans görsele uygun olarak tamamen yeniden yazıldı.
  List<Widget> _buildPlayerWidgetsFromGrid({
    required List<dynamic> players,
    required double pitchWidth,
    required double pitchHeight,
    required bool isHomeTeam,
  }) {
    final List<Widget> playerWidgets = [];

    // 1. Grid verisi olan ve olmayan oyuncuları ayır.
    final goalkeeper = players.firstWhere((p) => p['player']?['pos'] == 'G', orElse: () => null);
    // DÜZELTME: Kaleciyi listeden çıkararak mükerrer gösterimi engelle.
    final outfieldPlayers = players.where((p) => p['player']?['pos'] != 'G' && p['player']?['grid'] != null && (p['player']['grid'] as String).contains(':')).toList();

    // Grid verisi yoksa, mantık yürütülemez.
    if (outfieldPlayers.isEmpty) {
      return [];
    }
    
    // 2. Oyuncuları grid'deki satır ve sütun numaralarına göre grupla ve maksimum değerleri bul.
    final Map<int, List<Map<String, dynamic>>> playersByRow = {};
    int maxRow = 0;
    int maxCol = 0;

    for (var p in outfieldPlayers) {
      final parts = (p['player']['grid'] as String).split(':');
      final row = int.tryParse(parts[0]) ?? 0;
      final col = int.tryParse(parts[1]) ?? 0;

      if (row > 0) {
        if (!playersByRow.containsKey(row)) {
          playersByRow[row] = [];
        }
        playersByRow[row]!.add(p['player']);
        if (row > maxRow) maxRow = row;
        if (col > maxCol) maxCol = col;
      }
    }
    
    // 3. Kaleciyi her zaman standart yerine koy.
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
    
    // 4. Oynanabilir alanın sınırlarını ve dikey adımları tanımla.
    const double horizontalPadding = 0.08; // Kenarlardan %8 boşluk
    const double verticalPadding = 0.12;   // Kale arkasından %12 boşluk
    const double midFieldBuffer = 0.05;   // Orta saha çizgisinden %5 tampon

    final playableWidth = pitchWidth * (1 - 2 * horizontalPadding);
    final startX = pitchWidth * horizontalPadding;
    
    // 5. Her satırdaki (line) oyuncuları yerleştir.
    final sortedRows = playersByRow.keys.toList()..sort();

    for (var row in sortedRows) {
      final playersInRow = playersByRow[row]!;
      
      // Dikey pozisyonu (Y) hesapla.
      final double verticalRatio = (row - 1) / (maxRow > 1 ? maxRow - 1 : 1);
      
      double y;
      if (isHomeTeam) {
        // Ev sahibi (alt yarı saha): Defans (row 1) kaleye yakın, forvet (maxRow) orta sahaya yakın olmalı.
        final homeDefensiveLineY = pitchHeight * (1 - verticalPadding);
        final homeOffensiveLineY = (pitchHeight / 2) + (pitchHeight * midFieldBuffer);
        final homePlayableHeight = homeDefensiveLineY - homeOffensiveLineY;
        y = homeDefensiveLineY - (verticalRatio * homePlayableHeight);
      } else {
        // Deplasman (üst yarı saha): Defans (row 1) kaleye yakın, forvet (maxRow) orta sahaya yakın olmalı.
        final awayDefensiveLineY = pitchHeight * verticalPadding;
        final awayOffensiveLineY = (pitchHeight / 2) - (pitchHeight * midFieldBuffer);
        final awayPlayableHeight = awayOffensiveLineY - awayDefensiveLineY;
        y = awayDefensiveLineY + (verticalRatio * awayPlayableHeight);
      }

      // Yatay pozisyonu (X) hesapla.
      for (int i = 0; i < playersInRow.length; i++) {
        final player = playersInRow[i];
        final col = int.tryParse((player['grid'] as String).split(':')[1]) ?? 0;
        
        // DÜZELTME: Oyuncuları o hattaki sayısına göre değil, genel maksimum sütun sayısına göre yerleştir.
        // Bu, kanat oyuncularının kenarlara daha yakın olmasını sağlar.
        final double horizontalRatio = (col - 1) / (maxCol > 1 ? maxCol - 1 : 1);
        final double x = startX + (horizontalRatio * playableWidth);
        
        playerWidgets.add(
          _buildPlayer(
            player: player,
            left: x,
            top: y,
            isHome: isHomeTeam,
          ),
        );
      }
    }

    return playerWidgets;
  }

  // Oyuncu widget'ını oluşturan metot.
  Widget _buildPlayer({
    required dynamic player,
    required double left,
    required double top,
    required bool isHome,
  }) {
    final playerName = player['name'] as String? ?? 'Bilinmiyor';
    final playerWidgetWidth = 80.0;
    final playerWidgetHeight = 70.0; 
    
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
              padding: const EdgeInsets.all(5),
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
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)
                ]
              ),
              child: Text(
                player['number']?.toString() ?? '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                playerName.split(' ').last,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Yedek oyuncular listesi (Değişiklik yok)
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
            }).toList(),
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
