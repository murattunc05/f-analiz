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
          icon: Icons.flag_outlined,
          label: 'Toplam Korner',
          value: '~${data['beklenenToplamKorner']?.toStringAsFixed(1) ?? 'N/A'}',
          progress: ((data['beklenenToplamKorner'] as num? ?? 0) / 15).clamp(0.0, 1.0), // 15 korneri max kabul edelim
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildExpectationRow(
          theme: theme,
          icon: Icons.style_outlined,
          label: 'Toplam Sarı Kart',
          value: '~${data['beklenenToplamSariKart']?.toStringAsFixed(1) ?? 'N/A'}',
          progress: ((data['beklenenToplamSariKart'] as num? ?? 0) / 7).clamp(0.0, 1.0), // 7 kartı max kabul edelim
          color: Colors.amber,
        ),
        const SizedBox(height: 12),
        _buildExpectationRow(
          theme: theme,
          icon: Icons.shield_outlined,
          label: 'Toplam Faul',
          value: '~${data['beklenenToplamFaul']?.toStringAsFixed(1) ?? 'N/A'}',
          progress: ((data['beklenenToplamFaul'] as num? ?? 0) / 30).clamp(0.0, 1.0), // 30 faulü max kabul edelim
          color: Colors.red,
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
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final animatedValue = _controller.value * progress;
                return Text(
                  '${(animatedValue * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              },
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
