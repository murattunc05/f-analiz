// lib/widgets/stat_comparison_row.dart
import 'package:flutter/material.dart';

class StatComparisonRowWidget extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String homeValue;
  final String awayValue;
  // DEĞİŞİKLİK: 'icon' parametresi kaldırıldı.
  final bool higherIsBetter;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const StatComparisonRowWidget({
    super.key,
    required this.theme,
    required this.label,
    required this.homeValue,
    required this.awayValue,
    this.higherIsBetter = true,
    this.labelStyle,
    this.valueStyle,
  });

  Color _getValueColor(String val, String otherVal) {
    final defaultColor = valueStyle?.color ?? theme.textTheme.bodyMedium!.color!;
    if (val == '-' || otherVal == '-') return defaultColor;

    double? numVal = double.tryParse(val.replaceAll('%', '').trim());
    double? numOtherVal = double.tryParse(otherVal.replaceAll('%', '').trim());

    if (numVal == null || numOtherVal == null) return defaultColor;
    
    if (numVal == numOtherVal) return defaultColor;

    bool isBetter;
    if (higherIsBetter) {
      isBetter = numVal > numOtherVal;
    } else {
      isBetter = numVal < numOtherVal;
    }

    return isBetter ? theme.colorScheme.primary : defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    Color currentHomeColor = _getValueColor(homeValue, awayValue);
    Color currentAwayColor = _getValueColor(awayValue, homeValue);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        children: <Widget>[
          // Sol Değer
          Expanded(
            flex: 2,
            child: Text(
              (homeValue == 'null' || homeValue.isEmpty) ? '-' : homeValue,
              textAlign: TextAlign.center,
              style: valueStyle ?? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: currentHomeColor),
            ),
          ),
          // Orta Etiket
          Expanded(
            flex: 3,
            // DEĞİŞİKLİK: Ortadaki Row ve Icon kaldırıldı, sadece Text bırakıldı.
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: labelStyle ?? theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          // Sağ Değer
          Expanded(
            flex: 2,
            child: Text(
              (awayValue == 'null' || awayValue.isEmpty) ? '-' : awayValue,
              textAlign: TextAlign.center,
              style: valueStyle ?? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: currentAwayColor),
            ),
          ),
        ],
      ),
    );
  }
}