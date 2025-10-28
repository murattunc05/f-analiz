// lib/widgets/profile_matches_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/team_name_service.dart';
import '../services/logo_service.dart';
import '../design_system/widgets/modern_match_card.dart';
import '../design_system/widgets/modern_card.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../utils/dialog_utils.dart';
import '../team_profile_screen.dart';

class ProfileMatchesTab extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  final String teamName;
  final String leagueName;
  final String currentSeasonApiValue;
  final dynamic filterType; // TeamStatFilter tipini import etmek yerine dynamic kullanıyoruz

  const ProfileMatchesTab({
    super.key,
    required this.matches,
    required this.teamName,
    required this.leagueName,
    required this.currentSeasonApiValue,
    this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (matches.isEmpty) {
      return Center(
        child: ModernCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_soccer_outlined,
                size: 48,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Gösterilecek maç bulunmuyor",
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Maçları tarihe göre sırala (en yeni en üstte)
    final sortedMatches = List<Map<String, dynamic>>.from(matches);
    sortedMatches.sort((a, b) {
      try {
        return (b['_parsedDate'] as DateTime).compareTo(a['_parsedDate'] as DateTime);
      } catch (e) {
        return 0;
      }
    });

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sortedMatches.length,
      itemBuilder: (context, index) {
        return _ModernMatchResultCard(
          match: sortedMatches[index], 
          teamName: teamName,
          leagueName: leagueName,
          currentSeasonApiValue: currentSeasonApiValue,
        );
      },
    );
  }
}

class _ModernMatchResultCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final String teamName;
  final String leagueName;
  final String currentSeasonApiValue;

  const _ModernMatchResultCard({
    required this.match,
    required this.teamName,
    required this.leagueName,
    required this.currentSeasonApiValue,
  });

  // Takım adından lig bilgisini çıkarmaya çalışan yardımcı metod
  String _getLeagueFromTeamName(String teamName) {
    // Basit bir yaklaşım - takım adına göre lig tahmin etme
    // Bu metod LogoService'in daha iyi çalışması için gerekli
    
    // Türk takımları
    final turkishTeams = [
      'Galatasaray', 'Fenerbahce', 'Besiktas', 'Trabzonspor', 'Basaksehir',
      'Antalyaspor', 'Kayserispor', 'Konyaspor', 'Sivasspor', 'Gaziantep FK',
      'Alanyaspor', 'Hatayspor', 'Kasimpasa', 'Rizespor', 'Adana Demirspor',
      'Fatih Karagumruk', 'Giresunspor', 'Istanbulspor', 'Umraniyespor'
    ];
    
    // İngiliz takımları
    final englishTeams = [
      'Arsenal', 'Chelsea', 'Liverpool', 'Man City', 'Man United', 'Tottenham',
      'Newcastle', 'Brighton', 'Aston Villa', 'West Ham', 'Crystal Palace',
      'Fulham', 'Wolves', 'Everton', 'Brentford', 'Nottm Forest', 'Luton',
      'Burnley', 'Sheffield Utd', 'Bournemouth'
    ];
    
    // İspanyol takımları
    final spanishTeams = [
      'Real Madrid', 'Barcelona', 'Atletico Madrid', 'Sevilla', 'Real Sociedad',
      'Betis', 'Villarreal', 'Valencia', 'Athletic Bilbao', 'Osasuna',
      'Getafe', 'Las Palmas', 'Girona', 'Alaves', 'Mallorca', 'Rayo Vallecano',
      'Celta Vigo', 'Cadiz', 'Granada', 'Almeria'
    ];
    
    // Alman takımları
    final germanTeams = [
      'Bayern Munich', 'Dortmund', 'RB Leipzig', 'Union Berlin', 'Freiburg',
      'Bayer Leverkusen', 'Eintracht Frankfurt', 'Wolfsburg', 'Mainz',
      'Borussia Monchengladbach', 'Koln', 'Augsburg', 'Stuttgart',
      'Hoffenheim', 'Werder Bremen', 'Bochum', 'Heidenheim', 'Darmstadt'
    ];
    
    // İtalyan takımları
    final italianTeams = [
      'Juventus', 'Inter', 'AC Milan', 'Napoli', 'Roma', 'Lazio',
      'Atalanta', 'Fiorentina', 'Bologna', 'Torino', 'Monza', 'Genoa',
      'Lecce', 'Udinese', 'Frosinone', 'Empoli', 'Verona', 'Cagliari',
      'Sassuolo', 'Salernitana'
    ];
    
    // Fransız takımları
    final frenchTeams = [
      'PSG', 'Monaco', 'Lille', 'Nice', 'Rennes', 'Lyon', 'Marseille',
      'Montpellier', 'Strasbourg', 'Lens', 'Nantes', 'Toulouse', 'Lorient',
      'Le Havre', 'Metz', 'Reims', 'Brest', 'Clermont'
    ];
    
    if (turkishTeams.any((team) => teamName.contains(team) || team.contains(teamName))) {
      return 'Türkiye - Süper Lig';
    } else if (englishTeams.any((team) => teamName.contains(team) || team.contains(teamName))) {
      return 'İngiltere - Premier Lig';
    } else if (spanishTeams.any((team) => teamName.contains(team) || team.contains(teamName))) {
      return 'İspanya - La Liga';
    } else if (germanTeams.any((team) => teamName.contains(team) || team.contains(teamName))) {
      return 'Almanya - Bundesliga';
    } else if (italianTeams.any((team) => teamName.contains(team) || team.contains(teamName))) {
      return 'İtalya - Serie A';
    } else if (frenchTeams.any((team) => teamName.contains(team) || team.contains(teamName))) {
      return 'Fransa - Ligue 1';
    }
    
    // Eğer hiçbiri eşleşmezse boş string döndür
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final homeTeam = match['HomeTeam'] as String;
    final awayTeam = match['AwayTeam'] as String;
    final homeGoals = match['FTHG'];
    final awayGoals = match['FTAG'];
    final result = match['FTR'] as String;
    final date = match['Date'] as String;
    
    final bool isHomeTeam = homeTeam == teamName;
    final bool isWin = (isHomeTeam && result == 'H') || (!isHomeTeam && result == 'A');
    final bool isDraw = result == 'D';
    final bool isLoss = !isWin && !isDraw;
    
    // Sonuca göre renk ve ikon belirleme
    Color resultColor;
    Color borderColor;
    IconData resultIcon;
    String resultText;
    
    if (isWin) {
      resultColor = AppColors.success;
      borderColor = AppColors.success.withOpacity(0.3);
      resultIcon = Icons.emoji_events;
      resultText = "GALİBİYET";
    } else if (isDraw) {
      resultColor = AppColors.warning;
      borderColor = AppColors.warning.withOpacity(0.3);
      resultIcon = Icons.handshake;
      resultText = "BERABERLİK";
    } else {
      resultColor = AppColors.error;
      borderColor = AppColors.error.withOpacity(0.3);
      resultIcon = Icons.sentiment_dissatisfied;
      resultText = "MAĞLUBİYET";
    }

    // Takım logolarını al - önce mevcut lig ile dene, sonra tahmin edilen lig ile
    String? homeTeamLogo = LogoService.getTeamLogoUrl(homeTeam, leagueName) ?? 
                          LogoService.getTeamLogoUrl(homeTeam, _getLeagueFromTeamName(homeTeam));
    String? awayTeamLogo = LogoService.getTeamLogoUrl(awayTeam, leagueName) ?? 
                          LogoService.getTeamLogoUrl(awayTeam, _getLeagueFromTeamName(awayTeam));

    return GestureDetector(
      onTap: () => _showMatchDetailsPopup(context, match, leagueName, currentSeasonApiValue),
      child: ModernCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        hasBorder: true,
        borderColor: borderColor,
        child: Column(
        children: [
          // Sonuç durumu header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLg),
                topRight: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  resultIcon,
                  color: resultColor,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  resultText,
                  style: AppTypography.labelMedium.copyWith(
                    color: resultColor,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          
          // Maç detayları
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                // Ev sahibi takım
                Expanded(
                  child: Column(
                    children: [
                      homeTeamLogo != null
                        ? CachedNetworkImage(
                            imageUrl: homeTeamLogo,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) => Icon(
                              Icons.shield_outlined,
                              size: 40,
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                            ),
                          )
                        : Icon(
                            Icons.shield_outlined,
                            size: 40,
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                          ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        TeamNameService.getCorrectedTeamName(homeTeam),
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: isHomeTeam ? AppTypography.bold : AppTypography.medium,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isHomeTeam) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                          ),
                          child: Text(
                            "İÇ SAHA",
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: AppTypography.bold,
                              fontSize: 10, // Font boyutu küçültüldü
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Skor bölümü
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: resultColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Text(
                              homeGoals.toString(),
                              style: AppTypography.displaySmall.copyWith(
                                color: resultColor,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            "-",
                            style: AppTypography.titleLarge.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: resultColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Text(
                              awayGoals.toString(),
                              style: AppTypography.displaySmall.copyWith(
                                color: resultColor,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: resultColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                        ),
                        child: Text(
                          "NORMAL SÜRE",
                          style: AppTypography.labelSmall.copyWith(
                            color: resultColor,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Deplasman takımı
                Expanded(
                  child: Column(
                    children: [
                      awayTeamLogo != null
                        ? CachedNetworkImage(
                            imageUrl: awayTeamLogo,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) => Icon(
                              Icons.shield_outlined,
                              size: 40,
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                            ),
                          )
                        : Icon(
                            Icons.shield_outlined,
                            size: 40,
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                          ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        TeamNameService.getCorrectedTeamName(awayTeam),
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: !isHomeTeam ? AppTypography.bold : AppTypography.medium,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isHomeTeam) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                          ),
                          child: Text(
                            "DEPLASMAN",
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: AppTypography.bold,
                              fontSize: 10, // Font boyutu küçültüldü
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showMatchDetailsPopup(BuildContext context, Map<String, dynamic> matchData, String leagueName, String currentSeasonApiValue) {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    String originalHomeTeam = matchData['HomeTeam']?.toString() ?? 'Ev Sahibi';
    String originalAwayTeam = matchData['AwayTeam']?.toString() ?? 'Deplasman';
    String homeTeamDisplay = TeamNameService.getCorrectedTeamName(originalHomeTeam);
    String awayTeamDisplay = TeamNameService.getCorrectedTeamName(originalAwayTeam);
    String ftHomeGoals = matchData['FTHG']?.toString() ?? '?';
    String ftAwayGoals = matchData['FTAG']?.toString() ?? '?';
    String? htHomeGoals = matchData['HTHG']?.toString();
    String? htAwayGoals = matchData['HTAG']?.toString();
    String date = matchData['Date']?.toString() ?? 'Bilinmiyor';

    String? homeLogoUrl = LogoService.getTeamLogoUrl(originalHomeTeam, leagueName) ?? 
                          LogoService.getTeamLogoUrl(originalHomeTeam, _getLeagueFromTeamName(originalHomeTeam));
    String? awayLogoUrl = LogoService.getTeamLogoUrl(originalAwayTeam, leagueName) ?? 
                          LogoService.getTeamLogoUrl(originalAwayTeam, _getLeagueFromTeamName(originalAwayTeam));
    const double logoSize = 64.0;

    String halfTimeScoreInfo = "";
    if (htHomeGoals != null && htHomeGoals.isNotEmpty && htHomeGoals.isNotEmpty && htAwayGoals != null && htAwayGoals.isNotEmpty) {
      halfTimeScoreInfo = "(İY: $htHomeGoals-$htAwayGoals)";
    }

    Map<String, List<String>> statsToDisplay = {
      "Toplam Şut": [matchData['HS']?.toString() ?? '', matchData['AS']?.toString() ?? ''], 
      "İsabetli Şut": [matchData['HST']?.toString() ?? '', matchData['AST']?.toString() ?? ''],
      "Korner": [matchData['HC']?.toString() ?? '', matchData['AC']?.toString() ?? ''], 
      "Faul": [matchData['HF']?.toString() ?? '', matchData['AF']?.toString() ?? ''],
      "Sarı Kart": [matchData['HY']?.toString() ?? '', matchData['AY']?.toString() ?? ''], 
      "Kırmızı Kart": [matchData['HR']?.toString() ?? '', matchData['AR']?.toString() ?? ''],
    };

    Map<String, List<String>> availableStats = {};
    statsToDisplay.forEach((key, values) {
      if ((values[0].isNotEmpty && values[0] != 'null' && values[0] != 'NA') || (values[1].isNotEmpty && values[1] != 'null' && values[1] != 'NA')) {
        availableStats[key] = values.map((v) => (v.isEmpty || v == 'null' || v == 'NA') ? '-' : v).toList();
      }
    });
    bool hasAnyDetailedStat = availableStats.isNotEmpty;

    Widget buildStatComparisonRow(String statLabel, String homeVal, String awayVal) {
      double? numHome = double.tryParse(homeVal.replaceAll(RegExp(r'[^0-9.]'),''));
      double? numAway = double.tryParse(awayVal.replaceAll(RegExp(r'[^0-9.]'),''));
      TextStyle homeStyle = theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold);
      TextStyle awayStyle = theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold);

      if (numHome != null && numAway != null && homeVal != '-' && awayVal != '-') {
        bool higherIsBetter = !statLabel.toLowerCase().contains("faul") && !statLabel.toLowerCase().contains("kart");
        if (higherIsBetter ? (numHome > numAway) : (numHome < numAway)) { 
          homeStyle = homeStyle.copyWith(color: theme.colorScheme.primary); 
        } else if (higherIsBetter ? (numAway > numHome) : (numAway < numHome)) { 
          awayStyle = awayStyle.copyWith(color: theme.colorScheme.primary); 
        }
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: <Widget>[
            Expanded(flex: 2, child: Text(homeVal, textAlign: TextAlign.center, style: homeStyle)),
            Expanded(flex: 3, child: Text(statLabel, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
            Expanded(flex: 2, child: Text(awayVal, textAlign: TextAlign.center, style: awayStyle)),
          ]
        )
      );
    }
    
    showAnimatedDialog(
      context: context,
      titleWidget: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(leagueName, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
        Text('Maç Detayı', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary), textAlign: TextAlign.center),
      ]),
      dialogPadding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
      contentWidget: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(date, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8))),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Pop-up'ı kapat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamProfileScreen(
                            originalTeamName: originalHomeTeam,
                            leagueName: leagueName,
                            currentSeasonApiValue: currentSeasonApiValue,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                      ),
                      child: homeLogoUrl != null 
                          ? CachedNetworkImage(imageUrl: homeLogoUrl, width: logoSize, height: logoSize, fit: BoxFit.contain) 
                          : Icon(Icons.shield_outlined, size: logoSize),
                    ),
                  ),
                  const SizedBox(height: 8), 
                  Text(homeTeamDisplay, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2),
                ])),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Column(children: [
                    Text('$ftHomeGoals - $ftAwayGoals', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    if (halfTimeScoreInfo.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(halfTimeScoreInfo, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)))),
                  ])),
                Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Pop-up'ı kapat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamProfileScreen(
                            originalTeamName: originalAwayTeam,
                            leagueName: leagueName,
                            currentSeasonApiValue: currentSeasonApiValue,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                      ),
                      child: awayLogoUrl != null 
                          ? CachedNetworkImage(imageUrl: awayLogoUrl, width: logoSize, height: logoSize, fit: BoxFit.contain) 
                          : Icon(Icons.shield_outlined, size: logoSize),
                    ),
                  ),
                  const SizedBox(height: 8), 
                  Text(awayTeamDisplay, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2),
                ])),
              ]),
          ),
          const Divider(height: 20, thickness: 0.5),
          if (hasAnyDetailedStat) ...availableStats.entries.map((entry) => buildStatComparisonRow(entry.key, entry.value[0], entry.value[1]))
          else const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Text("Bu maç için detaylı istatistik bulunmuyor.", style: TextStyle(fontStyle: FontStyle.italic), textAlign: TextAlign.center)),
        ]),
      actionsWidget: [ TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop()) ], 
      maxHeightFactor: 0.85,
    );
  }
}