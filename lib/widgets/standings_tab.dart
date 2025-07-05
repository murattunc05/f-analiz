import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_service.dart';
import '../services/team_name_service.dart';
import '../services/logo_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/dialog_utils.dart';
import 'league_matches_tab_content.dart';

class StandingsTab extends ConsumerStatefulWidget {
  final List<String> favoriteLeagues;
  final String currentSeasonApiValue;

  const StandingsTab({super.key, required this.favoriteLeagues, required this.currentSeasonApiValue});

  @override
  ConsumerState<StandingsTab> createState() => _StandingsTabState();
}

class _StandingsTabState extends ConsumerState<StandingsTab> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  late final DataService _dataService;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, List<Map<String, dynamic>>> _standingsData = {};
  String? _expandedLeagueName;

  @override
  void initState() {
    super.initState();
    _dataService = ref.read(dataServiceProvider);
    if (widget.favoriteLeagues.isNotEmpty) {
      _fetchData();
    } else {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
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

  Future<void> _fetchData() async {
    if(!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; _standingsData.clear(); _expandedLeagueName = null; });
    
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
    if (htHomeGoals != null && htHomeGoals.isNotEmpty && htHomeGoals.isNotEmpty && htAwayGoals != null && htAwayGoals.isNotEmpty) {
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
                  if (homeLogoUrl != null) CachedNetworkImage(imageUrl: homeLogoUrl, width: logoSize, height: logoSize, fit: BoxFit.contain) else Icon(Icons.shield_outlined, size: logoSize),
                  const SizedBox(height: 8), Text(homeTeamDisplay, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2),
                ])),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Column(children: [
                    Text('$ftHomeGoals - $ftAwayGoals', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    if (halfTimeScoreInfo.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(halfTimeScoreInfo, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)))),
                  ])),
                Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (awayLogoUrl != null) CachedNetworkImage(imageUrl: awayLogoUrl, width: logoSize, height: logoSize, fit: BoxFit.contain) else Icon(Icons.shield_outlined, size: logoSize),
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
    final String? logoUrl = LogoService.getLeagueLogoUrl(leagueName);

    return InkWell(
      onTap: () => _handleExpansion(leagueName),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                      errorWidget: (context, url, error) => const Icon(Icons.shield_outlined, size: 34),
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.shield_outlined, size: 34),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(leagueName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (widget.favoriteLeagues.isEmpty) return const Center(child: Text("Favori lig seçin."));
    if (_errorMessage != null && _standingsData.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Bazı ligler yüklenemedi:\n$_errorMessage", textAlign: TextAlign.center)));
    
    return ListView.builder(
      key: const PageStorageKey<String>('standings_list'),
      padding: const EdgeInsets.all(12),
      itemCount: widget.favoriteLeagues.length,
      itemBuilder: (context, index) {
        final leagueName = widget.favoriteLeagues[index];
        final fullStandings = _standingsData[leagueName] ?? [];

        if (fullStandings.isEmpty) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding( padding: const EdgeInsets.all(16.0), child: Text("$leagueName için puan durumu verisi yükleniyor veya bulunamadı.", textAlign: TextAlign.center)),
          );
        }

        final isExpanded = _expandedLeagueName == leagueName;

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCardHeader(leagueName),
              const Divider(height: 1, thickness: 0.5),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                child: isExpanded 
                  ? _buildExpandedStandings(fullStandings, leagueName)
                  : _buildCollapsedStandings(fullStandings.take(3).toList()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollapsedStandings(List<Map<String, dynamic>> topTeams) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: topTeams.map((team) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Text("${team['pos']}.", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (team['logo_url'] != null)
                  CachedNetworkImage(imageUrl: team['logo_url'], width: 20, height: 20, fit: BoxFit.contain)
                else
                  const Icon(Icons.shield_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(team['teamDisplayName'], style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
                Text(team['pts'].toString(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpandedStandings(List<Map<String, dynamic>> standings, String leagueName) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFixedColumn(standings, leagueName),
        Expanded(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                // DÜZELTME: Gradyan renkleri temanın kart rengini kullanacak
                colors: <Color>[
                  theme.cardColor,
                  theme.cardColor.withOpacity(0.0)
                ],
                // DÜZELTME: Solma efektinin başlangıç ve bitiş noktaları ayarlandı
                stops: const [0.8, 1.0],
              ).createShader(bounds);
            },
            // DÜZELTME: Blend modu dstIn olarak değiştirildi
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              // DÜZELTME: Kaydırma pozisyonu sorununu çözmek için Key eklendi
              key: ValueKey(leagueName),
              scrollDirection: Axis.horizontal,
              child: _buildScrollableColumns(standings),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedColumn(List<Map<String, dynamic>> standings, String leagueName) {
    final theme = Theme.of(context);
    const double fixedWidth = 170.0;
    const double rowHeight = 48.0;

    return SizedBox(
      width: fixedWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: rowHeight,
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1.5))),
            child: Row(
              children: [
                SizedBox(width: 28, child: _HeaderCell(text: '#')),
                const SizedBox(width: 4),
                Expanded(child: _HeaderCell(text: 'Takım', alignment: TextAlign.left)),
              ],
            ),
          ),
          Column(
            children: standings.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> teamData = entry.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showTeamRecentMatchesPopup(context, teamData, leagueName),
                    child: Container(
                      height: rowHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Row(
                        children: [
                          SizedBox(width: 28, child: Text(teamData['pos'].toString(), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                          const SizedBox(width: 4),
                          if (teamData['logo_url'] != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: CachedNetworkImage(imageUrl: teamData['logo_url'], width: 24, height: 24, fit: BoxFit.contain, errorWidget: (c, u, e) => const Icon(Icons.shield_outlined, size: 24)),
                            )
                          else
                            const Padding(padding: const EdgeInsets.only(right: 8.0), child: Icon(Icons.shield, size: 24)),
                          Expanded(child: Text(teamData['teamDisplayName'], overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                  ),
                  if (index < standings.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 0),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableColumns(List<Map<String, dynamic>> standings) {
    final theme = Theme.of(context);
    const double cellWidth = 40.0;
    const double formCellWidth = 70.0;
    const double rowHeight = 48.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: rowHeight,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1.5))),
          child: Row(
            children: const [
              SizedBox(width: cellWidth, child: _HeaderCell(text: 'O')),
              SizedBox(width: cellWidth, child: _HeaderCell(text: 'G')),
              SizedBox(width: cellWidth, child: _HeaderCell(text: 'B')),
              SizedBox(width: cellWidth, child: _HeaderCell(text: 'M')),
              SizedBox(width: cellWidth, child: _HeaderCell(text: 'P')),
              SizedBox(width: cellWidth, child: _HeaderCell(text: 'AG')),
              SizedBox(width: cellWidth, child: _HeaderCell(text: 'YG')),
              SizedBox(width: cellWidth, child: _HeaderCell(text: 'A')),
              SizedBox(width: formCellWidth, child: _HeaderCell(text: 'Son 3')),
            ],
          ),
        ),
        Column(
          children: standings.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> teamData = entry.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: [
                      SizedBox(width: cellWidth, child: Center(child: Text(teamData['om'].toString()))),
                      SizedBox(width: cellWidth, child: Center(child: Text(teamData['g'].toString()))),
                      SizedBox(width: cellWidth, child: Center(child: Text(teamData['b'].toString()))),
                      SizedBox(width: cellWidth, child: Center(child: Text(teamData['m'].toString()))),
                      SizedBox(width: cellWidth, child: Center(child: Text(teamData['pts'].toString(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)))),
                      SizedBox(width: cellWidth, child: Center(child: Text(teamData['ag'].toString()))),
                      SizedBox(width: cellWidth, child: Center(child: Text(teamData['yg'].toString()))),
                      SizedBox(width: cellWidth, child: Center(child: Text(teamData['a'].toString()))),
                      SizedBox(width: formCellWidth, child: _buildFormIcons(teamData['formMatches'] ?? [])),
                    ],
                  ),
                ),
                if (index < standings.length - 1)
                  const Divider(height: 1),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFormIcons(List<dynamic> formMatches) {
    if (formMatches.isEmpty) {
      return const Text('-', textAlign: TextAlign.center);
    }
    List<Widget> formWidgets = [];
    final matchesToDisplay = formMatches.take(3).toList();
    for (int i = 0; i < 3; i++) {
      if (i < matchesToDisplay.length) {
        final match = matchesToDisplay[i];
        IconData iconData;
        Color iconColor;
        String result = match['result']?.toString() ?? "";
        if (result.startsWith("G")) {
          iconData = Icons.check_circle;
          iconColor = Colors.green.shade600;
        } else if (result.startsWith("B")) {
          iconData = Icons.remove_circle;
          iconColor = Colors.grey.shade600;
        } else if (result.startsWith("M")) {
          iconData = Icons.cancel;
          iconColor = Colors.red.shade600;
        } else {
          iconData = Icons.circle_outlined;
          iconColor = Colors.grey.shade400;
        }
        
        Widget iconWidget = Icon(iconData, color: iconColor, size: 16);

        if (i == 0) {
          iconWidget = Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withOpacity(0.8), width: 1.5),
            ),
            child: iconWidget,
          );
        }

        formWidgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: iconWidget,
        ));

      } else {
        formWidgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Icon(Icons.remove, color: Colors.grey.shade300, size: 16),
        ));
      }
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: formWidgets);
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final TextAlign alignment;

  const _HeaderCell({
    required this.text,
    this.alignment = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignment,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
    );
  }
}
