// lib/team_search_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:futbol_analiz_app/data_service.dart';
import 'package:futbol_analiz_app/services/team_name_service.dart';
import 'package:futbol_analiz_app/services/logo_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'team_profile_screen.dart'; 

class SearchableTeam {
  final String originalName;
  final String displayName;
  final String leagueName;
  final String? logoUrl;

  SearchableTeam({
    required this.originalName,
    required this.displayName,
    required this.leagueName,
    this.logoUrl,
  });
}

class TeamSearchScreen extends StatefulWidget {
  const TeamSearchScreen({super.key});

  @override
  State<TeamSearchScreen> createState() => _TeamSearchScreenState();
}

class _TeamSearchScreenState extends State<TeamSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DataService _dataService = DataService();

  List<SearchableTeam> _allTeams = [];
  List<SearchableTeam> _searchResults = [];
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAllTeams();
    _searchController.addListener(() {
      _filterTeams(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchAllTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteLeagues = prefs.getStringList('favorite_leagues_key') ?? DataService.leagueDisplayNames;
    final season = prefs.getString('season_preference') ?? DataService.AVAILABLE_SEASONS_API.first;
    
    List<SearchableTeam> tempTeams = [];
    String? tempError;

    final futures = favoriteLeagues.map((leagueName) async {
      try {
        final url = DataService.getLeagueUrl(leagueName, season);
        if (url == null) return;
        final csvData = await _dataService.fetchData(url);
        if (csvData == null) return;
        
        final parsed = _dataService.parseCsv(csvData);
        final headers = _dataService.getCsvHeaders(parsed);
        final teamNames = _dataService.getAllOriginalTeamNames(parsed, headers);
        
        for (var originalName in teamNames) {
          tempTeams.add(SearchableTeam(
            originalName: originalName,
            displayName: TeamNameService.getCorrectedTeamName(originalName),
            leagueName: leagueName,
            logoUrl: LogoService.getTeamLogoUrl(originalName, leagueName)
          ));
        }
      } catch (e) {
        tempError = "Veri çekilirken bir hata oluştu.";
      }
    });

    await Future.wait(futures);
    
    final uniqueTeams = <String, SearchableTeam>{};
    for(var team in tempTeams) {
        uniqueTeams[team.displayName] = team;
    }

    if (mounted) {
      setState(() {
        _allTeams = uniqueTeams.values.toList();
        _isLoading = false;
        _errorMessage = tempError;
      });
    }
  }

  void _filterTeams(String query) {
    if (!mounted) return;

    final normalizedQuery = TeamNameService.normalize(query);
    if (normalizedQuery.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() {
      _searchResults = _allTeams.where((team) {
        final normalizedDisplayName = TeamNameService.normalize(team.displayName);
        final normalizedOriginalName = TeamNameService.normalize(team.originalName);
        return normalizedDisplayName.contains(normalizedQuery) || normalizedOriginalName.contains(normalizedQuery);
      }).toList();
    });
  }
  
  void _onTeamSelected(SearchableTeam team) {
    // SharedPreferences'tan sezonu almamız lazım
    SharedPreferences.getInstance().then((prefs) {
      final season = prefs.getString('season_preference') ?? DataService.AVAILABLE_SEASONS_API.first;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TeamProfileScreen(
            originalTeamName: team.originalName,
            leagueName: team.leagueName,
            currentSeasonApiValue: season, // Bu parametreyi gönder
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takım Arama'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Takım adı veya kısaltma girin...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ) : null,
                border: OutlineInputBorder( borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none,),
                filled: true, contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_searchController.text.isEmpty) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "Tüm favori liglerdeki takımları arayabilirsiniz.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
              ),
          ));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text("Arama sonucu bulunamadı."));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 70, endIndent: 16),
      itemBuilder: (context, index) {
        final team = _searchResults[index];
        return ListTile(
          leading: SizedBox(
            width: 40,
            height: 40,
            child: team.logoUrl != null
              ? CachedNetworkImage(
                  imageUrl: team.logoUrl!,
                  placeholder: (c, u) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (c, u, e) => const Icon(Icons.shield_outlined, size: 30),
                  fit: BoxFit.contain,
                )
              : const Icon(Icons.shield_outlined, size: 30),
          ),
          title: Text(team.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(team.leagueName),
          onTap: () => _onTeamSelected(team),
        );
      },
    );
  }
}