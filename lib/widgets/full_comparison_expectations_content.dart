// lib/widgets/full_comparison_expectations_content.dart
import 'package:flutter/material.dart';
import 'package:futbol_analiz_app/main.dart'; 

class FullComparisonExpectationsContent extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic> team1Stats;
  final Map<String, dynamic> team2Stats;
  final Map<String, dynamic> comparisonResult;
  final StatsDisplaySettings statsSettings;

  const FullComparisonExpectationsContent({
    super.key,
    required this.theme,
    required this.team1Stats,
    required this.team2Stats,
    required this.comparisonResult,
    required this.statsSettings,
  });

  Widget _buildExpectationRow(String title, String expectation, IconData icon, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(expectation, style: theme.textTheme.bodyMedium, softWrap: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t1Name = team1Stats['displayTeamName'] ?? "Takım 1";
    final t2Name = team2Stats['displayTeamName'] ?? "Takım 2";

    // --- DEĞİŞKEN TANIMLAMALARI HATASIZ HALE GETİRİLDİ ---
    final double avgGoalDiff1 = (team1Stats['golFarki'] as num? ?? 0).toDouble() / ((team1Stats['oynananMacSayisi'] as num?)?.toDouble() ?? 1.0).clamp(1.0, double.infinity);
    final double avgGoalDiff2 = (team2Stats['golFarki'] as num? ?? 0).toDouble() / ((team2Stats['oynananMacSayisi'] as num?)?.toDouble() ?? 1.0).clamp(1.0, double.infinity);
    final double formPuani1 = (team1Stats['formPuani'] as num?)?.toDouble() ?? 0.0;
    final double formPuani2 = (team2Stats['formPuani'] as num?)?.toDouble() ?? 0.0;
    
    // Averaj ve Form Yorumu
    String handicapExpectation = "Takımların averajları ve form durumları arasında belirgin bir fark yok, dengeli bir mücadele olabilir.";
    if (formPuani1 > formPuani2 + 3 && avgGoalDiff1 > avgGoalDiff2 + 0.5) { handicapExpectation = "$t1Name, hem form hem de averaj olarak rakibine üstünlük kurmuş görünüyor. Farklı bir galibiyet potansiyeli taşıyor."; } 
    else if (formPuani2 > formPuani1 + 3 && avgGoalDiff2 > avgGoalDiff1 + 0.5) { handicapExpectation = "$t2Name, hem form hem de averaj olarak rakibine üstünlük kurmuş görünüyor. Farklı bir galibiyet potansiyeli taşıyor."; } 
    else if (avgGoalDiff1 > avgGoalDiff2 + 1.0) { handicapExpectation = "$t1Name'ın averaj üstünlüğü dikkat çekici. Maçın kontrolünü elinde tutabilir."; } 
    else if (avgGoalDiff2 > avgGoalDiff1 + 1.0) { handicapExpectation = "$t2Name'ın averaj üstünlüğü dikkat çekici. Maçın kontrolünü elinde tutabilir."; }
    
    // Korner Beklentileri
    final double ortKorner1 = (team1Stats['ortalamaKorner'] as num?)?.toDouble() ?? 0.0;
    final double ortKorner2 = (team2Stats['ortalamaKorner'] as num?)?.toDouble() ?? 0.0;
    final double toplamOrtKorner = ortKorner1 + ortKorner2;
    String cornerExpectation;
    if (toplamOrtKorner > 0) {
      cornerExpectation = "Maç genelinde beklenen toplam korner sayısı ~${toplamOrtKorner.toStringAsFixed(1)}. ";
      if (toplamOrtKorner > 10.5) { cornerExpectation += "Bu, bol kornerli bir maça işaret ediyor (9.5 Üst)."; } 
      else if (toplamOrtKorner < 8.5) { cornerExpectation += "Bu, az kornerli bir maça işaret ediyor (9.5 Alt)."; }
      if (ortKorner1 > ortKorner2 + 1.5) { cornerExpectation += "\n\n$t1Name'ın daha fazla korner kullanması muhtemel."; } 
      else if (ortKorner2 > ortKorner1 + 1.5) { cornerExpectation += "\n\n$t2Name'ın daha fazla korner kullanması muhtemel."; }
    } else { cornerExpectation = "Korner verisi yetersiz veya yok."; }

    // Kart Beklentileri
    final double ortSari1 = (team1Stats['ortalamaSariKart'] as num?)?.toDouble() ?? 0.0;
    final double ortSari2 = (team2Stats['ortalamaSariKart'] as num?)?.toDouble() ?? 0.0;
    final double toplamOrtSari = ortSari1 + ortSari2;
    String cardExpectation;
    if (toplamOrtSari > 0) {
      cardExpectation = "Maç genelinde beklenen toplam sarı kart sayısı ~${toplamOrtSari.toStringAsFixed(1)}. ";
      if (toplamOrtSari > 4.5) { cardExpectation += "Sert ve bol kartlı bir maç olabilir (3.5 Üst)."; } 
      else if (toplamOrtSari < 3.0) { cardExpectation += "Sakin bir maç geçmesi ve az kart çıkması beklenebilir (3.5 Alt)."; }
      final double faul1 = (team1Stats['ortalamaFaul'] as num?)?.toDouble() ?? 0.0;
      final double faul2 = (team2Stats['ortalamaFaul'] as num?)?.toDouble() ?? 0.0;
      if (faul1 > faul2 + 1.5 && ortSari1 > ortSari2 + 0.3) { cardExpectation += "\n\n$t1Name'ın daha agresif oynaması ve daha fazla kart görmesi olası."; } 
      else if (faul2 > faul1 + 1.5 && ortSari2 > ortSari1 + 0.3) { cardExpectation += "\n\n$t2Name'ın daha agresif oynaması ve daha fazla kart görmesi olası."; }
    } else { cardExpectation = "Kart verisi yetersiz veya yok."; }

    // Skor Aralığı ve KG Yorumu
    final double beklenenToplamGol = (comparisonResult["beklenenToplamGol"] as num?)?.toDouble() ?? 0.0;
    String scoreRangeExpectation;
    if (beklenenToplamGol <= 0) { scoreRangeExpectation = "Skor tahmini için yeterli veri yok."; } 
    else if (beklenenToplamGol < 2.0) { scoreRangeExpectation = "Düşük skorlu bir maç (0-1 gol) bekleniyor. 2.5 Alt seçeneği ağır basıyor."; } 
    else if (beklenenToplamGol < 2.7) { scoreRangeExpectation = "Orta skorlu bir maç (2-3 gol aralığı) daha muhtemel. 2.5 Alt/Üst baremi riskli."; } 
    else if (beklenenToplamGol < 3.5) { scoreRangeExpectation = "Gollü bir maç (3-4 gol aralığı) olabilir. 2.5 Üst seçeneği öne çıkıyor."; } 
    else { scoreRangeExpectation = "Çok gollü bir maç (4+ gol) bekleniyor. 3.5 Üst dahi denenebilir."; }
    
    // HATANIN OLDUĞU SATIRIN DÜZELTİLMİŞ HALİ
    final double kgVar1 = (team1Stats['kgVarYuzdesi'] as num?)?.toDouble() ?? 0.0;
    final double kgVar2 = (team2Stats['kgVarYuzdesi'] as num?)?.toDouble() ?? 0.0;
    final double kgVarOrt = (kgVar1 + kgVar2) / 2;
    
    if (kgVarOrt > 65) { scoreRangeExpectation += "\n\nKarşılıklı gol olma ihtimali (%${kgVarOrt.toStringAsFixed(0)}) oldukça yüksek."; } 
    else if (kgVarOrt > 0 && kgVarOrt < 45) { scoreRangeExpectation += "\n\nKarşılıklı gol olma ihtimali (%${kgVarOrt.toStringAsFixed(0)}) düşük görünüyor."; }

    // Defans & Ofans Yorumu
    List<String> yorumlar = [];
    final double macBasiGol1 = (team1Stats['macBasiOrtalamaGol'] as num?)?.toDouble() ?? 0.0;
    final double macBasiYedigiGol1 = ((team1Stats['yedigi'] as num?)?.toDouble() ?? 0.0) / ((team1Stats['oynananMacSayisi'] as num?)?.toDouble() ?? 1.0).clamp(1.0, double.infinity);
    final double macBasiGol2 = (team2Stats['macBasiOrtalamaGol'] as num?)?.toDouble() ?? 0.0;
    final double macBasiYedigiGol2 = ((team2Stats['yedigi'] as num?)?.toDouble() ?? 0.0) / ((team2Stats['oynananMacSayisi'] as num?)?.toDouble() ?? 1.0).clamp(1.0, double.infinity);

    if (macBasiGol1 > 1.8 && macBasiYedigiGol2 > 1.5) { yorumlar.add("$t1Name'ın golcü kimliği, $t2Name'ın savunma zaafları karşısında etkili olabilir."); }
    else if (macBasiGol1 > 1.5) { yorumlar.add("$t1Name'ın gol bulma potansiyeli yüksek."); }
    if (macBasiGol2 > 1.8 && macBasiYedigiGol1 > 1.5) { yorumlar.add("$t2Name'ın hücum gücü, $t1Name'ın savunma zaafları karşısında sonuç üretebilir."); }
    else if (macBasiGol2 > 1.5) { yorumlar.add("$t2Name'ın da skor üretmesi beklenebilir."); }

    final double csYuzde1 = (team1Stats['cleanSheetYuzdesi'] as num?)?.toDouble() ?? 0.0;
    final double csYuzde2 = (team2Stats['cleanSheetYuzdesi'] as num?)?.toDouble() ?? 0.0;

    if (csYuzde1 > 45 && macBasiGol2 < 1.0) { yorumlar.add("$t1Name'ın sağlam savunması, rakibine gol şansı tanımayabilir."); }
    if (csYuzde2 > 45 && macBasiGol1 < 1.0) { yorumlar.add("$t2Name'ın gol yememe potansiyeli dikkat çekici."); }
    
    final String defansOfansYorumu = yorumlar.isEmpty 
        ? "Takımların hücum ve savunma performansları istatistiksel olarak dengeli görünüyor."
        : "• ${yorumlar.join('\n\n• ')}";
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExpectationRow("Averaj ve Form Yorumu", handicapExpectation, Icons.trending_up),
          if(statsSettings.showAvgCorners) _buildExpectationRow("Korner Beklentileri", cornerExpectation, Icons.flag_circle_outlined),
          if(statsSettings.showAvgYellowCards) _buildExpectationRow("Kart Beklentileri", cardExpectation, Icons.style_outlined),
          if(statsSettings.showMaclardaOrtTplGol) _buildExpectationRow("Skor Aralığı ve KG Yorumu", scoreRangeExpectation, Icons.scoreboard_outlined),
          if(statsSettings.showCleanSheet && statsSettings.showMacBasiOrtGol) _buildExpectationRow("Defans & Ofans Yorumu", defansOfansYorumu.trim(), Icons.security_outlined),
          
          const Divider(height: 24, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("Bu veriler, yalnızca istatistiklerden yola çıkarak oluşturulmuş matematiksel çıkarımlardır ve kesinlik taşımaz.", style: theme.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant.withAlpha(204)), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}