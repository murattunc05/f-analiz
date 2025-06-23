// lib/widgets/profile_stats_tab.dart
import 'package:flutter/material.dart';

class ProfileStatsTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  const ProfileStatsTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if ((stats['oynananMacSayisi'] as num?)?.toInt() == 0) {
      return const Center(child: Text("Bu filtre için istatistik verisi yok."));
    }

    // Gösterilecek istatistikleri ve ikonlarını tanımla
    final List<Map<String, dynamic>> statItems = [
      {'label': 'Maç Başına Ort. Gol', 'key': 'macBasiOrtalamaGol', 'icon': Icons.score_outlined},
      {'label': 'Maçlarda Ort. Toplam Gol', 'key': 'maclardaOrtalamaToplamGol', 'icon': Icons.public_outlined},
      {'label': 'KG Var Yüzdesi', 'key': 'kgVarYuzdesi', 'icon': Icons.checklist_rtl_outlined, 'suffix': '%'},
      {'label': 'Clean Sheet Yüzdesi', 'key': 'cleanSheetYuzdesi', 'icon': Icons.shield_outlined, 'suffix': '%'},
      {'label': 'Ortalama Şut', 'key': 'ortalamaSut', 'icon': Icons.radar_outlined},
      {'label': 'Ortalama İsabetli Şut', 'key': 'ortalamaIsabetliSut', 'icon': Icons.gps_fixed},
      {'label': 'Ortalama Korner', 'key': 'ortalamaKorner', 'icon': Icons.flag_circle_outlined},
      {'label': 'Ortalama Faul', 'key': 'ortalamaFaul', 'icon': Icons.sports_kabaddi_outlined},
      {'label': 'Ortalama Sarı Kart', 'key': 'ortalamaSariKart', 'icon': Icons.style_outlined},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: statItems.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = statItems[index];
        final value = stats[item['key']];

        if (value == null) return const SizedBox.shrink(); // Veri yoksa gösterme

        return ListTile(
          leading: Icon(item['icon'], color: theme.colorScheme.primary),
          title: Text(item['label']),
          trailing: Text(
            "${value.toString()}${item['suffix'] ?? ''}",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}