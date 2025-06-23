// lib/widgets/team_selection_dialog_content.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/team_name_service.dart';
import '../services/logo_service.dart';

class TeamSelectionDialogContent extends StatefulWidget {
  final List<String> availableOriginalTeamNames;
  final String leagueName; 

  const TeamSelectionDialogContent({
    super.key,
    required this.availableOriginalTeamNames,
    required this.leagueName, 
  });

  @override
  State<TeamSelectionDialogContent> createState() => _TeamSelectionDialogContentState();
}

class _TeamSelectionDialogContentState extends State<TeamSelectionDialogContent> {
  // DEĞİŞİKLİK BURADA: Tür, nullable String'i kabul edecek şekilde güncellendi.
  late List<Map<String, String?>> _teamsToDisplay;
  List<Map<String, String?>> _filteredTeams = [];
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _teamsToDisplay = widget.availableOriginalTeamNames.map((originalName) {
      return {
        'original': originalName,
        'display': TeamNameService.getCorrectedTeamName(originalName),
        'logoUrl': LogoService.getTeamLogoUrl(originalName, widget.leagueName),
      };
    }).toList();
    _teamsToDisplay.sort((a, b) => TeamNameService.normalize(a['display']!).compareTo(TeamNameService.normalize(b['display']!)));

    _filteredTeams = List.from(_teamsToDisplay);

    _searchController.addListener(() {
      _filterTeams();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTeams() {
    final query = TeamNameService.normalize(_searchController.text);
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredTeams = List.from(_teamsToDisplay);
      } else {
        _filteredTeams = _teamsToDisplay.where((teamMap) {
          // '!' kullanarak null olmayacağını varsaydığımız değerler
          bool matchesDisplay = TeamNameService.normalize(teamMap['display']!).contains(query);
          bool matchesOriginal = TeamNameService.normalize(teamMap['original']!).contains(query);
          return matchesDisplay || matchesOriginal;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Takım Ara...',
                prefixIcon: Icon(Icons.search, color: theme.inputDecorationTheme.prefixIconColor),
              ),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _filteredTeams.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.availableOriginalTeamNames.isEmpty
                            ? 'Bu lig/sezon için takım bulunmuyor.'
                            : 'Arama kriterlerine uygun takım bulunamadı.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredTeams.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      color: theme.dividerTheme.color ?? theme.dividerColor.withOpacity(0.5),
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final teamMap = _filteredTeams[index];
                      final String displayTeamName = teamMap['display']!;
                      final String originalTeamName = teamMap['original']!;
                      final String? logoUrl = teamMap['logoUrl'];
                      const double logoSize = 28.0;

                      return ListTile(
                        leading: logoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: logoUrl,
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.contain,
                                placeholder: (c, u) => const SizedBox(width: logoSize, height: logoSize),
                                errorWidget: (c, u, e) => Icon(Icons.shield_outlined, size: logoSize, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                              )
                            : Icon(Icons.shield_outlined, size: logoSize, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        title: Text(
                          displayTeamName,
                          style: theme.textTheme.bodyLarge,
                        ),
                        onTap: () {
                          Navigator.pop(context, originalTeamName);
                        },
                      );
                    },
                  ),
          ),
        ],
      );
  }
}