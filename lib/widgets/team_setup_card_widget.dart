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
    this.onSeasonIconTap,
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
    const double logoSize = 28.0;

    // Takım numarasını başlıktan çıkar
    final bool isTeam1 = cardTitle.contains('1.');
    final teamNumber = isTeam1 ? '1' : '2';
    final teamColor = isTeam1 ? theme.colorScheme.primary : theme.colorScheme.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sade başlık alanı
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: teamColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      teamNumber,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$teamNumber. Takım Ayarları',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Lig, takım ve sezon seçimi',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLeagueSelected && isTeamSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'HAZIR',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AYARLA',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // İçerik alanı
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Lig seçimi
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.public,
                              size: 16,
                              color: teamColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Lig Seçimi',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: onLeagueSelectTap,
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: isLeagueSelected 
                                        ? teamColor.withOpacity(0.4)
                                        : theme.colorScheme.outline.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isLeagueSelected 
                                            ? teamColor.withOpacity(0.1)
                                            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: isLeagueSelected
                                          ? Image.asset(
                                              leagueLogoAssetPath, 
                                              width: logoSize, 
                                              height: logoSize, 
                                              fit: BoxFit.contain,
                                              errorBuilder: (ctx, error, stackTrace) => Icon(
                                                Icons.shield_outlined, 
                                                size: logoSize, 
                                                color: teamColor
                                              ),
                                            )
                                          : Icon(
                                              Icons.shield_outlined, 
                                              size: logoSize, 
                                              color: theme.colorScheme.onSurfaceVariant
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            !isLeagueSelected ? 'Lig Seçin' : capitalizeFirstLetterOfWordsUtils(selectedLeague!),
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isLeagueSelected 
                                                  ? theme.colorScheme.onSurface
                                                  : theme.colorScheme.onSurfaceVariant,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (isLeagueSelected)
                                            Text(
                                              'Seçili lig',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: teamColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Sezon seçimi
                          if (onSeasonIconTap != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: teamColor.withOpacity(0.3),
                                ),
                              ),
                              child: InkWell(
                                onTap: onSeasonIconTap,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        color: teamColor,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        displaySeasonShort,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: teamColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Takım seçimi
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.groups,
                            size: 16,
                            color: teamColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Takım Seçimi',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: onTeamSelectTap,
                      borderRadius: BorderRadius.circular(12.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: isTeamSelected 
                                ? teamColor.withOpacity(0.4)
                                : theme.colorScheme.outline.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isTeamSelected 
                                    ? teamColor.withOpacity(0.1)
                                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: isTeamSelected && teamLogoUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: teamLogoUrl, 
                                      width: logoSize, 
                                      height: logoSize, 
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => SizedBox(
                                        width: logoSize, 
                                        height: logoSize, 
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2, 
                                            color: teamColor,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Icon(
                                        Icons.shield_outlined, 
                                        size: logoSize, 
                                        color: teamColor
                                      ),
                                    )
                                  : Icon(
                                      Icons.group_outlined, 
                                      size: logoSize, 
                                      color: isTeamSelected 
                                          ? teamColor
                                          : theme.colorScheme.onSurfaceVariant
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    teamDisplayNameToShow,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isTeamSelected 
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  if (isTeamSelected)
                                    Text(
                                      'Seçili takım',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: teamColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}