// lib/widgets/expandable_league_card.dart
import 'package:flutter/material.dart';

class ExpandableLeagueCard extends StatelessWidget {
  final Widget header;
  final Widget collapsedChild;
  final Widget expandedChild;
  final bool isExpanded;
  final VoidCallback onTapHeader;
  
  // YENİ: Düz renkler yerine gradyan renk listesi alacağız
  final List<Color> gradientColors;

  const ExpandableLeagueCard({
    super.key,
    required this.header,
    required this.collapsedChild,
    required this.expandedChild,
    required this.isExpanded,
    required this.onTapHeader,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      // DIŞ CONTAINER: Gradyan çerçeveyi oluşturur
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      // Çerçeve kalınlığını padding ile ayarlıyoruz
      child: Padding(
        padding: const EdgeInsets.all(1.5), 
        // İÇ CONTAINER: Beyaz kartın kendisi
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.cardColor, // Açık temada beyaz, koyu temada koyu
            borderRadius: BorderRadius.circular(15.0), // Dıştakinden biraz daha az
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onTapHeader,
                child: header,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                child: isExpanded ? expandedChild : collapsedChild,
              ),
            ],
          ),
        ),
      ),
    );
  }
}