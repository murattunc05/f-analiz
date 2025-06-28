// lib/widgets/ai_loading_indicator.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AiLoadingIndicator extends StatefulWidget {
  const AiLoadingIndicator({super.key});

  @override
  State<AiLoadingIndicator> createState() => _AiLoadingIndicatorState();
}

class _AiLoadingIndicatorState extends State<AiLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 60,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, 60),
                      painter: _AiWavePainter(
                        animationValue: _controller.value,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Yapay zeka analizi hazırlanıyor...",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _AiWavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final waveHeight = size.height / 3;
    final waveLength = size.width;

    path.moveTo(0, size.height / 2);

    for (double i = 0.0; i <= waveLength; i++) {
      final x = i;
      final y = size.height / 2 +
          waveHeight * math.sin((i / waveLength) * 2 * math.pi + (animationValue * 2 * math.pi));
      path.lineTo(x, y);
    }
    
    final paint2 = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path2 = Path();
    path2.moveTo(0, size.height / 2);

    for (double i = 0.0; i <= waveLength; i++) {
      final x = i;
      final y = size.height / 2 +
          waveHeight * 1.2 * math.sin((i / waveLength) * 2.5 * math.pi - (animationValue * 2.2 * math.pi));
      path2.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
