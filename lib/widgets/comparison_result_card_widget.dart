// lib/widgets/comparison_result_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:futbol_analiz_app/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:futbol_analiz_app/services/logo_service.dart';

class ComparisonResultCardWidget extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic> comparisonResult;
  final Map<String, dynamic>? team1Stats;
  final Map<String, dynamic>? team2Stats;
  final StatsDisplaySettings statsSettings;
  final int numberOfMatchesToCompare;
  final VoidCallback onFullComparisonTap;

  const ComparisonResultCardWidget({
    super.key,
    required this.theme,
    required this.comparisonResult,
    this.team1Stats,
    this.team2Stats,
    required this.statsSettings,
    required this.numberOfMatchesToCompare,
    required this.onFullComparisonTap,
  });

  String _getBettingStyleComment(double? value, String type) {
    if (value == null || value <= 0) return "Veri Yok";
    double threshold;
    switch (type) {
      case 'goal': threshold = 2.5; break;
      case 'iy_goal': threshold = 0.5; break;
      case 'corner': threshold = 9.5; break;
      case 'shot': threshold = 24.5; break;
      case 'shotOnTarget': threshold = 8.5; break;
      case 'card': threshold = 3.5; break;
      case 'redCard': threshold = 0.5; break;
      default: return "Veri Yok";
    }
    if (value > threshold + (type == 'redCard' ? 0.2 : 0.5)) return "$threshold Üst";
    if (value < threshold - (type == 'redCard' ? 0.2 : 0.5)) return "$threshold Alt";
    return "$threshold Bareminde";
  }

  // --- HİZALAMA SORUNUNU GİDEREN YENİ WIDGET YAPISI ---
  Widget _buildSingleInfoRow(String label, {required Widget valueWidget, IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Satırlar arası boşluk
      child: IntrinsicHeight( // Row içindeki widget'ların aynı yüksekliğe sahip olmasını sağlar
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // İkon Sütunu (Sabit Genişlik)
            SizedBox(
              width: 40,
              child: icon != null 
                ? Icon(icon, size: 22.0, color: iconColor ?? theme.colorScheme.onSurfaceVariant)
                : const SizedBox.shrink(),
            ),
            // Etiket Sütunu (Esnek)
            Expanded(
              flex: 5, // Etiket için daha fazla alan
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            // Değer Sütunu (Esnek)
            Expanded(
              flex: 4, // Değer için biraz daha az alan
              child: Align(
                alignment: Alignment.centerRight,
                child: valueWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // ... build metodunun başındaki değişken tanımlamaları aynı ...
    final String winnerDisplayName = comparisonResult["kazanan"]?.toString() ?? "Bilinmiyor";
    final String? winnerOriginalName = comparisonResult["kazananOriginalName"] as String?;
    String? leagueName;
    if (winnerOriginalName != null) {
      if (team1Stats?['takim'] == winnerOriginalName) { leagueName = team1Stats?['leagueNameForLogo']; } 
      else { leagueName = team2Stats?['leagueNameForLogo']; }
    }
    final String? winnerLogoUrl = (winnerOriginalName != null && leagueName != null) ? LogoService.getTeamLogoUrl(winnerOriginalName, leagueName) : null;
    final String formPrediction = comparisonResult["formYorumu"] ?? "Form yorumu için yeterli veri yok.";
    final bool hasFormPrediction = formPrediction.isNotEmpty && formPrediction != "Formlar yakın, dengeli bir maç olabilir.";

    final double? totalGoal = comparisonResult["beklenenToplamGol"];
    final double? kgVarPercent = comparisonResult["kgVarYuzdesi"];
    final double? iyTotalGoal = comparisonResult["beklenenIyToplamGol"];
    final double? totalCorner = comparisonResult["beklenenToplamKorner"];
    final double? totalShot = comparisonResult["beklenenToplamSut"];
    final double? totalShotOnTarget = comparisonResult["beklenenToplamIsabetliSut"];
    final double? totalCard = comparisonResult["beklenenToplamSariKart"];
    final double? totalRedCard = comparisonResult["beklenenToplamKirmiziKart"];

    List<Widget> expectationWidgets = [
      if (statsSettings.showMaclardaOrtTplGol)
        _buildSingleInfoRow("Toplam Gol", icon: Icons.sports_soccer_outlined, valueWidget: Text("${_getBettingStyleComment(totalGoal, 'goal')} ($totalGoal)", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
      if (statsSettings.showGol2UstuOlasilik)
         _buildSingleInfoRow("2+ Gol Olasılığı", icon: Icons.percent_outlined, valueWidget: Text(comparisonResult["gol2PlusOlasilik"] != null ? '%${comparisonResult["gol2PlusOlasilik"]}' : 'N/A', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
      if (statsSettings.showComparisonKgVar)
        _buildSingleInfoRow("KG VAR İhtimali", icon: Icons.sync_alt_outlined, valueWidget: Text(kgVarPercent != null ? "%${kgVarPercent.toStringAsFixed(1)}" : "Veri Yok", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
      if (statsSettings.showIyGolOrt)
        _buildSingleInfoRow("İY Toplam Gol", icon: Icons.hourglass_top_outlined, valueWidget: Text("${_getBettingStyleComment(iyTotalGoal, 'iy_goal')} ($iyTotalGoal)", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
      if (statsSettings.showAvgShots)
        _buildSingleInfoRow("Toplam Şut", icon: Icons.radar_outlined, valueWidget: Text("${_getBettingStyleComment(totalShot, 'shot')} ($totalShot)", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
      if (statsSettings.showAvgShotsOnTarget)
        _buildSingleInfoRow("Toplam İsabetli Şut", icon: Icons.gps_fixed, valueWidget: Text("${_getBettingStyleComment(totalShotOnTarget, 'shotOnTarget')} ($totalShotOnTarget)", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
      if (statsSettings.showAvgCorners)
        _buildSingleInfoRow("Toplam Korner", icon: Icons.flag_circle_outlined, valueWidget: Text("${_getBettingStyleComment(totalCorner, 'corner')} ($totalCorner)", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
      if (statsSettings.showAvgYellowCards)
        _buildSingleInfoRow("Toplam Sarı Kart", icon: Icons.style_outlined, valueWidget: Text("${_getBettingStyleComment(totalCard, 'card')} ($totalCard)", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
      if (statsSettings.showAvgRedCards)
        _buildSingleInfoRow("Toplam Kırmızı Kart", icon: Icons.style, valueWidget: Text("${_getBettingStyleComment(totalRedCard, 'redCard')} ($totalRedCard)", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
    ];
    
    expectationWidgets.removeWhere((widget) => widget is! Padding);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () { HapticFeedback.lightImpact(); onFullComparisonTap(); },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.military_tech_outlined, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text('Karşılaştırma Sonuçları (Son $numberOfMatchesToCompare Maç):', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary), overflow: TextOverflow.ellipsis, maxLines: 2))
              ]),
              const Divider(height: 20, thickness: 0.5),
              _buildSingleInfoRow("Olası Kazanan", icon: Icons.emoji_events_outlined, iconColor: Colors.amber.shade700, valueWidget: Row( mainAxisAlignment: MainAxisAlignment.end, children: [
                if(winnerLogoUrl != null) Padding(padding: const EdgeInsets.only(right: 8.0), child: CachedNetworkImage(imageUrl: winnerLogoUrl, width: 20, height: 20, fit: BoxFit.contain)),
                Flexible(child: Text(winnerDisplayName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.end))])),
              _buildSingleInfoRow("Form Yorumu", icon: Icons.comment_outlined, iconColor: theme.colorScheme.tertiary.withAlpha(204), valueWidget: Text(formPrediction, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: hasFormPrediction ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.end)),

              const SizedBox(height: 8),
              Text("Maç Geneli Beklentileri:", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 15, thickness: 0.3),
              
              ...expectationWidgets,

              if (expectationWidgets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Beklentiler ayarlardan gizlendi.", style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)),
                ),

              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.2),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Center(
                  child: Text("Daha detaylı beklentiler ve yorumlar için dokunun.", style: theme.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant.withAlpha(191)), textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}