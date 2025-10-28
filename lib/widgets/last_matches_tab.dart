import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_service.dart';
import '../services/team_name_service.dart';
import '../services/logo_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/dialog_utils.dart';
import '../team_profile_screen.dart';

class LastMatchesTab extends ConsumerStatefulWidget {
  final List<String> favoriteLeagues;
  final String currentSeasonApiValue;
  
  const LastMatchesTab({super.key, required this.favoriteLeagues, required this.currentSeasonApiValue});

  @override
  ConsumerState<LastMatchesTab> createState() => _LastMatchesTabState();
}

class _LastMatchesTabState extends ConsumerState<LastMatchesTab> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  late final DataService _dataService;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, List<Map<String, dynamic>>> _matchesData = {};
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
  void didUpdateWidget(covariant LastMatchesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSeasonApiValue != oldWidget.currentSeasonApiValue || !_listEquals(widget.favoriteLeagues, oldWidget.favoriteLeagues)) {
      _fetchData();
    }
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null; if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) { if (a[i] != b[i]) return false; }
    return true;
  }
  
  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; _matchesData.clear(); _expandedLeagueName = null; });
    
    try {
      final futures = widget.favoriteLeagues.map((leagueName) async {
        final leagueUrl = DataService.getLeagueUrl(leagueName, widget.currentSeasonApiValue);
        if (leagueUrl == null) { _addError("$leagueName için URL yok."); return; }
        final csvData = await _dataService.fetchData(leagueUrl);
        if (csvData == null) { _addError("$leagueName için veri alınamadı."); return; }
        final parsedCsv = _dataService.parseCsv(csvData);
        if (parsedCsv.length < 2) return;
        final headers = _dataService.getCsvHeaders(parsedCsv);
        if (headers.isEmpty) return;
        
        if (mounted) {
            final matches = _parseAndSortMatches(parsedCsv, headers);
            _matchesData[leagueName] = matches;
        }
      }).toList();
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

  void _handleExpansion(String leagueName) {
    setState(() {
      if (_expandedLeagueName == leagueName) {
        _expandedLeagueName = null;
      } else {
        _expandedLeagueName = leagueName;
      }
    });
  }

  Widget _buildCardHeader(String leagueName) {
    final String? logoUrl = LogoService.getLeagueLogoUrl(leagueName);
    final bool isExpanded = _expandedLeagueName == leagueName;

    return InkWell(
      onTap: () => _handleExpansion(leagueName),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                      errorWidget: (context, url, error) => const Icon(Icons.shield_outlined, size: 28),
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.shield_outlined, size: 28),
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
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Pop-up'ı kapat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamProfileScreen(
                            originalTeamName: originalHomeTeam,
                            leagueName: leagueName,
                            currentSeasonApiValue: widget.currentSeasonApiValue,
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
                            currentSeasonApiValue: widget.currentSeasonApiValue,
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
      actionsWidget: [ TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop()) ], maxHeightFactor: 0.85,
    );
  }

  /// YENİ TASARIM: Maç satırı widget'ı Figma prensiplerine göre güncellendi.
  /// Logolar skorun yanına alındı ve hizalamalar iyileştirildi.
  Widget _buildCompactMatchRow(Map<String, dynamic> match, String leagueName) {
    final theme = Theme.of(context);
    String home = match['HomeTeam']?.toString() ?? 'Ev';
    String away = match['AwayTeam']?.toString() ?? 'Dep';
    String? homeLogo = LogoService.getTeamLogoUrl(home, leagueName);
    String? awayLogo = LogoService.getTeamLogoUrl(away, leagueName);
    TextStyle teamNameStyle = theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500);
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showMatchDetailsPopup(context, match, leagueName);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ev Sahibi Takım Adı
            Expanded(
              child: Text(
                TeamNameService.getCorrectedTeamName(home),
                style: teamNameStyle,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
            
            // Merkezi Skor Bloğu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  if (homeLogo != null)
                    CachedNetworkImage(imageUrl: homeLogo, width: 28, height: 28, fit: BoxFit.contain)
                  else
                    const Icon(Icons.shield_outlined, size: 28),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      '${match['FTHG'] ?? '?'} - ${match['FTAG'] ?? '?'}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),

                  if (awayLogo != null)
                    CachedNetworkImage(imageUrl: awayLogo, width: 28, height: 28, fit: BoxFit.contain)
                  else
                    const Icon(Icons.shield_outlined, size: 28),
                ],
              ),
            ),

            // Deplasman Takımı Adı
            Expanded(
              child: Text(
                TeamNameService.getCorrectedTeamName(away),
                style: teamNameStyle,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
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
    if (_errorMessage != null && _matchesData.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Bazı ligler yüklenemedi:\n$_errorMessage", textAlign: TextAlign.center)));
    
    return ListView.builder(
      key: const PageStorageKey<String>('last_matches_list'),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      itemCount: widget.favoriteLeagues.length,
      itemBuilder: (context, index) {
        final leagueName = widget.favoriteLeagues[index];
        final allMatches = _matchesData[leagueName] ?? [];
        
        if (allMatches.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final bool isExpanded = _expandedLeagueName == leagueName;
        final matchesToShow = allMatches.take(isExpanded ? 10 : 3).toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCardHeader(leagueName),
              const Divider(height: 1, thickness: 0.5),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: matchesToShow.length,
                  itemBuilder: (c, i) => _buildCompactMatchRow(matchesToShow[i], leagueName),
                  separatorBuilder: (c, i) => const Divider(height: 1, indent: 16, endIndent: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
