import 'package:flutter/material.dart';

/// Puan durumu tablosu için modern ve estetik bir satır widget'ı.
///
/// Bu widget, bir takımın puan durumu bilgilerini (sıra, logo, isim, istatistikler)
/// düzenli ve okunabilir bir şekilde gösterir.
class ModernStandingsRow extends StatelessWidget {
  final Map<String, dynamic> standing;
  final int rank;

  const ModernStandingsRow({
    Key? key,
    required this.standing,
    required this.rank,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final team = standing['team'];
    final allStats = standing['all'];
    final points = standing['points'];
    final rankText = '$rank';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sıra
          SizedBox(
            width: 30,
            child: Text(
              rankText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          
          // Takım Logosu
          Image.network(
            team['logo'],
            height: 24,
            width: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield_outlined, size: 24),
          ),
          const SizedBox(width: 12),
          
          // Takım Adı
          Expanded(
            flex: 4,
            child: Text(
              team['name'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          
          // İstatistikler (O, G, B, M, P)
          _buildStatCell(context, allStats['played'].toString(), flex: 1),
          _buildStatCell(context, allStats['win'].toString(), flex: 1),
          _buildStatCell(context, allStats['draw'].toString(), flex: 1),
          _buildStatCell(context, allStats['lose'].toString(), flex: 1),
          _buildStatCell(context, points.toString(), flex: 1, isPoints: true),
        ],
      ),
    );
  }

  /// Tablodaki her bir istatistik hücresini oluşturan yardımcı metod.
  Widget _buildStatCell(BuildContext context, String value, {int flex = 1, bool isPoints = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isPoints ? FontWeight.bold : FontWeight.normal,
              color: isPoints ? Theme.of(context).colorScheme.primary : null,
            ),
      ),
    );
  }
}

/// Puan durumu tablosu için başlık satırı.
class StandingsHeader extends StatelessWidget {
  const StandingsHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 30, child: _HeaderCell(text: '#')),
          const SizedBox(width: 36), // Logo için boşluk
          const Expanded(flex: 4, child: _HeaderCell(text: 'Takım', alignment: TextAlign.left)),
          const Expanded(flex: 1, child: _HeaderCell(text: 'O')),
          const Expanded(flex: 1, child: _HeaderCell(text: 'G')),
          const Expanded(flex: 1, child: _HeaderCell(text: 'B')),
          const Expanded(flex: 1, child: _HeaderCell(text: 'M')),
          const Expanded(flex: 1, child: _HeaderCell(text: 'P')),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final TextAlign alignment;

  const _HeaderCell({
    Key? key,
    required this.text,
    this.alignment = TextAlign.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignment,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
    );
  }
}
