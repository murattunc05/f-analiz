// lib/widgets/standings_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../data_service.dart';
import '../services/team_name_service.dart';
import '../services/logo_service.dart';
import 'expandable_league_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/dialog_utils.dart';
import 'league_standings_tab_content.dart';
import 'league_matches_tab_content.dart';

class StandingsTab extends StatefulWidget {
  final List<String> favoriteLeagues;
  final String currentSeasonApiValue;

  const StandingsTab({super.key, required this.favoriteLeagues, required this.currentSeasonApiValue});

  @override
  State<StandingsTab> createState() => _StandingsTabState();
}

class _StandingsTabState extends State<StandingsTab> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  final DataService _dataService = DataService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, List<Map<String, dynamic>>> _standingsData = {};
  String? _expandedLeagueName;

  final Map<String, List<Color>> _leagueCardGradients = {};
  static final List<List<Color>> _gradientPalettes = [
    [const Color(0xffa3e635), const Color(0xff4d7c0f), const Color(0xff166534)],
    [const Color(0xffec4899), const Color(0xff7e22ce), const Color(0xff2563eb)],
    [const Color(0xfff59e0b), const Color(0xffef4444), const Color(0xff8b5cf6), const Color(0xff3b82f6)],
    [const Color(0xfff97316), const Color(0xff9f1239), const Color(0xff4a044e)],
    [const Color(0xff22d3ee), const Color(0xff0e7490), const Color(0xff4c1d95)],
  ];

  @override
  void initState() {
    super.initState();
    if (widget.favoriteLeagues.isNotEmpty) {
      _fetchData();
    } else {
      setState(() { _isLoading = false; });
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _generateCardGradients();
  }

  @override
  void didUpdateWidget(covariant StandingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSeasonApiValue != oldWidget.currentSeasonApiValue ||
        !_listEquals(widget.favoriteLeagues, oldWidget.favoriteLeagues)) {
      _fetchData();
    }
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _generateCardGradients() {
    final List<List<Color>> palette = List.from(_gradientPalettes);
    palette.shuffle(Random());

    _leagueCardGradients.clear();
    for (int i = 0; i < widget.favoriteLeagues.length; i++) {
      final leagueName = widget.favoriteLeagues[i];
      _leagueCardGradients[leagueName] = palette[i % palette.length];
    }
  }

  Future<void> _fetchData() async {
    if(!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; _standingsData.clear(); _expandedLeagueName = null; });
    
    _generateCardGradients();
    
    try {
      final futures = widget.favoriteLeagues.map((leagueName) async {
        final leagueUrl = DataService.getLeagueUrl(leagueName, widget.currentSeasonApiValue);
        if (leagueUrl == null) { _addError("$leagueName için URL yok."); return; }
        final csvData = await _dataService.fetchData(leagueUrl);
        if (csvData == null) { _addError("$leagueName için veri alınamadı."); return; }
        final parsedCsv = _dataService.parseCsv(csvData);
        if (parsedCsv.length < 2) { return; }
        final headers = _dataService.getCsvHeaders(parsedCsv);
        if (headers.isEmpty) { return; }
        final matches = _parseAndSortMatches(parsedCsv, headers);
        if (mounted) {
          final standings = _calculateStandings(matches, leagueName);
          _standingsData[leagueName] = standings;
        }
      });
      await Future.wait(futures);
    } catch (e) {
      if (mounted) _errorMessage = e.toString();
    }
    if(mounted) setState(() { _isLoading = false; });
  }

  void _addError(String msg) {
      if(mounted) {
          setState(() {
             _errorMessage = (_errorMessage == null) ? msg : "$_errorMessage\n$msg";
          });
      }
  }

  List<Map<String, dynamic>> _parseAndSortMatches(List<List<dynamic>> parsedData, List<String> headers) {
    List<Map<String, dynamic>> allMatchesInLeague = [];
    for (int i = 1; i < parsedData.length; i++) {
      List<dynamic> row = parsedData[i]; if (row.length < headers.length) continue; Map<String, dynamic> match = {};
      bool essentialDataMissing = false;
      for (int j = 0; j < headers.length; j++) {
        match[headers[j]] = (j < row.length && row[j] != null) ? row[j].toString().trim() : '';
        if ((headers[j] == 'HomeTeam' || headers[j] == 'AwayTeam' || headers[j] == 'FTHG' || headers[j] == 'FTAG' || headers[j] == 'Date') && match[headers[j]].isEmpty) {
          essentialDataMissing = true; break;
        }
      }
      if(essentialDataMissing) continue;
      try {
        String? matchDateStr = match['Date']?.toString();
        if (matchDateStr != null && matchDateStr.isNotEmpty) {
          List<String> dateParts = matchDateStr.split('/');
          if (dateParts.length == 3) {
            int day = int.tryParse(dateParts[0]) ?? 1; int month = int.tryParse(dateParts[1]) ?? 1;
            int year = int.tryParse(dateParts[2]) ?? DateTime.now().year;
            if (year < 100) { year = 2000 + year; if (year > DateTime.now().year + 15) year -= 100;}
            match['_parsedDate'] = DateTime(year, month, day);
          } else { match['_parsedDate'] = null;}
        } else { match['_parsedDate'] = null;}
      } catch (e) { match['_parsedDate'] = null; }
      allMatchesInLeague.add(match);
    }
    
    allMatchesInLeague.sort((a, b) {
      final dateA = a['_parsedDate'] as DateTime?;
      final dateB = b['_parsedDate'] as DateTime?;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });
    
    return allMatchesInLeague;
  }
  
  List<Map<String, dynamic>> _calculateStandings(List<Map<String, dynamic>> allMatchesForLeague, String leagueName) {
    List<String> allTeamOriginalNamesInLeague = _dataService.getAllOriginalTeamNamesFromMatches(allMatchesForLeague);
    if (allTeamOriginalNamesInLeague.isEmpty) return [];
    List<Map<String, dynamic>> leagueStandings = [];
    for (String originalTeamName in allTeamOriginalNamesInLeague) {
      List<Map<String, dynamic>> teamSpecificMatches = allMatchesForLeague.where((match) {
        String home = match['HomeTeam']?.toString() ?? ''; String away = match['AwayTeam']?.toString() ?? '';
        return TeamNameService.normalize(home) == TeamNameService.normalize(originalTeamName) || TeamNameService.normalize(away) == TeamNameService.normalize(originalTeamName);
      }).toList();
      Map<String, dynamic> teamStats = _dataService.analyzeTeamStats(teamSpecificMatches, originalTeamName, lastNMatches: null);
      int played = teamStats['oynananMacSayisi'] as int? ?? 0;
      if (played == 0 && teamSpecificMatches.isEmpty) continue; 
      int points = ((teamStats['galibiyet'] as int? ?? 0) * 3) + (teamStats['beraberlik'] as int? ?? 0);
      Map<String, dynamic> formStats = _dataService.analyzeTeamStats(teamSpecificMatches, originalTeamName, lastNMatches: 5);
      leagueStandings.add({
        'pos': 0, 'teamOriginalName': originalTeamName, 'teamDisplayName': teamStats['displayTeamName'] as String? ?? originalTeamName,
        'om': played, 'g': teamStats['galibiyet'] as int? ?? 0, 'b': teamStats['beraberlik'] as int? ?? 0, 'm': teamStats['maglubiyet'] as int? ?? 0,
        'ag': teamStats['attigi'] as int? ?? 0, 'yg': teamStats['yedigi'] as int? ?? 0, 'a': teamStats['golFarki'] as int? ?? 0, 'pts': points,
        'logo_url': LogoService.getTeamLogoUrl(originalTeamName, leagueName), 'formMatches': (formStats["son${formStats['lastNMatchesUsed']}MacDetaylari"] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
        'last10Matches': teamSpecificMatches.take(10).toList(),
      });
    }
    leagueStandings.sort((a, b) {
      int ptsComp = (b['pts'] as int).compareTo(a['pts'] as int); if (ptsComp != 0) return ptsComp;
      int avgComp = (b['a'] as int).compareTo(a['a'] as int); if (avgComp != 0) return avgComp;
      return (a['teamDisplayName'] as String).toLowerCase().compareTo((b['teamDisplayName'] as String).toLowerCase());
    });
    for (int i = 0; i < leagueStandings.length; i++) { leagueStandings[i]['pos'] = i + 1; }
    return leagueStandings;
  }
  
  void _handleExpansion(String leagueName) { setState(() { _expandedLeagueName = (_expandedLeagueName == leagueName) ? null : leagueName; }); }
  
  String _getLeagueLogoAssetName(String leagueName) {
    String normalized = leagueName.toLowerCase().replaceAll(' - ', '_').replaceAll(' ', '_');
    const Map<String, String> charMap = { 'ı': 'i', 'ğ': 'g', 'ü': 'u', 'ş': 's', 'ö': 'o', 'ç': 'c', };
    charMap.forEach((tr, en) => normalized = normalized.replaceAll(tr, en));
    return 'assets/logos/leagues/${normalized.replaceAll(RegExp(r'[^\w_.-]'), '')}.png';
  }

  Future<void> _showTeamRecentMatchesPopup(BuildContext context, Map<String, dynamic> teamData, String leagueName) async {
    HapticFeedback.lightImpact(); final theme = Theme.of(context);
    final teamMatches = (teamData['last10Matches'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    showAnimatedDialog(
      context: context, titleWidget: Column(mainAxisSize: MainAxisSize.min, children: [
        if (teamData['logo_url'] != null) CachedNetworkImage(imageUrl: teamData['logo_url'], height: 60, fit: BoxFit.contain) else const Icon(Icons.shield_outlined, size: 60), const SizedBox(height: 8),
        Text(teamData['teamDisplayName'], style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary), textAlign: TextAlign.center),
        const Text("Son 10 Maç", style: TextStyle(color: Colors.grey)),]),
      dialogPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      contentWidget: SizedBox( height: MediaQuery.of(context).size.height * 0.4, 
        child: teamMatches.isEmpty 
            ? const Center(child: Text("Maç detayı bulunamadı.")) 
            : LeagueMatchesTabContent(
                theme: theme, 
                leagueName: leagueName, 
                matches: teamMatches,
                onMatchTap: (ctx, matchData, lgName) => _showMatchDetailsPopup(ctx, matchData, lgName),
                buildMatchRowWidget: (match, theme, {isPopup = false}) => _buildMatchRowForPopup(match, theme, leagueName))
        ),
      actionsWidget: [ TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop()) ], maxHeightFactor: 0.8,
    );
  }

  Widget _buildMatchRowForPopup(Map<String, dynamic> match, ThemeData theme, String leagueName) {
    String home = match['HomeTeam']?.toString() ?? 'Ev', away = match['AwayTeam']?.toString() ?? 'Dep';
    String? homeLogo = LogoService.getTeamLogoUrl(home, leagueName), awayLogo = LogoService.getTeamLogoUrl(away, leagueName);
    TextStyle teamNameStyle = theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500);

    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0), child: Row(children: [
      Expanded(flex: 5, child: Row(children: [
        if (homeLogo != null) CachedNetworkImage(imageUrl: homeLogo, width: 24, height: 24, fit: BoxFit.contain) else const Icon(Icons.shield_outlined, size: 24),
        const SizedBox(width: 8), Expanded(child: Text(TeamNameService.getCorrectedTeamName(home), style: teamNameStyle, overflow: TextOverflow.ellipsis)),
      ])),
      Expanded(flex: 3, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${match['FTHG'] ?? '?'} - ${match['FTAG'] ?? '?'}', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        if (match['Date'] != null) ...[const SizedBox(height: 2), Text(match['Date'].toString(), style: theme.textTheme.bodySmall)]
      ])),
      Expanded(flex: 5, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Expanded(child: Text(TeamNameService.getCorrectedTeamName(away), style: teamNameStyle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end,)),
        const SizedBox(width: 8),
        if (awayLogo != null) CachedNetworkImage(imageUrl: awayLogo, width: 24, height: 24, fit: BoxFit.contain) else const Icon(Icons.shield_outlined, size: 24),
      ])),
    ]));
  }
  
  void _showMatchDetailsPopup(BuildContext context, Map<String, dynamic> matchData, String leagueName) {
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

    String? homeLogoUrl = LogoService.getTeamLogoUrl(originalHomeTeam, leagueName);
    String? awayLogoUrl = LogoService.getTeamLogoUrl(originalAwayTeam, leagueName);
    const double logoSize = 64.0;

    String halfTimeScoreInfo = "";
    if (htHomeGoals != null && htHomeGoals.isNotEmpty && htHomeGoals != 'NA' && htAwayGoals != null && htAwayGoals.isNotEmpty && htAwayGoals != 'NA') {
      halfTimeScoreInfo = "(İY: $htHomeGoals-$htAwayGoals)";
    }

    Map<String, List<String>> statsToDisplay = {
      "Toplam Şut": [matchData['HS']?.toString() ?? '', matchData['AS']?.toString() ?? ''], "İsabetli Şut": [matchData['HST']?.toString() ?? '', matchData['AST']?.toString() ?? ''],
      "Korner": [matchData['HC']?.toString() ?? '', matchData['AC']?.toString() ?? ''], "Faul": [matchData['HF']?.toString() ?? '', matchData['AF']?.toString() ?? ''],
      "Sarı Kart": [matchData['HY']?.toString() ?? '', matchData['AY']?.toString() ?? ''], "Kırmızı Kart": [matchData['HR']?.toString() ?? '', matchData['AR']?.toString() ?? ''],
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
        if (higherIsBetter ? (numHome > numAway) : (numHome < numAway)) { homeStyle = homeStyle.copyWith(color: theme.colorScheme.primary); } 
        else if (higherIsBetter ? (numAway > numHome) : (numAway < numHome)) { awayStyle = awayStyle.copyWith(color: theme.colorScheme.primary); }
      }
      return Padding(padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
            Expanded(flex: 2, child: Text(homeVal, textAlign: TextAlign.center, style: homeStyle)),
            Expanded(flex: 3, child: Text(statLabel, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
            Expanded(flex: 2, child: Text(awayVal, textAlign: TextAlign.center, style: awayStyle)),
          ]));
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
                  if (homeLogoUrl != null) CachedNetworkImage(imageUrl: homeLogoUrl, width: logoSize, height: logoSize, fit: BoxFit.contain, errorWidget: (c,u,e)=>Icon(Icons.shield_outlined, size: logoSize)) else Icon(Icons.shield_outlined, size: logoSize),
                  const SizedBox(height: 8), Text(homeTeamDisplay, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2),
                ])),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Column(children: [
                    Text('$ftHomeGoals - $ftAwayGoals', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    if (halfTimeScoreInfo.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(halfTimeScoreInfo, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)))),
                  ])),
                Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (awayLogoUrl != null) CachedNetworkImage(imageUrl: awayLogoUrl, width: logoSize, height: logoSize, fit: BoxFit.contain, errorWidget: (c,u,e)=>Icon(Icons.shield_outlined, size: logoSize)) else Icon(Icons.shield_outlined, size: logoSize),
                  const SizedBox(height: 8), Text(awayTeamDisplay, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2),
                ])),
              ]),
          ),
          const Divider(height: 20, thickness: 0.5),
          if (hasAnyDetailedStat) ...availableStats.entries.map((entry) => buildStatComparisonRow(entry.key, entry.value[0], entry.value[1]))
          else const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Text("Bu maç için detaylı istatistik bulunmuyor.", style: TextStyle(fontStyle: FontStyle.italic), textAlign: TextAlign.center)),
        ]),
      actionsWidget: [ TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop()) ], maxHeightFactor: 0.85,
    );
  }
  
  Widget _buildCardHeader(String leagueName) {
    final bool isExpanded = _expandedLeagueName == leagueName;
    return Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Image.asset(_getLeagueLogoAssetName(leagueName), width: 34, height: 34, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.shield_outlined, size: 34)),
        const SizedBox(width: 10),
        Expanded(child: Text(leagueName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
        Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down)
      ]));
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (widget.favoriteLeagues.isEmpty) return const Center(child: Text("Favori lig seçin."));
    if (_errorMessage != null && _standingsData.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Bazı ligler yüklenemedi:\n$_errorMessage", textAlign: TextAlign.center)));
    
    final defaultGradient = _gradientPalettes.first;

    return ListView.builder(
      key: const PageStorageKey<String>('standings_list'),
      padding: const EdgeInsets.all(12),
      itemCount: widget.favoriteLeagues.length,
      itemBuilder: (context, index) {
        final leagueName = widget.favoriteLeagues[index];
        final fullStandings = _standingsData[leagueName] ?? [];
        final cardGradient = _leagueCardGradients[leagueName] ?? defaultGradient;

        if (fullStandings.isEmpty) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding( padding: const EdgeInsets.all(16.0), child: Text("$leagueName için puan durumu verisi yükleniyor veya bulunamadı.", textAlign: TextAlign.center)),
          );
        }

        Widget collapsedChild = Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0), 
          child: Column(children: [
              const SizedBox(height: 8), 
              Row( children: [
                  SizedBox(width: 48, child: Text("# Takım", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))), const Spacer(),
                  SizedBox(width: 25, child: Text("G", textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                  SizedBox(width: 25, child: Text("B", textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                  SizedBox(width: 25, child: Text("M", textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                  SizedBox(width: 30, child: Text("P", textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                ]),
              const Divider(height: 10),
              ...fullStandings.take(3).map((team) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(children: [
                      SizedBox(width: 20, child: Text("${team['pos']}.", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
                      if (team['logo_url'] != null) CachedNetworkImage(imageUrl: team['logo_url'], width: 20, height: 20, fit: BoxFit.contain) else const Icon(Icons.shield_outlined, size: 20),
                      const SizedBox(width: 8), Expanded(child: Text(team['teamDisplayName'], style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
                      SizedBox(width: 25, child: Text(team['g'].toString(), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)),
                      SizedBox(width: 25, child: Text(team['b'].toString(), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)),
                      SizedBox(width: 25, child: Text(team['m'].toString(), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)),
                      SizedBox(width: 30, child: Text(team['pts'].toString(), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary))),
                    ]),
                );
              }).toList(),
            ]),
        );
        
        Widget expandedChild = Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: StandingsTableWidget(
            theme: Theme.of(context),
            standingsData: fullStandings,
            onTeamTap: (ctx, teamData) => _showTeamRecentMatchesPopup(ctx, teamData, leagueName),
            leagueName: leagueName,
          )
        );
        
        return ExpandableLeagueCard(
          header: _buildCardHeader(leagueName),
          collapsedChild: collapsedChild, 
          expandedChild: expandedChild,
          isExpanded: _expandedLeagueName == leagueName,
          onTapHeader: () => _handleExpansion(leagueName),
          gradientColors: cardGradient,
        );
      },
    );
  }
}