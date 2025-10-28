import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatisticalExpectationsCard extends StatefulWidget {
  final AsyncValue<Map<String, dynamic>> expectations;

  const StatisticalExpectationsCard({
    super.key,
    required this.expectations,
  });

  @override
  State<StatisticalExpectationsCard> createState() => _StatisticalExpectationsCardState();
}

class _StatisticalExpectationsCardState extends State<StatisticalExpectationsCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  void startAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Yardımcı fonksiyon: Tam sayı olmayan değerlere ~ sembolü ekler
  String _formatNumericValue(dynamic value) {
    if (value == null) return 'N/A';
    
    final double doubleValue = (value as num).toDouble();
    final int roundedValue = doubleValue.round();
    
    // Eğer orijinal değer tam sayıya eşitse ~ sembolü ekleme
    if (doubleValue == roundedValue.toDouble()) {
      return roundedValue.toString();
    } else {
      // Tam sayı değilse ~ sembolü ekle
      return '~$roundedValue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildCardContent(context);
  }

  Widget _buildCardContent(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_outlined, color: theme.colorScheme.secondary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'İstatistiksel Beklentiler',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Divider(color: theme.colorScheme.secondary.withOpacity(0.2)),
            const SizedBox(height: 8),
            widget.expectations.when(
              data: (data) => AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: _buildExpectationsContent(context, data),
                    ),
                  );
                },
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Beklentiler oluşturuluyor...'),
                    ],
                  ),
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Beklentiler oluşturulurken bir hata oluştu: $error',
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectationsContent(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final winner = data['kazanan'] as String?;

    return Column(
      children: [
        if (winner != null) ...[
          _buildWinnerRow(theme, winner),
          const SizedBox(height: 16),
          Divider(color: theme.colorScheme.secondary.withOpacity(0.1)),
          const SizedBox(height: 16),
        ],
        _buildExpectationRow(
          theme: theme,
          icon: Icons.sports_soccer_outlined,
          label: 'Toplam Gol (2.5 Üstü)',
          value: '${data['gol2PlusOlasilik'] ?? 'N/A'}%',
          progress: (data['gol2PlusOlasilik'] as num? ?? 0) / 100,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildExpectationRow(
          theme: theme,
          icon: Icons.swap_horiz_outlined,
          label: 'Karşılıklı Gol (KG Var)',
          value: '${data['kgVarYuzdesi'] ?? 'N/A'}%',
          progress: (data['kgVarYuzdesi'] as num? ?? 0) / 100,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildExpectationRow(
          theme: theme,
          icon: Icons.sports_soccer_outlined,
          label: 'Beklenen Toplam Gol',
          value: _formatNumericValue(data['beklenenToplamGol']),
          progress: ((data['beklenenToplamGol'] as num? ?? 0) / 5).clamp(0.0, 1.0),
          color: Colors.purple,
          isNumeric: true,
        ),
        const SizedBox(height: 12),
        _buildExpectationRow(
          theme: theme,
          icon: Icons.sports_outlined,
          label: 'İY Beklenen Gol',
          value: _formatNumericValue(data['beklenenIyToplamGol']),
          progress: ((data['beklenenIyToplamGol'] as num? ?? 0) / 3).clamp(0.0, 1.0),
          color: Colors.indigo,
          isNumeric: true,
        ),
        const SizedBox(height: 12),
        _buildExpectationRow(
          theme: theme,
          icon: Icons.flag_outlined,
          label: 'Toplam Korner',
          value: _formatNumericValue(data['beklenenToplamKorner']),
          progress: ((data['beklenenToplamKorner'] as num? ?? 0) / 15).clamp(0.0, 1.0),
          color: Colors.orange,
          isNumeric: true,
        ),
        const SizedBox(height: 12),
        _buildExpectationRow(
          theme: theme,
          icon: Icons.sports_basketball_outlined,
          label: 'Toplam Şut',
          value: _formatNumericValue(data['beklenenToplamSut']),
          progress: ((data['beklenenToplamSut'] as num? ?? 0) / 25).clamp(0.0, 1.0),
          color: Colors.teal,
          isNumeric: true,
        ),
        const SizedBox(height: 12),
        _buildExpectationRow(
          theme: theme,
          icon: Icons.gps_fixed_outlined,
          label: 'Toplam İsabetli Şut',
          value: _formatNumericValue(data['beklenenToplamIsabetliSut']),
          progress: ((data['beklenenToplamIsabetliSut'] as num? ?? 0) / 12).clamp(0.0, 1.0),
          color: Colors.cyan,
          isNumeric: true,
        ),
        const SizedBox(height: 12),
        _buildExpectationRow(
          theme: theme,
          icon: Icons.shield_outlined,
          label: 'Toplam Faul',
          value: _formatNumericValue(data['beklenenToplamFaul']),
          progress: ((data['beklenenToplamFaul'] as num? ?? 0) / 30).clamp(0.0, 1.0),
          color: Colors.red,
          isNumeric: true,
        ),
        const SizedBox(height: 12),
        _buildExpectationRow(
          theme: theme,
          icon: Icons.style_outlined,
          label: 'Toplam Sarı Kart',
          value: _formatNumericValue(data['beklenenToplamSariKart']),
          progress: ((data['beklenenToplamSariKart'] as num? ?? 0) / 7).clamp(0.0, 1.0),
          color: Colors.amber,
          isNumeric: true,
        ),
        const SizedBox(height: 16),
        // Açıklama metni
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            'Bu beklentiler yalnızca istatistiklerden oluşturulmuş ortalama değerlerdir. Kesinlik taşımaz ve takım kaliteleri göz önüne alınmamıştır.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerRow(ThemeData theme, String winner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Beklenen Kazanan',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, color: Colors.amber[700], size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                winner,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpectationRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required double progress,
    required Color color,
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _controller.value * progress,
                backgroundColor: color.withOpacity(0.2),
                color: color,
                minHeight: 6,
              ),
            );
          },
        ),
      ],
    );
  }
}
