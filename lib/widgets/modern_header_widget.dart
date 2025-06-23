import 'package:flutter/material.dart';

class ModernHeaderWidget extends StatelessWidget {
  final VoidCallback onSettingsTap;
  final VoidCallback onSearchTap;

  const ModernHeaderWidget({
    super.key,
    required this.onSettingsTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 26,
      color: theme.colorScheme.onSurface,
    );
    final iconColor = theme.colorScheme.onSurface.withOpacity(0.7);
    final circularButtonBgColor = theme.cardColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ayarlar Butonu
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: circularButtonBgColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
            child: IconButton(
              icon: Icon(Icons.settings_outlined, color: iconColor, size: 24),
              onPressed: onSettingsTap,
              tooltip: 'Ayarlar',
            ),
          ),

          const Spacer(), // İkonu sola yaslar

          // Başlık
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('G', style: titleStyle),
              // DEĞİŞİKLİK: Top ikonunun boyutu ve dikey hizalaması ayarlandı
              Transform.translate(
                offset: const Offset(0, 2.0), // Dikeyde hafif aşağı kaydırma
                child: Icon(
                  Icons.sports_soccer,
                  color: theme.colorScheme.primary,
                  size: titleStyle!.fontSize! * 0.8, // 'a' harfi boyutuna yakın
                ),
              ),
              Text('alitycs', style: titleStyle),
            ],
          ),

          const Spacer(), // İkonu sağa yaslar

          // Arama Butonu
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: circularButtonBgColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
            child: IconButton(
              icon: Icon(Icons.search, color: iconColor, size: 24),
              onPressed: onSearchTap,
              tooltip: 'Takım Ara',
            ),
          ),
        ],
      ),
    );
  }
}