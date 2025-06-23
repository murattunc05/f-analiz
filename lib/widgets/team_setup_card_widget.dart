// lib/widgets/team_setup_card_widget.dart
import 'package:flutter/material.dart';
import 'package:futbol_analiz_app/data_service.dart';
import 'package:futbol_analiz_app/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/logo_service.dart';
import '../services/team_name_service.dart';

class TeamSetupCardWidget extends StatelessWidget {
  final ThemeData theme;
  final String cardTitle;
  final String? selectedLeague;
  final String? selectedSeasonApiVal;
  final String currentTeamName;
  final String globalCurrentSeasonApiValue;
  final VoidCallback onLeagueSelectTap;
  final VoidCallback onTeamSelectTap;
  // DEĞİŞİKLİK: Bu callback artık nullable, yani isteğe bağlı ve 'required' değil.
  final VoidCallback? onSeasonIconTap;

  const TeamSetupCardWidget({
    super.key,
    required this.theme,
    required this.cardTitle,
    required this.selectedLeague,
    required this.selectedSeasonApiVal,
    required this.currentTeamName,
    required this.globalCurrentSeasonApiValue,
    required this.onLeagueSelectTap,
    required this.onTeamSelectTap,
    this.onSeasonIconTap, // required kelimesi kaldırıldı
  });

  String _getLeagueLogoAssetName(String leagueName) {
    String normalized = leagueName.toLowerCase().replaceAll(' - ', '_').replaceAll(' ', '_');
    const Map<String, String> charMap = { 'ı': 'i', 'ğ': 'g', 'ü': 'u', 'ş': 's', 'ö': 'o', 'ç': 'c', };
    charMap.forEach((tr, en) => normalized = normalized.replaceAll(tr, en));
    return 'assets/logos/leagues/${normalized.replaceAll(RegExp(r'[^\w_.-]'), '')}.png';
  }

  @override
  Widget build(BuildContext context) {
    final String seasonToDisplay = selectedSeasonApiVal ?? globalCurrentSeasonApiValue;
    String displaySeasonShort = DataService.getDisplaySeasonFromApiValue(seasonToDisplay)
        .split('/')
        .map((e) => e.length > 2 ? e.substring(2) : e)
        .join('/');
    
    if (seasonToDisplay == "2021") {
      displaySeasonShort = "20/21";
    }

    final bool isLeagueSelected = selectedLeague != null && selectedLeague!.isNotEmpty;
    final String leagueLogoAssetPath = isLeagueSelected ? _getLeagueLogoAssetName(selectedLeague!) : 'assets/logos/leagues/default_league_logo.png';

    final bool isTeamSelected = currentTeamName.isNotEmpty;
    String teamDisplayNameToShow = isTeamSelected ? TeamNameService.getCorrectedTeamName(currentTeamName) : 'Takım Seçin';
    
    String? teamLogoUrl;
    if (isTeamSelected && selectedLeague != null) {
      teamLogoUrl = LogoService.getTeamLogoUrl(currentTeamName, selectedLeague!);
    }
    const double logoSize = 24.0;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cardTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onLeagueSelectTap,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? theme.colorScheme.outline.withOpacity(0.5),
                          width: theme.inputDecorationTheme.enabledBorder?.borderSide.width ?? 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isLeagueSelected)
                            Image.asset(leagueLogoAssetPath, width: logoSize, height: logoSize, fit: BoxFit.contain, errorBuilder: (ctx, error, stackTrace) => Icon(Icons.shield_outlined, size: logoSize, color: theme.inputDecorationTheme.prefixIconColor ?? theme.colorScheme.primary.withOpacity(0.7)),)
                          else
                            Icon(Icons.shield_outlined, size: logoSize, color: theme.inputDecorationTheme.prefixIconColor ?? theme.colorScheme.primary.withOpacity(0.7)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text( !isLeagueSelected ? 'Lig Seçin' : capitalizeFirstLetterOfWordsUtils(selectedLeague!),
                              style: !isLeagueSelected ? theme.textTheme.bodyLarge?.copyWith(color: theme.inputDecorationTheme.hintStyle?.color) : theme.textTheme.bodyLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                // DEĞİŞİKLİK: Sezon butonu sadece callback null DEĞİLSE gösterilecek.
                if (onSeasonIconTap != null) ...[
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Sezon', style: theme.textTheme.labelSmall?.copyWith(fontSize: 12, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.9))),
                      SizedBox(width: 48, height: 48,
                        child: IconButton(
                          icon: const Icon(Icons.calendar_month_outlined, size: 24),
                          tooltip: 'Sezon Değiştir ($displaySeasonShort)',
                          color: theme.colorScheme.primary, padding: EdgeInsets.zero,
                          onPressed: onSeasonIconTap,
                        )),
                      Text(displaySeasonShort, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 12, color: theme.colorScheme.primary,)),
                    ],
                  )
                ]
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onTeamSelectTap,
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? theme.colorScheme.outline.withOpacity(0.5),
                    width: theme.inputDecorationTheme.enabledBorder?.borderSide.width ?? 1.0,
                  ),
                ),
                child: Row(children: [
                  if (isTeamSelected && teamLogoUrl != null)
                    CachedNetworkImage(
                      imageUrl: teamLogoUrl, width: logoSize, height: logoSize, fit: BoxFit.contain,
                      placeholder: (context, url) => SizedBox(width: logoSize, height: logoSize, child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: theme.colorScheme.primary.withOpacity(0.7),))),
                      errorWidget: (context, url, error) => Icon(Icons.shield_outlined, size: logoSize, color: theme.inputDecorationTheme.prefixIconColor ?? theme.colorScheme.primary.withOpacity(0.7)),
                    )
                  else
                    Icon(Icons.group_outlined, size: logoSize, color: theme.inputDecorationTheme.prefixIconColor ?? theme.colorScheme.primary.withOpacity(0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(teamDisplayNameToShow, style: !isTeamSelected ? theme.textTheme.bodyLarge?.copyWith(color: theme.inputDecorationTheme.hintStyle?.color) : theme.textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis, maxLines: 1,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey)
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}