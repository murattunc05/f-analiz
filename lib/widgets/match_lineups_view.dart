import 'package:flutter/material.dart';
import 'dart:math' as math;

// Mevcut kadro görünümünü, futbol sahası üzerinde dizilişi gösterecek şekilde güncelleyen widget.
class MatchLineupsView extends StatelessWidget {
  // Gelen verinin hem List hem de Map olabilmesi için türü 'dynamic' olarak değiştirildi.
  final dynamic lineups;

  const MatchLineupsView({Key? key, required this.lineups}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? homeTeam;
    Map<String, dynamic>? awayTeam;

    // Gelen 'lineups' verisinin türünü kontrol ediyoruz. Bu yapı, API'den gelebilecek
    // farklı veri formatlarına (List veya Map) karşı uygulamayı daha dayanıklı hale getirir.
    if (lineups is List && lineups.length >= 2) {
      // API'den gelen veri List<dynamic> ise, ilk elemanı ev sahibi, ikincisini deplasman olarak atıyoruz.
      homeTeam = lineups[0] as Map<String, dynamic>?;
      awayTeam = lineups[1] as Map<String, dynamic>?;
    } else if (lineups is Map<String, dynamic>) {
      // Veri Map<String, dynamic> formatında ise, 'home' ve 'away' anahtarlarını kullanarak atama yapıyoruz.
      homeTeam = lineups['home'] as Map<String, dynamic>?;
      awayTeam = lineups['away'] as Map<String, dynamic>?;
    }

    // Takım verileri herhangi bir nedenle (API hatası, boş veri vb.) alınamazsa,
    // kullanıcıya bilgilendirici bir mesaj gösteriyoruz.
    if (homeTeam == null || awayTeam == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Kadro bilgileri mevcut değil veya formatı hatalı.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Ana gövde, kaydırılabilir bir yapıda olacak
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Takım isimleri ve dizilişlerini gösteren başlık
            _buildFormationHeader(
              context,
              homeTeam['team']?['name'] ?? 'Ev Sahibi', // Null kontrolü eklendi
              awayTeam['team']?['name'] ?? 'Deplasman', // Null kontrolü eklendi
              homeTeam['formation'] ?? 'N/A', // Null kontrolü eklendi
              awayTeam['formation'] ?? 'N/A', // Null kontrolü eklendi
            ),
            const SizedBox(height: 16),
            // Futbol sahası ve oyuncuların dizilişi
            _buildFootballPitch(context, homeTeam, awayTeam),
            const SizedBox(height: 24),
            // Yedek oyuncular bölümü
            _buildSubstitutes(context, homeTeam, awayTeam),
          ],
        ),
      ),
    );
  }

  // Takım isimlerini ve formasyon bilgilerini gösteren bir başlık widget'ı oluşturur.
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

  // Futbol sahasını ve üzerine yerleştirilmiş oyuncuları içeren ana widget'ı oluşturur.
  Widget _buildFootballPitch(BuildContext context, Map<String, dynamic> homeTeam, Map<String, dynamic> awayTeam) {
    // Takımların ilk 11 ve formasyon bilgilerinin null veya boş olup olmadığını kontrol et
    final homeStarters = (homeTeam['startXI'] as List<dynamic>?) ?? [];
    final awayStarters = (awayTeam['startXI'] as List<dynamic>?) ?? [];
    final homeFormation = homeTeam['formation'] as String?;
    final awayFormation = awayTeam['formation'] as String?;

    if (homeStarters.isEmpty || awayStarters.isEmpty || homeFormation == null || awayFormation == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('İlk 11 bilgisi mevcut değil.'),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final pitchWidth = constraints.maxWidth;
        // Sahanın en-boy oranını korumak için yüksekliği belirliyoruz
        final pitchHeight = pitchWidth * 1.4;

        return ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: pitchWidth,
            height: pitchHeight,
            color: Colors.green[800],
            // Stack, saha üzerine oyuncuları ve saha çizgilerini eklememizi sağlar
            child: Stack(
              children: [
                // Saha çizgilerini çizen widget
                CustomPaint(
                  size: Size.infinite,
                  painter: PitchPainter(),
                ),
                // Ev sahibi takım oyuncuları
                ..._buildPlayerWidgets(
                  players: homeStarters,
                  formation: homeFormation,
                  pitchWidth: pitchWidth,
                  pitchHeight: pitchHeight,
                  isHomeTeam: true,
                ),
                // Deplasman takımı oyuncuları
                ..._buildPlayerWidgets(
                  players: awayStarters,
                  formation: awayFormation,
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

  // Oyuncuları formasyona göre saha üzerine yerleştiren widget listesini döndürür.
  List<Widget> _buildPlayerWidgets({
    required List<dynamic> players,
    required String formation,
    required double pitchWidth,
    required double pitchHeight,
    required bool isHomeTeam,
  }) {
    // Formasyon verisinin geçerli olup olmadığını kontrol et
    if (formation.isEmpty || !formation.contains('-')) {
        return []; // Geçersiz formasyon durumunda boş liste dön
    }
    
    final formationLines = formation.split('-').map(int.tryParse).where((n) => n != null).cast<int>().toList();
    if (formationLines.isEmpty || formationLines.fold(0, (a, b) => a + b) > 10) {
        return []; // Ayrıştırma başarısız olursa veya oyuncu sayısı hatalıysa boş liste dön
    }

    final List<Widget> playerWidgets = [];

    // 1. Kaleci
    final goalkeeper = players.firstWhere((p) => p['player']?['pos'] == 'G', orElse: () => players.isNotEmpty ? players.first : null);
    if (goalkeeper != null) {
      playerWidgets.add(
        _buildPlayer(
          player: goalkeeper,
          left: pitchWidth / 2,
          top: isHomeTeam ? pitchHeight * 0.92 : pitchHeight * 0.08,
          isHome: isHomeTeam,
        ),
      );
    }

    final outfieldPlayers = players.where((p) => p['player']?['pos'] != 'G').toList();
    double verticalStep = (pitchHeight * 0.75) / (formationLines.length);
    int playerIndex = 0;

    // 2. Diğer Oyuncular (Defans, Orta Saha, Forvet)
    for (int i = 0; i < formationLines.length; i++) {
      final linePlayerCount = formationLines[i];
      final verticalPosition = isHomeTeam
          ? (pitchHeight * 0.82) - (verticalStep * i)
          : (pitchHeight * 0.18) + (verticalStep * i);

      for (int j = 0; j < linePlayerCount; j++) {
        if (playerIndex >= outfieldPlayers.length) break;
        
        final horizontalPosition = (pitchWidth / (linePlayerCount + 1)) * (j + 1);

        playerWidgets.add(
          _buildPlayer(
            player: outfieldPlayers[playerIndex],
            left: horizontalPosition,
            top: verticalPosition,
            isHome: isHomeTeam,
          ),
        );
        playerIndex++;
      }
    }

    return playerWidgets;
  }

  // Tek bir oyuncuyu temsil eden widget'ı oluşturur.
  Widget _buildPlayer({
    required dynamic player,
    required double left,
    required double top,
    required bool isHome,
  }) {
    final playerName = player['player']?['name'] as String? ?? 'Bilinmiyor';
    final playerWidgetWidth = 65.0;
    final playerWidgetHeight = 55.0;
    
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
                player['player']?['number']?.toString() ?? '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
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

  // Yedek oyuncuları listeleyen widget'ı oluşturur.
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

  // Belirli bir takımın yedek oyuncu listesini oluşturan yardımcı widget.
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
              if (player == null) return const SizedBox.shrink(); // Veri yoksa boş widget dön
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

// Futbol sahası çizgilerini çizen CustomPainter sınıfı.
class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final width = size.width;
    final height = size.height;

    // Dış çizgiler
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

    // Orta saha çizgisi
    canvas.drawLine(Offset(0, height / 2), Offset(width, height / 2), paint);

    // Orta yuvarlak
    canvas.drawCircle(Offset(width / 2, height / 2), width / 8, paint);

    // Orta nokta
    canvas.drawCircle(Offset(width / 2, height / 2), 3, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;

    // Ceza Sahaları
    final penaltyAreaHeight = height * 0.18;
    final penaltyAreaWidth = width * 0.65;
    // Ev sahibi ceza sahası
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(width / 2, height - penaltyAreaHeight / 2),
        width: penaltyAreaWidth,
        height: penaltyAreaHeight,
      ),
      paint,
    );
    // Deplasman ceza sahası
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(width / 2, penaltyAreaHeight / 2),
        width: penaltyAreaWidth,
        height: penaltyAreaHeight,
      ),
      paint,
    );

    // Kale Alanları (Altı Pas)
    final goalAreaHeight = height * 0.07;
    final goalAreaWidth = width * 0.3;
    // Ev sahibi kale alanı
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(width / 2, height - goalAreaHeight / 2),
        width: goalAreaWidth,
        height: goalAreaHeight,
      ),
      paint,
    );
    // Deplasman kale alanı
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(width / 2, goalAreaHeight / 2),
        width: goalAreaWidth,
        height: goalAreaHeight,
      ),
      paint,
    );

    // Ceza yayı
    final penaltyArcRadius = width * 0.15;
    // Ev sahibi ceza yayı
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(width / 2, height - penaltyAreaHeight),
        width: penaltyArcRadius * 2,
        height: penaltyArcRadius * 2,
      ),
      math.pi * 0.2, // Başlangıç açısı
      math.pi * 0.6, // Tarama açısı
      false,
      paint,
    );
    // Deplasman ceza yayı
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(width / 2, penaltyAreaHeight),
        width: penaltyArcRadius * 2,
        height: penaltyArcRadius * 2,
      ),
      math.pi * 1.2, // Başlangıç açısı
      math.pi * 0.6, // Tarama açısı
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
