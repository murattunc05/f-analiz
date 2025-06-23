// lib/widgets/h2h_popup_content.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/logo_service.dart';
import '../services/team_name_service.dart';

class H2HPopupContent extends StatelessWidget {
  final ThemeData theme;
  final List<Map<String, dynamic>> h2hMatches;
  final Map<String, dynamic> team1Data;
  final Map<String, dynamic> team2Data;
  final Map<String, int> h2hStats;

  const H2HPopupContent({
    super.key,
    required this.theme,
    required this.h2hMatches,
    required this.team1Data,
    required this.team2Data,
    required this.h2hStats,
  });

  @override
  Widget build(BuildContext context) {
    final team1OriginalName = team1Data['takim'] as String;
    final team1DisplayName = TeamNameService.getCorrectedTeamName(team1OriginalName);
    final team1LogoUrl = LogoService.getTeamLogoUrl(team1OriginalName, team1Data['leagueNameForLogo']);

    final team2OriginalName = team2Data['takim'] as String;
    final team2DisplayName = TeamNameService.getCorrectedTeamName(team2OriginalName);
    final team2LogoUrl = LogoService.getTeamLogoUrl(team2OriginalName, team2Data['leagueNameForLogo']);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BAŞLIK BÖLÜMÜ
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTeamHeader(team1LogoUrl, team1DisplayName),
              Text("VS", style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              _buildTeamHeader(team2LogoUrl, team2DisplayName),
            ],
          ),
        ),
        const Divider(),
        // MAÇ LİSTESİ BÖLÜMÜ
        Flexible(
          child: h2hMatches.isEmpty
              ? const Center(child: Text("Aralarında oynanmış maç bulunamadı."))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: h2hMatches.length,
                  itemBuilder: (context, index) {
                    final match = h2hMatches[index];
                    return _buildMatchRow(match, team1OriginalName, theme);
                  },
                  separatorBuilder: (context, index) => const Divider(height: 1),
                ),
        ),
      ],
    );
  }

  Widget _buildTeamHeader(String? logoUrl, String name) {
    return Column(
      children: [
        if (logoUrl != null)
          CachedNetworkImage(imageUrl: logoUrl, width: 48, height: 48, fit: BoxFit.contain)
        else
          Icon(Icons.shield_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 4),
        SizedBox(
          width: 100,
          child: Text(
            name,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchRow(Map<String, dynamic> match, String team1OriginalName, ThemeData theme) {
    final homeTeamOriginal = match['HomeTeam'] as String;
    final awayTeamOriginal = match['AwayTeam'] as String;
    
    final homeTeamName = TeamNameService.getCorrectedTeamName(homeTeamOriginal);
    final awayTeamName = TeamNameService.getCorrectedTeamName(awayTeamOriginal);
    
    final homeGoals = match['FTHG']?.toString() ?? '?';
    final awayGoals = match['FTAG']?.toString() ?? '?';
    final result = match['FTR']?.toString();
    final date = match['Date']?.toString() ?? '';

    final isTeam1Home = TeamNameService.normalize(homeTeamOriginal) == TeamNameService.normalize(team1OriginalName);
    
    FontWeight homeFontWeight = FontWeight.normal;
    FontWeight awayFontWeight = FontWeight.normal;
    
    if (result == 'H') { // Ev sahibi kazandı
      homeFontWeight = FontWeight.bold;
    } else if (result == 'A') { // Deplasman kazandı
      awayFontWeight = FontWeight.bold;
    }

    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(homeTeamName, style: TextStyle(fontWeight: homeFontWeight), textAlign: TextAlign.right)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("$homeGoals - $awayGoals", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(awayTeamName, style: TextStyle(fontWeight: awayFontWeight), textAlign: TextAlign.left)),
        ],
      ),
      subtitle: Center(child: Text(date, style: theme.textTheme.bodySmall)),
    );
  }
}